namespace ModConductor.Diagnostics.Tests

open System
open System.IO
open System.Text
open System.Text.Json
open System.Threading
open System.Threading.Tasks
open ModConductor.Bethesda
open ModConductor.Deployment
open ModConductor.DeploymentPlanning
open ModConductor.Diagnostics
open ModConductor.Executables
open ModConductor.FilePlanning
open ModConductor.GameLaunching
open ModConductor.GameContexts
open ModConductor.ModLibrary
open ModConductor.Persistence
open ModConductor.Platform
open ModConductor.Workspaces
open NUnit.Framework

type private FixturePlans(workspaceId: Guid, profileId: Guid) =
    let snapshotId = Guid.NewGuid()

    let target =
        LogicalPath.create [ "meshes"; "marker.nif" ]
        |> Result.defaultWith (string >> invalidOp)

    let dllTarget =
        LogicalPath.create [ "SKSE"; "Plugins"; "Failed.dll" ]
        |> Result.defaultWith (string >> invalidOp)

    let dllCopy =
        { ModId = Guid.NewGuid()
          VersionId = Guid.NewGuid()
          Path = dllTarget }

    let copies =
        [ for name in [ "First mod"; "Second mod" ] do
              let id = Guid.NewGuid()

              yield
                  { Copy =
                      { ModId = id
                        VersionId = Guid.NewGuid()
                        Path = target }
                    Name = name
                    VersionLabel = "1.0"
                    Priority = 10
                    Hidden = false } ]

    let summary =
        { Id = snapshotId
          WorkspaceId = workspaceId
          ProfileId = profileId
          Fingerprint = "fixture-file-view"
          Loaded = true
          Stale = false
          PlannedFiles = 0
          AbsentTargets = 0
          InspectedFiles = 2
          Problems = [ "Multiple sources have the same priority." ]
          ProblemCount = 1
          ObservedAt = Some DateTimeOffset.UtcNow }

    let problem =
        { Id = "priority-tie:meshes/marker.nif"
          Code = "priority-tie"
          Title = "Multiple sources have the same priority."
          Target = Some target
          Sources = copies }

    let mutable stale = false
    let mutable changes = 0
    let unused () = Task.FromResult(Error(FilePlanError.Unsupported "Unused by this fixture."))

    member _.SnapshotId = snapshotId
    member _.Changes = changes
    member _.MakeStale() = stale <- true

    interface IFilePlans with
        member _.Open(_, _) = unused ()
        member _.Acquire(_, _, _, _) = unused ()

        member _.Read id =
            if id <> snapshotId then Task.FromResult(Error FilePlanError.NotFound)
            elif stale then Task.FromResult(Error FilePlanError.Stale)
            else Task.FromResult(Ok summary)

        member _.Children(_, _, _, _) = unused ()
        member _.Problems(_, _) = unused ()

        member _.DiagnosticProblems id =
            if id <> snapshotId then Task.FromResult(Error FilePlanError.NotFound)
            elif stale then Task.FromResult(Error FilePlanError.Stale)
            else Task.FromResult(Ok [ problem ])

        member _.Inspect(id, requested, _) =
            if id <> snapshotId then Task.FromResult(Error FilePlanError.NotFound)
            elif requested <> dllTarget then
                Task.FromResult(Ok { Writable = false; Snapshot = summary; Target = requested; Copies = []; FocusedCopy = None; Next = None })
            else
                let source =
                    FilePreviewSource.ManagedCopy
                        { Copy = dllCopy
                          SourcePath = dllTarget
                          Target = dllTarget
                          PayloadId = Guid.NewGuid()
                          Length = 1L
                          Sha256 = String.replicate 64 "0"
                          ModRevision = 1L }

                let copy =
                    { Source = source
                      Standing = FileSourceStanding.Winner
                      Copy = Some dllCopy
                      SourcePath = dllTarget
                      Name = "Failed plugin mod"
                      VersionLabel = "1.0"
                      Priority = Some 10
                      Enabled = true
                      Hidden = false
                      Winner = true
                      Historical = false
                      Length = 1L
                      Sha256 = String.replicate 64 "0"
                      CanHide = false
                      CanUnhide = false }

                Task.FromResult(Ok { Writable = false; Snapshot = summary; Target = requested; Copies = [ copy ]; FocusedCopy = None; Next = None })

        member _.InspectCopy(_, _) = unused ()

        member _.Change(id, copy, hidden, _) =
            if stale then
                Task.FromResult(Error FilePlanError.Stale)
            elif id <> snapshotId || copy <> copies.Head.Copy || not hidden then
                Task.FromResult(Error FilePlanError.InvalidCopy)
            else
                changes <- changes + 1
                Task.FromResult(Ok { Snapshot = summary; Changed = None })

        member _.History(_, _, _) = unused ()
        member _.Preview(_, _, _, _) = unused ()
        member _.OpenManagedText(_, _, _) = unused ()
        member _.SaveManagedText(_, _, _, _, _) = unused ()
        member _.AbandonManagedText _ = unused ()

