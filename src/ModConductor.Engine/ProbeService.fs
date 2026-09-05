namespace ModConductor.Engine

open System
open System.Threading.Tasks
open Grpc.Core
open ModConductor.Protocol.V1

type ProbeService() =
    inherit EngineProbe.EngineProbeBase()

    override _.InspectRuntime(request, _) =
        if request.ProtocolMajor <> 1u then
            raise (
                RpcException(Status(StatusCode.FailedPrecondition, "Unsupported protocol version."))
            )

        let runtime = Probe.runtime ()

        Task.FromResult(
            RuntimeInfo(
                ProtocolMajor = 1u,
                Architecture = runtime.Architecture,
                NativeAot = runtime.NativeAot
            )
        )

    override _.WatchHeartbeat(request, response, context) =
        task {
            if
                String.IsNullOrWhiteSpace(request.RequestId)
                || request.RequestId.Length > 64
                || request.Count < 1u
                || request.Count > 16u
            then
                raise (
                    RpcException(Status(StatusCode.InvalidArgument, "Invalid heartbeat request."))
                )

            let subscription: Probe.Subscription =
                { RequestId = request.RequestId
                  Count = int request.Count }

            for tick in Probe.ticks subscription do
                do! Task.Delay(40, context.CancellationToken)

                do!
                    response.WriteAsync(
                        Heartbeat(
                            RequestId = tick.RequestId,
                            Sequence = uint32 tick.Sequence,
                            Complete = tick.Complete
                        ),
                        context.CancellationToken
                    )
        }
        :> Task
