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

let runWithNexus registration (handoff: ModConductor.Nexus.IOAuthHandoff) args =
    let directory, workspaceDirectory =
        match args with
        | [||] ->
            let application =
                Path.Combine(
                    Environment.GetFolderPath(
                        Environment.SpecialFolder.LocalApplicationData,
                        Environment.SpecialFolderOption.Create
                    ),
                    "ModConductor"
                )

            Path.Combine(application, "state"), Path.Combine(application, "workspaces")
        | [| "--state-directory"; path |] when Path.IsPathFullyQualified path ->
            path, Path.Combine(path, "workspaces")
        | _ -> invalidArg "args" "Invalid engine arguments."

    use input = Console.OpenStandardInput()

    let capability =
        ModConductor.Engine.Bootstrap.readCapability input
        |> fun pending -> pending.GetAwaiter().GetResult()

    use sessionKey = ModConductor.Engine.SessionKey.create ()
    use certificate = ModConductor.Engine.Bootstrap.createCertificate sessionKey.Rsa

    use stateLease = ModConductor.Desktop.StateLease.acquire directory

    use credentials =
        new ModConductor.Credentials.CredentialSession(
            ModConductor.Credentials.CredentialStore.create ()
        )

    let mutable downloads: ModConductor.HttpDownloads.DownloadSession option = None

    use nexus =
        new ModConductor.Nexus.NexusSession(
            credentials,
            registration,
            handoff,
            fun subject ->
                match downloads with
                | Some value -> value.PauseAccount(subject) :> Task
                | None -> Task.CompletedTask
        )

    use store =
        new OperationStore(directory, nexusLinks = ModConductor.Engine.NexusDownloadLinks(nexus))

    downloads <- Some store.Downloads

    use skse =
        new ModConductor.Engine.SkseCoordinator(
            nexus,
            store.Downloads,
            store.GameContexts,
            store,
            handoff
        )

    use enb =
        new ModConductor.Engine.EnbCoordinator(
            nexus,
            store.Downloads,
            store,
            handoff,
            ModConductor.Enb.EnbCatalogue.lean
        )

    use fnis =
        new ModConductor.Engine.FnisCoordinator(nexus, store.Downloads, store, handoff)

    use fnisRunner = new ModConductor.Engine.FnisRunner(store)

    use skyrimSetup =
        new ModConductor.Engine.SkyrimSetupCoordinator(
            store,
            skse,
            enb,
            fnis,
            fnisRunner,
            store.GameLaunching,
            store.PluginOrders
        )

    use nxmIngress = ModConductor.Engine.NxmIngress.create nexus skse enb fnis

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

    ModConductor.Engine.EngineComposition.registerComponents
        builder.Services
        directory
        capability
        credentials
        nexus
        handoff
        nxmIngress
        skse
        enb
        fnis
        fnisRunner
        skyrimSetup
        store

    ModConductor.Engine.EngineComposition.registerWorkspaceServices
        builder.Services
        directory
        workspaceDirectory
        store

    ModConductor.Engine.EngineComposition.registerOperationServices
        builder.Services
        coordinator
        store

    ModConductor.Engine.GrpcComposition.configureGrpc builder.Services

    use app = builder.Build()
    ModConductor.Engine.GrpcComposition.mapGrpc app
    let savedNexusConnection = nexus.ConnectSaved()
    app.StartAsync().GetAwaiter().GetResult()

    let address =
        app.Services.GetRequiredService<IServer>().Features.Get<IServerAddressesFeature>().Addresses
        |> Seq.exactlyOne

    ModConductor.Engine.Bootstrap.announce (Uri(address).Port) certificate
    let lifetime = app.Services.GetRequiredService<IHostApplicationLifetime>()

    ModConductor.Engine.EngineLifetime.supervise lifetime input store coordinator skyrimSetup

    ModConductor.Engine.EngineLifetime.stop
        app
        nxmIngress
        skyrimSetup
        fnisRunner
        skse
        enb
        fnis
        store
        nexus
        savedNexusConnection
        coordinator

    0

let run args =
    runWithNexus
        None
        (ModConductor.Engine.OAuthHandoff(ModConductor.Engine.OAuthHandoff.SystemBrowser))
        args

[<EntryPoint>]
let main args =
    try
        run args
    with _ ->
        Console.Error.WriteLine("The engine could not start or stop.")
        1
