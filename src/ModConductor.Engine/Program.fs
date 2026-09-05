module ModConductor.Engine.Program

open System
open System.IO
open ModConductor.Operations
open ModConductor.Persistence
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

let run args =
    let directory =
        match args with
        | [||] ->
            Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "ModConductor",
                "state"
            )
        | [| "--state-directory"; path |] when Path.IsPathFullyQualified path -> path
        | _ -> invalidArg "args" "Invalid engine arguments."

    use input = Console.OpenStandardInput()

    let capability =
        ModConductor.Engine.Bootstrap.readCapability input
        |> fun pending -> pending.GetAwaiter().GetResult()

    use sessionKey = ModConductor.Engine.SessionKey.create ()
    use certificate = ModConductor.Engine.Bootstrap.createCertificate sessionKey.Rsa

    use store = new OperationStore(directory)

    let sqliteVersion = store.SqliteVersion

    let coordinator =
        Coordinator(store, fun () -> ModConductor.Engine.Probe.runtime sqliteVersion)

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

    builder.Services.AddSingleton<IOperationStore>(store) |> ignore
    builder.Services.AddSingleton<Coordinator>(coordinator) |> ignore
    builder.Services.AddSingleton<ModConductor.Engine.OperationService>() |> ignore

    builder.Services.AddGrpc(fun options ->
        options.Interceptors.Add<ModConductor.Engine.SessionAuthentication>()
        options.MaxReceiveMessageSize <- Nullable 4096
        options.MaxSendMessageSize <- Nullable 65536
        options.EnableDetailedErrors <- Nullable false)
    |> ignore

    use app = builder.Build()
    app.MapGrpcService<ModConductor.Engine.OperationService>() |> ignore
    app.StartAsync().GetAwaiter().GetResult()

    let address =
        app.Services.GetRequiredService<IServer>().Features.Get<IServerAddressesFeature>().Addresses
        |> Seq.exactlyOne

    ModConductor.Engine.Bootstrap.announce (Uri(address).Port) certificate
    let lifetime = app.Services.GetRequiredService<IHostApplicationLifetime>()

    coordinator.Failed.ContinueWith(fun (_: Task) -> lifetime.StopApplication())
    |> ignore

    Task.Run(fun () ->
        input.ReadByte() |> ignore
        lifetime.StopApplication())
    |> ignore

    app.WaitForShutdownAsync().GetAwaiter().GetResult()
    coordinator.Drain().GetAwaiter().GetResult()
    0

[<EntryPoint>]
let main args =
    try
        run args
    with _ ->
        Console.Error.WriteLine("The engine could not start or stop.")
        1
