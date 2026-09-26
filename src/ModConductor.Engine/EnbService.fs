namespace ModConductor.Engine

open System
open System.Threading
open System.Threading.Tasks
open ModConductor.Enb
open ModConductor.GameContexts
open ModConductor.HttpDownloads
open ModConductor.Nexus
open ModConductor.Persistence
open ModConductor.Protocol.V1

type EnbCoordinator
    (
        nexus: NexusSession,
        downloads: DownloadSession,
        store: OperationStore,
        handoff: IOAuthHandoff,
        row: EnbCompatibilityRow,
        ?eligibilityOverride: Guid * Guid -> Task<Result<unit, EnbProblem>>
    ) as this =
    let changed = Event<Guid * Guid>()

    let view = EnbPresentation.view row
    let defaultView () = EnbPresentation.defaultView row
    let adoptionView () = EnbPresentation.adoptionView row
    let fromStored = EnbPresentation.fromStored

    let persist workspace profile artifact hash (value: EnbView) =
        task {
            do!
                store.EnbSetups.SaveStatus
                    { WorkspaceId = workspace
                      ProfileId = profile
                      Phase = EnbPresentation.phaseName value.Phase
                      Status = value.Status
                      Detail = value.Detail
                      RuntimeVersion = value.RuntimeVersion
                      PresetVersion = value.PresetVersion
                      ArtifactId = artifact
                      ArchiveSha256 = hash
                      CheckedAt = DateTimeOffset.UtcNow }

            changed.Trigger(workspace, profile)
            return value
        }

    let eligibility workspace profile =
        match eligibilityOverride with
        | Some qualify -> qualify (workspace, profile)
        | None ->
            task {
                let! context = (store.GameContexts :> IGameContexts).Read(workspace, profile)
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

    let acquisition =
        EnbAcquisition(nexus, downloads, store, handoff, row, persist, view)

    let reference = acquisition.Reference
    let pendingFor = acquisition.PendingFor
    let beginAcquisition = acquisition.Begin

    let selection =
        EnbArchiveSelection(store, row, eligibility, persist, view, adoptionView, beginAcquisition)

    let selectArchive = selection.Select

    let recovery =
        EnbRecovery(store, persist, view, fun workspace profile -> this.Read(workspace, profile))

    let operationLoop =
        new EnbOperationLoop(downloads, store, acquisition, defaultView, changed.Trigger)

    let runAdvance = operationLoop.RunAdvance

    let nxmIngress =
        EnbNxmIngress(
            nexus,
            downloads,
            store,
            acquisition,
            persist,
            view,
            operationLoop.Signal,
            operationLoop.CancelActive
        )

    member _.Changed = changed.Publish

    member _.Read(workspace, profile) =
        if not row.TermsApproved then
            Task.FromResult(adoptionView ())
        else
            task {
                let key = workspace, profile
                let! operation = store.EnbSetups.ConfigurationOperation(workspace, profile)
                let! saved = store.EnbSetups.ReadStatus(workspace, profile)

                match operation, saved with
                | Some _, Some value when operationLoop.Contains key -> return fromStored value
                | Some _, None when operationLoop.Contains key ->
                    return
                        view
                            EnbPhase.Installing
                            "Setting up Lean ENB"
                            "The owned component operation is active."
                | Some operation, _ ->
                    return
                        view
                            (if operation.Phase = "conflict" then
                                 EnbPhase.Conflict
                             else
                                 EnbPhase.Failed)
                            "ENB setup recovery is required"
                            (if String.IsNullOrWhiteSpace operation.Detail then
                                 "Finish recovery before changing this ENB setup."
                             else
                                 operation.Detail)
                | None, Some value when value.Phase = "acquiring" || value.Phase = "installing" ->
                    return! runAdvance workspace profile
                | None, Some value when
                    value.Phase = "waiting"
                    || value.Phase = "failed"
                    || value.Phase = "conflict"
                    || value.Phase = "ready"
                    || value.Phase = "unavailable"
                    ->
                    return fromStored value
                | None, _ ->
                    let! eligible = eligibility workspace profile

                    return
                        match eligible with
                        | Ok() -> defaultView ()
                        | Error problem ->
                            view
                                EnbPhase.Unavailable
                                "ENB setup is unavailable"
                                (EnbProblem.message problem)
            }

    member _.OpenAuthorPage(workspace, profile) =
        if not row.TermsApproved then
            Task.FromResult(adoptionView ())
        else
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
                        do! handoff.Open(row.Runtime.Source, operationLoop.Token)

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
        if not row.TermsApproved then
            Task.FromResult(adoptionView ())
        else
            task {
                let key = workspace, profile

                do! operationLoop.CancelAndWait key

                let! configuration = store.EnbSetups.ConfigurationOperation(workspace, profile)
                let! deployed = store.Deployments.Read profile

                if
                    configuration.IsSome
                    || (deployed |> Result.toOption |> Option.bind _.PendingReceipt |> Option.isSome)
                then
                    return! this.Recover(workspace, profile, CancellationToken.None)
                else
                    let! pending = pendingFor profile

                    for source in pending do
                        let nexusReference =
                            reference source.AccountId source.NexusModId source.File false

                        let! artifact = downloads.FindNexus(workspace, nexusReference)

                        match artifact with
                        | Some value ->
                            let! _ = downloads.Control(workspace, value.Id, DownloadAction.Pause)
                            ()
                        | None -> ()

                    do! store.EnbSetups.RemovePending(profile, None)
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
        if not row.TermsApproved then
            Task.FromResult(adoptionView ())
        else
            operationLoop.Select
                workspace
                profile
                token
                (fun cancellation ->
                    selectArchive false (workspace, profile, operation, path, cancellation))
                (fun () -> this.Read(workspace, profile))

    member _.SelectRuntimeArchive(workspace, profile, operation, path: string, token) =
        if not row.TermsApproved then
            Task.FromResult(adoptionView ())
        else
            operationLoop.Select
                workspace
                profile
                token
                (fun cancellation ->
                    selectArchive true (workspace, profile, operation, path, cancellation))
                (fun () -> this.Read(workspace, profile))

    member _.Update(workspace, profile) =
        if not row.TermsApproved then
            Task.FromResult(adoptionView ())
        else
            task {
                let! saved = store.EnbSetups.ReadStatus(workspace, profile)

                match saved |> Option.bind _.ArtifactId with
                | None ->
                    return!
                        persist
                            workspace
                            profile
                            None
                            None
                            (view
                                EnbPhase.Failed
                                "The ENBSeries archive is unavailable"
                                "Choose the ENBSeries archive before updating Lean ENB.")
                | Some id ->
                    let! artifact = store.Artifacts.Read(workspace, id)

                    match artifact with
                    | Ok value ->
                        let! started = beginAcquisition workspace profile value operationLoop.Token

                        if started.Phase = EnbPhase.Acquiring then
                            let! _ = runAdvance workspace profile
                            ()

                        return started
                    | Error _ ->
                        return!
                            persist
                                workspace
                                profile
                                None
                                None
                                (view
                                    EnbPhase.Failed
                                    "The ENBSeries archive is unavailable"
                                    "Choose the ENBSeries archive again.")
            }

    member _.Remove(workspace, profile, token, ?runtimeOnly: bool) =
        if not row.TermsApproved then
            Task.FromResult(adoptionView ())
        else
            task {
                try
                    let! removed =
                        store.RemoveEnb(
                            workspace,
                            profile,
                            token,
                            runtimeOnly = defaultArg runtimeOnly false
                        )

                    match removed with
                    | Ok _ ->
                        do! store.EnbSetups.RemovePending(profile, None)
                        return! persist workspace profile None None (defaultView ())
                    | Error detail ->
                        return!
                            persist
                                workspace
                                profile
                                None
                                None
                                (view
                                    (if
                                         detail.Contains(
                                             "preserved",
                                             StringComparison.OrdinalIgnoreCase
                                         )
                                     then
                                         EnbPhase.Conflict
                                     else
                                         EnbPhase.Failed)
                                    "ENB removal needs attention"
                                    detail)
                with error ->
                    return!
                        persist
                            workspace
                            profile
                            None
                            None
                            (view
                                (if
                                     error.Message.Contains(
                                         "preserved",
                                         StringComparison.OrdinalIgnoreCase
                                     )
                                 then
                                     EnbPhase.Conflict
                                 else
                                     EnbPhase.Failed)
                                "ENB removal needs attention"
                                error.Message)
            }

    member _.Recover(workspace, profile, token) =
        if not row.TermsApproved then
            Task.FromResult(adoptionView ())
        else
            recovery.Recover(workspace, profile, token)

    member _.AcceptNxm(id: Guid) =
        if row.TermsApproved then
            nxmIngress.Accept(id)

    member internal _.Stop() = operationLoop.Stop()

    interface IDisposable with
        member _.Dispose() =
            (operationLoop :> IDisposable).Dispose()