type private FixtureLaunch(
    workspaceId: Guid,
    profileId: Guid,
    phase: RunPhase,
    contextId: Guid,
    latestContextRevision: int64
) =
    let runId = Guid.NewGuid()

    let run =
        { Source =
            RunSource.Game
                { Request =
                    { Id = runId
                      WorkspaceId = workspaceId
                      WorkspaceRevision = 2L
                      ProfileId = profileId
                      ContextRevision = latestContextRevision
                      SourceToken = "https://token.example/access=secret /home/private ; run-command" }
                  ContextId = contextId
                  Name = "Skyrim Special Edition"
                  GameDirectory = "redacted"
                  Runtime = "Fixture"
                  Launch =
                    { Executable = "redacted"
                      Arguments = []
                      WorkingDirectory = "redacted"
                      Environment = [] }
                  Preparation =
                    { Phase = GamePreparationPhase.Ready
                      Completed = 1
                      Total = 1 }
                  Files = None
                  ProfileDataRevision = 0L
                  ProfileData = None }
          Revision = 3L
          ProfileId = Some profileId
          ProfileName = Some "Main"
          RequestedAt = DateTimeOffset.UtcNow
          Phase = phase
          ProcessId = None
          Scope = None
          RootExitCode = None
          ActiveProcesses = None
          Problem = Some "Injected native path /home/example and token=secret-value" }

    interface IGameLaunching with
        member _.Read(workspace, profile) =
            if workspace = workspaceId && profile = profileId then
                Task.FromResult(
                    Ok
                        { WorkspaceId = workspaceId
                          ProfileId = profileId
                          ContextRevision = 4L
                          SourceToken = "https://token.example/access=secret /home/private ; run-command"
                          Name = "Skyrim Special Edition"
                          Runtime = "Fixture"
                          Problem = run.Problem
                          Latest = Some run }
                )
            else
                Task.FromResult(Error ExecutableError.NotFound)

        member _.Begin _ = Task.FromResult(Error ExecutableError.NotFound)
        member _.Cancel(_, _) = Task.FromResult(Error ExecutableError.NotFound)

type private FixtureDeployments(workspaceId: Guid, profileId: Guid) =
    let receiptId = Guid.NewGuid()
    let mutable statusProfile = profileId
    let mutable recoveries = 0

    let stamp profile =
        { WorkspaceId = workspaceId
          ProfileId = profile
          SelectionRevision = 1L
          ContextRevision = 1L
          ExclusionRevision = 1L
          OutputRevision = 1L
          Versions = []
          Deployment = None }

    let receipt =
        { Id = receiptId
          WorkspaceId = workspaceId
          Revision = 2L
          Phase = DeploymentPhase.Blocked
          Previous = None
          Proposed = Guid.NewGuid()
          Completed = 1
          Total = 2
          Detail = "Fixture restore" }

    member _.ReceiptId = receiptId
    member _.Revision = receipt.Revision
    member _.Recoveries = recoveries
    member _.SetStatusProfile(value) = statusProfile <- value

    interface IDeploymentBackend with
        member _.Read profile =
            if profile <> profileId then
                Task.FromResult(Error DeploymentError.NotFound)
            else
                Task.FromResult(
                    Ok
                        { WorkspaceId = workspaceId
                          Revision = 1L
                          ActiveGeneration = None
                          Active = None
                          PendingReceipt = Some receiptId
                          Sources = stamp statusProfile }
                )

        member _.Saved(_, _) = Task.FromResult(Error DeploymentError.NotFound)
        member _.Prepare(_, _, _, _) = Task.FromResult(Error DeploymentError.NotFound)
        member _.PrepareRetained(_, _, _, _, _) = Task.FromResult(Error DeploymentError.NotFound)
        member _.Activate(_, _, _, _) = Task.FromResult(Error DeploymentError.NotFound)

        member _.Recover(id, revision, restore, _, _) =
            if id = receiptId && revision = receipt.Revision && restore then
                recoveries <- recoveries + 1
                Task.FromResult(Ok receipt)
            else
                Task.FromResult(Error DeploymentError.Stale)

        member _.Receipt id =
            if id = receiptId then Task.FromResult(Ok receipt)
            else Task.FromResult(Error DeploymentError.NotFound)

        member _.PreviewRecovery(id, revision) =
            if id = receiptId && revision = receipt.Revision then
                Task.FromResult(
                    Ok
                        { ReceiptId = receiptId
                          WorkspaceId = workspaceId
                          Revision = revision
                          Paths = [ "meshes/marker.nif" ] }
                )
            else
                Task.FromResult(Error DeploymentError.Stale)

