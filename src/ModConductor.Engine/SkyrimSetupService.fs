namespace ModConductor.Engine

open System
open System.Collections.Concurrent
open System.IO
open System.Security.Cryptography
open System.Text
open System.Threading
open System.Threading.Tasks
open ModConductor.Deployment
open ModConductor.Executables
open ModConductor.FilePlanning
open ModConductor.Fnis
open ModConductor.GameContexts
open ModConductor.GameLaunching
open ModConductor.Persistence
open ModConductor.ProfileGameData
open ModConductor.Protocol.V1

type SkyrimSetupComponentView =
    { Name: string
      Status: string
      Detail: string
      Ready: bool
      Active: bool
      Blocked: bool }

type SkyrimSetupChangeView = { Title: string; Detail: string }

type SkyrimSetupView =
    { Phase: SkyrimSetupPhase
      Status: string
      Detail: string
      PlanToken: string
      Changes: SkyrimSetupChangeView list
      Components: SkyrimSetupComponentView list
      IncludeFnis: bool
      ConsentRecorded: bool
      CanStart: bool
      CanContinue: bool
      CanSelectEnbArchive: bool
      Active: bool
      CanCancel: bool
      Ready: bool }

type internal SkyrimSetupPlanSnapshot =
    { Sources: SourceStamp
      DeploymentRevision: int64
      ActiveGeneration: Guid option }

[<RequireQualifiedAccess>]
type internal SkyrimSetupStageChange =
    | Deployment of generation: Guid
    | ComponentDeployment of generation: Guid * versions: (Guid * Guid) list
    | FnisOutput of modId: Guid * versionId: Guid

module internal SkyrimSetupPlan =
    let private writeSnapshot (snapshot: SkyrimSetupPlanSnapshot) =
        use stream = new MemoryStream()
        use writer = new BinaryWriter(stream, Encoding.UTF8, true)
        let sources = snapshot.Sources
        writer.Write 2uy
        writer.Write(sources.WorkspaceId.ToByteArray())
        writer.Write(sources.ProfileId.ToByteArray())
        writer.Write sources.SelectionRevision
        writer.Write sources.ContextRevision
        writer.Write sources.ExclusionRevision
        writer.Write sources.OutputRevision
        writer.Write snapshot.DeploymentRevision
        writer.Write sources.Versions.Length

        for modId, versionId in sources.Versions do
            writer.Write(modId.ToByteArray())
            writer.Write versionId.IsSome
            versionId |> Option.iter (fun value -> writer.Write(value.ToByteArray()))

        writer.Write sources.Deployment.IsSome
        sources.Deployment |> Option.iter writer.Write
        writer.Write snapshot.ActiveGeneration.IsSome

        snapshot.ActiveGeneration
        |> Option.iter (fun value -> writer.Write(value.ToByteArray()))

        writer.Flush()
        stream.ToArray()

    let private readGuid (reader: BinaryReader) =
        let bytes = reader.ReadBytes 16

        if bytes.Length <> 16 then
            raise (EndOfStreamException())

        Guid bytes

    let private readSnapshot (bytes: byte array) =
        try
            use stream = new MemoryStream(bytes, false)
            use reader = new BinaryReader(stream, Encoding.UTF8, true)

            if reader.ReadByte() <> 2uy then
                None
            else
                let workspace = readGuid reader
                let profile = readGuid reader
                let selection = reader.ReadInt64()
                let context = reader.ReadInt64()
                let exclusion = reader.ReadInt64()
                let output = reader.ReadInt64()
                let deploymentRevision = reader.ReadInt64()
                let count = reader.ReadInt32()

                if count < 0 || count > 100000 then
                    None
                else
                    let versions =
                        [ for _ in 1..count do
                              let modId = readGuid reader

                              let versionId =
                                  if reader.ReadBoolean() then Some(readGuid reader) else None

                              yield modId, versionId ]

                    let deployment =
                        if reader.ReadBoolean() then
                            Some(reader.ReadString())
                        else
                            None

                    let generation = if reader.ReadBoolean() then Some(readGuid reader) else None

                    if stream.Position <> stream.Length then
                        None
                    else
                        Some
                            { Sources =
                                { WorkspaceId = workspace
                                  ProfileId = profile
                                  SelectionRevision = selection
                                  ContextRevision = context
                                  ExclusionRevision = exclusion
                                  OutputRevision = output
                                  Versions = versions
                                  Deployment = deployment }
                              DeploymentRevision = deploymentRevision
                              ActiveGeneration = generation }
        with
        | :? EndOfStreamException
        | :? IOException
        | :? FormatException -> None

    let private base64 (bytes: byte array) =
        Convert.ToBase64String bytes
        |> fun value -> value.TrimEnd('=').Replace('+', '-').Replace('/', '_')

    let private tryBase64 (value: string) =
        try
            let padded = value.Replace('-', '+').Replace('_', '/')
            let padded = padded + String.replicate ((4 - padded.Length % 4) % 4) "="
            Some(Convert.FromBase64String padded)
        with :? FormatException ->
            None

    let private hash
        (workspace: Guid)
        (profile: Guid)
        includeFnis
        contextRevision
        (payload: byte array)
        =
        use incremental = IncrementalHash.CreateHash HashAlgorithmName.SHA256
        incremental.AppendData(Encoding.UTF8.GetBytes "mc-skyrim-setup-v3")
        incremental.AppendData(workspace.ToByteArray())
        incremental.AppendData(profile.ToByteArray())
        incremental.AppendData([| if includeFnis then 1uy else 0uy |])
        let revision = Array.zeroCreate<byte> 8
        Buffers.Binary.BinaryPrimitives.WriteInt64LittleEndian(revision, contextRevision)
        incremental.AppendData revision
        incremental.AppendData payload
        Convert.ToHexStringLower(incremental.GetHashAndReset())

    let token workspace profile includeFnis contextRevision snapshot =
        let payload = writeSnapshot snapshot

        hash workspace profile includeFnis contextRevision payload
        + "."
        + base64 payload

    let snapshot workspace profile includeFnis contextRevision (value: string) =
        match value.Split('.', 2) with
        | [| expected; encoded |] ->
            match tryBase64 encoded with
            | Some payload when
                CryptographicOperations.FixedTimeEquals(
                    Encoding.ASCII.GetBytes expected,
                    Encoding.ASCII.GetBytes(
                        hash workspace profile includeFnis contextRevision payload
                    )
                )
                ->
                readSnapshot payload
            | _ -> None
        | _ -> None

    let private stableSourceData (before: SourceStamp) (after: SourceStamp) =
        before.WorkspaceId = after.WorkspaceId
        && before.ProfileId = after.ProfileId
        && before.ContextRevision = after.ContextRevision
        && before.ExclusionRevision = after.ExclusionRevision
        && before.OutputRevision = after.OutputRevision

    let private stableSources (before: SourceStamp) (after: SourceStamp) =
        stableSourceData before after && before.Deployment = after.Deployment

    let private expectedDeploymentTransition before after =
        after.DeploymentRevision = before.DeploymentRevision + 1L
        && after.Sources.Deployment.IsSome
        && after.Sources.Deployment <> before.Sources.Deployment

    let private versionChanges expected before after =
        let before = before |> Map.ofList
        let after = after |> Map.ofList

        let changed =
            Set.union (before |> Map.keys |> Set.ofSeq) (after |> Map.keys |> Set.ofSeq)
            |> Set.filter (fun key -> before.TryFind key <> after.TryFind key)

        let expectedIds = expected |> List.map fst |> Set.ofList

        if
            not changed.IsEmpty
            && changed.IsSubsetOf expectedIds
            && (expected
                |> List.forall (fun (modId, versionId) ->
                    after.TryFind modId = Some(Some versionId)))
        then
            Some changed.Count
        else
            None

    let permits (before: SkyrimSetupPlanSnapshot) (after: SkyrimSetupPlanSnapshot) change =
        match change with
        | SkyrimSetupStageChange.Deployment generation ->
            stableSourceData before.Sources after.Sources
            && before.ActiveGeneration.IsNone
            && after.ActiveGeneration = Some generation
            && after.Sources.Deployment.IsSome
            && after.DeploymentRevision = before.DeploymentRevision + 1L
            && before.Sources.SelectionRevision = after.Sources.SelectionRevision
            && before.Sources.Versions = after.Sources.Versions
        | SkyrimSetupStageChange.ComponentDeployment(generation, versions) ->
            stableSourceData before.Sources after.Sources
            && expectedDeploymentTransition before after
            && after.ActiveGeneration = Some generation
            && (match versionChanges versions before.Sources.Versions after.Sources.Versions with
                | Some count ->
                    after.Sources.SelectionRevision = before.Sources.SelectionRevision
                                                      + int64 count
                                                      + 1L
                | None -> false)
        | SkyrimSetupStageChange.FnisOutput(modId, versionId) ->
            stableSources before.Sources after.Sources
            && after.DeploymentRevision = before.DeploymentRevision
            && after.ActiveGeneration = before.ActiveGeneration
            && (match
                    versionChanges
                        [ modId, versionId ]
                        before.Sources.Versions
                        after.Sources.Versions
                with
                | Some _ ->
                    let alreadyRegistered =
                        before.Sources.Versions |> List.exists (fun (id, _) -> id = modId)

                    after.Sources.SelectionRevision = before.Sources.SelectionRevision
                                                      + (if alreadyRegistered then 1L else 2L)
                | None -> false)


