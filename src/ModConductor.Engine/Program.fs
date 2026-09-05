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

let run () =
    use input = Console.OpenStandardInput()

    let capability =
        ModConductor.Engine.Bootstrap.readCapability input
        |> fun pending -> pending.GetAwaiter().GetResult()

    use certificate = ModConductor.Engine.Bootstrap.createCertificate ()

    let builder =
        WebApplication.CreateSlimBuilder(
            WebApplicationOptions(ContentRootPath = AppContext.BaseDirectory, Args = [||])
        )

    builder.Logging.ClearProviders() |> ignore

    builder.WebHost.ConfigureKestrel(fun options ->
        options.Listen(
            IPAddress.Loopback,
            0,
            fun endpoint ->
                endpoint.Protocols <- HttpProtocols.Http2
                endpoint.UseHttps(certificate) |> ignore
        ))
    |> ignore

    builder.Services.AddSingleton<ModConductor.Engine.SessionAuthentication>(
        ModConductor.Engine.SessionAuthentication(capability)
    )
    |> ignore

    builder.Services.AddGrpc(fun options ->
        options.Interceptors.Add<ModConductor.Engine.SessionAuthentication>()
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

    ModConductor.Engine.Bootstrap.announce (Uri(address).Port) certificate
    let lifetime = app.Services.GetRequiredService<IHostApplicationLifetime>()

    Task.Run(fun () ->
        input.ReadByte() |> ignore
        lifetime.StopApplication())
    |> ignore

    app.WaitForShutdownAsync().GetAwaiter().GetResult()
    0

[<EntryPoint>]
let main _ =
    try
        run ()
    with _ ->
        Console.Error.WriteLine("The engine could not start or stop.")
        1
