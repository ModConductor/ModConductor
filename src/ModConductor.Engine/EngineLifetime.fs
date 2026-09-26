module ModConductor.Engine.EngineLifetime

open System.IO
open System.Threading.Tasks
open Microsoft.AspNetCore.Builder
open Microsoft.Extensions.Hosting
open ModConductor.Operations
open ModConductor.Persistence

let internal supervise
    (lifetime: IHostApplicationLifetime)
    (input: Stream)
    (store: OperationStore)
    (coordinator: Coordinator)
    (skyrimSetup: SkyrimSetupCoordinator)
    =
    store.ModLibrary.Failed.ContinueWith(fun (_: Task) -> lifetime.StopApplication())
    |> ignore

    store.ExecutablesFailed.ContinueWith(fun (_: Task) -> lifetime.StopApplication())
    |> ignore

    coordinator.Failed.ContinueWith(fun (_: Task) -> lifetime.StopApplication())
    |> ignore

    skyrimSetup.Failed.ContinueWith(fun (_: Task) -> lifetime.StopApplication())
    |> ignore

    Task.Run(fun () ->
        input.ReadByte() |> ignore
        lifetime.StopApplication())
    |> ignore

    store.Downloads.Failed.ContinueWith(fun (_: Task) -> lifetime.StopApplication())
    |> ignore

let internal stop
    (app: WebApplication)
    (nxmIngress: ModConductor.Desktop.PrivateIngress)
    (skyrimSetup: SkyrimSetupCoordinator)
    (fnisRunner: FnisRunner)
    (skse: SkseCoordinator)
    (enb: EnbCoordinator)
    (fnis: FnisCoordinator)
    (store: OperationStore)
    (nexus: ModConductor.Nexus.NexusSession)
    (savedNexusConnection: Task)
    (coordinator: Coordinator)
    =
    app.WaitForShutdownAsync().GetAwaiter().GetResult()
    nxmIngress.Stop().GetAwaiter().GetResult()
    skyrimSetup.Stop().GetAwaiter().GetResult()
    fnisRunner.Stop().GetAwaiter().GetResult()
    skse.Stop().GetAwaiter().GetResult()
    enb.Stop().GetAwaiter().GetResult()
    fnis.Stop().GetAwaiter().GetResult()
    store.Installations.Stop().GetAwaiter().GetResult()
    store.Downloads.Stop().GetAwaiter().GetResult()
    nexus.Stop().GetAwaiter().GetResult()
    savedNexusConnection.GetAwaiter().GetResult()
    coordinator.Drain().GetAwaiter().GetResult()
    store.DrainOutputs().GetAwaiter().GetResult()
    store.CloseExecutables().GetAwaiter().GetResult()
    store.DrainDeployments().GetAwaiter().GetResult()
    store.FilePlans.Drain().GetAwaiter().GetResult()
    store.ModLibrary.Drain().GetAwaiter().GetResult()
    store.Workspaces.Drain().GetAwaiter().GetResult()
