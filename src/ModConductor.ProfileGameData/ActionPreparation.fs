namespace ModConductor.ProfileGameData

open System
open System.Threading
open ModConductor.Platform

module internal DataActionPreparation =
    let stages
        (repository: IProfileDataRepository)
        (initialContext: ProfileDataContext)
        (initialAction: ProfileDataActionRecord)
        =
        task {
            let mutable context = initialContext
            let mutable action = initialAction

            match context.OriginalsRoot with
            | Some root -> DataLocations.existing context.Documents root |> ignore
            | None ->
                let root =
                    DataLocations.child
                        context.Documents
                        (".mod-conductor-profile-originals-" + context.Id.ToString("N"))

                context <-
                    { context with
                        OriginalsRoot = Some root }

                do! repository.SaveContext context

            match action.WorkspaceStage with
            | Some root -> DataLocations.existing context.Storage.Value root |> ignore
            | None ->
                action <-
                    { action with
                        WorkspaceStage =
                            Some(
                                DataLocations.child
                                    context.Storage.Value
                                    ("action-" + action.Id.ToString("N"))
                            ) }

                do! repository.SaveAction action

            match action.DocumentsStage with
            | Some root -> DataLocations.existing context.OriginalsRoot.Value root |> ignore
            | None ->
                action <-
                    { action with
                        DocumentsStage =
                            Some(
                                DataLocations.child
                                    context.OriginalsRoot.Value
                                    (action.Id.ToString("N"))
                            ) }

                do! repository.SaveAction action

            return context, action
        }

    let prepare
        (repository: IProfileDataRepository)
        context
        (action: ProfileDataActionRecord)
        (incoming: PrivateProfileData option)
        (token: CancellationToken)
        =
        task {
            if action.Prepared then
                return context, action
            else
                let! context, action = stages repository context action

                for root in [ action.WorkspaceStage.Value; action.DocumentsStage.Value ] do
                    use staging = HeldDirectory.Open(root.Path, root.Identity)

                    for name in staging.Names |> Seq.toList do
                        match DataFiles.observe staging name token with
                        | Some file -> staging.RemoveFile(name, file.Identity)
                        | None -> ()

                let! outgoing =
                    match context.Applied with
                    | Some active -> repository.Profile(context.Id, active.ProfileId)
                    | None -> System.Threading.Tasks.Task.FromResult None

                let effects, link, proposed =
                    SettingsPreparation.prepare
                        context
                        incoming
                        outgoing
                        action.WorkspaceStage.Value
                        action.DocumentsStage.Value
                        token

                let prepared =
                    { action with
                        Prepared = true
                        Files = effects
                        Link = link
                        Proposed = proposed }

                do! repository.SaveAction prepared
                return context, prepared
        }