type internal SkyrimSetupDependencies =
    { ReadSkse: Guid -> Guid -> System.Threading.Tasks.Task<SkseView>
      StartSkse: Guid -> Guid -> System.Threading.Tasks.Task<SkseView>
      CancelSkse: Guid -> Guid -> System.Threading.Tasks.Task<SkseView>
      ReadEnb: Guid -> Guid -> System.Threading.Tasks.Task<EnbView>
      OpenEnb: Guid -> Guid -> System.Threading.Tasks.Task<EnbView>
      SelectEnb:
          Guid
              -> Guid
              -> Guid
              -> string
              -> CancellationToken
              -> System.Threading.Tasks.Task<EnbView>
      CancelEnb: Guid -> Guid -> System.Threading.Tasks.Task<EnbView>
      RecoverEnb: Guid -> Guid -> CancellationToken -> System.Threading.Tasks.Task<EnbView>
      ReadFnis: Guid -> Guid -> System.Threading.Tasks.Task<FnisView>
      InstallFnis: Guid -> Guid -> System.Threading.Tasks.Task<FnisView>
      UpdateFnis: Guid -> Guid -> System.Threading.Tasks.Task<FnisView>
      CancelFnis: Guid -> Guid -> System.Threading.Tasks.Task<FnisView>
      RecoverFnis: Guid -> Guid -> CancellationToken -> System.Threading.Tasks.Task<FnisView>
      InspectFnis:
          Guid
              -> Guid
              -> CancellationToken
              -> System.Threading.Tasks.Task<Result<FnisInspection, FnisExecutionError>>
      RunFnis:
          ModConductor.Fnis.FnisRunRequest
              -> CancellationToken
              -> System.Threading.Tasks.Task<Result<FnisInspection, FnisExecutionError>>
      CancelFnisRun:
          Guid -> Guid -> System.Threading.Tasks.Task<Result<FnisInspection, FnisExecutionError>>
      ReadLaunch:
          Guid
              -> Guid
              -> System.Threading.Tasks.Task<
                  Result<ModConductor.GameLaunching.GameLaunchState, ExecutableError>
               >
      PluginPreflight:
          Guid
              -> Guid
              -> CancellationToken
              -> System.Threading.Tasks.Task<Result<unit, ProfileDataError>> }

module internal SkyrimSetupDependencies =
    let production
        (skse: SkseCoordinator)
        (enb: EnbCoordinator)
        (fnis: FnisCoordinator)
        (execution: IFnisExecution)
        (launches: IGameLaunching)
        (pluginOrders: IProfilePluginOrders)
        =
        { ReadSkse = fun workspace profile -> skse.Read(workspace, profile)
          StartSkse = fun workspace profile -> skse.Start(workspace, profile)
          CancelSkse = fun workspace profile -> skse.Cancel(workspace, profile)
          ReadEnb = fun workspace profile -> enb.Read(workspace, profile)
          OpenEnb = fun workspace profile -> enb.OpenAuthorPage(workspace, profile)
          SelectEnb =
            fun workspace profile operation path token ->
                enb.SelectArchive(workspace, profile, operation, path, token)
          CancelEnb = fun workspace profile -> enb.Cancel(workspace, profile)
          RecoverEnb = fun workspace profile token -> enb.Recover(workspace, profile, token)
          ReadFnis = fun workspace profile -> fnis.Read(workspace, profile)
          InstallFnis = fun workspace profile -> fnis.Install(workspace, profile)
          UpdateFnis = fun workspace profile -> fnis.Update(workspace, profile)
          CancelFnis = fun workspace profile -> fnis.Cancel(workspace, profile)
          RecoverFnis = fun workspace profile token -> fnis.Recover(workspace, profile, token)
          InspectFnis = fun workspace profile token -> execution.Inspect(workspace, profile, token)
          RunFnis = fun request token -> execution.Run(request, token)
          CancelFnisRun = fun workspace profile -> execution.Cancel(workspace, profile)
          ReadLaunch = fun workspace profile -> launches.Read(workspace, profile)
          PluginPreflight =
            fun workspace profile token ->
                pluginOrders.PreflightForLaunch(workspace, profile, token) }

