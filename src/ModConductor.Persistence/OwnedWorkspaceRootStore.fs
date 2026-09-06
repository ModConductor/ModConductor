namespace ModConductor.Persistence

open System
open System.Collections.Generic
open System.IO
open System.Text
open System.Threading.Tasks
open ModConductor.Platform

/// Storage for the root identity file only; other files in a selected root are not adopted.
type OwnedWorkspaceRootStore internal (database: StateDatabase) =
    let active = HashSet<Guid>()
    let gate = obj ()
    let mutable closed = false

    let enter id =
        lock gate (fun () -> not closed && active.Count < 2 && active.Add id)

    let leave id =
        lock gate (fun () -> active.Remove id |> ignore)

    let contents row =
        Encoding.UTF8.GetBytes(
            "ModConductor root 1\n"
            + row.Receipt.Workspace.Id.ToString("N")
            + "\n"
            + row.Marker.ToString("N")
            + "\n"
        )

    let finish row phase identity detail =
        database.EnqueueInternal(fun () ->
            WorkspaceRows.finish database.Connection database.OwnerId row phase identity detail)

    let fileAttempt action =
        Task.Run(
            Func<_>(fun () ->
                try
                    Ok(action ())
                with
                | :? IOException as error -> Error error.Message
                | :? UnauthorizedAccessException as error -> Error error.Message
                | :? PlatformNotSupportedException as error -> Error error.Message)
        )

    let claim id expected recovery phase =
        database.Enqueue(fun () ->
            WorkspaceRows.claim database.Connection database.OwnerId id expected recovery phase)

    let apply id expected afterEffect =
        task {
            if not (enter id) then
                return Error WorkspaceFailure.Busy
            else
                try
                    let! result = claim id expected false RootCreationPhase.Intent

                    match result with
                    | Error error -> return Error error
                    | Ok row when row.Receipt.Phase = RootCreationPhase.Complete ->
                        return Ok row.Receipt
                    | Ok row ->
                        let! effect =
                            fileAttempt (fun () ->
                                let root = row.Receipt.Workspace

                                let identity =
                                    RootIdentityFile.create root.Path root.Identity (contents row)

                                afterEffect ()
                                identity)

                        match effect with
                        | Ok identity ->
                            return! finish row RootCreationPhase.Observed (Some identity) ""
                        | Error error -> return! finish row RootCreationPhase.Unresolved None error
                finally
                    leave id
        }

    let reconcile id expected recovery =
        task {
            if not (enter id) then
                return Error WorkspaceFailure.Busy
            else
                try
                    let! result = claim id expected recovery RootCreationPhase.Observed

                    match result with
                    | Error error -> return Error error
                    | Ok row when row.Receipt.Phase = RootCreationPhase.Complete ->
                        return Ok row.Receipt
                    | Ok row ->
                        match row.Receipt.MarkerIdentity with
                        | None ->
                            return!
                                finish
                                    row
                                    RootCreationPhase.Unresolved
                                    None
                                    "No durable file identity was recorded. Existing files were left unchanged."
                        | Some identity ->
                            let! observed =
                                fileAttempt (fun () ->
                                    let root = row.Receipt.Workspace

                                    RootIdentityFile.matches
                                        root.Path
                                        root.Identity
                                        identity
                                        (contents row))

                            match observed with
                            | Ok true ->
                                return! finish row RootCreationPhase.Complete (Some identity) ""
                            | Ok false ->
                                return!
                                    finish
                                        row
                                        RootCreationPhase.Unresolved
                                        (Some identity)
                                        "The root identity file changed. It was left unchanged."
                            | Error error ->
                                return!
                                    finish row RootCreationPhase.Unresolved (Some identity) error
                finally
                    leave id
        }

    member _.Prepare(id: Guid, expectedWorkspaceRevision: int64, root: SelectedRoot) =
        database.Enqueue(fun () ->
            WorkspaceRows.prepare
                database.Connection
                database.OwnerId
                id
                expectedWorkspaceRevision
                root)

    member _.Get(id: Guid) =
        database.Enqueue(fun () ->
            WorkspaceRows.find database.Connection null id
            |> Option.map (fun row -> row.Receipt))

    member _.Apply(id, expectedReceiptRevision) = apply id expectedReceiptRevision ignore

    member internal _.ApplyAtCheckpoint(id, expectedReceiptRevision, afterEffect) =
        apply id expectedReceiptRevision afterEffect

    member _.Complete(id, expectedReceiptRevision) =
        reconcile id expectedReceiptRevision false

    member _.Reconcile(id, expectedReceiptRevision) =
        reconcile id expectedReceiptRevision true

    member _.Recoverable(afterId: Guid option) =
        database.Enqueue(fun () ->
            use command =
                Sqlite.command
                    database.Connection
                    null
                    "SELECT id FROM root_creation_receipts WHERE phase<>3 AND (abandoned=1 OR owner=$owner) AND id>$after ORDER BY id LIMIT 16"
                    [ "$owner", box database.OwnerId
                      "$after", box (afterId |> Option.map string |> Option.defaultValue "") ]

            use reader = command.ExecuteReader()

            [ while reader.Read() do
                  yield Guid.Parse(reader.GetString 0) ])

    member internal _.TryClose() =
        lock gate (fun () ->
            if active.Count <> 0 then
                false
            else
                closed <- true
                true)
