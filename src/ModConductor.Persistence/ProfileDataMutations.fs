namespace ModConductor.Persistence

open System
open System.IO
open System.Threading
open ModConductor.ProfileGameData
open ModConductor.Workspaces

[<Sealed>]
type internal ProfileDataMutations
    (
        database: StateDatabase,
        access: LibraryAccess,
        recovery: ModConductor.DeploymentRecovery.Recovery,
        enter: Guid -> IDisposable option
    ) =
    let connection = database.Connection
    let repository = ProfileDataRepository(database, access) :> IProfileDataRepository

    let services =
        { Database = database
          Access = access
          Recovery = recovery
          Repository = repository }

    let completed workspace command (action: ProfileDataActionRecord) =
        database.Enqueue(fun () ->
            let root = WorkspaceRows.find connection null workspace |> Option.get
            let current = WorkspaceProfiles.summary connection null root.Receipt |> Option.get

            match command with
            | ProfileEdit.Clone(_, target) ->
                match WorkspaceProfiles.profile connection null workspace target.Id with
                | Some profile ->
                    Ok
                        { Workspace = current
                          Changed = Some profile
                          Deleted = None }
                | None ->
                    Error(
                        WorkspaceError.ProfileData(
                            action.Problem
                            |> Option.defaultValue "The profile copy did not complete."
                        )
                    )
            | ProfileEdit.Delete target ->
                Ok
                    { Workspace = current
                      Changed = None
                      Deleted = Some target }
            | _ -> invalidOp "Expected a retained profile mutation.")

    let mutate
        workspace
        expected
        command
        (progress: ProfileCopyProgress -> unit)
        (token: CancellationToken)
        beforeCommit
        captureCheckpoint
        =
        task {
            match enter workspace with
            | None -> return Error WorkspaceError.Busy
            | Some lease ->
                use lease = lease

                try
                    let! validated =
                        database.Enqueue(fun () ->
                            WorkspaceProfiles.validate connection null workspace expected command)

                    match validated with
                    | Error error -> return Error error
                    | Ok(_, command) ->
                        let request =
                            { Workspace = workspace
                              Expected = expected
                              Command = command
                              Progress = progress
                              Token = token
                              BeforeCommit = beforeCommit
                              CaptureCheckpoint = captureCheckpoint }

                        match command with
                        | ProfileEdit.Create _
                        | ProfileEdit.Rename _
                        | ProfileEdit.Select _ ->
                            return!
                                database.Enqueue(fun () ->
                                    WorkspaceProfiles.edit
                                        connection
                                        workspace
                                        expected
                                        command
                                        beforeCommit)
                        | ProfileEdit.Clone(source, target) ->
                            return! ProfileCloneMutation.run services request source target
                        | ProfileEdit.Delete target ->
                            return! ProfileDeleteMutation.run services request target
                with
                | ProfileDataException ProfileDataError.Busy -> return Error WorkspaceError.Busy
                | ProfileDataException error ->
                    let detail =
                        match error with
                        | ProfileDataError.Invalid text
                        | ProfileDataError.Unavailable text
                        | ProfileDataError.Conflict text -> text
                        | ProfileDataError.NotFound -> "The private profile files were not found."
                        | ProfileDataError.Stale ->
                            "The profile data changed. Read the profile again."
                        | ProfileDataError.Cancelled -> "The profile copy was cancelled."
                        | ProfileDataError.Busy -> "Wait for the current profile operation."

                    return Error(WorkspaceError.ProfileData detail)
                | :? OperationCanceledException ->
                    return Error(WorkspaceError.ProfileData "The profile copy was cancelled.")
                | :? IOException as error -> return Error(WorkspaceError.ProfileData error.Message)
                | :? UnauthorizedAccessException ->
                    return
                        Error(
                            WorkspaceError.ProfileData
                                "The private profile files cannot be accessed."
                        )
        }

    member _.Edit(workspace, expected, command, progress, token, beforeCommit) =
        mutate workspace expected command progress token beforeCommit ignore

    member _.CloneAtCaptureCheckpoint(workspace, expected, source, target, token, checkpoint) =
        mutate workspace expected (ProfileEdit.Clone(source, target)) ignore token ignore checkpoint

    member _.Resume(workspace, id, progress, token) =
        task {
            let! existing = repository.Action(workspace, id)

            match existing with
            | Error ProfileDataError.NotFound -> return Error WorkspaceError.NotFound
            | Error ProfileDataError.Busy -> return Error WorkspaceError.Busy
            | Error error ->
                return Error(WorkspaceError.ProfileData(DataErrors.problemMessage error))
            | Ok None -> return Error WorkspaceError.NotFound
            | Ok(Some action) when
                (match action.Kind with
                 | ProfileDataActionKind.Clone _
                 | ProfileDataActionKind.Delete _ -> false
                 | _ -> true)
                ->
                return
                    Error(
                        WorkspaceError.ProfileData "Continue this action from Settings and saves."
                    )
            | Ok(Some action) ->
                let command, expected =
                    match action.Kind with
                    | ProfileDataActionKind.Clone(target, name, revision) ->
                        ProfileEdit.Clone(action.ProfileId, { Id = target; Name = name }), revision
                    | ProfileDataActionKind.Delete revision ->
                        ProfileEdit.Delete action.ProfileId, revision
                    | _ -> invalidOp "This is not a profile mutation."

                if action.Complete then
                    return! completed workspace command action
                else
                    return! mutate workspace expected command progress token ignore ignore
        }
