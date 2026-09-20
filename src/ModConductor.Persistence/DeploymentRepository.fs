namespace ModConductor.Persistence

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
                        OutputRows.active connection transaction root.Root.Id
                        || MaintenanceClaims.workspace connection transaction root.Root.Id)
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

                if
                    receipt.Context.Roots
                    |> List.exists (fun root ->
                        MaintenanceClaims.workspace connection transaction root.Root.Id)
                then
                    raise (RecoveryException RecoveryError.Busy)

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

                transaction.Commit()
                next)

        member _.Release id =
            database.EnqueueInternal(fun () ->
                Sqlite.execute
                    connection
                    null
                    "UPDATE deployment_receipts SET busy=0 WHERE id=$id AND owner=$owner"
                    [ "$id", box (string id); "$owner", box owner ])