type private FixtureGameContexts(
    workspaceId: Guid,
    root: string,
    documents: Location
) =
    let identity =
        { Device = DeviceIdentity.LinuxDevice(1u, 1u)
          Low = 1UL
          High = 1UL }

    let evidence =
        { DefinitionId = Skyrim.definition.Id
          DefinitionRevision = Skyrim.definition.Revision
          Platform = ContextPlatform.Proton
          RootPath = root
          RootIdentity = Some identity
          DataPath = Some root
          DataIdentity = Some identity
          Executable =
            Some
                { Path = Path.Combine(root, Skyrim.definition.Executable)
                  Identity = identity
                  Length = 1L
                  Sha256 = String.replicate 64 "0"
                  FileVersion = "1.0"
                  ProductVersion = "1.0" }
          LauncherPath = None
          Locations =
            { Documents = documents
              Saves = Location.Located(root, true)
              LocalAppData = Location.Located(root, true) }
          Proton = None
          Problems = []
          CheckedAt = DateTimeOffset.UtcNow
          Fingerprint = "fixture-context" }

    let state =
        { WorkspaceId = workspaceId
          Revision = 4L
          Binding =
            Some
                { Id = Guid.NewGuid()
                  Path = root
                  Proton = None
                  Evidence = evidence
                  NeedsCheck = false
                  Failure = None } }

    member _.BindingId = state.Binding.Value.Id
    member _.State = state

    interface IGameContexts with
        member _.Read workspace =
            if workspace = workspaceId then
                Task.FromResult(Ok state)
            else
                Task.FromResult(Error ContextError.NotFound)

        member _.Save(_, _, _) =
            Task.FromResult(Error ContextError.NotFound)

        member _.Refresh(_, _) =
            Task.FromResult(Error ContextError.NotFound)


