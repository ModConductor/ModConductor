namespace ModConductor.ProfileGameData

open System
open System.Threading
open ModConductor.Platform

module internal ProfileCloning =
    let prepare
        (repository: IProfileDataRepository)
        (initialContext: ProfileDataContext)
        (source: PrivateProfileData)
        (initial: ProfileDataActionRecord)
        (token: CancellationToken)
        progress
        captureCheckpoint
        =
        ProfileDataResultTask.resultTask {
            let targetId =
                match initial.Kind with
                | ProfileDataActionKind.Clone(target, _, _) -> target
                | _ -> invalidOp "Expected a profile clone."

            let mutable context = initialContext
            let mutable action = initial

            if
                context.Applied
                |> Option.exists (fun active ->
                    active.ProfileId = source.ProfileId && active.Options.Settings)
            then
                if not action.Prepared then
                    let! nextContext, staged =
                        DataActionPreparation.stages repository context action

                    context <- nextContext
                    action <- staged

                    let! files, _, _ =
                        SettingsPreparation.prepare
                            context
                            (Some source)
                            (Some source)
                            action.WorkspaceStage.Value
                            action.DocumentsStage.Value
                            token

                    action <-
                        { action with
                            Prepared = true
                            Files =
                                files
                                |> List.filter (fun effect -> Some effect.Target = source.Settings)
                            Link = SaveLinkEffect.Unchanged
                            Proposed = context.Applied }

                    do! repository.SaveAction action

                let save value =
                    task {
                        do! repository.SaveAction value
                        action <- value
                    }

                // Finish recorded source replacements before cancellation can delete their stage.
                let! copied =
                    DataEffects.run context action save CancellationToken.None captureCheckpoint

                action <- copied

            token.ThrowIfCancellationRequested()

            let mutable target =
                action.CloneTarget
                |> Option.defaultValue
                    { ProfileId = targetId
                      Revision = 1L
                      Options = source.Options
                      Root = None
                      Settings = None
                      Saves = None
                      SettingsInitialized = false
                      SavesInitialized = false
                      PluginOrder = source.PluginOrder
                      ArchiveList =
                        source.ArchiveList
                        |> Option.map (fun receipt -> { receipt with Documents = None }) }

            let saveTarget () =
                task {
                    action <-
                        { action with
                            CloneTarget = Some target }

                    do! repository.SaveAction action
                }

            match target.Root with
            | Some root -> DataLocations.existing context.Storage.Value root |> ignore
            | None ->
                target <-
                    { target with
                        Root =
                            Some(DataLocations.child context.Storage.Value (targetId.ToString("N"))) }

                do! saveTarget ()

            match target.Settings with
            | Some root -> DataLocations.existing target.Root.Value root |> ignore
            | None ->
                target <-
                    { target with
                        Settings = Some(DataLocations.child target.Root.Value "settings") }

                do! saveTarget ()

            match target.Saves with
            | Some root -> DataLocations.existing target.Root.Value root |> ignore
            | None ->
                target <-
                    { target with
                        Saves = Some(DataLocations.child target.Root.Value "saves") }

                do! saveTarget ()

            if source.SettingsInitialized && not target.SettingsInitialized then
                SaveTrees.clearPrepared target.Settings.Value
                let! tree = SaveTrees.observe source.Settings.Value token progress
                SaveTrees.copy tree target.Settings.Value token progress

                target <-
                    { target with
                        SettingsInitialized = true }

                do! saveTarget ()

            if source.SavesInitialized && not target.SavesInitialized then
                SaveTrees.clearPrepared target.Saves.Value
                let! tree = SaveTrees.observe source.Saves.Value token progress
                SaveTrees.copy tree target.Saves.Value token progress
                target <- { target with SavesInitialized = true }
                do! saveTarget ()

            return context, action, target
        }
