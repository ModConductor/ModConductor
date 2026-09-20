namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Text.Json
open ModConductor.Persistence
open ModConductor.Workspaces

module SkyrimSetupFixtures =
    let private wait (pending: System.Threading.Tasks.Task<'T>) = pending.GetAwaiter().GetResult()

    let private result =
        function
        | Ok value -> value
        | Error error -> failwith (string error)

    let observe (writer: Utf8JsonWriter) area =
        let state =
            Directory.CreateDirectory(Path.Combine(area, "skyrim-setup-state")).FullName

        let root =
            Directory.CreateDirectory(Path.Combine(area, "skyrim-setup-workspace")).FullName

        let workspace, profile = Guid.NewGuid(), Guid.NewGuid()
        let token = String.replicate 64 "a"

        do
            use store = new OperationStore(state)
            let workspaces = store.Workspaces :> IWorkspaceState

            let created =
                workspaces.Create(workspace, "Skyrim setup", StorageWorker.select root)
                |> wait
                |> result

            workspaces.Edit(
                workspace,
                created.Workspace.Revision,
                ProfileEdit.Create { Id = profile; Name = "Skyrim setup" }
            )
            |> wait
            |> result
            |> ignore

            store.SkyrimSetups.Save
                { WorkspaceId = workspace
                  ProfileId = profile
                  IncludeFnis = true
                  PlanToken = token
                  RequestedAt = DateTimeOffset.UtcNow }
            |> wait

        use reopened = new OperationStore(state)

        let recovered: StoredSkyrimSetupIntent option =
            reopened.SkyrimSetups.Read(workspace, profile) |> wait

        let foreign: StoredSkyrimSetupIntent option =
            reopened.SkyrimSetups.Read(Guid.NewGuid(), profile) |> wait

        writer.WriteStartObject("skyrimSetup")
        writer.WriteBoolean("intentSurvivesRestart", recovered.IsSome)
        writer.WriteBoolean("fnisChoiceSurvivesRestart", recovered |> Option.exists _.IncludeFnis)

        writer.WriteBoolean(
            "planConsentSurvivesRestart",
            recovered |> Option.exists (fun value -> value.PlanToken = token)
        )

        writer.WriteBoolean("profileIntentIsWorkspaceScoped", foreign.IsNone)
        writer.WriteEndObject()
