namespace ModConductor.Persistence

open System
open ModConductor.Platform
open ModConductor.ProfileGameData

[<Sealed>]
type internal ProfileDataRepository(database: StateDatabase, access: LibraryAccess) =
    let connection = database.Connection

    let ensureContext transaction id =
        match ProfileDataRows.context connection transaction id with
        | Some value -> Ok value
        | None -> Error ProfileDataError.NotFound

    let pending transaction (action: ProfileDataActionRecord) =
        ensureContext transaction action.ContextId
        |> Result.bind (fun context ->
            if
                context.Pending <> Some action.Id || context.Revision <> action.ExpectedRevision
            then
                Error ProfileDataError.Stale
            else
                Ok context)

    let commit (transaction: Microsoft.Data.Sqlite.SqliteTransaction) result =
        if Result.isOk result then
            transaction.Commit()

        result

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

                match root with
                | Error _ ->
                    return
                        Error(ProfileDataError.Unavailable "The workspace folder is unavailable.")
                | Ok root ->
                    let! game =
                        database.Enqueue(fun () ->
                            ProfileDataRows.checkProfile connection null workspace profile
                            |> Result.bind (fun () ->
                                GameContextRows.read
                                    connection
                                    null
                                    database.OwnerId
                                    workspace
                                    profile
                                |> Result.mapError (fun _ -> ProfileDataError.NotFound)))

                    match game with
                    | Error error -> return Error error
                    | Ok game ->
                        let documents, availability =
                            try
                                Some(DataLocations.documents game), None
                            with
                            | ProfileDataException(ProfileDataError.Unavailable detail) ->
                                None, Some detail
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
                                                | ModConductor.GameContexts.Location.Located(path,
                                                                                             _) ->
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
                                        ProfileDataRows.profile
                                            connection
                                            transaction
                                            value.Id
                                            profile)

                                transaction.Commit()

                                Ok
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
                        Ok current
                    | Some _ -> Error ProfileDataError.Stale
                    | None ->
                        ProfileDataRows.saveContext connection transaction value
                        Ok value

                commit transaction result)

        member _.SaveContext value =
            database.Enqueue(fun () ->
                use transaction = connection.BeginTransaction(deferred = false)

                ensureContext transaction value.Id
                |> Result.bind (fun previous ->
                    if
                        previous.Revision <> value.Revision || previous.Pending <> value.Pending
                    then
                        Error ProfileDataError.Stale
                    else
                        ProfileDataRows.saveContext connection transaction value
                        Ok())
                |> commit transaction)

        member _.SaveProfile(context, profile) =
            database.Enqueue(fun () ->
                use transaction = connection.BeginTransaction(deferred = false)

                ensureContext transaction context
                |> Result.bind (fun current ->
                    ProfileDataRows.checkProfile
                        connection
                        transaction
                        current.WorkspaceId
                        profile.ProfileId)
                |> Result.map (fun () ->
                    ProfileDataRows.saveProfile connection transaction context profile)
                |> commit transaction)

        member _.SaveOrder(context, profile, stamp) =
            database.Enqueue(fun () ->
                use transaction = connection.BeginTransaction(deferred = false)

                ensureContext transaction context.Id
                |> Result.bind (fun current ->
                    if
                        current.Revision <> context.Revision
                        || FilePlanRows.stamp connection transaction profile.ProfileId
                           <> Some stamp
                    then
                        Error ProfileDataError.Stale
                    elif current.Pending.IsSome then
                        Error ProfileDataError.Busy
                    else
                        ProfileDataRows.checkProfile
                            connection
                            transaction
                            current.WorkspaceId
                            profile.ProfileId)
                |> Result.map (fun () ->
                    ProfileDataRows.saveProfile connection transaction context.Id profile

                    ProfileDataRows.saveContext
                        connection
                        transaction
                        { context with
                            Revision = context.Revision + 1L })
                |> commit transaction)

        member _.Profile(context, profile) =
            database.Enqueue(fun () -> ProfileDataRows.profile connection null context profile)

        member _.Claim(expected, action) =
            database.Enqueue(fun () ->
                use transaction = connection.BeginTransaction(deferred = false)

                let claim current =
                    ProfileDataRows.checkProfile
                        connection
                        transaction
                        current.WorkspaceId
                        action.ProfileId
                    |> Result.bind (fun () ->
                        match ProfileDataRows.action connection transaction action.Id with
                        | Some previous when
                            previous.ContextId = action.ContextId
                            && previous.ProfileId = action.ProfileId
                            && previous.Kind = action.Kind
                            ->
                            if previous.Complete then
                                Ok previous
                            elif
                                current.Pending <> Some action.Id
                                || current.Revision <> previous.ExpectedRevision
                            then
                                Error ProfileDataError.Stale
                            else
                                let busy =
                                    Sqlite.number
                                        connection
                                        transaction
                                        "SELECT busy FROM profile_data_actions WHERE id=$id"
                                        [ "$id", box (string action.Id) ]

                                if busy <> 0L then
                                    Error ProfileDataError.Busy
                                else
                                    ProfileDataRows.saveAction
                                        connection
                                        transaction
                                        database.OwnerId
                                        true
                                        previous

                                    Ok previous
                        | Some _ -> Error ProfileDataError.Stale
                        | None ->
                            if current.Revision <> expected.Revision then
                                Error ProfileDataError.Stale
                            elif current.Pending.IsSome then
                                Error ProfileDataError.Busy
                            else
                                ProfileDataRows.checkOwnership connection transaction current
                                |> Result.map (fun () ->
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

                                    action))

                ensureContext transaction expected.Id |> Result.bind claim |> commit transaction)

        member _.Action(workspace, id) =
            database.Enqueue(fun () ->
                ProfileDataRows.action connection null id
                |> Option.map (fun action ->
                    ensureContext null action.ContextId
                    |> Result.map (fun context ->
                        if context.WorkspaceId = workspace then
                            Some action
                        else
                            None))
                |> Option.defaultValue (Ok None))

        member _.SaveAction action =
            database.Enqueue(fun () ->
                use transaction = connection.BeginTransaction(deferred = false)

                pending transaction action
                |> Result.map (fun _ ->
                    ProfileDataRows.saveAction connection transaction database.OwnerId true action)
                |> commit transaction)

        member _.Complete(context, profile, action) =
            database.Enqueue(fun () ->
                use transaction = connection.BeginTransaction(deferred = false)

                pending transaction action
                |> Result.map (fun _ ->
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
                        { action with Complete = true })
                |> commit transaction)

        member _.Release id =
            database.EnqueueInternal(fun () ->
                Sqlite.execute
                    connection
                    null
                    "UPDATE profile_data_actions SET busy=0 WHERE id=$id AND owner=$owner"
                    [ "$id", box (string id); "$owner", box database.OwnerId ])
