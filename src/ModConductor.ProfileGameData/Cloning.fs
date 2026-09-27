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
                    let! stagesResult = DataActionPreparation.stages repository context action
                    let! nextContext, staged = stagesResult

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

                    let! saved = repository.SaveAction action
                    do! saved

                let save
                    (value: ProfileDataActionRecord)
                    : System.Threading.Tasks.Task<Result<unit, ProfileDataError>> =
                    ProfileDataResultTask.resultTask {
                        let! saved = repository.SaveAction value
                        do! saved
                        action <- value
                    }

                // Finish recorded source replacements before cancellation can delete their stage.
                let! copiedResult =
                    DataEffects.run context action save CancellationToken.None captureCheckpoint

                let! copied = copiedResult

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
                ProfileDataResultTask.resultTask {
                    action <-
                        { action with
                            CloneTarget = Some target }

                    let! saved = repository.SaveAction action
                    do! saved
                }

            match target.Root with
            | Some root -> DataLocations.existing context.Storage.Value root |> ignore
            | None ->
                target <-
                    { target with
                        Root =
                            Some(DataLocations.child context.Storage.Value (targetId.ToString("N"))) }

                let! saved = saveTarget ()
                do! saved

            match target.Settings with
            | Some root -> DataLocations.existing target.Root.Value root |> ignore
            | None ->
                target <-
                    { target with
                        Settings = Some(DataLocations.child target.Root.Value "settings") }

                let! saved = saveTarget ()
                do! saved

            match target.Saves with
            | Some root -> DataLocations.existing target.Root.Value root |> ignore
            | None ->
                target <-
                    { target with
                        Saves = Some(DataLocations.child target.Root.Value "saves") }

                let! saved = saveTarget ()
                do! saved

            if source.SettingsInitialized && not target.SettingsInitialized then
                SaveTrees.clearPrepared target.Settings.Value
                let! tree = SaveTrees.observe source.Settings.Value token progress
                SaveTrees.copy tree target.Settings.Value token progress

                target <-
                    { target with
                        SettingsInitialized = true }

                let! saved = saveTarget ()
                do! saved

            if source.SavesInitialized && not target.SavesInitialized then
                SaveTrees.clearPrepared target.Saves.Value
                let! tree = SaveTrees.observe source.Saves.Value token progress
                SaveTrees.copy tree target.Saves.Value token progress
                target <- { target with SavesInitialized = true }
                let! saved = saveTarget ()
                do! saved

            return context, action, target
        }
