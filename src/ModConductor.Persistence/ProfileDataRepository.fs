namespace ModConductor.Persistence

open System
open ModConductor.Platform
open ModConductor.ProfileGameData

[<Sealed>]
type internal ProfileDataRepository(database: StateDatabase, access: LibraryAccess) =
    let connection = database.Connection

    let ensureContext transaction id =
        ProfileDataRows.context connection transaction id
        |> Option.defaultWith (fun () -> ProfileDataRows.fail ProfileDataError.NotFound)

    let pending transaction (action: ProfileDataActionRecord) =
        let context = ensureContext transaction action.ContextId

        if context.Pending <> Some action.Id || context.Revision <> action.ExpectedRevision then
            ProfileDataRows.fail ProfileDataError.Stale

        context

    interface IProfileDataRepository with
        member _.HasData workspace =
            database.Enqueue(fun () ->
                Sqlite.number
                    connection
                    null
                    "SELECT count(*) FROM profile_data_contexts WHERE workspace_id=$workspace"
                    [ "$workspace", box (string workspace) ]
                <> 0L)

        member _.Read(workspace, profile) =
            task {
                let! root = access.Root workspace

                let root =
                    root
                    |> Result.defaultWith (fun _ ->
                        ProfileDataRows.fail (
                            ProfileDataError.Unavailable "The workspace folder is unavailable."
                        ))

                let! game =
                    database.Enqueue(fun () ->
                        ProfileDataRows.checkProfile connection null workspace profile

                        GameContextRows.read connection null database.OwnerId workspace profile
                        |> Result.defaultWith (fun _ ->
                            ProfileDataRows.fail ProfileDataError.NotFound))

                let documents, availability =
                    try
                        Some(DataLocations.documents game), None
                    with
                    | ProfileDataException(ProfileDataError.Unavailable detail) -> None, Some detail
                    | :? System.IO.IOException as error -> None, Some error.Message

                return!
                    database.Enqueue(fun () ->
                        use transaction = connection.BeginTransaction(deferred = true)

                        let context =
                            match documents with
                            | Some root ->
                                ProfileDataRows.context
                                    connection
                                    transaction
                                    (DataLocations.id workspace root)
                            | None ->
                                let selectedPath =
                                    game.Binding
                                    |> Option.bind (fun binding ->
                                        match binding.Evidence.Locations.Documents with
                                        | ModConductor.GameContexts.Location.Located(path, _) ->
                                            Some path
                                        | _ -> None)

                                use query =
                                    Sqlite.command
                                        connection
                                        transaction
                                        "SELECT body FROM profile_data_contexts WHERE workspace_id=$workspace"
                                        [ "$workspace", box (string workspace) ]

                                use reader = query.ExecuteReader()

                                let candidates =
                                    [ while reader.Read() do
                                          let value =
                                              ProfileDataEncoding.readContext (
                                                  reader.GetFieldValue<byte array> 0
                                              )

                                          if
                                              selectedPath = Some(
                                                  HostPath.value value.Documents.Path
                                              )
                                          then
                                              yield value ]

                                match candidates with
                                | [ value ] -> Some value
                                | _ -> None

                        let privateData =
                            context
                            |> Option.bind (fun value ->
                                ProfileDataRows.profile connection transaction value.Id profile)

                        transaction.Commit()

                        { WorkspaceId = workspace
                          ProfileId = profile
                          Workspace =
                            { Path = root.Path
                              Identity = root.Identity }
                          Game = game
                          Availability = availability
                          Context = context
                          Profile = privateData })
            }

        member _.CreateContext value =
            database.Enqueue(fun () ->
                use transaction = connection.BeginTransaction(deferred = false)

                let result =
                    match ProfileDataRows.context connection transaction value.Id with
                    | Some current when
                        current.Workspace = value.Workspace && current.Documents = value.Documents
                        ->
                        current
                    | Some _ -> ProfileDataRows.fail ProfileDataError.Stale
                    | None ->
                        ProfileDataRows.saveContext connection transaction value
                        value

                transaction.Commit()
                result)

        member _.SaveContext value =
            database.Enqueue(fun () ->
                use transaction = connection.BeginTransaction(deferred = false)
                let previous = ensureContext transaction value.Id

                if previous.Revision <> value.Revision || previous.Pending <> value.Pending then
                    ProfileDataRows.fail ProfileDataError.Stale

                ProfileDataRows.saveContext connection transaction value
                transaction.Commit())

        member _.SaveProfile(context, profile) =
            database.Enqueue(fun () ->
                use transaction = connection.BeginTransaction(deferred = false)
                let current = ensureContext transaction context

                ProfileDataRows.checkProfile
                    connection
                    transaction
                    current.WorkspaceId
                    profile.ProfileId

                ProfileDataRows.saveProfile connection transaction context profile
                transaction.Commit())

        member _.SaveOrder(context, profile, stamp) =
            database.Enqueue(fun () ->
                use transaction = connection.BeginTransaction(deferred = false)
                let current = ensureContext transaction context.Id

                if
                    current.Revision <> context.Revision
                    || FilePlanRows.stamp connection transaction profile.ProfileId <> Some stamp
                then
                    ProfileDataRows.fail ProfileDataError.Stale

                if current.Pending.IsSome then
                    ProfileDataRows.fail ProfileDataError.Busy

                ProfileDataRows.checkProfile
                    connection
                    transaction
                    current.WorkspaceId
                    profile.ProfileId

                ProfileDataRows.saveProfile connection transaction context.Id profile

                ProfileDataRows.saveContext
                    connection
                    transaction
                    { context with
                        Revision = context.Revision + 1L }

                transaction.Commit())

        member _.Profile(context, profile) =
            database.Enqueue(fun () -> ProfileDataRows.profile connection null context profile)

        member _.Claim(expected, action) =
            database.Enqueue(fun () ->
                use transaction = connection.BeginTransaction(deferred = false)
                let current = ensureContext transaction expected.Id

                ProfileDataRows.checkProfile
                    connection
                    transaction
                    current.WorkspaceId
                    action.ProfileId

                let result =
                    match ProfileDataRows.action connection transaction action.Id with
                    | Some previous when
                        previous.ContextId = action.ContextId
                        && previous.ProfileId = action.ProfileId
                        && previous.Kind = action.Kind
                        ->
                        if previous.Complete then
                            previous
                        else
                            if
                                current.Pending <> Some action.Id
                                || current.Revision <> previous.ExpectedRevision
                            then
                                ProfileDataRows.fail ProfileDataError.Stale

                            let busy =
                                Sqlite.number
                                    connection
                                    transaction
                                    "SELECT busy FROM profile_data_actions WHERE id=$id"
                                    [ "$id", box (string action.Id) ]

                            if busy <> 0L then
                                ProfileDataRows.fail ProfileDataError.Busy

                            ProfileDataRows.saveAction
                                connection
                                transaction
                                database.OwnerId
                                true
                                previous

                            previous
                    | Some _ -> ProfileDataRows.fail ProfileDataError.Stale
                    | None ->
                        if current.Revision <> expected.Revision then
                            ProfileDataRows.fail ProfileDataError.Stale

                        if current.Pending.IsSome then
                            ProfileDataRows.fail ProfileDataError.Busy

                        ProfileDataRows.checkOwnership connection transaction current

                        ProfileDataRows.saveContext
                            connection
                            transaction
                            { current with
                                Pending = Some action.Id }

                        ProfileDataRows.saveAction
                            connection
                            transaction
                            database.OwnerId
                            true
                            action

                        action

                transaction.Commit()
                result)

        member _.Action(workspace, id) =
            database.Enqueue(fun () ->
                ProfileDataRows.action connection null id
                |> Option.filter (fun action ->
                    (ensureContext null action.ContextId).WorkspaceId = workspace))

        member _.SaveAction action =
            database.Enqueue(fun () ->
                use transaction = connection.BeginTransaction(deferred = false)
                pending transaction action |> ignore
                ProfileDataRows.saveAction connection transaction database.OwnerId true action
                transaction.Commit())

        member _.Complete(context, profile, action) =
            database.Enqueue(fun () ->
                use transaction = connection.BeginTransaction(deferred = false)
                pending transaction action |> ignore

                let observed =
                    action.Files
                    |> List.tryFind (fun effect ->
                        Some effect.Target = context.PluginRoot
                        && effect.Change.Name.Equals(
                            "plugins.txt",
                            StringComparison.OrdinalIgnoreCase
                        ))
                    |> Option.map (fun effect ->
                        effect.Change.Replacement
                        |> Option.map (fun value ->
                            { value with
                                Root = effect.Target
                                Name = effect.Change.Name }))
                    |> Option.orElse context.PluginObserved

                ProfileDataRows.saveContext
                    connection
                    transaction
                    { context with
                        Revision = context.Revision + 1L
                        Pending = None
                        PluginObserved = observed
                        Applied = action.Proposed }

                profile
                |> Option.iter (ProfileDataRows.saveProfile connection transaction context.Id)

                ProfileDataRows.saveAction
                    connection
                    transaction
                    database.OwnerId
                    false
                    { action with Complete = true }

                transaction.Commit())

        member _.Release id =
            database.EnqueueInternal(fun () ->
                Sqlite.execute
                    connection
                    null
                    "UPDATE profile_data_actions SET busy=0 WHERE id=$id AND owner=$owner"
                    [ "$id", box (string id); "$owner", box database.OwnerId ])
