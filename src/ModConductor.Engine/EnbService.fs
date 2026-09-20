namespace ModConductor.Engine

open System
open System.Threading
open ModConductor.ArtifactLibrary
open ModConductor.ArchiveInspection
open ModConductor.Enb
open ModConductor.GameContexts
open ModConductor.Nexus
open ModConductor.Persistence
open ModConductor.Protocol.V1

type EnbView =
    { Phase: EnbPhase
      Status: string
      Detail: string
      RuntimeVersion: string
      PresetVersion: string }

type EnbCoordinator
    (
        store: OperationStore,
        handoff: IOAuthHandoff,
        row: EnbCompatibilityRow,
        ?eligibilityOverride: Guid * Guid -> Threading.Tasks.Task<Result<unit, EnbProblem>>
    ) =
    let lifetime = new CancellationTokenSource()

    let phaseName =
        function
        | EnbPhase.Blocked -> "blocked"
        | EnbPhase.Available -> "available"
        | EnbPhase.WaitingForArchive -> "waiting"
        | EnbPhase.Validating -> "validating"
        | EnbPhase.Acquiring -> "acquiring"
        | EnbPhase.Installing -> "installing"
        | EnbPhase.Ready -> "ready"
        | EnbPhase.Failed -> "failed"
        | EnbPhase.Conflict -> "conflict"
        | _ -> "unavailable"

    let phase =
        function
        | "blocked" -> EnbPhase.Blocked
        | "available" -> EnbPhase.Available
        | "waiting" -> EnbPhase.WaitingForArchive
        | "validating" -> EnbPhase.Validating
        | "acquiring" -> EnbPhase.Acquiring
        | "installing" -> EnbPhase.Installing
        | "ready" -> EnbPhase.Ready
        | "failed" -> EnbPhase.Failed
        | "conflict" -> EnbPhase.Conflict
        | _ -> EnbPhase.Unavailable

    let view state status detail =
        { Phase = state
          Status = status
          Detail = detail
          RuntimeVersion = row.Runtime.Version
          PresetVersion = row.Preset.Version }

    let persist workspace profile artifact hash value =
        task {
            do!
                store.EnbSetups.SaveStatus
                    { WorkspaceId = workspace
                      ProfileId = profile
                      Phase = phaseName value.Phase
                      Status = value.Status
                      Detail = value.Detail
                      RuntimeVersion = value.RuntimeVersion
                      PresetVersion = value.PresetVersion
                      ArtifactId = artifact
                      ArchiveSha256 = hash
                      CheckedAt = DateTimeOffset.UtcNow }

            return value
        }

    let defaultView () =
        if
            row.TermsApproved
            && row.Runtime.ExpectedSha256.IsSome
            && row.Preset.ExpectedSha256.IsSome
            && row.Companions |> List.forall (fun pin -> pin.ExpectedSha256.IsSome)
        then
            view
                EnbPhase.Available
                "Lean ENB is available"
                "Open the ENBSeries author page, download version 0.505, then choose the archive."
        else
            view
                EnbPhase.Blocked
                "Lean ENB setup is blocked"
                (EnbProblem.message EnbProblem.AdoptionBlocked)

    let fromStored (stored: StoredEnbStatus) =
        { Phase = phase stored.Phase
          Status = stored.Status
          Detail = stored.Detail
          RuntimeVersion = stored.RuntimeVersion
          PresetVersion = stored.PresetVersion }

    let eligibility workspace profile =
        match eligibilityOverride with
        | Some qualify -> qualify (workspace, profile)
        | None ->
            task {
                let! context = (store.GameContexts :> IGameContexts).Read workspace
                let! deployed = store.Deployments.Read profile

                match context, deployed with
                | Ok context, Ok deployed when
                    deployed.WorkspaceId = workspace
                    && context.Binding.IsSome
                    && not context.Binding.Value.NeedsCheck
                    && context.Binding.Value.Evidence.Valid
                    && context.Binding.Value.Evidence.DefinitionId = Skyrim.definition.Id
                    && Skyrim.definition.Storefront = "Steam"
                    && (context.Binding.Value.Evidence.Platform = ContextPlatform.Windows
                        || (context.Binding.Value.Evidence.Platform = ContextPlatform.Proton
                            && context.Binding.Value.Evidence.Proton.IsSome))
                    ->
                    return Ok()
                | _ -> return Error EnbProblem.GameUnavailable
            }

    member _.Read(workspace, profile) =
        task {
            let! saved = store.EnbSetups.ReadStatus(workspace, profile)

            match saved with
            | Some value when value.Phase = "waiting" || value.Phase = "failed" ->
                return fromStored value
            | None when (defaultView ()).Phase = EnbPhase.Blocked -> return defaultView ()
            | _ ->
                let! eligible = eligibility workspace profile

                return
                    match eligible with
                    | Ok() -> saved |> Option.map fromStored |> Option.defaultWith defaultView
                    | Error problem ->
                        view
                            EnbPhase.Unavailable
                            "ENB setup is unavailable"
                            (EnbProblem.message problem)
        }

    member _.OpenAuthorPage(workspace, profile) =
        task {
            let! eligible = eligibility workspace profile

            match eligible with
            | Error problem ->
                return!
                    persist
                        workspace
                        profile
                        None
                        None
                        (view
                            EnbPhase.Unavailable
                            "ENB setup is unavailable"
                            (EnbProblem.message problem))
            | Ok() ->
                try
                    do! handoff.Open(row.Runtime.Source, lifetime.Token)

                    return!
                        persist
                            workspace
                            profile
                            None
                            None
                            (view
                                EnbPhase.WaitingForArchive
                                "Waiting for the ENBSeries archive"
                                "Download ENBSeries 0.505 from the author page, then choose that archive here.")
                with error ->
                    return!
                        persist
                            workspace
                            profile
                            None
                            None
                            (view
                                EnbPhase.Failed
                                "The ENBSeries page could not be opened"
                                error.Message)
        }

    member _.Cancel(workspace, profile) =
        task {
            let! eligible = eligibility workspace profile

            return!
                persist
                    workspace
                    profile
                    None
                    None
                    (match eligible with
                     | Ok() -> defaultView ()
                     | Error problem ->
                         view
                             EnbPhase.Unavailable
                             "ENB setup is unavailable"
                             (EnbProblem.message problem))
        }

    member _.SelectArchive(workspace, profile, operation, path: string, token) =
        task {
            let! eligible = eligibility workspace profile

            if Result.isError eligible then
                return!
                    persist
                        workspace
                        profile
                        None
                        None
                        (view
                            EnbPhase.Unavailable
                            "ENB setup is unavailable"
                            (EnbProblem.message EnbProblem.GameUnavailable))
            elif
                not row.TermsApproved
                || row.Runtime.ExpectedSha256.IsNone
                || row.Preset.ExpectedSha256.IsNone
                || row.Companions |> List.exists (fun pin -> pin.ExpectedSha256.IsNone)
            then
                return!
                    persist
                        workspace
                        profile
                        None
                        None
                        (view
                            EnbPhase.Blocked
                            "The archive cannot be installed"
                            (EnbProblem.message EnbProblem.AdoptionBlocked))
            else
                let! added =
                    store.Artifacts.Add(
                        { Id = operation
                          WorkspaceId = workspace
                          Path = path
                          Storage = ArtifactStorage.Reference },
                        token
                    )

                match added with
                | Error _ ->
                    return!
                        persist
                            workspace
                            profile
                            None
                            None
                            (view
                                EnbPhase.Failed
                                "The ENBSeries archive could not be read"
                                "Choose the downloaded archive again from its current folder.")
                | Ok artifact ->
                    let reference =
                        { WorkspaceId = workspace
                          Id = artifact.Id
                          Revision = artifact.Revision }

                    try
                        let! inspected = store.ArchiveInspection.Inspect(reference, token)

                        let result =
                            inspected
                            |> Result.mapError (fun _ ->
                                EnbProblem.InvalidArchive
                                    "The selected archive is unavailable. No files were changed.")
                            |> Result.bind (EnbArchiveLayouts.runtime row.Runtime)

                        match result with
                        | Error problem ->
                            let! _ = store.Artifacts.Remove reference

                            return!
                                persist
                                    workspace
                                    profile
                                    None
                                    None
                                    (view
                                        EnbPhase.Failed
                                        "The ENBSeries archive was refused"
                                        (EnbProblem.message problem))
                        | Ok _ ->
                            return!
                                persist
                                    workspace
                                    profile
                                    (Some artifact.Id)
                                    artifact.Sha256
                                    (view
                                        EnbPhase.Acquiring
                                        "ENBSeries 0.505 was validated"
                                        "Lean ENB 1.0.0 and Cathedral Weathers 2.50 will use their pinned Nexus sources.")
                    with error ->
                        let! _ = store.Artifacts.Remove reference

                        let detail =
                            ArchiveFailure.message error
                            |> Option.defaultValue
                                "The archive could not be validated. No files were changed."

                        return!
                            persist
                                workspace
                                profile
                                None
                                None
                                (view EnbPhase.Failed "The ENBSeries archive was refused" detail)
        }

    interface IDisposable with
        member _.Dispose() =
            lifetime.Cancel()
            lifetime.Dispose()