type internal SkyrimSetupCoordinator(store: OperationStore, dependencies: SkyrimSetupDependencies) =
    let lifetime = new CancellationTokenSource()
    let workers = ConcurrentDictionary<Guid * Guid, CancellationTokenSource>()

    let startWorker workspace profile action =
        let key = workspace, profile
        let cancellation = CancellationTokenSource.CreateLinkedTokenSource(lifetime.Token)

        if workers.TryAdd(key, cancellation) then
            Task.Run(fun () ->
                task {
                    try
                        try
                            let! _ = action cancellation.Token
                            ()
                        with :? OperationCanceledException when
                            cancellation.IsCancellationRequested ->
                            ()
                    finally
                        match workers.TryRemove key with
                        | true, owned -> owned.Dispose()
                        | _ -> ()
                }
                :> Task)
            |> ignore

            true
        else
            cancellation.Dispose()
            false

    let firstRunInstruction =
        "Start Skyrim once through Steam. Close it, then select Refresh."

    let planToken
        (workspace: Guid)
        (profile: Guid)
        includeFnis
        contextRevision
        (deployment: DeploymentStatus)
        =
        SkyrimSetupPlan.token
            workspace
            profile
            includeFnis
            contextRevision
            { Sources = deployment.Sources
              DeploymentRevision = deployment.Revision
              ActiveGeneration = deployment.ActiveGeneration }

    let componentView name status detail ready active blocked =
        { Name = name
          Status = status
          Detail = detail
          Ready = ready
          Active = active
          Blocked = blocked }

    let changes includeFnis hasDeployment =
        [ if not hasDeployment then
              { Title = "Prepare the first deployment"
                Detail =
                  "Create and activate the initial owned deployment before component files are installed." }

          { Title = "Set up SKSE"
            Detail = "Install the matching SKSE version in the selected profile." }
          { Title = "Set up Lean ENB"
            Detail =
              "Wait for the ENBSeries archive that you download from the author page, then install Lean ENB and its companion." }

          if includeFnis then
              { Title = "Set up and run FNIS"
                Detail =
                  "Install FNIS and update the active profile output when its animation inputs are stale." }

          { Title = "Check Play readiness"
            Detail =
              "Use the selected installation, deployment, plugin order and launch checks. Other profiles, foreign files and saves stay unchanged." } ]

    let view
        phase
        status
        detail
        token
        planned
        components
        includeFnis
        consent
        start
        continueSetup
        select
        active
        ready
        =
        { Phase = phase
          Status = status
          Detail = detail
          PlanToken = token
          Changes = planned
          Components = components
          IncludeFnis = includeFnis
          ConsentRecorded = consent
          CanStart = start
          CanContinue = continueSetup
          CanSelectEnbArchive = select
          Active = active
          CanCancel = consent && not ready
          Ready = ready }

    let unavailable includeFnis status detail =
        view
            SkyrimSetupPhase.Unavailable
            status
            detail
            ""
            []
            [ componentView "Skyrim installation" status detail false false true ]
            includeFnis
            false
            false
            false
            false
            false
            false

    let missingFirstRun (binding: GameBinding) =
        let explicitlyMissing =
            binding.NeedsCheck
            && binding.Failure
               |> Option.exists (fun detail ->
                   detail.Contains("first run", StringComparison.OrdinalIgnoreCase))

        match binding.Evidence.Platform with
        | ContextPlatform.Windows -> explicitlyMissing
        | ContextPlatform.Proton ->
            binding.Evidence.Proton.IsNone
            || explicitlyMissing
            || (binding.NeedsCheck
                && binding.Failure
                   |> Option.exists (fun detail ->
                       detail.Contains("prefix", StringComparison.OrdinalIgnoreCase)
                       || detail.Contains("Proton data", StringComparison.OrdinalIgnoreCase)
                       || detail.Contains("user folder", StringComparison.OrdinalIgnoreCase)))

    let deploymentError =
        function
        | DeploymentError.NotFound -> "The deployment is unavailable."
        | DeploymentError.Busy -> "Wait for the current deployment operation, then select Continue."
        | DeploymentError.Stale -> "The profile changed. Select Refresh and review the new plan."
        | DeploymentError.Cancelled -> "Setup stopped. Select Continue to recover it."
        | DeploymentError.Blocked detail
        | DeploymentError.Unavailable detail -> detail

    let initialDeployment (deployment: DeploymentStatus) action token =
        task {
            match deployment.PendingReceipt with
            | Some id ->
                let! receipt = store.Deployments.Receipt id

                match receipt with
                | Error error -> return Error(deploymentError error)
                | Ok receipt ->
                    let! recovered =
                        store.Deployments.Recover(
                            receipt.Id,
                            receipt.Revision,
                            false,
                            ignore,
                            token
                        )

                    return recovered |> Result.map ignore |> Result.mapError deploymentError
            | None when deployment.ActiveGeneration.IsNone ->
                let! prepared = store.Deployments.Prepare(action, deployment.Sources, ignore, token)

                match prepared with
                | Error error -> return Error(deploymentError error)
                | Ok prepared ->
                    let! activated =
                        store.Deployments.Activate(prepared.Id, deployment.Sources, ignore, token)

                    return activated |> Result.map ignore |> Result.mapError deploymentError
            | None -> return Ok()
        }

    let recoverPending workspace profile (deployment: DeploymentStatus) token =
        task {
            let! enbOperation = store.EnbSetups.ConfigurationOperation(workspace, profile)
            let! fnisStatus = store.FnisSetups.ReadStatus(workspace, profile)

            match enbOperation, fnisStatus with
            | Some _, _ ->
                let! result = dependencies.RecoverEnb workspace profile token

                return
                    if result.Phase = EnbPhase.Failed || result.Phase = EnbPhase.Conflict then
                        Error(result.Status + ". " + result.Detail)
                    else
                        Ok()
            | None, Some status when status.Phase = "recovery" ->
                let! result = dependencies.RecoverFnis workspace profile token

                return
                    if
                        result.Phase = FnisPhase.RecoveryRequired || result.Phase = FnisPhase.Failed
                    then
                        Error(result.Status + ". " + result.Detail)
                    else
                        Ok()
            | None, _ ->
                match deployment.PendingReceipt with
                | None -> return Ok()
                | Some id ->
                    let! receipt = store.Deployments.Receipt id

                    match receipt with
                    | Error error -> return Error(deploymentError error)
                    | Ok receipt ->
                        let! recovered =
                            store.Deployments.Recover(
                                receipt.Id,
                                receipt.Revision,
                                true,
                                ignore,
                                token
                            )

                        return recovered |> Result.map ignore |> Result.mapError deploymentError
        }

    let inspect workspace profile includeFnis (intent: StoredSkyrimSetupIntent option) token =
        task {
            let consent =
                intent
                |> Option.exists (fun value -> not value.Cancelled && not value.Completed)

            let! contextResult = (store.GameContexts :> IGameContexts).Read workspace

            match contextResult with
            | Error _ ->
                return
                    unavailable
                        includeFnis
                        "Skyrim setup is unavailable"
                        "Select and refresh the Skyrim Special Edition Steam installation."
            | Ok context ->
                match context.Binding with
                | Some binding when missingFirstRun binding ->
                    return
                        unavailable
                            includeFnis
                            "Skyrim needs its first Steam run"
                            firstRunInstruction
                | None ->
                    return
                        unavailable
                            includeFnis
                            "Skyrim setup is unavailable"
                            "Select and refresh the Skyrim Special Edition Steam installation."
                | Some binding when
                    binding.NeedsCheck
                    || not binding.Evidence.Valid
                    || binding.Evidence.DefinitionId <> Skyrim.definition.Id
                    ->
                    return
                        unavailable
                            includeFnis
                            "Skyrim setup is unavailable"
                            "Refresh the selected Skyrim Special Edition Steam installation."
                | Some _ ->
                    let! deployed = store.Deployments.Read profile

                    match deployed with
                    | Error error ->
                        return
                            unavailable
                                includeFnis
                                "The deployment is unavailable"
                                (deploymentError error)
                    | Ok deployed when deployed.WorkspaceId <> workspace ->
                        return
                            unavailable
                                includeFnis
                                "The selected profile is unavailable"
                                "Select a profile from this workspace."
                    | Ok deployed ->
                        let tokenValue =
                            planToken workspace profile includeFnis context.Revision deployed

                        let currentSnapshot =
                            { Sources = deployed.Sources
                              DeploymentRevision = deployed.Revision
                              ActiveGeneration = deployed.ActiveGeneration }

                        let planned = changes includeFnis deployed.ActiveGeneration.IsSome

                        let recorded = intent |> Option.filter (fun value -> not value.Cancelled)

                        let mutable tokenChanged =
                            recorded |> Option.exists (fun value -> value.PlanToken <> tokenValue)

                        let mutable stage = recorded |> Option.map _.Stage |> Option.defaultValue ""

                        let contextChanged =
                            recorded
                            |> Option.exists (fun value ->
                                value.ContextRevision <> context.Revision)

                        let permitsStageChange (value: StoredSkyrimSetupIntent) change =
                            SkyrimSetupPlan.snapshot
                                workspace
                                profile
                                includeFnis
                                value.ContextRevision
                                value.PlanToken
                            |> Option.exists (fun before ->
                                SkyrimSetupPlan.permits before currentSnapshot change)

                        let stalePlan components =
                            view
                                SkyrimSetupPhase.NeedsConsent
                                "The Skyrim setup plan changed"
                                "The installation, profile sources or active deployment changed. Review and confirm the current plan before setup writes again."
                                tokenValue
                                planned
                                components
                                includeFnis
                                false
                                true
                                false
                                false
                                false
                                false

                        let staleActivePlan components =
                            { stalePlan components with
                                CanStart = false
                                Active = true
                                CanCancel = true }

                        if intent |> Option.exists _.CancelRequested then
                            let pending = intent.Value

                            return
                                { view
                                      SkyrimSetupPhase.RecoveryRequired
                                      "Skyrim setup cancellation needs completion"
                                      (if String.IsNullOrWhiteSpace pending.CancelDetail then
                                           "Select Continue to finish the recorded child cancellation and recovery."
                                       else
                                           pending.CancelDetail)
                                      tokenValue
                                      planned
                                      [ componentView
                                            "Setup"
                                            "Cancellation recorded"
                                            "The child owner must finish cancellation before setup can continue."
                                            false
                                            false
                                            true ]
                                      includeFnis
                                      consent
                                      false
                                      true
                                      false
                                      false
                                      false with
                                    CanCancel = false }
                        elif intent |> Option.exists _.Cancelled then
                            let cancelled = intent.Value

                            return
                                view
                                    SkyrimSetupPhase.Cancelled
                                    "Skyrim setup is cancelled"
                                    (if String.IsNullOrWhiteSpace cancelled.CancelDetail then
                                         "The recorded component operations stopped without replacing the prior active setup. Review the current plan to continue."
                                     else
                                         cancelled.CancelDetail)
                                    tokenValue
                                    planned
                                    [ componentView
                                          "Setup"
                                          "Cancelled"
                                          "The selected profile and retained setup remain available."
                                          false
                                          false
                                          false ]
                                    includeFnis
                                    false
                                    true
                                    false
                                    false
                                    false
                                    false
                        elif deployed.ActiveGeneration.IsSome && deployed.PendingReceipt.IsSome then
                            return
                                { view
                                      SkyrimSetupPhase.RecoveryRequired
                                      "The deployment needs recovery"
                                      "Finish the recorded child operation before setup reads or changes another component."
                                      tokenValue
                                      planned
                                      [ componentView
                                            "Deployment"
                                            "Recovery required"
                                            "The previous active generation remains selected until recovery completes."
                                            false
                                            false
                                            true ]
                                      includeFnis
                                      consent
                                      false
                                      consent
                                      false
                                      false
                                      false with
                                    CanCancel = false }
                        elif deployed.ActiveGeneration.IsNone then
                            return
                                view
                                    (if consent then
                                         SkyrimSetupPhase.PreparingDeployment
                                     else
                                         SkyrimSetupPhase.NeedsConsent)
                                    (if deployed.PendingReceipt.IsSome then
                                         "The first deployment needs recovery"
                                     elif consent then
                                         "The first deployment is ready to prepare"
                                     else
                                         "Review the Skyrim setup changes")
                                    (if deployed.PendingReceipt.IsSome then
                                         "Select Continue to finish the recorded deployment."
                                     else
                                         "Mod Conductor prepares the owned deployment before it installs component files.")
                                    tokenValue
                                    planned
                                    [ componentView
                                          "Deployment"
                                          (if deployed.PendingReceipt.IsSome then
                                               "Recovery required"
                                           else
                                               "Not prepared")
                                          "The active profile needs an owned deployment."
                                          false
                                          false
                                          deployed.PendingReceipt.IsSome ]
                                    includeFnis
                                    consent
                                    (not consent && deployed.PendingReceipt.IsNone)
                                    consent
                                    false
                                    false
                                    false
                        elif contextChanged then
                            return
                                stalePlan
                                    [ componentView
                                          "Skyrim installation"
                                          "Plan changed"
                                          "The selected installation context changed."
                                          false
                                          false
                                          true ]
                        elif workers.ContainsKey((workspace, profile)) then
                            let workerPhase, workerName, workerStatus, workerDetail =
                                match stage with
                                | "fnis-run" ->
                                    SkyrimSetupPhase.FnisRunning,
                                    "FNIS",
                                    "Updating FNIS output",
                                    "Cancel remains available while the FNIS owner updates the active output."
                                | _ ->
                                    SkyrimSetupPhase.SettingUpEnb,
                                    "Lean ENB",
                                    "Setting up",
                                    "Cancel remains available while the child operation is active."

                            let workerComponent =
                                componentView workerName workerStatus workerDetail false true false

                            if tokenChanged then
                                return staleActivePlan [ workerComponent ]
                            else
                                return
                                    view
                                        workerPhase
                                        workerStatus
                                        workerDetail
                                        tokenValue
                                        planned
                                        [ workerComponent ]
                                        includeFnis
                                        consent
                                        false
                                        false
                                        false
                                        true
                                        false
                        else
                            match recorded with
                            | Some value when tokenChanged && stage = "deployment-running" ->
                                let! receipt =
                                    match value.ActionId with
                                    | Some action -> store.Deployments.Receipt action
                                    | None -> Task.FromResult(Error DeploymentError.NotFound)

                                let caused =
                                    match receipt, deployed.ActiveGeneration with
                                    | Ok receipt, Some active ->
                                        receipt.Phase = ModConductor.Deployment.DeploymentPhase.Complete
                                        && receipt.Proposed = active
                                        && permitsStageChange
                                            value
                                            (SkyrimSetupStageChange.Deployment active)
                                    | _ -> false

                                if caused then
                                    do!
                                        store.SkyrimSetups.Save
                                            { value with
                                                PlanToken = tokenValue
                                                Stage = "skse-start"
                                                ActionId = None }

                                    tokenChanged <- false
                                    stage <- "skse-start"
                            | _ -> ()

                            let! skseState = dependencies.ReadSkse workspace profile
                            let skseReady = skseState.Phase = SksePhase.Ready

                            let skseActive =
                                skseState.Phase = SksePhase.Downloading
                                || skseState.Phase = SksePhase.Installing

                            let skseBlocked =
                                skseState.Phase = SksePhase.Failed
                                || skseState.Phase = SksePhase.Incompatible
                                || skseState.Phase = SksePhase.SourceUnavailable
                                || skseState.Phase = SksePhase.Unavailable

                            let skseComponent =
                                componentView
                                    "SKSE"
                                    skseState.Status
                                    skseState.Detail
                                    skseReady
                                    skseActive
                                    skseBlocked

                            if not skseReady then
                                let phase =
                                    if skseBlocked then SkyrimSetupPhase.Failed
                                    elif skseActive then SkyrimSetupPhase.SettingUpSkse
                                    else SkyrimSetupPhase.WaitingForSkse

                                if tokenChanged then
                                    if skseActive then
                                        return staleActivePlan [ skseComponent ]
                                    else
                                        return stalePlan [ skseComponent ]
                                else
                                    return
                                        view
                                            (if consent then
                                                 phase
                                             else
                                                 SkyrimSetupPhase.NeedsConsent)
                                            skseState.Status
                                            skseState.Detail
                                            tokenValue
                                            planned
                                            [ skseComponent ]
                                            includeFnis
                                            consent
                                            (not consent)
                                            (consent
                                             && (skseState.Phase = SksePhase.Available
                                                 || skseState.Phase = SksePhase.UpdateAvailable
                                                 || skseState.Phase = SksePhase.Failed))
                                            false
                                            skseActive
                                            false
                            else
                                let! skseTransition =
                                    if tokenChanged && stage = "skse" then
                                        task {
                                            let! installed =
                                                store.SkseLoaders.ReadStored(
                                                    workspace,
                                                    profile,
                                                    deployed.ActiveGeneration
                                                )

                                            return
                                                match installed, recorded with
                                                | Some installed, Some intent ->
                                                    permitsStageChange
                                                        intent
                                                        (SkyrimSetupStageChange.ComponentDeployment(
                                                            installed.Loader.GenerationId,
                                                            [ installed.ModId, installed.VersionId ]
                                                        ))
                                                | _ -> false
                                        }
                                    else
                                        Task.FromResult false

                                match recorded with
                                | Some value when tokenChanged && stage = "skse" && skseTransition ->
                                    do!
                                        store.SkyrimSetups.Save
                                            { value with
                                                PlanToken = tokenValue
                                                Stage = "enb-start" }

                                    tokenChanged <- false
                                    stage <- "enb-start"
                                | Some value when
                                    not tokenChanged && (stage = "skse" || stage = "skse-start")
                                    ->
                                    do!
                                        store.SkyrimSetups.Save
                                            { value with
                                                PlanToken = tokenValue
                                                Stage = "enb-start" }

                                    stage <- "enb-start"
                                | _ -> ()

                                let! enbState = dependencies.ReadEnb workspace profile
                                let enbReady = enbState.Phase = EnbPhase.Ready

                                let enbActive =
                                    enbState.Phase = EnbPhase.Validating
                                    || enbState.Phase = EnbPhase.Acquiring
                                    || enbState.Phase = EnbPhase.Installing

                                let enbBlocked =
                                    enbState.Phase = EnbPhase.Blocked
                                    || enbState.Phase = EnbPhase.Failed
                                    || enbState.Phase = EnbPhase.Conflict
                                    || enbState.Phase = EnbPhase.Unavailable

                                let enbComponent =
                                    componentView
                                        "Lean ENB"
                                        enbState.Status
                                        enbState.Detail
                                        enbReady
                                        enbActive
                                        enbBlocked

                                if not enbReady then
                                    let waiting = enbState.Phase = EnbPhase.WaitingForArchive

                                    if tokenChanged then
                                        if enbActive then
                                            return staleActivePlan [ skseComponent; enbComponent ]
                                        else
                                            return stalePlan [ skseComponent; enbComponent ]
                                    else
                                        return
                                            view
                                                (if consent then
                                                     if waiting then
                                                         SkyrimSetupPhase.WaitingForEnbArchive
                                                     else
                                                         SkyrimSetupPhase.SettingUpEnb
                                                 else
                                                     SkyrimSetupPhase.NeedsConsent)
                                                enbState.Status
                                                enbState.Detail
                                                tokenValue
                                                planned
                                                [ skseComponent; enbComponent ]
                                                includeFnis
                                                consent
                                                (not consent)
                                                (consent
                                                 && (enbState.Phase = EnbPhase.Available
                                                     || (enbState.Phase = EnbPhase.Failed
                                                         && deployed.PendingReceipt.IsSome)))
                                                (consent
                                                 && (waiting || enbState.Phase = EnbPhase.Failed))
                                                enbActive
                                                false
                                else
                                    let! enbTransition =
                                        if tokenChanged && stage = "enb" then
                                            task {
                                                let! configured =
                                                    store.EnbSetups.ConfigurationPlan(
                                                        workspace,
                                                        profile,
                                                        deployed.ActiveGeneration
                                                    )

                                                let! components =
                                                    store.EnbSetups.Components(
                                                        workspace,
                                                        profile,
                                                        deployed.ActiveGeneration
                                                    )

                                                return
                                                    match
                                                        configured,
                                                        recorded |> Option.bind _.ActionId,
                                                        recorded,
                                                        deployed.ActiveGeneration
                                                    with
                                                    | Some(_, Some observed),
                                                      Some expected,
                                                      Some intent,
                                                      Some generation ->
                                                        observed = expected
                                                        && not components.IsEmpty
                                                        && permitsStageChange
                                                            intent
                                                            (SkyrimSetupStageChange
                                                                .ComponentDeployment(
                                                                    generation,
                                                                    components
                                                                    |> List.map (fun item ->
                                                                        item.ModId, item.VersionId)
                                                                ))
                                                    | _ -> false
                                            }
                                        else
                                            Task.FromResult false

                                    match recorded with
                                    | Some value when tokenChanged && stage = "enb" && enbTransition ->
                                        let nextStage =
                                            if includeFnis then "fnis-install" else "readiness"

                                        do!
                                            store.SkyrimSetups.Save
                                                { value with
                                                    PlanToken = tokenValue
                                                    Stage = nextStage }

                                        tokenChanged <- false
                                        stage <- nextStage
                                    | Some value when
                                        not tokenChanged && (stage = "enb" || stage = "enb-start")
                                        ->
                                        let nextStage =
                                            if includeFnis then "fnis-install" else "readiness"

                                        do!
                                            store.SkyrimSetups.Save
                                                { value with
                                                    PlanToken = tokenValue
                                                    Stage = nextStage }

                                        stage <- nextStage
                                    | _ -> ()

                                    let baseComponents = [ skseComponent; enbComponent ]

                                    let! fnisState, output =
                                        if includeFnis then
                                            task {
                                                let! value = dependencies.ReadFnis workspace profile

                                                if
                                                    value.Phase = FnisPhase.Ready
                                                    || value.Phase = FnisPhase.UpdateAvailable
                                                    || value.Phase = FnisPhase.SourceUnavailable
                                                then
                                                    let! inspected =
                                                        dependencies.InspectFnis
                                                            workspace
                                                            profile
                                                            token

                                                    return Some value, Result.toOption inspected
                                                else
                                                    return Some value, None
                                            }
                                        else
                                            task { return None, None }

                                    let fnisReady =
                                        match fnisState, output with
                                        | None, _ -> true
                                        | Some state, Some output ->
                                            state.Phase = FnisPhase.Ready
                                            && output.Phase = ModConductor.Fnis.FnisOutputPhase.Current
                                        | _ -> false

                                    let fnisActive =
                                        match fnisState, output with
                                        | Some state, _ when
                                            state.Phase = FnisPhase.Downloading
                                            || state.Phase = FnisPhase.Installing
                                            ->
                                            true
                                        | _, Some output when
                                            output.Phase = ModConductor.Fnis.FnisOutputPhase.Running
                                            ->
                                            true
                                        | _ -> false

                                    let fnisBlocked =
                                        match fnisState, output with
                                        | Some state, _ ->
                                            state.Phase = FnisPhase.Failed
                                            || state.Phase = FnisPhase.RecoveryRequired
                                            || state.Phase = FnisPhase.SourceUnavailable
                                            || state.Phase = FnisPhase.Unavailable
                                            || (output
                                                |> Option.exists (fun value ->
                                                    value.Phase = ModConductor.Fnis.FnisOutputPhase.Failed
                                                    || value.Phase = ModConductor.Fnis.FnisOutputPhase.Cancelled
                                                    || value.Phase = ModConductor.Fnis.FnisOutputPhase.Abandoned))
                                        | None, _ -> false

                                    let components =
                                        match fnisState with
                                        | None -> baseComponents
                                        | Some state ->
                                            let status, detail =
                                                match output with
                                                | Some output -> output.Status, output.Detail
                                                | None -> state.Status, state.Detail

                                            baseComponents
                                            @ [ componentView
                                                    "FNIS"
                                                    status
                                                    detail
                                                    fnisReady
                                                    fnisActive
                                                    fnisBlocked ]

                                    let fnisSetupReady =
                                        fnisState
                                        |> Option.exists (fun value ->
                                            value.Phase = FnisPhase.Ready)

                                    let nextFnisStage =
                                        if fnisReady then "readiness" else "fnis-run"

                                    let! fnisInstallTransition =
                                        if
                                            tokenChanged && stage = "fnis-install" && fnisSetupReady
                                        then
                                            task {
                                                let! installed =
                                                    store.FnisSetups.ReadExact(
                                                        workspace,
                                                        profile,
                                                        deployed.ActiveGeneration
                                                    )

                                                return
                                                    match installed, recorded with
                                                    | Some installed, Some intent ->
                                                        permitsStageChange
                                                            intent
                                                            (SkyrimSetupStageChange
                                                                .ComponentDeployment(
                                                                    installed.GenerationId,
                                                                    [ installed.ModId,
                                                                      installed.VersionId ]
                                                                ))
                                                    | _ -> false
                                            }
                                        else
                                            Task.FromResult false

                                    let! fnisRunTransition =
                                        if tokenChanged && stage = "fnis-run" && fnisReady then
                                            task {
                                                match
                                                    recorded |> Option.bind _.ActionId,
                                                    output,
                                                    recorded
                                                with
                                                | Some expected, Some observed, Some intent when
                                                    observed.LatestRunId = Some expected
                                                    ->
                                                    let! published =
                                                        store.FnisSetups.PublishedOutput(
                                                            workspace,
                                                            profile,
                                                            expected
                                                        )

                                                    return
                                                        published
                                                        |> Option.exists (fun (modId, versionId) ->
                                                            permitsStageChange
                                                                intent
                                                                (SkyrimSetupStageChange.FnisOutput(
                                                                    modId,
                                                                    versionId
                                                                )))
                                                | _ -> return false
                                            }
                                        else
                                            Task.FromResult false

                                    match recorded with
                                    | Some value when
                                        tokenChanged
                                        && stage = "fnis-install"
                                        && fnisSetupReady
                                        && fnisInstallTransition
                                        ->
                                        do!
                                            store.SkyrimSetups.Save
                                                { value with
                                                    PlanToken = tokenValue
                                                    Stage = nextFnisStage
                                                    ActionId = None }

                                        tokenChanged <- false
                                        stage <- nextFnisStage
                                    | Some value when
                                        tokenChanged
                                        && stage = "fnis-run"
                                        && fnisReady
                                        && fnisRunTransition
                                        ->
                                        do!
                                            store.SkyrimSetups.Save
                                                { value with
                                                    PlanToken = tokenValue
                                                    Stage = "readiness"
                                                    ActionId = None }

                                        tokenChanged <- false
                                        stage <- "readiness"
                                    | Some value when
                                        not tokenChanged && stage = "fnis-install" && fnisSetupReady
                                        ->
                                        do!
                                            store.SkyrimSetups.Save
                                                { value with Stage = nextFnisStage }

                                        stage <- nextFnisStage
                                    | Some value when
                                        not tokenChanged && stage = "fnis-run" && fnisReady
                                        ->
                                        do!
                                            store.SkyrimSetups.Save
                                                { value with Stage = "readiness" }

                                        stage <- "readiness"
                                    | _ -> ()

                                    if not fnisReady && tokenChanged then
                                        if fnisActive then
                                            return staleActivePlan components
                                        else
                                            return stalePlan components
                                    elif not fnisReady then
                                        let stale =
                                            output
                                            |> Option.exists (fun value ->
                                                value.Phase
                                                <> ModConductor.Fnis.FnisOutputPhase.Current
                                                && value.Phase
                                                   <> ModConductor.Fnis.FnisOutputPhase.Running)

                                        return
                                            view
                                                (if consent then
                                                     if
                                                         output
                                                         |> Option.exists (fun value ->
                                                             value.Phase = ModConductor.Fnis.FnisOutputPhase.Running)
                                                     then
                                                         SkyrimSetupPhase.FnisRunning
                                                     elif fnisBlocked then
                                                         SkyrimSetupPhase.Failed
                                                     elif stale then
                                                         SkyrimSetupPhase.FnisStale
                                                     else
                                                         SkyrimSetupPhase.SettingUpFnis
                                                 else
                                                     SkyrimSetupPhase.NeedsConsent)
                                                (components |> List.last).Status
                                                (components |> List.last).Detail
                                                tokenValue
                                                planned
                                                components
                                                includeFnis
                                                consent
                                                (not consent)
                                                (consent && not fnisActive)
                                                false
                                                fnisActive
                                                false
                                    elif tokenChanged then
                                        return stalePlan components
                                    else
                                        let! pluginPreflight =
                                            dependencies.PluginPreflight workspace profile token

                                        let! launch = dependencies.ReadLaunch workspace profile

                                        let launchReady, launchStatus, launchDetail =
                                            match pluginPreflight, launch with
                                            | Error(ProfileDataError.Invalid detail), _
                                            | Error(ProfileDataError.Unavailable detail), _
                                            | Error(ProfileDataError.Conflict detail), _ ->
                                                false, "Plugin order needs attention", detail
                                            | Error ProfileDataError.Busy, _ ->
                                                false,
                                                "Plugin order is busy",
                                                "Wait for the current profile operation, then select Refresh."
                                            | Error _, _ ->
                                                false,
                                                "Plugin order needs attention",
                                                "Refresh the plugins before playing."
                                            | Ok(), Ok state when
                                                state.Problem.IsNone && state.Runtime <> ""
                                                ->
                                                true,
                                                "Play is ready",
                                                "The selected deployment, plugin order and "
                                                + state.Runtime
                                                + " launch context passed their checks."
                                            | Ok(), Ok state ->
                                                false,
                                                "Play needs attention",
                                                state.Problem
                                                |> Option.defaultValue
                                                    "Refresh the selected launch context."
                                            | Ok(), Error(ExecutableError.Unavailable detail)
                                            | Ok(), Error(ExecutableError.Invalid detail) ->
                                                false, "Play needs attention", detail
                                            | Ok(), Error _ ->
                                                false,
                                                "Play needs attention",
                                                "Refresh the selected deployment and launch context."

                                        let components =
                                            components
                                            @ [ componentView
                                                    "Play"
                                                    launchStatus
                                                    launchDetail
                                                    launchReady
                                                    false
                                                    (not launchReady) ]

                                        return
                                            view
                                                (if launchReady then
                                                     SkyrimSetupPhase.Ready
                                                 else
                                                     SkyrimSetupPhase.Failed)
                                                (if launchReady then
                                                     "Skyrim setup is ready"
                                                 else
                                                     launchStatus)
                                                (if launchReady then
                                                     "Play uses the checked SKSE, ENB, optional FNIS output and selected runtime."
                                                 else
                                                     launchDetail)
                                                tokenValue
                                                planned
                                                components
                                                includeFnis
                                                consent
                                                false
                                                false
                                                false
                                                false
                                                launchReady
        }

    let completeCancellation workspace profile (intent: StoredSkyrimSetupIntent) token =
        task {
            let key = workspace, profile

            match workers.TryGetValue key with
            | true, cancellation -> cancellation.Cancel()
            | _ -> ()

            let! childResult =
                task {
                    match intent.Stage with
                    | "enb-start"
                    | "enb-wait"
                    | "enb" ->
                        let! result = dependencies.CancelEnb workspace profile

                        let detail = result.Status + ". " + result.Detail

                        return
                            if
                                result.Phase = EnbPhase.Validating
                                || result.Phase = EnbPhase.Acquiring
                                || result.Phase = EnbPhase.Installing
                                || result.Phase = EnbPhase.Failed
                                || result.Phase = EnbPhase.Conflict
                            then
                                Error detail
                            else
                                Ok detail
                    | "skse-start"
                    | "skse" ->
                        let! result = dependencies.CancelSkse workspace profile
                        let detail = result.Status + ". " + result.Detail

                        return
                            if
                                result.Phase = SksePhase.Downloading
                                || result.Phase = SksePhase.Installing
                            then
                                Error detail
                            else
                                Ok detail
                    | "fnis-install" ->
                        let! result = dependencies.CancelFnis workspace profile
                        let detail = result.Status + ". " + result.Detail

                        return
                            if
                                result.Phase = FnisPhase.Downloading
                                || result.Phase = FnisPhase.Installing
                                || result.Phase = FnisPhase.RecoveryRequired
                            then
                                Error detail
                            else
                                Ok detail
                    | "fnis-run" ->
                        let! result = dependencies.CancelFnisRun workspace profile

                        return
                            match result with
                            | Ok value when value.Phase = ModConductor.Fnis.FnisOutputPhase.Running ->
                                Error(value.Status + ". " + value.Detail)
                            | Ok value -> Ok(value.Status + ". " + value.Detail)
                            | Error error -> Error("FNIS cancellation result: " + string error)
                    | _ -> return Ok "No child operation remained active."
                }

            let! deployed = store.Deployments.Read profile

            let! recovered =
                match deployed with
                | Ok value when value.PendingReceipt.IsSome ->
                    recoverPending workspace profile value token
                | _ -> Task.FromResult(Ok())

            match childResult, recovered with
            | Error childDetail, Error recoveryDetail ->
                let pending =
                    { intent with
                        CancelRequested = true
                        Cancelled = false
                        Completed = false
                        CancelDetail = childDetail + " " + recoveryDetail }

                do! store.SkyrimSetups.Save pending
                return! inspect workspace profile intent.IncludeFnis (Some pending) token
            | Error detail, Ok()
            | Ok _, Error detail ->
                let pending =
                    { intent with
                        CancelRequested = true
                        Cancelled = false
                        Completed = false
                        CancelDetail = detail }

                do! store.SkyrimSetups.Save pending
                return! inspect workspace profile intent.IncludeFnis (Some pending) token
            | Ok childDetail, Ok() ->
                let cancelled =
                    { intent with
                        CancelRequested = false
                        Cancelled = true
                        Completed = false
                        Stage = "cancelled"
                        ActionId = None
                        ArchivePath = None
                        CancelDetail = childDetail }

                do! store.SkyrimSetups.Save cancelled
                return! inspect workspace profile intent.IncludeFnis (Some cancelled) token
        }

    let confirmPlan workspace profile includeFnis expected =
        task {
            let! contextResult = (store.GameContexts :> IGameContexts).Read workspace
            let! deploymentResult = store.Deployments.Read profile

            match contextResult, deploymentResult with
            | Ok context, Ok deployment when deployment.WorkspaceId = workspace ->
                let current = planToken workspace profile includeFnis context.Revision deployment

                return if current = expected then Some context.Revision else None
            | _ -> return None
        }

    let advance workspace profile (intent: StoredSkyrimSetupIntent) token =
        task {
            let! before = inspect workspace profile intent.IncludeFnis (Some intent) token

            match before.Phase with
            | SkyrimSetupPhase.PreparingDeployment
            | SkyrimSetupPhase.RecoveryRequired ->
                let! deployment = store.Deployments.Read profile

                match deployment with
                | Error error ->
                    return
                        { before with
                            Phase = SkyrimSetupPhase.Failed
                            Status = "The first deployment could not be prepared"
                            Detail = deploymentError error
                            Active = false
                            CanContinue = true }
                | Ok deployment ->
                    let running =
                        if deployment.ActiveGeneration.IsNone then
                            { intent with
                                Stage = "deployment-running"
                                ActionId = Some(intent.ActionId |> Option.defaultWith Guid.NewGuid) }
                        else
                            intent

                    if deployment.ActiveGeneration.IsNone then
                        do! store.SkyrimSetups.Save running

                    let! result =
                        if deployment.ActiveGeneration.IsNone then
                            initialDeployment deployment running.ActionId.Value token
                        else
                            recoverPending workspace profile deployment token

                    match result with
                    | Error detail ->
                        return
                            { before with
                                Phase = SkyrimSetupPhase.Failed
                                Status = "The first deployment could not be prepared"
                                Detail = detail
                                Active = false
                                CanContinue = true }
                    | Ok() ->
                        return! inspect workspace profile intent.IncludeFnis (Some running) token
            | SkyrimSetupPhase.WaitingForSkse when before.CanContinue ->
                do! store.SkyrimSetups.Save { intent with Stage = "skse" }
                let! _ = dependencies.StartSkse workspace profile
                return! inspect workspace profile intent.IncludeFnis (Some intent) token
            | SkyrimSetupPhase.SettingUpEnb when before.CanContinue ->
                let waiting = { intent with Stage = "enb-wait" }
                do! store.SkyrimSetups.Save waiting
                let! _ = dependencies.OpenEnb workspace profile
                return! inspect workspace profile intent.IncludeFnis (Some waiting) token
            | SkyrimSetupPhase.SettingUpFnis when before.CanContinue ->
                do! store.SkyrimSetups.Save { intent with Stage = "fnis-install" }
                let! current = dependencies.ReadFnis workspace profile

                let! _ =
                    if current.Phase = FnisPhase.UpdateAvailable then
                        dependencies.UpdateFnis workspace profile
                    elif current.Phase = FnisPhase.RecoveryRequired then
                        dependencies.RecoverFnis workspace profile token
                    else
                        dependencies.InstallFnis workspace profile

                return! inspect workspace profile intent.IncludeFnis (Some intent) token
            | SkyrimSetupPhase.FnisStale when before.CanContinue ->
                let run = Guid.NewGuid()

                let running =
                    { intent with
                        Stage = "fnis-run"
                        ActionId = Some run }

                do! store.SkyrimSetups.Save running

                startWorker workspace profile (fun childToken ->
                    dependencies.RunFnis
                        { Id = run
                          WorkspaceId = workspace
                          ProfileId = profile }
                        childToken)
                |> ignore

                return! inspect workspace profile intent.IncludeFnis (Some running) token
            | SkyrimSetupPhase.Failed when before.CanContinue ->
                let! deployment = store.Deployments.Read profile

                let! output =
                    if intent.IncludeFnis then
                        task {
                            let! inspected = dependencies.InspectFnis workspace profile token
                            return Result.toOption inspected
                        }
                    else
                        task { return None }

                let! enbState = dependencies.ReadEnb workspace profile
                let! fnisState = dependencies.ReadFnis workspace profile
                let! skseState = dependencies.ReadSkse workspace profile

                if
                    output
                    |> Option.exists (fun value ->
                        value.Phase = ModConductor.Fnis.FnisOutputPhase.Failed
                        || value.Phase = ModConductor.Fnis.FnisOutputPhase.Cancelled
                        || value.Phase = ModConductor.Fnis.FnisOutputPhase.Abandoned)
                then
                    let run = Guid.NewGuid()

                    let running =
                        { intent with
                            Stage = "fnis-run"
                            ActionId = Some run }

                    do! store.SkyrimSetups.Save running

                    startWorker workspace profile (fun childToken ->
                        dependencies.RunFnis
                            { Id = run
                              WorkspaceId = workspace
                              ProfileId = profile }
                            childToken)
                    |> ignore

                    return! inspect workspace profile intent.IncludeFnis (Some running) token
                elif
                    deployment |> Result.toOption |> Option.bind _.PendingReceipt |> Option.isSome
                    && (enbState.Phase = EnbPhase.Failed || enbState.Phase = EnbPhase.Conflict)
                then
                    let! _ = dependencies.RecoverEnb workspace profile token
                    return! inspect workspace profile intent.IncludeFnis (Some intent) token
                elif fnisState.Phase = FnisPhase.RecoveryRequired then
                    let! _ = dependencies.RecoverFnis workspace profile token
                    return! inspect workspace profile intent.IncludeFnis (Some intent) token
                elif
                    skseState.Phase = SksePhase.Failed
                    || skseState.Phase = SksePhase.UpdateAvailable
                then
                    let! _ = dependencies.StartSkse workspace profile
                    return! inspect workspace profile intent.IncludeFnis (Some intent) token
                elif fnisState.Phase = FnisPhase.Failed then
                    let! _ = dependencies.InstallFnis workspace profile
                    return! inspect workspace profile intent.IncludeFnis (Some intent) token
                else
                    return before
            | SkyrimSetupPhase.Ready ->
                do!
                    store.SkyrimSetups.Save
                        { intent with
                            Completed = true
                            Stage = "complete"
                            PlanToken = before.PlanToken
                            ActionId = None
                            ArchivePath = None
                            CancelRequested = false
                            CancelDetail = "" }

                return
                    { before with
                        ConsentRecorded = false
                        CanCancel = false }
            | _ -> return before
        }

    new
        (
            store: OperationStore,
            skse: SkseCoordinator,
            enb: EnbCoordinator,
            fnis: FnisCoordinator,
            execution: IFnisExecution,
            launches: IGameLaunching,
            pluginOrders: IProfilePluginOrders
        ) =
        new SkyrimSetupCoordinator(
            store,
            SkyrimSetupDependencies.production skse enb fnis execution launches pluginOrders
        )

    member _.Read(workspace, profile, includeFnis, token) =
        task {
            let! intent = store.SkyrimSetups.Read(workspace, profile)
            let selected = intent |> Option.map _.IncludeFnis |> Option.defaultValue includeFnis
            let! current = inspect workspace profile selected intent token

            return current
        }

    member _.Start(workspace, profile, includeFnis, expectedPlan, confirmed, token) =
        task {
            let! existing = store.SkyrimSetups.Read(workspace, profile)

            match existing with
            | Some intent when
                confirmed
                && not intent.Cancelled
                && not intent.Completed
                && expectedPlan = intent.PlanToken
                ->
                return! advance workspace profile intent token
            | Some intent ->
                let! planned = inspect workspace profile includeFnis None token

                if not confirmed || planned.PlanToken = "" || planned.PlanToken <> expectedPlan then
                    return
                        { planned with
                            Status = "Review the current change plan"
                            Detail =
                                "Setup did not start because the confirmed plan is missing or out of date."
                            CanStart = planned.PlanToken <> "" }
                else
                    let! contextRevision = confirmPlan workspace profile includeFnis expectedPlan

                    match contextRevision with
                    | None ->
                        return
                            { planned with
                                Status = "Review the current change plan"
                                Detail =
                                    "Setup did not start because the installation, profile sources or active deployment changed."
                                CanStart = true }
                    | Some contextRevision ->
                        let initialStage =
                            if
                                planned.Components
                                |> List.exists (fun item -> item.Name = "Deployment")
                            then
                                "deployment"
                            else
                                "skse-start"

                        let replacement =
                            { intent with
                                IncludeFnis = includeFnis
                                PlanToken = expectedPlan
                                Cancelled = false
                                Completed = false
                                Stage = initialStage
                                ContextRevision = contextRevision
                                ActionId = None
                                ArchivePath = None
                                CancelRequested = false
                                CancelDetail = ""
                                RequestedAt = DateTimeOffset.UtcNow }

                        do! store.SkyrimSetups.Save replacement
                        return! advance workspace profile replacement token
            | None ->
                let! planned = inspect workspace profile includeFnis None token

                if not confirmed || planned.PlanToken = "" || planned.PlanToken <> expectedPlan then
                    return
                        { planned with
                            Status = "Review the current change plan"
                            Detail =
                                "Setup did not start because the confirmed plan is missing or out of date."
                            CanStart = planned.PlanToken <> "" }
                else
                    let! contextRevision = confirmPlan workspace profile includeFnis expectedPlan

                    match contextRevision with
                    | None ->
                        return
                            { planned with
                                Status = "Review the current change plan"
                                Detail =
                                    "Setup did not start because the installation, profile sources or active deployment changed."
                                CanStart = true }
                    | Some contextRevision ->
                        let initialStage =
                            if
                                planned.Components
                                |> List.exists (fun item -> item.Name = "Deployment")
                            then
                                "deployment"
                            else
                                "skse-start"

                        let intent =
                            { WorkspaceId = workspace
                              ProfileId = profile
                              IncludeFnis = includeFnis
                              PlanToken = expectedPlan
                              Cancelled = false
                              Completed = false
                              Stage = initialStage
                              ContextRevision = contextRevision
                              ActionId = None
                              ArchivePath = None
                              CancelRequested = false
                              CancelDetail = ""
                              RequestedAt = DateTimeOffset.UtcNow }

                        do! store.SkyrimSetups.Save intent
                        return! advance workspace profile intent token
        }

    member _.Continue(workspace, profile, token) =
        task {
            let! intent = store.SkyrimSetups.Read(workspace, profile)

            match intent with
            | Some value when value.CancelRequested ->
                return! completeCancellation workspace profile value token
            | Some value -> return! advance workspace profile value token
            | None -> return! inspect workspace profile false None token
        }

    member _.SelectEnbArchive(workspace, profile, operation, path, token) =
        task {
            let! intent = store.SkyrimSetups.Read(workspace, profile)

            match intent with
            | None -> return! inspect workspace profile false None token
            | Some intent ->
                let! current = inspect workspace profile intent.IncludeFnis (Some intent) token

                if
                    intent.Cancelled
                    || intent.Completed
                    || current.PlanToken <> intent.PlanToken
                    || current.Phase <> SkyrimSetupPhase.WaitingForEnbArchive
                then
                    return current
                else
                    let selecting =
                        { intent with
                            Stage = "enb"
                            ActionId = Some operation
                            ArchivePath = Some path }

                    do! store.SkyrimSetups.Save selecting

                    startWorker workspace profile (fun childToken ->
                        dependencies.SelectEnb workspace profile operation path childToken)
                    |> ignore

                    return
                        { current with
                            Phase = SkyrimSetupPhase.SettingUpEnb
                            Status = "Setting up Lean ENB"
                            Detail =
                                "The child owner is validating and applying the selected ENB archive."
                            CanSelectEnbArchive = false
                            CanContinue = false
                            Active = true
                            CanCancel = true }
        }

    member _.Cancel(workspace, profile, token) =
        task {
            let! intent = store.SkyrimSetups.Read(workspace, profile)

            match intent with
            | None -> return! inspect workspace profile false None token
            | Some intent when intent.Cancelled || intent.Completed ->
                return! inspect workspace profile intent.IncludeFnis (Some intent) token
            | Some intent ->
                let requested =
                    { intent with
                        CancelRequested = true
                        Cancelled = false
                        Completed = false
                        CancelDetail = "Cancellation was requested." }

                do! store.SkyrimSetups.Save requested
                return! completeCancellation workspace profile requested token
        }

    interface IDisposable with
        member _.Dispose() =
            lifetime.Cancel()

            for key in workers.Keys do
                match workers.TryRemove key with
                | true, cancellation ->
                    cancellation.Cancel()
                    cancellation.Dispose()
                | _ -> ()

            lifetime.Dispose()

