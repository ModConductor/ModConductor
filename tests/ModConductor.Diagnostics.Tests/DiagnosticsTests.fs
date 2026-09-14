namespace ModConductor.Diagnostics.Tests

open System
open System.IO
open System.Text
open System.Text.Json
open System.Threading
open System.Threading.Tasks
open ModConductor.Deployment
open ModConductor.DeploymentPlanning
open ModConductor.Diagnostics
open ModConductor.Executables
open ModConductor.FilePlanning
open ModConductor.GameLaunching
open ModConductor.Persistence
open ModConductor.Platform
open ModConductor.Workspaces
open NUnit.Framework

type private FixturePlans(workspaceId: Guid, profileId: Guid) =
    let snapshotId = Guid.NewGuid()

    let target =
        LogicalPath.create [ "meshes"; "marker.nif" ]
        |> Result.defaultWith (string >> invalidOp)

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

        member _.Inspect(_, _, _) = unused ()
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

type private FixtureLaunch(workspaceId: Guid, profileId: Guid, phase: RunPhase) =
    let runId = Guid.NewGuid()

    let run =
        { Source =
            RunSource.Game
                { Request =
                    { Id = runId
                      WorkspaceId = workspaceId
                      WorkspaceRevision = 2L
                      ProfileId = profileId
                      ContextRevision = 4L
                      SourceToken = "https://token.example/access=secret /home/private ; run-command" }
                  ContextId = Guid.NewGuid()
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

type private DiagnosticFixtureEnvironment(?launchPhase: RunPhase, ?useFixtureDeployment: bool) =
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
    let launches = FixtureLaunch(workspaceId, profileId, defaultArg launchPhase RunPhase.Failed)
    let fixtureDeployments = FixtureDeployments(workspaceId, profileId)
    let deploymentBackend =
        if defaultArg useFixtureDeployment false then fixtureDeployments :> IDeploymentBackend
        else store.Deployments

    let diagnostics =
        DiagnosticSession(
            workspaces,
            plans :> IFilePlans,
            deploymentBackend,
            launches :> IGameLaunching,
            store.ProfileGameData
        )
        :> IDiagnostics

    let request =
        { WorkspaceId = workspaceId
          ProfileId = profileId
          FileSnapshotId = Some plans.SnapshotId
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
                FileSnapshotId = None }

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
        Assert.That(finding.Title, Is.EqualTo "Mod Conductor canceled the Skyrim launch")
        Assert.That(finding.Summary, Is.EqualTo "The game did not start.")
        Assert.That(finding.NextAction, Is.EqualTo "When you are ready, select Play.")
        Assert.That(finding.FixDetail, Is.EqualTo "You do not need to change anything.")
        Assert.That(Option.isNone finding.Detail, Is.True)
