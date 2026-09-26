namespace ModConductor.Persistence

open System
open System.IO
open ModConductor.DeploymentGenerations
open ModConductor.DeploymentRecovery

/// Shares the existing SQLite queue and process owner with all other workspace state.
type internal DeploymentRepository(database: StateDatabase) =
    let connection = database.Connection
    let owner = database.OwnerId

    let required value =
        value
        |> Option.defaultWith (fun () -> raise (RecoveryException RecoveryError.NotFound))

    let terminal receipt =
        receipt.Phase = ReceiptPhase.Complete || receipt.Phase = ReceiptPhase.Restored

    let checkClaim transaction id expected =
        let receipt, actualOwner, busy, _ =
            DeploymentRows.receipt connection transaction id |> required

        if receipt.Revision <> expected then
            raise (RecoveryException RecoveryError.Stale)

        if actualOwner <> owner || not busy then
            raise (RecoveryException RecoveryError.Busy)

        let context =
            DeploymentRows.context connection transaction receipt.Context.Id |> required

        if context.Pending <> Some id || context.Revision <> receipt.Context.Revision then
            raise (RecoveryException RecoveryError.Stale)

        receipt

    let retainComponentSelections transaction (receipt: Receipt) =
        match receipt.Previous with
        | None -> ()
        | Some previous when receipt.Previous = Some receipt.Proposed -> ()
        | Some previous ->
            let proposed =
                DeploymentRows.generation connection transaction receipt.Context.Id receipt.Proposed
                |> required

            let selected =
                proposed.Provenance
                |> Option.bind _.Profile
                |> Option.map (fun profile ->
                    profile.Mods
                    |> List.choose (fun row ->
                        if row.Enabled then row.VersionId |> Option.map (fun id -> row.ModId, id)
                        else None)
                    |> Map.ofList)
                |> Option.defaultValue Map.empty

            // The existing generation's component records are authority for routing.
            // A new setup has already written its own proposed-generation row.
            let copy (table: string) (columns: string) (modId: Guid) (versionId: Guid) =
                let selectedColumns = columns.Replace("generation_id", "$proposed")
                Sqlite.execute
                    connection
                    transaction
                    ("INSERT OR IGNORE INTO " + table + "(" + columns + ") SELECT " + selectedColumns + " FROM " + table + " WHERE generation_id=$previous AND mod_id=$mod AND version_id=$version")
                    [ "$proposed", box (string receipt.Proposed)
                      "$previous", box (string previous)
                      "$mod", box (string modId)
                      "$version", box (string versionId) ]

            for KeyValue(modId, versionId) in selected do
                copy
                    "skse_loader_selections"
                    "profile_id,workspace_id,mod_id,version_id,generation_id,executable,component_version,runtime_version,game_sha256,archive_sha256,nexus_mod,nexus_file,source_checked_at"
                    modId
                    versionId
                copy
                    "fnis_generators"
                    "profile_id,workspace_id,generation_id,mod_id,version_id,artifact_id,file_name,file_version,executable,component_version,archive_sha256,provider,source,terms,nexus_mod,nexus_file,acquired_at"
                    modId
                    versionId
                copy
                    "enb_generation_components"
                    "profile_id,workspace_id,generation_id,kind,mod_id,version_id,component_version,archive_sha256,nexus_mod,nexus_file,source_url,terms_url,checked_at"
                    modId
                    versionId

            let oldEnb =
                use query =
                    Sqlite.command
                        connection
                        transaction
                        "SELECT mod_id,version_id FROM enb_generation_components WHERE generation_id=$previous"
                        [ "$previous", box (string previous) ]
                use reader = query.ExecuteReader()
                [ while reader.Read() do
                    yield Guid.Parse(reader.GetString 0), Guid.Parse(reader.GetString 1) ]

            if not oldEnb.IsEmpty && oldEnb |> List.forall (fun (id, version) -> selected.TryFind id = Some version) then
                Sqlite.execute
                    connection
                    transaction
                    "INSERT OR IGNORE INTO enb_launch_plans(profile_id,workspace_id,generation_id,game_sha256,runtime_version,preset_version,runtime_sha256,preset_sha256,companion_provenance,dll_overrides,selected_runtime,previous_values,configuration_action) SELECT profile_id,workspace_id,$proposed,game_sha256,runtime_version,preset_version,runtime_sha256,preset_sha256,companion_provenance,dll_overrides,selected_runtime,previous_values,configuration_action FROM enb_launch_plans WHERE generation_id=$previous"
                    [ "$proposed", box (string receipt.Proposed)
                      "$previous", box (string previous) ]

    interface IRecoveryRepository with
        member _.Context id =
            database.Enqueue(fun () -> DeploymentRows.context connection null id)

        member _.Generation(context, id) =
            database.Enqueue(fun () -> DeploymentRows.generation connection null context id)

        member _.Read id =
            database.Enqueue(fun () ->
                DeploymentRows.receipt connection null id
                |> Option.map (fun (receipt, _, _, _) -> receipt))

        member _.Pending after =
            database.Enqueue(fun () -> DeploymentRows.pending connection after)

        member _.Begin(previous, receipt, generation, expectedSources) =
            database.Enqueue(fun () ->
                use transaction = connection.BeginTransaction(deferred = false)

                if
                    DeploymentRows.context connection transaction receipt.Context.Id <> previous
                then
                    raise (RecoveryException RecoveryError.Stale)

                if DeploymentRows.receipt connection transaction receipt.Id |> Option.isSome then
                    raise (RecoveryException RecoveryError.Stale)

                match expectedSources with
                | Some expected when
                    FilePlanRows.stamp connection transaction expected.ProfileId <> Some expected
                    ->
                    raise (RecoveryException RecoveryError.Stale)
                | _ -> ()

                if not (MaintenanceClaims.generationExists connection transaction generation) then
                    raise (RecoveryException RecoveryError.Stale)

                if
                    receipt.Context.Roots
                    |> List.exists (fun root ->
                        OutputRows.active connection transaction root.Root.Id)
                then
                    raise (RecoveryException RecoveryError.Busy)

                DeploymentRows.checkOwnership
                    connection
                    transaction
                    receipt.Context
                    (expectedSources |> Option.map _.WorkspaceId)

                DeploymentRows.writeContext
                    connection
                    transaction
                    { receipt.Context with
                        Pending = Some receipt.Id }

                DeploymentRows.writeGeneration connection transaction receipt.Context.Id generation
                DeploymentRows.insert connection transaction owner receipt
                transaction.Commit()
                receipt)

        member _.Claim(id, expected) =
            database.Enqueue(fun () ->
                use transaction = connection.BeginTransaction(deferred = false)

                let receipt, actualOwner, busy, abandoned =
                    DeploymentRows.receipt connection transaction id |> required

                if receipt.Revision <> expected then
                    raise (RecoveryException RecoveryError.Stale)

                if not (terminal receipt) then
                    if busy || (actualOwner <> owner && not abandoned) then
                        raise (RecoveryException RecoveryError.Busy)

                    let context =
                        DeploymentRows.context connection transaction receipt.Context.Id
                        |> required

                    if
                        context.Pending <> Some id || context.Revision <> receipt.Context.Revision
                    then
                        raise (RecoveryException RecoveryError.Stale)

                    Sqlite.execute
                        connection
                        transaction
                        "UPDATE deployment_receipts SET owner=$owner,busy=1,abandoned=0 WHERE id=$id"
                        [ "$owner", box owner; "$id", box (string id) ]

                transaction.Commit()
                receipt)

        member _.Save receipt =
            database.EnqueueInternal(fun () ->
                use transaction = connection.BeginTransaction(deferred = false)
                checkClaim transaction receipt.Id receipt.Revision |> ignore
                let next = DeploymentRows.update connection transaction receipt
                transaction.Commit()
                next)

        member _.Finish(receipt, context) =
            database.EnqueueInternal(fun () ->
                use transaction = connection.BeginTransaction(deferred = false)
                checkClaim transaction receipt.Id receipt.Revision |> ignore
                DeploymentRows.writeContext connection transaction context
                let next = DeploymentRows.update connection transaction receipt

                SkseRows.completeReplacement
                    connection
                    transaction
                    receipt.Id
                    (receipt.Phase = ReceiptPhase.Complete)

                EnbRows.completeReplacement
                    connection
                    transaction
                    receipt.Id
                    (receipt.Phase = ReceiptPhase.Complete)

                FnisPublicationRows.completePublication
                    connection
                    transaction
                    receipt.Id
                    (receipt.Phase = ReceiptPhase.Complete)

                if receipt.Phase = ReceiptPhase.Complete then
                    retainComponentSelections transaction receipt

                let profileViewRoot (path: string) =
                    let profile = Path.GetDirectoryName path
                    not (String.IsNullOrWhiteSpace profile)
                    && Path.GetFileName path = "game"
                    && Path.GetFileName(Path.GetDirectoryName profile) = ".mc-game-views"

                let retired =
                    if
                        context.Roots.Length = 2
                        && context.Roots
                           |> List.exists (fun root ->
                               profileViewRoot (ModConductor.Platform.HostPath.value root.Directory.Path))
                    then
                        let id =
                            match receipt.Phase with
                            | ReceiptPhase.Complete -> receipt.Previous
                            | ReceiptPhase.Restored -> Some receipt.Proposed
                            | _ -> None

                        id
                        |> Option.filter (fun id ->
                            context.Active <> Some id
                            && context.Links |> List.forall (fun link -> link.Spec.Generation <> id))
                        |> Option.bind (DeploymentRows.generation connection transaction context.Id)
                    else
                        None

                retired
                |> Option.iter (fun generation ->
                    let transient =
                        Sqlite.number
                            connection
                            transaction
                            "SELECT count(*) FROM deployment_generations WHERE context_id=$context AND id=$id AND saved=0"
                            [ "$context", box (string context.Id)
                              "$id", box (string generation.Id) ] = 1L

                    if transient && (receipt.Phase = ReceiptPhase.Complete || receipt.Phase = ReceiptPhase.Restored) then
                        Sqlite.execute
                            connection
                            transaction
                            "DELETE FROM deployment_receipts WHERE context_id=$context AND proposed_id=$id AND phase IN (2,3); DELETE FROM deployment_generations WHERE context_id=$context AND id=$id AND saved=0"
                            [ "$context", box (string context.Id)
                              "$id", box (string generation.Id) ])

                transaction.Commit()

                retired
                |> Option.iter (fun generation ->
                    try
                        GenerationFiles.removeOwned generation
                    with
                    | :? IOException as error ->
                        Diagnostics.Trace.TraceWarning(
                            "Retired profile game generation cleanup was deferred: " + error.Message
                        )
                    | :? UnauthorizedAccessException as error ->
                        Diagnostics.Trace.TraceWarning(
                            "Retired profile game generation cleanup was deferred: " + error.Message
                        ))
                next)

        member _.Release id =
            database.EnqueueInternal(fun () ->
                Sqlite.execute
                    connection
                    null
                    "UPDATE deployment_receipts SET busy=0 WHERE id=$id AND owner=$owner"
                    [ "$id", box (string id); "$owner", box owner ])
