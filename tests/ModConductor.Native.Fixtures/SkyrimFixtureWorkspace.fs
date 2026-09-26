namespace ModConductor.Native.Fixtures

open System
open System.IO
open ModConductor.GameContexts
open ModConductor.Persistence
open ModConductor.Workspaces

module SkyrimFixtureWorkspace =
    let create
        (store: OperationStore)
        area name workspaceDirectory installationDirectory includeProton =
        let workspace, profile = Guid.NewGuid(), Guid.NewGuid()
        let root = Directory.CreateDirectory(Path.Combine(area, workspaceDirectory)).FullName
        let game, proton = ProtonFixtures.create (Path.Combine(area, installationDirectory))

        if OperatingSystem.IsLinux() then
            let launcher = Path.Combine(proton.RuntimeDirectory, "proton")
            File.WriteAllText(launcher, "#!/bin/sh\nexit 0\n")

            File.SetUnixFileMode(
                launcher,
                UnixFileMode.UserRead ||| UnixFileMode.UserWrite ||| UnixFileMode.UserExecute
            )

            File.WriteAllText(
                Path.Combine(proton.RuntimeDirectory, "toolmanifest.vdf"),
                "manifest { version 2 commandline \"/proton %verb%\" }"
            )

        let workspaces = store.Workspaces :> IWorkspaceState
        let created =
            workspaces.Create(workspace, name, StorageWorker.select root)
            |> StorageWorker.wait
            |> StorageWorker.result

        workspaces.Edit(
            workspace,
            created.Workspace.Revision,
            ProfileEdit.Create { Id = profile; Name = name }
        )
        |> StorageWorker.wait
        |> StorageWorker.result
        |> ignore

        let context =
            (store.GameContexts :> IGameContexts)
                .Save(
                    workspace,
                    profile,
                    0L,
                    { GameId = GameId.SkyrimSpecialEditionSteam
                      Path = game
                      Proton = if includeProton && OperatingSystem.IsLinux() then Some proton else None }
                )
            |> StorageWorker.wait

        workspace, profile, game, proton, context
