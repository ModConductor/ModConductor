module ModConductor.Engine.Program

open System
open System.Net
open System.Threading.Tasks
open Microsoft.AspNetCore.Builder
open Microsoft.AspNetCore.Hosting
open Microsoft.AspNetCore.Hosting.Server
open Microsoft.AspNetCore.Hosting.Server.Features
open Microsoft.AspNetCore.Server.Kestrel.Core
open Microsoft.Extensions.DependencyInjection
open Microsoft.Extensions.Hosting
open Microsoft.Extensions.Logging

[<EntryPoint>]
let main _ =
    let builder =
        WebApplication.CreateSlimBuilder(
            WebApplicationOptions(ContentRootPath = AppContext.BaseDirectory, Args = [||])
        )

    builder.Logging.ClearProviders() |> ignore

    builder.WebHost.ConfigureKestrel(fun options ->
        options.Listen(
            IPAddress.Loopback,
            0,
            fun endpoint -> endpoint.Protocols <- HttpProtocols.Http2
        ))
    |> ignore

    builder.Services.AddGrpc(fun options ->
        options.MaxReceiveMessageSize <- Nullable 4096
        options.MaxSendMessageSize <- Nullable 4096
        options.EnableDetailedErrors <- Nullable false)
    |> ignore

    use app = builder.Build()
    app.MapGrpcService<ModConductor.Engine.ProbeService>() |> ignore
    app.StartAsync().GetAwaiter().GetResult()

    let address =
        app.Services.GetRequiredService<IServer>().Features.Get<IServerAddressesFeature>().Addresses
        |> Seq.exactlyOne
    // Only this owned stdout pipe announces the endpoint; it carries no secret.
    Console.Out.WriteLine(address)
    Console.Out.Flush()
    let lifetime = app.Services.GetRequiredService<IHostApplicationLifetime>()

    Task.Run(fun () ->
        Console.In.Read() |> ignore
        lifetime.StopApplication())
    |> ignore

    app.WaitForShutdownAsync().GetAwaiter().GetResult()
    0
