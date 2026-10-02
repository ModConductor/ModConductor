namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Threading
open System.Threading.Tasks
open ModConductor.Deployment
open ModConductor.GameContexts
open ModConductor.Persistence
open ModConductor.Workspaces
open ModConductor.Thunderstore

module UnityMonoEnvironment =
    let get task =
        task |> StorageWorker.wait |> StorageWorker.result

    let token = CancellationToken.None

    let createFor (store: OperationStore) area (definition: GameDefinition) game proton =
        let workspace = Guid.NewGuid()
        let first, second = Guid.NewGuid(), Guid.NewGuid()
        let root = Directory.CreateDirectory(Path.Combine(area, "workspace")).FullName
        let ws = store.Workspaces :> IWorkspaceState

        let initial =
            ws.Create(workspace, definition.Name, StorageWorker.select root) |> get

        let mutable revision = initial.Workspace.Revision

        for profile in [ first; second ] do
            let current =
                ws.Edit(
                    workspace,
                    revision,
                    ProfileEdit.Create { Id = profile; Name = string profile }
                )
                |> get

            revision <- current.Workspace.Revision

            (store.GameContexts :> IGameContexts)
                .Save(
                    workspace,
                    profile,
                    0L,
                    { GameId = definition.Id
                      Path = game
                      Proton = proton
                      Wine = None }
                )
            |> get
            |> ignore

        workspace, first, second, root

    let create store area game =
        createFor store area Valheim.definition game None

    let acquire (store: OperationStore) workspace =
        use loader = new DownloadServer(UnityMonoSamples.loader ())
        use plugin = new DownloadServer(UnityMonoSamples.plugin ())

        let packages =
            [ ThunderstoreSamples.package
                  ThunderstoreSamples.bep
                  (loader.Url + "/good")
                  (int64 loader.Payload.Length)
                  []
              ThunderstoreSamples.package
                  ThunderstoreSamples.jotunn
                  (plugin.Url + "/good")
                  (int64 plugin.Payload.Length)
                  [ ThunderstoreSamples.dependency ThunderstoreSamples.bep ] ]

        let acquisition =
            ThunderstoreAcquisition(
                ThunderstoreSamples.reader packages,
                store.Downloads,
                store.Artifacts,
                store.Installations,
                store.ThunderstoreInventory
            )

        acquisition.Acquire(
            workspace,
            ThunderstoreSamples.jotunn,
            (fun _ -> Task.CompletedTask),
            token
        )
        |> StorageWorker.wait
        |> Result.defaultWith (Problem.message >> invalidOp)

    let deploy (store: OperationStore) profile =
        let status = store.Deployments.Read profile |> get

        let prepared =
            store.Deployments.Prepare(Guid.NewGuid(), status.Sources, ignore, token) |> get

        let active =
            store.Deployments.Activate(prepared.Id, prepared.Sources, ignore, token) |> get

        if active.Phase <> DeploymentPhase.Complete then
            invalidOp active.Detail

        status.RunnableRoot