type internal SkyrimSetupService(coordinator: SkyrimSetupCoordinator) =
    inherit SkyrimSetupOperations.SkyrimSetupOperationsBase()

    let ids workspace profile =
        ModLibraryWire.id workspace, ModLibraryWire.id profile

    let wire (value: SkyrimSetupView) =
        let result =
            SkyrimSetupState(
                Phase = value.Phase,
                Status = value.Status,
                Detail = value.Detail,
                PlanToken = value.PlanToken,
                IncludeFnis = value.IncludeFnis,
                ConsentRecorded = value.ConsentRecorded,
                CanStart = value.CanStart,
                CanContinue = value.CanContinue,
                CanSelectEnbArchive = value.CanSelectEnbArchive,
                Active = value.Active,
                CanCancel = value.CanCancel,
                Ready = value.Ready
            )

        result.Changes.AddRange(
            value.Changes
            |> Seq.map (fun change ->
                SkyrimSetupChange(Title = change.Title, Detail = change.Detail))
        )

        result.Components.AddRange(
            value.Components
            |> Seq.map (fun item ->
                SkyrimSetupComponent(
                    Name = item.Name,
                    Status = item.Status,
                    Detail = item.Detail,
                    Ready = item.Ready,
                    Active = item.Active,
                    Blocked = item.Blocked
                ))
        )

        result

    override _.ReadSkyrimSetup(request, context) =
        let workspace, profile = ids request.WorkspaceId request.ProfileId

        task {
            let! value =
                coordinator.Read(workspace, profile, request.IncludeFnis, context.CancellationToken)

            return wire value
        }

    override _.StartSkyrimSetup(request, context) =
        let workspace, profile = ids request.WorkspaceId request.ProfileId

        task {
            let! value =
                coordinator.Start(
                    workspace,
                    profile,
                    request.IncludeFnis,
                    request.PlanToken,
                    request.ChangePlanConfirmed,
                    context.CancellationToken
                )

            return wire value
        }

    override _.ContinueSkyrimSetup(request, context) =
        let workspace, profile = ids request.WorkspaceId request.ProfileId

        task {
            let! value = coordinator.Continue(workspace, profile, context.CancellationToken)
            return wire value
        }

    override _.SelectSkyrimSetupEnbArchive(request, context) =
        let workspace, profile = ids request.WorkspaceId request.ProfileId

        task {
            let! value =
                coordinator.SelectEnbArchive(
                    workspace,
                    profile,
                    ModLibraryWire.id request.OperationId,
                    request.Path,
                    context.CancellationToken
                )

            return wire value
        }

    override _.CancelSkyrimSetup(request, context) =
        let workspace, profile = ids request.WorkspaceId request.ProfileId

        task {
            let! value = coordinator.Cancel(workspace, profile, context.CancellationToken)
            return wire value
        }
