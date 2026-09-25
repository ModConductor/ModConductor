namespace ModConductor.Native.Fixtures

open System
open System.Threading
open System.Threading.Tasks
open Grpc.Core

module WatchCountFixtures =
    type StreamContext(token: CancellationToken) =
        inherit ServerCallContext()
        let mutable status = Status.DefaultSuccess
        let mutable options = null
        override _.MethodCore = "/modconductor.v1/fixture"
        override _.HostCore = "localhost"
        override _.PeerCore = "fixture"
        override _.DeadlineCore = DateTime.MaxValue
        override _.RequestHeadersCore = Metadata()
        override _.CancellationTokenCore = token
        override _.ResponseTrailersCore = Metadata()
        override _.StatusCore with get () = status and set value = status <- value
        override _.WriteOptionsCore with get () = options and set value = options <- value
        override _.AuthContextCore = Unchecked.defaultof<AuthContext>
        override _.CreatePropagationTokenCore _ = Unchecked.defaultof<ContextPropagationToken>
        override _.WriteResponseHeadersAsyncCore _ = Task.CompletedTask

    type CounterStream<'a>() =
        let mutable count = 0
        let mutable options = null
        member _.Count = Volatile.Read(&count)
        interface IServerStreamWriter<'a> with
            member _.WriteOptions with get () = options and set value = options <- value
            member _.WriteAsync(_) =
                Interlocked.Increment(&count) |> ignore
                Task.CompletedTask
            member _.WriteAsync(_, _) =
                Interlocked.Increment(&count) |> ignore
                Task.CompletedTask

    let until label condition =
        if not (SpinWait.SpinUntil(Func<bool>(condition), TimeSpan.FromSeconds 3.)) then
            failwith ("Timed out waiting for " + label + ".")
