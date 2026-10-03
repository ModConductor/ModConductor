namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Text.Json
open System.Threading
open System.Threading.Tasks
open Grpc.Core
open Microsoft.Data.Sqlite
open ModConductor.Deployment
open ModConductor.DeploymentPlanning
open ModConductor.DeploymentRecovery
open ModConductor.Engine
open ModConductor.GameContexts
open ModConductor.ModLibrary
open ModConductor.ModSelection
open ModConductor.Persistence
open ModConductor.Protocol.V1
open ModConductor.Workspaces

module DeploymentRemovalFixtures =
    let private wait = StorageWorker.wait
    let private result = StorageWorker.result
    let private token = CancellationToken.None

    type private Events() =
        let values = ResizeArray<DeploymentRunEvent>()
        member _.Values = List.ofSeq values

        interface IServerStreamWriter<DeploymentRunEvent> with
            member val WriteOptions = null with get, set

            member _.WriteAsync(value) =
                values.Add value
                Task.CompletedTask

            member _.WriteAsync(value, _) =
                values.Add value
                Task.CompletedTask

    let private receiptSequence state =
        use connection =
            new SqliteConnection("Data Source=" + Path.Combine(state, "state.db"))

        connection.Open()
        use query = connection.CreateCommand()

        query.CommandText <-
            "SELECT coalesce(max(seq),0) FROM sqlite_sequence WHERE name='deployment_receipts'"

        query.ExecuteScalar() :?> int64

    let private scenario parent action =
        let area =
            Directory.CreateDirectory(Path.Combine(parent, "removal-" + action)).FullName

        let root = Directory.CreateDirectory(Path.Combine(area, "workspace")).FullName
        let statePath = Path.Combine(area, "state")
        let game, proton = ProtonFixtures.create (Path.Combine(area, "installation"))

        let workspace, profile, other, modId =
            Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid()

        let mutable store = new OperationStore(statePath)

        use close =
            { new IDisposable with
                member _.Dispose() = (store :> IDisposable).Dispose() }

        let workspaces = store.Workspaces :> IWorkspaceState

        let created =
            workspaces.Create(workspace, "Removal", StorageWorker.select root)
            |> wait
            |> result

        let mutable revision = created.Workspace.Revision

        for id in [ profile; other ] do
            let changed =
                workspaces.Edit(
                    workspace,
                    revision,
                    ProfileEdit.Create { Id = id; Name = string id }
                )
                |> wait
                |> result

            revision <- changed.Workspace.Revision

            (store.GameContexts :> IGameContexts)
                .Save(
                    workspace,
                    id,
                    0L,
                    { GameId = GameId.SkyrimSpecialEditionSteam
                      Path = game
                      Wine = None
                      Proton = if OperatingSystem.IsLinux() then Some proton else None }
                )
            |> wait
            |> result
            |> ignore

            DeploymentFixtureData.isolateWindowsGameLocations store statePath area workspace id

        let source = Directory.CreateDirectory(Path.Combine(root, "Managed")).FullName
        File.WriteAllText(Path.Combine(source, "shared.txt"), "shared")
        let library = store.ModLibrary :> IModLibrary

        let registered =
            library.Register(
                workspace,
                modId,
                { Name = "Managed"
                  Version = "1"
                  Notes = ""
                  Comment = ""
                  Source = ""
                  Categories = [] },
                Registration.Directory(ModKind.Regular, DeploymentFixtureData.path "Managed")
            )
            |> wait
            |> result

        let version = Guid.NewGuid()

        let published =
            library.Publish(modId, registered.Revision, version) |> wait |> result

        let selection = InventoryObservations.read store profile

        (store.ModSelection :> IModSelection)
            .Change(profile, selection.SelectionRevision, [ modId ], SelectionEdit.Enable true)
        |> wait
        |> result
        |> ignore

        let otherState = store.Deployments.Read other |> wait |> result

        let otherPlan =
            store.Deployments.Prepare(Guid.NewGuid(), otherState.Sources, ignore, token)
            |> wait
            |> result

        store.Deployments.Activate(otherPlan.Id, otherPlan.Sources, ignore, token)
        |> wait
        |> result
        |> ignore

        let otherBefore = store.Deployments.Read other |> wait |> result

        let recorded = DeploymentFixtureData.create (Path.Combine(root, "recorded"))
        let generation = recorded.First
        let directory = Path.Combine(root, ".mc-generation-" + generation.Id.ToString("N"))
        Directory.Move(ModConductor.Platform.HostPath.value generation.Directory.Path, directory)

        if OperatingSystem.IsLinux() then
            File.SetUnixFileMode(
                directory,
                UnixFileMode.UserRead ||| UnixFileMode.UserWrite ||| UnixFileMode.UserExecute
            )

        Directory.Move(
            Path.Combine(directory, DeploymentFixtureData.rootId.ToString("N")),
            Path.Combine(directory, workspace.ToString("N"))
        )

        let storage = DeploymentFixtureData.location directory
        ModConductor.Platform.GenerationStorage.protectDirectory storage.Path storage.Identity

        let gameData = Path.Combine(game, "Data")
        let original = Path.Combine(gameData, "shared.txt")
        File.WriteAllText(original, "displaced original")

        let foreignFolder =
            Directory.CreateDirectory(Path.Combine(gameData, "folder")).FullName

        let foreign = Path.Combine(foreignFolder, "foreign.txt")
        File.WriteAllText(foreign, "foreign data")

        let evidence =
            ((store.GameContexts :> IGameContexts).Read(workspace, profile) |> wait |> result)
                .Binding.Value.Evidence

        let fingerprint = DeploymentContextId.fingerprint evidence
        let contextId = DeploymentContextId.create workspace profile fingerprint

        let target path =
            { Root = workspace
              Path = DeploymentFixtureData.path path }

        let targetRoot =
            { generation.Roots.Head with
                Id = workspace }

        let modVersion = library.Version(version, 0) |> wait |> result

        let request =
            { DeploymentFixtureData.request recorded (Guid.NewGuid()) 0L generation with
                ContextId = contextId
                ContextFingerprint = fingerprint
                Roots =
                    [ { recorded.Bindings.Head with
                          Root = targetRoot
                          Directory = DeploymentFixtureData.location gameData } ]
                DirectoryBoundaries = []
                PreserveOriginals = [ target "shared.txt" ]
                Generation =
                    { generation with
                        Directory = DeploymentFixtureData.location directory
                        Roots = [ targetRoot ]
                        Files =
                            generation.Files
                            |> List.map (fun file ->
                                { file with
                                    Target = { file.Target with Root = workspace }
                                    Path =
                                        ModConductor.Platform.LogicalPath.create (
                                            workspace.ToString("N")
                                            :: (ModConductor.Platform.LogicalPath.components
                                                    file.Path
                                                |> List.tail)
                                        )
                                        |> Result.defaultWith (fun _ ->
                                            invalidOp "The prepared fixture path is invalid.") })
                        Writable = []
                        References =
                            modVersion.Entries
                            |> List.map (fun entry -> SourcePin.Mod(modId, version, entry))
                        Provenance =
                            Some
                                { PreparedAt = DateTimeOffset.UtcNow
                                  Profile =
                                    Some
                                        { Id = profile
                                          Name = "Managed"
                                          Revision = 1L
                                          Mods =
                                            [ { ModId = modId
                                                VersionId = Some version
                                                Priority = 0
                                                Enabled = true } ]
                                          Hidden = Set.empty } } } }

        let receipt = store.Deployment.Start request |> wait |> DeploymentFixtureData.ok
        DeploymentFixtureData.apply store receipt |> ignore

        if File.ReadAllText original <> "shared" then
            invalidOp "The recorded fixture did not displace its original."

        let beforeSequence = receiptSequence statePath
        let beforeSaved = store.Deployments.Saved(profile, None) |> wait |> result

        if action = "mod" then
            let replacement, runtime = ProtonFixtures.create (Path.Combine(area, "replacement"))

            let current =
                (store.GameContexts :> IGameContexts).Read(workspace, profile) |> wait |> result

            (store.GameContexts :> IGameContexts)
                .Save(
                    workspace,
                    profile,
                    current.Revision,
                    { GameId = GameId.SkyrimSpecialEditionSteam
                      Path = replacement
                      Wine = None
                      Proton = if OperatingSystem.IsLinux() then Some runtime else None }
                )
            |> wait
            |> result
            |> ignore

            DeploymentFixtureData.isolateWindowsGameLocations store statePath area workspace profile

        (store :> IDisposable).Dispose()
        store <- new OperationStore(statePath)

        let restarted =
            ((store.GameContexts :> IGameContexts).Read(workspace, profile) |> wait |> result)
                .Binding.Value.NeedsCheck

        let completed =
            match action with
            | "deactivate" ->
                let events = Events()

                DeploymentService(store.Deployments)
                    .DeactivateDeployment(
                        DeactivateDeploymentRequest(
                            ProfileId = profile.ToString("N"),
                            GenerationId = generation.Id.ToString("N")
                        ),
                        events,
                        WatchCountFixtures.StreamContext(token)
                    )
                |> fun task -> task.GetAwaiter().GetResult()

                events.Values
                |> List.exists (fun event ->
                    not (isNull event.Deactivated)
                    && not (isNull event.Deactivated.State)
                    && isNull event.Deactivated.State.Active)
            | "mod" ->
                DeletionService(store.Deletions, store.Deployments)
                    .DeleteMod(
                        DeleteModRequest(
                            WorkspaceId = workspace.ToString("N"),
                            ModId = modId.ToString("N"),
                            Revision = uint64 published.Revision
                        ),
                        WatchCountFixtures.StreamContext(token)
                    )
                |> wait
                |> ignore

                ((store.ModLibrary :> IModLibrary).Scan(workspace, 100) |> wait |> result).Entries
                |> List.forall (fun entry -> entry.Id <> modId)
            | "profile" ->
                let current =
                    (store.Workspaces :> IWorkspaceState).Read(workspace, None) |> wait |> result

                let selected =
                    (store.Workspaces :> IWorkspaceState)
                        .Edit(workspace, current.Workspace.Revision, ProfileEdit.Select other)
                    |> wait
                    |> result

                let changed =
                    (store.Workspaces :> IWorkspaceState)
                        .Edit(workspace, selected.Workspace.Revision, ProfileEdit.Delete profile)
                    |> wait
                    |> Result.defaultWith (function
                        | WorkspaceError.ProfileData detail -> invalidOp detail
                        | error -> invalidOp (string error))

                changed.Deleted = Some profile
            | _ -> invalidOp "Unknown removal fixture action."

        let context = store.Deployment.Context contextId |> wait

        let cleared =
            if action = "profile" then
                context.IsNone
            else
                context
                |> Option.exists (fun value ->
                    value.Active.IsNone && value.Links.IsEmpty && value.Originals.IsEmpty)

        let otherAfter = store.Deployments.Read other |> wait |> result

        let savedUnchanged =
            action <> "deactivate"
            || (store.Deployments.Saved(profile, None) |> wait |> result).Entries.Length = beforeSaved.Entries.Length

        restarted
        && completed
        && cleared
        && savedUnchanged
        && receiptSequence statePath = beforeSequence
        && File.ReadAllText original = "displaced original"
        && File.ReadAllText foreign = "foreign data"
        && not (File.Exists(Path.Combine(gameData, "removed.txt")))
        && not (File.Exists(Path.Combine(gameData, "folder", "file.txt")))
        && otherAfter.ActiveGeneration = otherBefore.ActiveGeneration
        && File.Exists(Path.Combine(otherAfter.RunnableRoot, "SkyrimSE.exe"))

    let observe (writer: Utf8JsonWriter) primary =
        writer.WriteStartObject("deploymentRemoval")

        for action in [ "deactivate"; "mod"; "profile" ] do
            writer.WriteBoolean(action + "AfterStoreRestart", scenario primary action)

        writer.WriteEndObject()
