namespace ModConductor.Persistence

open System
open System.Threading
open ModConductor.DeploymentRecovery
open ModConductor.FilePlanning
open ModConductor.ModLibrary

/// Called only by fresh Deployment Prepare. No capture occurs at tool launch or exit.
type internal ToolOutputSnapshots(database: StateDatabase, library: ModLibraryStore) =
    member _.Capture(sources: PlanSources, token: CancellationToken) =
        task {
            let! selected =
                database.Enqueue(fun () ->
                    use transaction = database.Connection.BeginTransaction(deferred = true)

                    let result =
                        if
                            FilePlanRows.stamp
                                database.Connection
                                transaction
                                sources.Stamp.ProfileId
                            <> Some sources.Stamp
                        then
                            Error RecoveryError.Stale
                        else
                            let context =
                                OutputRows.contextId
                                    sources.Stamp.WorkspaceId
                                    sources.Stamp.ProfileId
                                    sources.Context

                            use query =
                                Sqlite.command
                                    database.Connection
                                    transaction
                                    "SELECT m.id FROM mods m JOIN profile_mods s ON s.mod_id=m.id JOIN output_locations o ON o.id=m.id WHERE s.profile_id=$profile AND s.enabled=1 AND m.kind=5 AND m.source_path IS NOT NULL AND o.workspace_id=$workspace AND o.context_id=$context AND o.purpose=0 AND o.enabled=1 AND o.initialized=1 ORDER BY s.priority"
                                    [ "$profile", box (string sources.Stamp.ProfileId)
                                      "$workspace", box (string sources.Stamp.WorkspaceId)
                                      "$context", box (string context) ]

                            use reader = query.ExecuteReader()

                            let ids =
                                [ while reader.Read() do
                                      yield Guid.Parse(reader.GetString 0) ]

                            reader.Close()

                            Ok(
                                ids
                                |> List.choose (LibraryRows.find database.Connection transaction)
                            )

                    transaction.Commit()
                    result)

            match selected with
            | Error error -> return Error error
            | Ok rows ->
                let mutable failure = None

                for row in rows do
                    if failure.IsNone then
                        token.ThrowIfCancellationRequested()

                        let! published =
                            library.Access.Run(fun () ->
                                library.PublicationOwner.Capture(
                                    row.Entry.Id,
                                    row.Entry.Revision,
                                    Guid.NewGuid(),
                                    token
                                ))

                        match published with
                        | Error error ->
                            failure <-
                                Some(
                                    RecoveryError.Unavailable(
                                        "The generated output could not be captured: "
                                        + string error
                                    )
                                )
                        | Ok _ -> ()

                match failure with
                | Some error -> return Error error
                | None ->
                    return!
                        database.Enqueue(fun () ->
                            FilePlanRows.read
                                database.Connection
                                null
                                database.OwnerId
                                sources.Stamp.ProfileId
                            |> Result.mapError (fun _ -> RecoveryError.Stale)
                            |> Result.bind (fun current ->
                                // Only the requested output versions may change during our capture.
                                let captured = rows |> List.map _.Entry.Id |> Set.ofList
                                let previous = sources.Stamp.Versions |> Map.ofList

                                let versions =
                                    current.Stamp.Versions
                                    |> List.map (fun (id, version) ->
                                        id,
                                        if captured.Contains id then previous[id] else version)

                                let original =
                                    { current.Stamp with
                                        Versions = versions }

                                if original = sources.Stamp then
                                    Ok current
                                else
                                    Error RecoveryError.Stale))
        }
