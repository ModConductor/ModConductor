namespace ModConductor.Engine

open System.Security.Cryptography
open System.Text
open System.Threading.Tasks
open Grpc.Core
open Grpc.Core.Interceptors

type SessionAuthentication(capability: byte array) =
    inherit Interceptor()

    let authenticate (context: ServerCallContext) =
        let supplied =
            context.RequestHeaders
            |> Seq.filter (fun entry -> entry.Key = "mc-session")
            |> Seq.toArray

        if
            supplied.Length <> 1
            || supplied[0].IsBinary
            || supplied[0].Value.Length <> capability.Length
            || not (
                CryptographicOperations.FixedTimeEquals(
                    Encoding.ASCII.GetBytes(supplied[0].Value),
                    capability
                )
            )
        then
            raise (
                RpcException(Status(StatusCode.Unauthenticated, "Session authentication failed."))
            )

    override _.UnaryServerHandler
        (request, context, continuation: UnaryServerMethod<'Request, 'Response>)
        : Task<'Response> =
        authenticate context
        continuation.Invoke(request, context)

    override _.ServerStreamingServerHandler
        (request, response, context, continuation: ServerStreamingServerMethod<'Request, 'Response>)
        =
        authenticate context
        continuation.Invoke(request, response, context)

    override _.ClientStreamingServerHandler
        (request, context, continuation: ClientStreamingServerMethod<'Request, 'Response>)
        : Task<'Response> =
        authenticate context
        continuation.Invoke(request, context)

    override _.DuplexStreamingServerHandler
        (request, response, context, continuation: DuplexStreamingServerMethod<'Request, 'Response>)
        =
        authenticate context
        continuation.Invoke(request, response, context)
