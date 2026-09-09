namespace ModConductor.Persistence

open System
open System.IO
open System.Security.Cryptography
open System.Threading
open System.Threading.Tasks
open ModConductor.Platform
open ModConductor.ProfileGameData
open ModConductor.Workspaces
open ModConductor.Deployment

[<Sealed>]
type internal ProfileDataMutations
    (database: StateDatabase, access: LibraryAccess, enter: Guid -> IDisposable option) =
    let connection = database.Connection
    let repository = ProfileDataRepository(database, access) :> IProfileDataRepository

    let actionId (context: Guid) (target: Guid) purpose =
        Guid(
            SHA256.HashData(
                Array.concat [ context.ToByteArray(); target.ToByteArray(); [| purpose |] ]
            )
            |> Array.take 16
        )

    let contexts profile =
        database.Enqueue(fun () ->
            use query =
                Sqlite.command
                    connection
                    null
                    "SELECT context_id FROM profile_data_profiles WHERE profile_id=$profile ORDER BY context_id"
                    [ "$profile", box (string profile) ]

            use reader = query.ExecuteReader()

            let ids =
                [ while reader.Read() do
                      yield Guid.Parse(reader.GetString 0) ]

            reader.Close()

            ids
            |> List.map (fun id ->
                ProfileDataRows.context connection null id |> Option.get,
                ProfileDataRows.profile connection null id profile |> Option.get))

    let initial id (context: ProfileDataContext) profile kind =
        { Id = id
          ContextId = context.Id
          ProfileId = profile
          ExpectedRevision = context.Revision
          Kind = kind
          Deletion = None
          CloneTarget = None
          Prepared = false
          WorkspaceStage = None
          DocumentsStage = None
          Files = []
          CompletedFiles = 0
          Link = SaveLinkEffect.Unchanged
          LinkRemoved = false
          LinkCreated = None
          Proposed = context.Applied
          Complete = false
          Problem = None }
        : ProfileDataActionRecord

    let claim context source id kind =
        task {
            let! action = repository.Claim(context, initial id context source kind)

            return
                { context with
                    Pending = Some action.Id },
                action
        }

    let clearClone (context: ProfileDataContext) (action: ProfileDataActionRecord) =
        let remove (parent: DataRoot) (root: DataRoot) =
            SaveTrees.clearPrepared root
            use held = HeldDirectory.Open(parent.Path, parent.Identity)
            held.RemoveDirectory(Path.GetFileName(HostPath.value root.Path), root.Identity)

        action.CloneTarget
        |> Option.bind _.Root
        |> Option.iter (remove context.Storage.Value)

        action.WorkspaceStage |> Option.iter (remove context.Storage.Value)

        match context.OriginalsRoot, action.DocumentsStage with
        | Some parent, Some root -> remove parent root
        | _ -> ()

    let mutate
        workspace
        expected
        command
        (progress: ProfileCopyProgress -> unit)
        (token: CancellationToken)
        beforeCommit
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
                            let! records = contexts source

                            let completed =
                                ResizeArray<
                                    ProfileDataContext *
                                    ProfileDataActionRecord *
                                    PrivateProfileData
                                 >()

                            let claimed = ResizeArray<ProfileDataContext * Guid>()

                            try
                                for context, profile in records do
                                    token.ThrowIfCancellationRequested()

                                    if
                                        context.Applied
                                        |> Option.exists (fun active -> active.ProfileId = source)
                                    then
                                        let! scope = repository.Read(workspace, source)

                                        if
                                            (DataLocations.documents scope.Game).Identity
                                            <> context.Documents.Identity
                                        then
                                            raise (
                                                ProfileDataException(
                                                    ProfileDataError.Unavailable
                                                        "Restore the profile in its previous installation before cloning it."
                                                )
                                            )

                                        GameProcesses.validate scope.Game |> ignore

                                    let! context, action =
                                        claim
                                            context
                                            source
                                            (actionId context.Id target.Id 0uy)
                                            (ProfileDataActionKind.Clone(
                                                target.Id,
                                                target.Name,
                                                expected
                                            ))

                                    claimed.Add(context, action.Id)

                                    let notify (value: ProfileDataProgress) =
                                        progress
                                            { Files = value.Files
                                              Bytes = value.Bytes }

                                    let! context, action, copy =
                                        ProfileCloning.prepare
                                            repository
                                            context
                                            profile
                                            action
                                            token
                                            notify

                                    completed.Add(context, action, copy)

                                token.ThrowIfCancellationRequested()

                                let! committed =
                                    database.Enqueue(fun () ->
                                        use transaction =
                                            connection.BeginTransaction(deferred = false)

                                        let result =
                                            WorkspaceProfiles.editIn
                                                connection
                                                transaction
                                                workspace
                                                expected
                                                command

                                        match result with
                                        | Error _ -> ()
                                        | Ok _ ->
                                            for context, action, copy in completed do
                                                let current =
                                                    ProfileDataRows.context
                                                        connection
                                                        transaction
                                                        context.Id
                                                    |> Option.get

                                                if
                                                    current.Pending <> Some action.Id
                                                    || current.Revision <> action.ExpectedRevision
                                                then
                                                    ProfileDataRows.fail ProfileDataError.Stale

                                                ProfileDataRows.saveProfile
                                                    connection
                                                    transaction
                                                    context.Id
                                                    copy

                                                ProfileDataRows.saveContext
                                                    connection
                                                    transaction
                                                    { context with
                                                        Pending = None
                                                        Revision = context.Revision + 1L }

                                                ProfileDataRows.saveAction
                                                    connection
                                                    transaction
                                                    database.OwnerId
                                                    false
                                                    { action with
                                                        Complete = true
                                                        Problem = None }

                                            beforeCommit ()
                                            transaction.Commit()

                                        result)

                                if Result.isError committed then
                                    for _, id in claimed do
                                        do! repository.Release id

                                return committed
                            with error ->
                                for context, id in claimed do
                                    let! retained = repository.Action(workspace, id)

                                    match retained with
                                    | Some action when (error :? OperationCanceledException) ->
                                        let! current =
                                            database.Enqueue(fun () ->
                                                ProfileDataRows.context connection null context.Id
                                                |> Option.get)

                                        clearClone current action

                                        do!
                                            database.Enqueue(fun () ->
                                                use transaction =
                                                    connection.BeginTransaction(deferred = false)

                                                let current =
                                                    ProfileDataRows.context
                                                        connection
                                                        transaction
                                                        context.Id
                                                    |> Option.get

                                                ProfileDataRows.saveContext
                                                    connection
                                                    transaction
                                                    { current with
                                                        Pending = None
                                                        Revision = current.Revision + 1L }

                                                ProfileDataRows.saveAction
                                                    connection
                                                    transaction
                                                    database.OwnerId
                                                    false
                                                    { action with
                                                        Complete = true
                                                        Problem =
                                                            Some "The profile copy was cancelled." }

                                                transaction.Commit())
                                    | Some _ -> do! repository.Release id
                                    | None -> ()

                                return raise error
                        | ProfileEdit.Delete target ->
                            let! records = contexts target

                            if
                                records
                                |> List.exists (fun (context, _) ->
                                    context.Applied
                                    |> Option.exists (fun active -> active.ProfileId = target))
                            then
                                return
                                    Error(
                                        WorkspaceError.ProfileData
                                            "Restore global settings and saves before deleting this profile."
                                    )
                            else
                                for context, profile in records do
                                    let! context, action =
                                        claim
                                            context
                                            target
                                            (actionId context.Id target 1uy)
                                            (ProfileDataActionKind.Delete expected)

                                    try
                                        let notify (value: ProfileDataProgress) =
                                            progress
                                                { Files = value.Files
                                                  Bytes = value.Bytes }

                                        let! action =
                                            task {
                                                match action.Deletion with
                                                | Some _ -> return action
                                                | None ->
                                                    let deletion =
                                                        match profile.Root with
                                                        | None -> ProfileDeletion.prepare [] []
                                                        | Some root ->
                                                            let tree =
                                                                SaveTrees.observe root token notify

                                                            ProfileDeletion.prepare
                                                                [ tree ]
                                                                [ { Parent = context.Storage.Value
                                                                    Name =
                                                                      Path.GetFileName(
                                                                          HostPath.value root.Path
                                                                      )
                                                                    Identity = root.Identity } ]

                                                    let prepared =
                                                        { action with Deletion = Some deletion }

                                                    do! repository.SaveAction prepared
                                                    return prepared
                                            }

                                        let! action =
                                            ProfileDeletion.run
                                                action
                                                repository.SaveAction
                                                token
                                                notify

                                        do!
                                            database.Enqueue(fun () ->
                                                use transaction =
                                                    connection.BeginTransaction(deferred = false)

                                                Sqlite.execute
                                                    connection
                                                    transaction
                                                    "DELETE FROM profile_data_profiles WHERE context_id=$context AND profile_id=$profile"
                                                    [ "$context", box (string context.Id)
                                                      "$profile", box (string target) ]

                                                ProfileDataRows.saveContext
                                                    connection
                                                    transaction
                                                    { context with
                                                        Pending = None
                                                        Revision = context.Revision + 1L }

                                                ProfileDataRows.saveAction
                                                    connection
                                                    transaction
                                                    database.OwnerId
                                                    false
                                                    { action with Complete = true }

                                                transaction.Commit())
                                    with error ->
                                        do! repository.Release action.Id
                                        raise error

                                return!
                                    database.Enqueue(fun () ->
                                        WorkspaceProfiles.edit
                                            connection
                                            workspace
                                            expected
                                            command
                                            beforeCommit)
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
        mutate workspace expected command progress token beforeCommit

    member _.Resume(workspace, id, progress, token) =
        task {
            let! existing = repository.Action(workspace, id)

            match existing with
            | None -> return Error WorkspaceError.NotFound
            | Some action when
                (match action.Kind with
                 | ProfileDataActionKind.Clone _
                 | ProfileDataActionKind.Delete _ -> false
                 | _ -> true)
                ->
                return
                    Error(
                        WorkspaceError.ProfileData "Continue this action from Settings and saves."
                    )
            | Some action ->
                let command, expected =
                    match action.Kind with
                    | ProfileDataActionKind.Clone(target, name, revision) ->
                        ProfileEdit.Clone(action.ProfileId, { Id = target; Name = name }), revision
                    | ProfileDataActionKind.Delete revision ->
                        ProfileEdit.Delete action.ProfileId, revision
                    | _ -> invalidOp "This is not a profile mutation."

                if action.Complete then
                    return!
                        database.Enqueue(fun () ->
                            let root = WorkspaceRows.find connection null workspace |> Option.get

                            let current =
                                WorkspaceProfiles.summary connection null root.Receipt
                                |> Option.get

                            match command with
                            | ProfileEdit.Clone(_, target) ->
                                match
                                    WorkspaceProfiles.profile connection null workspace target.Id
                                with
                                | Some profile ->
                                    Ok
                                        { Workspace = current
                                          Changed = Some profile
                                          Deleted = None }
                                | None ->
                                    Error(
                                        WorkspaceError.ProfileData(
                                            action.Problem
                                            |> Option.defaultValue
                                                "The profile copy did not complete."
                                        )
                                    )
                            | ProfileEdit.Delete target ->
                                Ok
                                    { Workspace = current
                                      Changed = None
                                      Deleted = Some target }
                            | _ -> invalidOp "Expected a retained profile mutation.")
                else
                    return! mutate workspace expected command progress token ignore
        }