type private DiagnosticFixtureEnvironment(
    ?launchPhase: RunPhase,
    ?useFixtureDeployment: bool,
    ?documents: string,
    ?unavailableDocuments: string,
    ?latestContextRevision: int64
) =
    let directory =
        Path.Combine(Path.GetTempPath(), "mod-conductor-diagnostics-" + Guid.NewGuid().ToString "N")

    let state = Directory.CreateDirectory(Path.Combine(directory, "state")).FullName
    let root = Directory.CreateDirectory(Path.Combine(directory, "workspace")).FullName
    let workspaceId, profileId = Guid.NewGuid(), Guid.NewGuid()
    let store = new OperationStore(state)
    let workspaces = store.Workspaces :> IWorkspaceState

    let selectedRoot =
        HostPath.create root
        |> Result.defaultWith invalidOp
        |> RootSelection.select
        |> Result.defaultWith (fun _ -> invalidOp "The fixture root is invalid.")

    let wait (value: Task<'value>) = value.GetAwaiter().GetResult()
    let result value = value |> Result.defaultWith (fun _ -> invalidOp "The fixture request failed.")
    let created = workspaces.Create(workspaceId, "Workspace /home/private secret-value", selectedRoot) |> wait |> result

    do
        workspaces.Edit(
            workspaceId,
            created.Workspace.Revision,
            ProfileEdit.Create { Id = profileId; Name = "Main" }
        )
        |> wait
        |> result
        |> ignore

    let plans = FixturePlans(workspaceId, profileId)
    let fixtureDeployments = FixtureDeployments(workspaceId, profileId)
    let deploymentBackend =
        if defaultArg useFixtureDeployment false then fixtureDeployments :> IDeploymentBackend
        else store.Deployments

    let fixtureGameContexts =
        match documents, unavailableDocuments with
        | Some path, _ ->
            Some(FixtureGameContexts(workspaceId, path, Location.Located(path, true)))
        | None, Some detail ->
            Some(FixtureGameContexts(workspaceId, root, Location.Unavailable detail))
        | None, None -> None

    let gameContexts =
        fixtureGameContexts
        |> Option.map (fun fixture -> fixture :> IGameContexts)
        |> Option.defaultValue store.GameContexts

    let contextId =
        fixtureGameContexts
        |> Option.map _.BindingId
        |> Option.defaultWith (fun () -> Guid.NewGuid())

    let launches =
        FixtureLaunch(
            workspaceId,
            profileId,
            defaultArg launchPhase RunPhase.Failed,
            contextId,
            defaultArg latestContextRevision 4L
        )

    let diagnostics =
        DiagnosticSession(
            workspaces,
            plans :> IFilePlans,
            deploymentBackend,
            launches :> IGameLaunching,
            store.ProfileGameData,
            gameContexts,
            store.PluginOrders
        )
        :> IDiagnostics

    let request =
        { WorkspaceId = workspaceId
          ProfileId = profileId
          FileSnapshotId = Some plans.SnapshotId
          PluginSnapshotId = None
          DeploymentReceipt = None }

    member _.Diagnostics = diagnostics
    member _.Plans = plans
    member _.Deployments = fixtureDeployments
    member _.Request = request
    member _.WorkspaceId = workspaceId
    member _.ProfileId = profileId
    member _.Wait(value: Task<'value>) = wait value
    member _.Result value = result value

    interface IDisposable with
        member _.Dispose() =
            (store :> IDisposable).Dispose()
            Directory.Delete(directory, true)

[<TestFixture>]
type DiagnosticsTests() =
    [<Test>]
    member _.``failed launch and conflict should retain exact context and require explicit apply``() =
        use environment = new DiagnosticFixtureEnvironment()
        let diagnostics = environment.Diagnostics
        let snapshot = diagnostics.Check(environment.Request, CancellationToken.None) |> environment.Wait |> environment.Result
        let launch = snapshot.Findings |> List.find (fun finding -> finding.Code = "launch-failed")
        let conflict = snapshot.Findings |> List.find (fun finding -> finding.Code = "priority-tie")

        Assert.That(launch.WorkspaceId, Is.EqualTo environment.WorkspaceId)
        Assert.That(launch.ProfileId, Is.EqualTo environment.ProfileId)
        Assert.That(launch.Evidence.Length, Is.GreaterThanOrEqualTo 4)
        Assert.That(conflict.Fixability, Is.EqualTo Fixability.PreviewAvailable)

        let preview = diagnostics.Preview(snapshot.Id, conflict.Id, CancellationToken.None) |> environment.Wait |> environment.Result
        Assert.That(environment.Plans.Changes, Is.Zero)
        Assert.That(preview.Items.Length, Is.EqualTo 3)
        Assert.That(preview.Items[0].Label, Is.EqualTo "Target file")
        Assert.That(preview.Items[0].Value, Is.EqualTo "meshes/marker.nif")
        Assert.That(preview.Items[1].Label, Is.EqualTo "Saved copy")
        Assert.That(preview.Items[1].Value, Is.EqualTo "First mod · 1.0")
        Assert.That(preview.Items[2].Label, Is.EqualTo "Profile setting")
        Assert.That(preview.Items[2].Value, Is.EqualTo "Hide this copy for Main")
        Assert.That(
            preview.Identifiers |> List.map _.Label = [ "Mod ID"; "Version ID"; "Profile ID" ],
            Is.True
        )

        let applied = diagnostics.Apply(preview.Id, CancellationToken.None) |> environment.Wait |> environment.Result
        Assert.That(applied.Complete, Is.True)
        Assert.That(
            applied.Detail = Some "Second mod now supplies this file in the saved mod files.",
            Is.True
        )
        Assert.That(environment.Plans.Changes, Is.EqualTo 1)

        let repeated = diagnostics.Apply(preview.Id, CancellationToken.None) |> environment.Wait
        let repeatedRefused =
            match repeated with
            | Error DiagnosticError.Expired -> true
            | _ -> false

        Assert.That(repeatedRefused, Is.True)
        Assert.That(environment.Plans.Changes, Is.EqualTo 1)

    [<Test>]
    member _.``stale and foreign targets should refuse without a write``() =
        use environment = new DiagnosticFixtureEnvironment()
        let diagnostics = environment.Diagnostics
        let snapshot = diagnostics.Check(environment.Request, CancellationToken.None) |> environment.Wait |> environment.Result
        let conflict = snapshot.Findings |> List.find (fun finding -> finding.Code = "priority-tie")
        environment.Plans.MakeStale()

        let stale = diagnostics.Preview(snapshot.Id, conflict.Id, CancellationToken.None) |> environment.Wait
        let staleRefused =
            match stale with
            | Error DiagnosticError.Stale -> true
            | _ -> false

        Assert.That(staleRefused, Is.True)

        let foreignRequest =
            { environment.Request with
                ProfileId = Guid.NewGuid()
                FileSnapshotId = None
                PluginSnapshotId = None }

        let foreign = diagnostics.Check(foreignRequest, CancellationToken.None) |> environment.Wait
        let foreignRefused =
            match foreign with
            | Error DiagnosticError.Foreign -> true
            | _ -> false

        Assert.That(foreignRefused, Is.True)
        Assert.That(environment.Plans.Changes, Is.Zero)

    [<Test>]
    member _.``support report should correlate safe identifiers without disclosed input``() =
        use environment = new DiagnosticFixtureEnvironment()
        let diagnostics = environment.Diagnostics
        let snapshot = diagnostics.Check(environment.Request, CancellationToken.None) |> environment.Wait |> environment.Result
        let report = diagnostics.Export(snapshot.Id, CancellationToken.None) |> environment.Wait |> environment.Result
        let text = Encoding.UTF8.GetString report.Content
        use json = JsonDocument.Parse report.Content

        let ids =
            json.RootElement.GetProperty("problems").EnumerateArray()
            |> Seq.collect (fun problem -> problem.GetProperty("ids").EnumerateArray())
            |> Seq.toArray

        Assert.That(ids.Length, Is.GreaterThanOrEqualTo 3)
        Assert.That(
            ids
            |> Array.forall (fun item ->
                match Guid.TryParseExact(item.GetProperty("id").GetString(), "N") with
                | true, _ -> true
                | _ -> false),
            Is.True
        )
        Assert.That(text, Does.Not.Contain "secret-value")
        Assert.That(text, Does.Not.Contain "/home/")
        Assert.That(text, Does.Not.Contain "token=")
        Assert.That(text, Does.Not.Contain "token.example")
        Assert.That(text, Does.Not.Contain "run-command")
        Assert.That(report.Content.Length, Is.LessThanOrEqualTo ModConductor.Diagnostics.Limits.exportBytes)

    [<Test>]
    member _.``process cache should expire the oldest diagnostic snapshot at its exact bound``() =
        use environment = new DiagnosticFixtureEnvironment()
        let diagnostics = environment.Diagnostics

        let snapshots =
            [ for _ in 1 .. ModConductor.Diagnostics.Limits.previews + 1 ->
                  diagnostics.Check(environment.Request, CancellationToken.None)
                  |> environment.Wait
                  |> environment.Result ]

        let oldest = diagnostics.Export(snapshots.Head.Id, CancellationToken.None) |> environment.Wait
        let newest =
            diagnostics.Export((snapshots |> List.last).Id, CancellationToken.None)
            |> environment.Wait
        let oldestExpired =
            match oldest with
            | Error DiagnosticError.Expired -> true
            | _ -> false

        Assert.That(oldestExpired, Is.True)
        Assert.That(Result.isOk newest, Is.True)

    [<Test>]
    member _.``deployment receipt should require the selected profile owner at check preview and apply``() =
        use environment = new DiagnosticFixtureEnvironment(useFixtureDeployment = true)
        let diagnostics = environment.Diagnostics
        let deployment = environment.Deployments
        let request =
            { environment.Request with
                FileSnapshotId = None
                PluginSnapshotId = None
                DeploymentReceipt = Some(deployment.ReceiptId, deployment.Revision) }

        let snapshot = diagnostics.Check(request, CancellationToken.None) |> environment.Wait |> environment.Result
        let finding = snapshot.Findings |> List.find (fun value -> value.Code = "deployment-incomplete")
        let preview = diagnostics.Preview(snapshot.Id, finding.Id, CancellationToken.None) |> environment.Wait |> environment.Result
        Assert.That(preview.Items, Has.Length.EqualTo 1)

        deployment.SetStatusProfile(Guid.NewGuid())
        let apply = diagnostics.Apply(preview.Id, CancellationToken.None) |> environment.Wait
        let applyRefused =
            match apply with
            | Error DiagnosticError.Foreign -> true
            | _ -> false

        Assert.That(applyRefused, Is.True)
        Assert.That(deployment.Recoveries = 0, Is.True)

        let refused = diagnostics.Check(request, CancellationToken.None) |> environment.Wait
        let checkRefused =
            match refused with
            | Error DiagnosticError.Foreign -> true
            | _ -> false

        Assert.That(checkRefused, Is.True)

    [<Test>]
    member _.``cancelled launch should produce one bounded finding``() =
        use environment = new DiagnosticFixtureEnvironment(launchPhase = RunPhase.Cancelled)
        let snapshot =
            environment.Diagnostics.Check(environment.Request, CancellationToken.None)
            |> environment.Wait
            |> environment.Result

        let finding = snapshot.Findings |> List.find (fun value -> value.Code = "launch-cancelled")
        let launchFindings =
            snapshot.Findings
            |> List.filter (fun value -> value.Code.StartsWith("launch-", StringComparison.Ordinal))

        Assert.That(launchFindings, Has.Length.EqualTo 1)
        Assert.That(finding.Severity, Is.EqualTo DiagnosticSeverity.Information)
        Assert.That(finding.Fixability, Is.EqualTo Fixability.NotFixable)
        Assert.That(finding.Action, Is.EqualTo DiagnosticAction.CheckAgain)
        Assert.That(Option.isNone finding.Detail, Is.True)

[<TestFixture>]
type SkyrimDiagnosticSessionTests() =
    [<Test>]
    member _.``skyrim diagnostics should require an available compiled capability``() =
        let workspaceId = Guid.NewGuid()

        let context =
            FixtureGameContexts(
                workspaceId,
                "fixture",
                Location.Located("fixture", false)
            )

        Assert.That(
            DiagnosticAdmission.tryBinding
                workspaceId
                CapabilityId.SkyrimSpecialEdition
                context.State
            |> Option.isSome,
            Is.True
        )

        Assert.That(
            DiagnosticAdmission.tryBinding
                workspaceId
                CapabilityId.IndividualSaveEditing
                context.State
            |> Option.isNone,
            Is.True
        )

        Assert.That(
            DiagnosticAdmission.tryBinding
                workspaceId
                CapabilityId.LegacyExtensionAbi
                context.State
            |> Option.isNone,
            Is.True
        )

    [<Test>]
    member _.``SKSE plugin findings should use known mod origins and keep unknown origins``() =
        let documents =
            Path.Combine(
                Path.GetTempPath(),
                "mod-conductor-skse-session-" + Guid.NewGuid().ToString "N"
            )

        let directory = Directory.CreateDirectory(Path.Combine(documents, "SKSE")).FullName

        let log = Path.Combine(directory, "skse64.log")

        File.WriteAllText(
            log,
            "couldn't load plugin C:\\mods\\Failed.dll\n"
            + "couldn't load plugin C:\\mods\\Unknown.dll\n"
        )

        try
            use environment = new DiagnosticFixtureEnvironment(documents = documents)
            File.SetLastWriteTimeUtc(log, DateTime.UtcNow.AddMinutes 1.)

            let snapshot =
                environment.Diagnostics.Check(environment.Request, CancellationToken.None)
                |> environment.Wait
                |> environment.Result

            let failed =
                snapshot.Findings
                |> List.find (fun finding -> finding.Id = "skse-plugin:failed.dll")

            let unknown =
                snapshot.Findings
                |> List.find (fun finding -> finding.Id = "skse-plugin:unknown.dll")

            Assert.That(
                failed.Evidence
                |> List.exists (fun value ->
                    value.Label = "Mod" && value.Value = "Failed plugin mod"),
                Is.True
            )

            Assert.That(
                unknown.Evidence |> List.exists (fun value -> value.Label = "Mod"),
                Is.False
            )
        finally
            Directory.Delete(documents, true)

    [<Test>]
    member _.``skse log date should ignore a launch from an older context revision``() =
        let documents =
            Path.Combine(
                Path.GetTempPath(),
                "mod-conductor-skse-context-" + Guid.NewGuid().ToString "N"
            )

        let directory = Directory.CreateDirectory(Path.Combine(documents, "SKSE")).FullName
        let log = Path.Combine(directory, "skse64.log")
        File.WriteAllText(log, "couldn't load plugin C:\\mods\\Failed.dll\n")
        File.SetLastWriteTimeUtc(log, DateTime.UtcNow.AddHours -1.)

        try
            use environment =
                new DiagnosticFixtureEnvironment(
                    documents = documents,
                    latestContextRevision = 3L
                )

            let snapshot =
                environment.Diagnostics.Check(environment.Request, CancellationToken.None)
                |> environment.Wait
                |> environment.Result

            Assert.That(
                snapshot.Findings
                |> List.exists (fun finding -> finding.Id = "skse-plugin:failed.dll"),
                Is.True
            )

            Assert.That(
                snapshot.Findings
                |> List.exists (fun finding -> finding.Code = "skse-log-stale"),
                Is.False
            )
        finally
            Directory.Delete(documents, true)

    [<Test>]
    member _.``unavailable documents detail should not reach diagnostics or support output``() =
        let disclosed = "/home/private/secret-documents token=secret-value"

        use environment =
            new DiagnosticFixtureEnvironment(unavailableDocuments = disclosed)

        let snapshot =
            environment.Diagnostics.Check(environment.Request, CancellationToken.None)
            |> environment.Wait
            |> environment.Result

        let finding =
            snapshot.Findings
            |> List.find (fun value -> value.Code = "skse-log-malformed")

        Assert.That(
            finding.Detail,
            Is.EqualTo(Some "The SKSE log folder is unavailable.")
        )

        let report =
            environment.Diagnostics.Export(snapshot.Id, CancellationToken.None)
            |> environment.Wait
            |> environment.Result
            |> _.Content
            |> Encoding.UTF8.GetString

        Assert.That(report, Does.Not.Contain disclosed)
        Assert.That(report, Does.Not.Contain "/home/private")
        Assert.That(report, Does.Not.Contain "secret-value")


[<TestFixture>]
type SkyrimCheckTests() =
    let path name =
        LogicalPath.create [ name ] |> Result.defaultWith (string >> invalidOp)

    let header (name: string) form =
        { Extension = Path.GetExtension(name).ToLowerInvariant()
          Flags = 0u
          FormVersion = form
          HeaderVersion = 1.7f
          DeclaredRecords = 1u
          Kind = PluginKind.Plugin
          Localized = false
          Author = None
          Description = None
          Masters = [] }

    let source name =
        { Source =
            CandidateSource.Pinned(
                SourcePin.Mod(
                    Guid.NewGuid(),
                    Guid.NewGuid(),
                    { Path = path name
                      Payload =
                        { Id = Guid.NewGuid()
                          Length = 1L
                          Sha256 = String.replicate 64 "0" } }
                )
            )
          Name = "Known mod"
          Version = "1.0" }

    let entry name form winner =
        { Name = name
          Path = path name
          Winner = winner
          Alternatives = []
          Header = Ok(header name form)
          Ambiguity = None
          Masters = [] }

    [<Test>]
    member _.``current missing stale and malformed SKSE logs should remain distinct``() =
        let root =
            Path.Combine(Path.GetTempPath(), "mod-conductor-skse-" + Guid.NewGuid().ToString "N")

        let directory = Directory.CreateDirectory(Path.Combine(root, "SKSE")).FullName
        let log = Path.Combine(directory, "skse64.log")

        try
            match SkyrimChecks.readLog root None CancellationToken.None with
            | SkseLogResult.Missing -> ()
            | value -> Assert.Fail("Expected a missing log, got " + string value)

            File.WriteAllText(
                log,
                "plugin C:\\mods\\Good.dll loaded correctly\n"
                + "couldn't load plugin C:\\mods\\Failed.dll\n"
                + "plugin C:\\mods\\Old.dll reported as incompatible during query\n"
            )

            match SkyrimChecks.readLog root None CancellationToken.None with
            | SkseLogResult.Current issues ->
                Assert.That(issues, Has.Length.EqualTo 2)
                Assert.That(issues[0].Name, Is.EqualTo "Failed.dll")
                Assert.That(issues[0].Problem, Is.EqualTo SksePluginProblem.Failed)
                Assert.That(issues[1].Name, Is.EqualTo "Old.dll")
                Assert.That(issues[1].Problem, Is.EqualTo SksePluginProblem.Incompatible)
            | value -> Assert.Fail("Expected a current log, got " + string value)

            let old = DateTime.UtcNow.AddMinutes -10.
            File.SetLastWriteTimeUtc(log, old)

            match
                SkyrimChecks.readLog root (Some(DateTimeOffset.UtcNow)) CancellationToken.None
            with
            | SkseLogResult.Stale modified -> Assert.That(modified.UtcDateTime, Is.EqualTo old)
            | value -> Assert.Fail("Expected a stale log, got " + string value)

            File.WriteAllBytes(log, [||])

            match SkyrimChecks.readLog root None CancellationToken.None with
            | SkseLogResult.Malformed _ -> ()
            | value -> Assert.Fail("Expected a malformed log, got " + string value)
        finally
            Directory.Delete(root, true)

    [<Test>]
    member _.``unreadable skse log should use fixed user text``() =
        let root =
            Path.Combine(Path.GetTempPath(), "mod-conductor-skse-read-" + Guid.NewGuid().ToString "N")

        let directory = Directory.CreateDirectory(Path.Combine(root, "SKSE")).FullName
        let log = Path.Combine(directory, "skse64.log")
        File.WriteAllText(log, "plugin C:\\mods\\Good.dll loaded correctly\n")

        try
            use locked = File.Open(log, FileMode.Open, FileAccess.ReadWrite, FileShare.None)

            match SkyrimChecks.readLog root None CancellationToken.None with
            | SkseLogResult.Malformed detail ->
                Assert.That(detail, Is.EqualTo "The SKSE log cannot be read.")
                Assert.That(detail, Does.Not.Contain log)
            | value -> Assert.Fail("Expected an unreadable log, got " + string value)
        finally
            Directory.Delete(root, true)

    [<Test>]
    member _.``old form check should report only enabled ESM and ESP entries below form 44``() =
        let known = source "Old.esp"

        let snapshot =
            { Id = Guid.NewGuid()
              Stamp =
                { WorkspaceId = Guid.NewGuid()
                  ProfileId = Guid.NewGuid()
                  SelectionRevision = 1L
                  ContextRevision = 1L
                  ExclusionRevision = 1L
                  OutputRevision = 1L
                  Versions = []
                  Deployment = None }
              ObservedAt = DateTimeOffset.UtcNow
              Stale = false
              Entries =
                [ entry "Old.esp" 43us (Some known)
                  entry "Disabled.esm" 1us (Some(source "Disabled.esm"))
                  entry "Current.esp" 44us (Some(source "Current.esp"))
                  entry "Future.esm" 45us (Some(source "Future.esm"))
                  entry "Old.esl" 1us (Some(source "Old.esl"))
                  entry "Unknown.esp" 42us None ]
              Problems = [] }

        let settings =
            snapshot.Entries
            |> List.map (fun plugin ->
                { Name = plugin.Name
                  Enabled = Some(plugin.Name <> "Disabled.esm")
                  LockedIndex = None })

        let findings = SkyrimChecks.oldPluginFormats snapshot settings
        Assert.That((findings |> List.map _.Name) = [ "Old.esp"; "Unknown.esp" ], Is.True)
        Assert.That(findings.Head.Owner, Is.EqualTo(Some "Known mod"))
        Assert.That(findings[1].Owner, Is.EqualTo None)
