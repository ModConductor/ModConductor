namespace ModConductor.ProfileGameData

open System.Threading
open ModConductor.Platform

module internal PluginPreparation =
    let prepare
        (repository: IProfileDataRepository)
        (initialContext: ProfileDataContext)
        (initialAction: ProfileDataActionRecord)
        (incoming: PrivateProfileData option)
        (desired: byte array option)
        (proposed: AppliedProfileData option)
        token
        =
        task {
            let previous = initialContext.Applied |> Option.bind _.Plugins

            match initialAction.Kind with
            | ProfileDataActionKind.Edit _ ->
                return
                    initialContext,
                    initialAction,
                    [],
                    proposed |> Option.map (fun value -> { value with Plugins = previous })
            | _ when previous.IsNone && desired.IsNone ->
                return initialContext, initialAction, [], proposed
            | _ ->
                let mutable context = initialContext
                let mutable action = initialAction
                let root = context.PluginRoot.Value
                let actual, file, bytes = PluginInputs.readFile root PluginInputs.fileName token

                match context.PluginObserved with
                | Some observed when file <> observed ->
                    DataFiles.fail
                        "The game plugin list changed. Use game order or restore the list before playing."
                | _ -> ()

                match context.PluginOriginals with
                | Some value -> DataLocations.existing root value |> ignore
                | None ->
                    context <-
                        { context with
                            PluginOriginals =
                                Some(
                                    DataLocations.child
                                        root
                                        (".mod-conductor-plugin-originals-"
                                         + context.Id.ToString("N"))
                                ) }

                    do! repository.SaveContext context

                match action.PluginStage with
                | Some value -> DataLocations.existing context.PluginOriginals.Value value |> ignore
                | None ->
                    action <-
                        { action with
                            PluginStage =
                                Some(
                                    DataLocations.child
                                        context.PluginOriginals.Value
                                        (action.Id.ToString("N"))
                                ) }

                    do! repository.SaveAction action

                let stagingRoot = action.PluginStage.Value
                use staging = HeldDirectory.Open(stagingRoot.Path, stagingRoot.Identity)

                for name in staging.Names |> Seq.toList do
                    match DataFiles.observe staging name token with
                    | Some value -> staging.RemoveFile(name, value.Identity)
                    | None -> ()

                let original =
                    match previous with
                    | Some previous -> previous.Original
                    | None ->
                        file
                        |> Option.map (fun value ->
                            { value with
                                Root = stagingRoot
                                Name = "before-plugins.txt" })

                let replacement, next =
                    match desired with
                    | Some desired when file.IsSome && bytes = desired ->
                        file,
                        Some
                            { Original = original
                              ProfileRevision = incoming.Value.Revision }
                    | Some desired ->
                        let staged =
                            { Root = stagingRoot
                              Name = "apply-plugins.txt"
                              File = DataFiles.stage staging "apply-plugins.txt" desired token }

                        Some staged,
                        Some
                            { Original = original
                              ProfileRevision = incoming.Value.Revision }
                    | None -> original, None

                let effects =
                    if replacement = file then
                        []
                    else
                        [ { Target = root
                            Backups = stagingRoot
                            Change =
                              { Name = actual
                                Before = file |> Option.map _.File
                                Replacement = replacement
                                BackupName = "before-plugins.txt" } } ]
                // An unchanged first application still needs an independent original for later restoration.
                let next =
                    match previous, next, effects, file with
                    | None, Some next, [], Some _ ->
                        let copy =
                            { Root = stagingRoot
                              Name = "original-plugins.txt"
                              File = DataFiles.stage staging "original-plugins.txt" bytes token }

                        Some { next with Original = Some copy }
                    | _ -> next

                let proposed =
                    match proposed, next with
                    | Some value, _ -> Some { value with Plugins = next }
                    | None, Some next ->
                        Some
                            { ProfileId = incoming.Value.ProfileId
                              Options = incoming.Value.Options
                              Originals = []
                              SaveOverride = None
                              SaveLink = None
                              Plugins = Some next }
                    | None, None -> None

                return context, action, effects, proposed
        }