type internal EnbService(coordinator: EnbCoordinator) =
    inherit EnbOperations.EnbOperationsBase()

    let ids (request: EnbRequest) =
        ModLibraryWire.id request.WorkspaceId, ModLibraryWire.id request.ProfileId

    let wire value =
        EnbState(
            Phase = value.Phase,
            Status = value.Status,
            Detail = value.Detail,
            RuntimeVersion = value.RuntimeVersion,
            PresetVersion = value.PresetVersion,
            CanOpenAuthorPage =
                (value.Phase <> EnbPhase.Validating && value.Phase <> EnbPhase.Installing),
            CanSelectArchive =
                (value.Phase = EnbPhase.WaitingForArchive || value.Phase = EnbPhase.Failed),
            CanCancel = (value.Phase = EnbPhase.WaitingForArchive)
        )

    override _.ReadEnb(request, _) =
        task {
            let workspace, profile = ids request
            let! value = coordinator.Read(workspace, profile)
            return wire value
        }

    override _.OpenEnbAuthorPage(request, _) =
        task {
            let workspace, profile = ids request
            let! value = coordinator.OpenAuthorPage(workspace, profile)
            return wire value
        }

    override _.CancelEnbWait(request, _) =
        task {
            let workspace, profile = ids request
            let! value = coordinator.Cancel(workspace, profile)
            return wire value
        }

    override _.SelectEnbArchive(request, context) =
        task {
            let workspace = ModLibraryWire.id request.WorkspaceId
            let profile = ModLibraryWire.id request.ProfileId
            let operation = ModLibraryWire.id request.OperationId

            let! value =
                coordinator.SelectArchive(
                    workspace,
                    profile,
                    operation,
                    request.Path,
                    context.CancellationToken
                )

            return wire value
        }
