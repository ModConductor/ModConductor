namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Security.Cryptography
open System.Text.Json
open System.Threading
open ModConductor.Platform
open ModConductor.ModLibrary
open ModConductor.ModSelection
open ModConductor.Workspaces
open ModConductor.GameContexts
open ModConductor.Deployment
open ModConductor.Persistence

module DeploymentLiveFixture =
    let private wait = StorageWorker.wait
    let private result = StorageWorker.result
    let private logical = DeploymentFixtureData.path

    let private hash file =
        use stream = File.OpenRead file
        Convert.ToHexStringLower(SHA256.HashData stream)

    let private report file action =
        use stream = File.Create file
        use writer = new Utf8JsonWriter(stream, JsonWriterOptions(Indented = true))
        writer.WriteStartObject()
        action writer
        writer.WriteEndObject()
        writer.Flush()

    let private receipt (writer: Utf8JsonWriter) (value: DeploymentReceipt) =
        writer.WriteString("receipt", value.Id)
        writer.WriteNumber("revision", value.Revision)
        writer.WriteString("generation", value.Proposed)
        writer.WriteNumber("completed", value.Completed)
        writer.WriteNumber("total", value.Total)

    let run area game compat runtime tool =
        if Directory.Exists area then
            invalidOp "Use a new owned qualification directory."

        Directory.CreateDirectory area |> ignore
        let data = Path.Combine(game, "Data")
        let collisionName = "ccBGSSSE037-Curios.esl"
        let collision = Path.Combine(data, collisionName)

        if not (File.Exists collision) then
            invalidOp "The selected qualification collision file is unavailable."

        let workspace, profile, modId = Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid()
        let qualifier = "MCQualification-" + workspace.ToString("N")
        let firstPath = qualifier + "/one.txt"
        let secondPath = "Video/" + qualifier + ".txt"

        if
            Directory.GetFileSystemEntries data
            |> Array.exists (fun path ->
                Path.GetFileName(path).Equals(qualifier, StringComparison.OrdinalIgnoreCase))
        then
            invalidOp "The qualification target is already occupied."

        let before =
            Directory.GetFiles(data, "*", SearchOption.AllDirectories)
            |> Array.map (fun file -> Path.GetRelativePath(data, file), hash file)
            |> Map.ofArray

        report (Path.Combine(area, "before.json")) (fun writer ->
            writer.WriteString("game", game)
            writer.WriteNumber("fileCount", before.Count)
            writer.WriteStartObject("files")
            before |> Map.iter (fun path value -> writer.WriteString(path, value))
            writer.WriteEndObject())

        let workspacePath =
            Directory.CreateDirectory(Path.Combine(area, "workspace")).FullName

        let source =
            Directory.CreateDirectory(Path.Combine(workspacePath, "Managed")).FullName

        let write path (value: string) =
            let path = Path.Combine(source, path)
            Directory.CreateDirectory(Path.GetDirectoryName path) |> ignore
            File.WriteAllText(path, value)

        write firstPath "generation one\n"
        write secondPath "unchanged managed bytes\n"
        File.Copy(collision, Path.Combine(source, collisionName.ToLowerInvariant()), false)

        let selection =
            { Path = game
              Proton =
                if OperatingSystem.IsLinux() then
                    Some
                        { AppId = 489830u
                          Association = ProtonAssociation.Manual
                          CompatData = compat
                          RuntimeDirectory = runtime
                          ToolId = tool }
                else
                    None }

        let statePath = Path.Combine(area, "state")
        let mutable store = new OperationStore(statePath)
        let mutable lastProgress = DateTime.MinValue

        let progress (value: DeploymentProgress) =
            if (DateTime.UtcNow - lastProgress).TotalSeconds >= 1. then
                report (Path.Combine(area, "progress.json")) (fun writer ->
                    writer.WriteNumber("completed", value.Completed)
                    writer.WriteNumber("total", value.Total)
                    writer.WriteNumber("bytes", value.Bytes))

                lastProgress <- DateTime.UtcNow

        let checkpoint phase value =
            report (Path.Combine(area, phase + ".json")) (fun writer ->
                receipt writer value
                writer.WriteNumber("pid", Environment.ProcessId)
                writer.WriteString("workspace", workspace)
                writer.WriteString("profile", profile)
                writer.WriteString("data", data)
                writer.WriteStartObject("probeFiles")

                for relative in [ firstPath; secondPath; collisionName ] do
                    writer.WriteString(relative, hash (Path.Combine(data, relative)))

                writer.WriteEndObject())

            let until = DateTime.UtcNow.AddMinutes 15.

            while not (File.Exists(Path.Combine(area, phase + "-continue"))) do
                if DateTime.UtcNow > until then
                    invalidOp "The qualification checkpoint expired; its receipt remains available."

                Thread.Sleep 100

        try
            let workspaces = store.Workspaces :> IWorkspaceState

            let created =
                workspaces.Create(
                    workspace,
                    "Real deployment qualification",
                    StorageWorker.select workspacePath
                )
                |> wait
                |> result

            workspaces.Edit(
                workspace,
                created.Workspace.Revision,
                ProfileEdit.Create { Id = profile; Name = "Qualified" }
            )
            |> wait
            |> result
            |> ignore

            let library = store.ModLibrary :> IModLibrary

            let registered =
                library.Register(
                    workspace,
                    modId,
                    { Name = "Qualification"
                      Version = "1"
                      Notes = ""
                      Comment = ""
                      Source = ""
                      Categories = [] },
                    Registration.Directory(ModKind.Regular, logical "Managed")
                )
                |> wait
                |> result

            let firstVersion = Guid.NewGuid()

            let firstPublished =
                library.Publish(modId, registered.Revision, firstVersion) |> wait |> result

            let selected = InventoryObservations.read store profile

            (store.ModSelection :> IModSelection)
                .Change(profile, selected.SelectionRevision, [ modId ], SelectionEdit.Enable true)
            |> wait
            |> result
            |> ignore

            (store.GameContexts :> IGameContexts).Save(workspace, 0L, selection)
            |> wait
            |> result
            |> ignore

            let backend = store.Deployments
            let current = backend.Read profile |> wait |> result

            let first =
                backend.Prepare(Guid.NewGuid(), current.Sources, progress, CancellationToken.None)
                |> wait
                |> result

            let active =
                backend.Activate(first.Id, first.Sources, progress, CancellationToken.None)
                |> wait
                |> result

            checkpoint "phase1" active
            let contexts = store.GameContexts :> IGameContexts
            let context = contexts.Read workspace |> wait |> result
            contexts.Refresh(workspace, context.Revision) |> wait |> result |> ignore
            write firstPath "generation two\n"
            let secondVersion = Guid.NewGuid()

            library.Publish(modId, firstPublished.Revision, secondVersion)
            |> wait
            |> result
            |> ignore

            let current = backend.Read profile |> wait |> result

            let second =
                backend.Prepare(Guid.NewGuid(), current.Sources, progress, CancellationToken.None)
                |> wait
                |> result

            let active =
                backend.Activate(second.Id, second.Sources, progress, CancellationToken.None)
                |> wait
                |> result

            checkpoint "phase2" active
            let context = contexts.Read workspace |> wait |> result
            contexts.Refresh(workspace, context.Revision) |> wait |> result |> ignore
            let current = backend.Read profile |> wait |> result

            let baseline =
                backend.PrepareRetained(
                    Guid.NewGuid(),
                    current.Sources,
                    None,
                    progress,
                    CancellationToken.None
                )
                |> wait
                |> result

            use cancel = new CancellationTokenSource()

            let stopped =
                backend.Activate(
                    baseline.Id,
                    baseline.Sources,
                    (fun value ->
                        progress value
                        cancel.Cancel()),
                    cancel.Token
                )
                |> wait

            let pending = backend.Receipt baseline.Id |> wait |> result

            report (Path.Combine(area, "interrupted.json")) (fun writer ->
                receipt writer pending
                writer.WriteBoolean("interrupted", Result.isError stopped)
                writer.WriteBoolean("blocked", pending.Phase = DeploymentPhase.Blocked))

            (store :> IDisposable).Dispose()
            store <- new OperationStore(statePath)
            let contexts = store.GameContexts :> IGameContexts
            let reloaded = contexts.Read workspace |> wait |> result

            if not reloaded.Binding.Value.NeedsCheck then
                invalidOp "Restart did not require context revalidation."

            contexts.Refresh(workspace, reloaded.Revision) |> wait |> result |> ignore

            let restored =
                store.Deployments.Recover(
                    pending.Id,
                    pending.Revision,
                    false,
                    progress,
                    CancellationToken.None
                )
                |> wait
                |> result

            let after =
                Directory.GetFiles(data, "*", SearchOption.AllDirectories)
                |> Array.map (fun file -> Path.GetRelativePath(data, file), hash file)
                |> Map.ofArray

            report (Path.Combine(area, "restored.json")) (fun writer ->
                receipt writer restored
                writer.WriteBoolean("originalFilesMatch", (before = after))

                writer.WriteBoolean(
                    "ownedDirectoryRemoved",
                    not (Directory.Exists(Path.Combine(data, qualifier)))
                )

                writer.WriteBoolean(
                    "ownedLeafRemoved",
                    not (File.Exists(Path.Combine(data, secondPath)))
                )

                writer.WriteString("firstVersion", firstVersion)
                writer.WriteString("secondVersion", secondVersion)
                writer.WriteString("collisionSha256", hash collision)
                writer.WriteNumber("fileCount", after.Count))

            if before <> after then
                invalidOp "The restored game files differ from the retained baseline."

            Console.WriteLine(Path.Combine(area, "restored.json"))
        finally
            (store :> IDisposable).Dispose()
