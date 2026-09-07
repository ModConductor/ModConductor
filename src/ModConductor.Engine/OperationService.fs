namespace ModConductor.Engine

open System
open System.Threading
open System.Threading.Tasks
open Grpc.Core
open ModConductor.Operations
open ModConductor.Protocol.V1

module private OperationWire =
    let snapshot (value: Snapshot) =
        let result =
            OperationSnapshot(
                OperationId = value.Request.Id,
                ExpectedRevision = uint64 value.Request.ExpectedRevision,
                HeartbeatCount = uint32 value.Request.Count,
                Progress = uint32 value.Progress,
                ResultRevision = uint64 value.ResultRevision,
                Phase =
                    match value.Phase with
                    | Running -> OperationPhase.Running
                    | Completed -> OperationPhase.Completed
                    | Cancelled -> OperationPhase.Cancelled
                    | Interrupted -> OperationPhase.Interrupted
                    | Stale -> OperationPhase.Stale
            )

        match value.Result with
        | Some runtime ->
            result.Result <-
                RuntimeInfo(
                    Architecture = runtime.Architecture,
                    NativeAot = runtime.NativeAot,
                    SqliteVersion = runtime.SqliteVersion
                )
        | None -> ()

        result

    let batch (value: Feed) =
        let result =
            OperationBatch(
                Cursor = uint64 value.Cursor,
                Revision = uint64 value.Revision,
                ResyncRequired = value.ResyncRequired,
                HasSnapshot = value.Snapshot.IsSome
            )

        value.Snapshot
        |> Option.iter (fun items -> result.Snapshot.AddRange(items |> Seq.map snapshot))

        result.Changes.AddRange(
            value.Changes
            |> Seq.map (fun change ->
                OperationChange(
                    Cursor = uint64 change.Cursor,
                    Operation = snapshot change.Operation
                ))
        )

        result

    let reject code message =
        raise (RpcException(Status(code, message)))

    let unwrap =
        function
        | Ok value -> value
        | Error StaleRevision ->
            reject StatusCode.FailedPrecondition "The state changed. Read the current revision."
        | Error IdentityConflict ->
            reject StatusCode.AlreadyExists "This operation ID has a different request."
        | Error Capacity -> reject StatusCode.ResourceExhausted "The operation queue is full."
        | Error NotFound -> reject StatusCode.NotFound "The operation was not found."

    let id value =
        match Guid.TryParseExact(value, "N") with
        | true, id -> id.ToString("N")
        | false, _ -> reject StatusCode.InvalidArgument "Invalid operation ID."

    let revision value =
        if value > uint64 Int64.MaxValue then
            reject StatusCode.InvalidArgument "Invalid revision or cursor."

        int64 value

    let execute action =
        task {
            try
                return! action ()
            with :? CapacityException ->
                return reject StatusCode.ResourceExhausted "The operation queue is full."
        }

type OperationService(store: IOperationStore, coordinator: Coordinator) =
    inherit EngineOperations.EngineOperationsBase()
    let readers = new SemaphoreSlim(8, 8)

    override _.GetState(request, _) =
        OperationWire.execute (fun () ->
            task {
                if request.ProtocolMajor <> 1u then
                    OperationWire.reject
                        StatusCode.FailedPrecondition
                        "Unsupported protocol version."

                let! feed = store.InitialFeed None
                return OperationWire.batch feed
            })

    override _.BeginRuntimeCheck(request, _) =
        OperationWire.execute (fun () ->
            task {
                if request.HeartbeatCount < 1u || request.HeartbeatCount > 16u then
                    OperationWire.reject StatusCode.InvalidArgument "Invalid heartbeat count."

                let command =
                    { Id = OperationWire.id request.OperationId
                      ExpectedRevision = OperationWire.revision request.ExpectedRevision
                      Count = int request.HeartbeatCount }

                let! result = coordinator.Begin command
                return result |> OperationWire.unwrap |> OperationWire.snapshot
            })

    override _.GetOperation(request, _) =
        OperationWire.execute (fun () ->
            task {
                let! result = store.Get(OperationWire.id request.OperationId)
                return result |> OperationWire.unwrap |> OperationWire.snapshot
            })

    override _.CancelOperation(request, _) =
        OperationWire.execute (fun () ->
            task {
                let! result = store.Cancel(OperationWire.id request.OperationId)
                return result |> OperationWire.unwrap |> OperationWire.snapshot
            })

    override _.WatchOperations(request, response, context) =
        task {
            if not (readers.Wait 0) then
                OperationWire.reject StatusCode.ResourceExhausted "Too many operation readers."

            try
                let after =
                    if request.HasAfterCursor then
                        Some(OperationWire.revision request.AfterCursor)
                    else
                        None

                let! initial = store.InitialFeed after
                do! response.WriteAsync(OperationWire.batch initial, context.CancellationToken)
                let mutable cursor = initial.Cursor

                while not context.CancellationToken.IsCancellationRequested do
                    let! feed = store.Changes cursor

                    if feed.ResyncRequired || not feed.Changes.IsEmpty then
                        do! response.WriteAsync(OperationWire.batch feed, context.CancellationToken)
                        cursor <- feed.Cursor
                    else
                        do! Task.Delay(40, context.CancellationToken)
            finally
                readers.Release() |> ignore
        }
        :> Task
