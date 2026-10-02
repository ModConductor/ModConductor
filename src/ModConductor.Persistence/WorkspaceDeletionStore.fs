namespace ModConductor.Persistence

open System
open System.IO
open System.Threading
open System.Threading.Tasks
open ModConductor.DeploymentRecovery
open ModConductor.GameContexts
open ModConductor.ProfileGameData
open ModConductor.Workspaces

type internal WorkspaceDeletionStore
    (
        database: StateDatabase,
        deactivate:
            WorkspaceDeletionState -> CancellationToken -> Task<Result<unit, WorkspaceError>>,
        restore:
            ProfileDataContext
                -> CancellationToken
                -> Task<Result<ProfileDataResult, ProfileDataError>>,
        enter: Guid -> IDisposable option,
        directory: string
    ) =
    let unknownSaveFolder =
        WorkspaceError.ProfileData
            "The game save folder is unknown. Select and refresh the affected profile's game context, or turn off moving saves."

    let sources (state: WorkspaceDeletionState) =
        database.Enqueue(fun () ->
            state.Data
            |> List.collect (fun (context, profiles) ->
                profiles
                |> List.choose (fun profile ->
                    profile.Saves
                    |> Option.map (fun saves ->
                        let destination =
                            GameContextRows.read
                                database.Connection
                                null
                                database.OwnerId
                                state.Workspace.Id
                                profile.ProfileId
                            |> Result.toOption
                            |> Option.bind _.Binding
                            |> Option.bind (fun binding ->
                                match
                                    binding.Evidence.Locations.Saves,
                                    binding.Evidence.Locations.Documents
                                with
                                | Location.Located(path, _), Location.Located(documents, _) when
                                    documents = ModConductor.Platform.HostPath.value
                                        context.Documents.Path
                                    ->
                                    Some path
                                | _ -> None)

                        saves, destination))))

    let protect action =
        task {
            try
                return! action ()
            with
            | RecoveryException(RecoveryError.Mismatch detail)
            | RecoveryException(RecoveryError.Unavailable detail) ->
                return Error(WorkspaceError.ProfileData detail)
            | :? IOException as error ->
                return
                    Error(
                        WorkspaceError.ProfileData(
                            error.Message
                            + " Check folder permissions or close programs using it, then try again."
                        )
                    )
            | :? UnauthorizedAccessException ->
                return
                    Error(
                        WorkspaceError.ProfileData
                            "Workspace data cannot be removed. Check folder permissions and try again."
                    )
            | :? OperationCanceledException ->
                return
                    Error(WorkspaceError.ProfileData "Workspace deletion was cancelled. Try again.")
            | :? Microsoft.Data.Sqlite.SqliteException as error ->
                return
                    Error(
                        WorkspaceError.ProfileData(
                            "Workspace registration could not be removed. Try again: "
                            + error.Message
                        )
                    )
        }

    let cleanup workspace moveSaves (token: CancellationToken) =
        task {
            match enter workspace with
            | None -> return Error WorkspaceError.Busy
            | Some lease ->
                use lease = lease
                let! latest = WorkspaceDeletionRows.read database workspace

                match latest with
                | Error error -> return Error error
                | Ok state when
                    (state.DeploymentContexts
                     |> List.exists (fun context ->
                         context.Active.IsSome
                         || not context.Links.IsEmpty
                         || not context.Originals.IsEmpty))
                    || (state.Data |> List.exists (fun (context, _) -> context.Applied.IsSome))
                    ->
                    return Error WorkspaceError.Busy
                | Ok state ->
                    let! idle = WorkspaceDeletionRows.idle database state

                    match idle with
                    | Error error -> return Error error
                    | Ok() ->
                        let! saves = sources state

                        let! moves =
                            Task.Run(fun () ->
                                if not moveSaves then
                                    Ok []
                                else
                                    saves
                                    |> List.filter (fst >> WorkspaceSaveTransfer.hasFiles)
                                    |> ProfileDataResultFlow.traverse (fun (root, destination) ->
                                        match destination with
                                        | Some path -> Ok(root, path)
                                        | None -> Error unknownSaveFolder))

                        match moves with
                        | Error error -> return Error error
                        | Ok moves ->
                            do!
                                Task.Run(fun () ->
                                    token.ThrowIfCancellationRequested()

                                    for root, destination in moves do
                                        WorkspaceSaveTransfer.move root destination token

                                    WorkspaceDeletionFiles.remove
                                        state
                                        (Path.Combine(
                                            directory,
                                            "profile-images",
                                            workspace.ToString "N"
                                        ))

                                    WorkspaceDeletionFiles.finishRoot state)

                            do! WorkspaceDeletionRows.remove database state
                            return Ok()
        }

    let prepare state moveSaves token =
        task {
            let! destinations = sources state

            let unknown =
                moveSaves
                && (destinations
                    |> List.exists (fun (root, destination) ->
                        destination.IsNone && WorkspaceSaveTransfer.hasFiles root))

            if unknown then
                return Error unknownSaveFolder
            else
                let! deactivated = deactivate state token

                match deactivated with
                | Error error -> return Error error
                | Ok() ->
                    let! unapplied = WorkspaceDeletionPreparation.unapply restore state token

                    match unapplied with
                    | Error error -> return Error error
                    | Ok() -> return! cleanup state.Workspace.Id moveSaves token
        }

    member _.Info workspace =
        protect (fun () ->
            task {
                let! read = WorkspaceDeletionRows.read database workspace

                match read with
                | Error error -> return Error error
                | Ok state ->
                    let! saves = sources state

                    let! existing =
                        Task.Run(fun () ->
                            saves |> List.filter (fst >> WorkspaceSaveTransfer.hasFiles))

                    return
                        Ok
                            { HasPrivateSaves = not existing.IsEmpty
                              SaveDestinations = existing |> List.choose snd |> List.distinct }
            })

    member _.Delete(workspace, expected, moveSaves, token) =
        protect (fun () ->
            task {
                let! read = WorkspaceDeletionRows.read database workspace

                match read with
                | Error error -> return Error error
                | Ok state when state.Workspace.Revision <> expected ->
                    return Error WorkspaceError.StaleRevision
                | Ok state when state.Receipt.Phase <> RootCreationPhase.Complete ->
                    return Error WorkspaceError.RootUnresolved
                | Ok state ->
                    do! Task.Run(fun () -> WorkspaceDeletionFiles.validate state)
                    let! idle = WorkspaceDeletionRows.idle database state

                    match idle with
                    | Error error -> return Error error
                    | Ok() ->
                        match enter workspace with
                        | None -> return Error WorkspaceError.Busy
                        | Some lease ->
                            lease.Dispose()
                            return! prepare state moveSaves token
            })
