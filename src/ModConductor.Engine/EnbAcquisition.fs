namespace ModConductor.Engine

open System
open System.Threading
open System.Threading.Tasks
open ModConductor.ArtifactLibrary
open ModConductor.Enb
open ModConductor.HttpDownloads
open ModConductor.Nexus
open ModConductor.Persistence
open ModConductor.Protocol.V1

type internal EnbAcquisition
    (
        nexus: NexusSession,
        downloads: DownloadSession,
        store: OperationStore,
        handoff: IOAuthHandoff,
        row: EnbCompatibilityRow,
        persist: Guid -> Guid -> Guid option -> string option -> EnbView -> Task<EnbView>,
        view: EnbPhase -> string -> string -> EnbView
    ) =
    let fromStored = EnbPresentation.fromStored
    let defaultView () = EnbPresentation.defaultView row
    let sources = EnbSources(nexus, downloads, store, handoff, row, persist, view)
    let reference = sources.Reference
    let resolveSources = sources.Resolve
    let pendingFor = sources.PendingFor
    let classifyPending = sources.Classify
    let acquireNext = sources.AcquireNext

    let installReady workspace profile (runtime: Artifact) available token =
        task {
            let! _ =
                persist
                    workspace
                    profile
                    (Some runtime.Id)
                    runtime.Sha256
                    (view
                        EnbPhase.Installing
                        "Installing Lean ENB"
                        "Reviewing owned root, Data and configuration targets.")

            try
                let! _ = store.InstallEnb(workspace, profile, row, runtime, available, token)
                do! store.EnbSetups.RemovePending(profile, None)

                return!
                    persist
                        workspace
                        profile
                        (Some runtime.Id)
                        runtime.Sha256
                        (view
                            EnbPhase.Ready
                            "Lean ENB is ready"
                            "Play uses the selected profile generation and its preserved runtime settings.")
            with error ->
                let conflict =
                    error.Message.Contains("owns", StringComparison.OrdinalIgnoreCase)
                    || error.Message.Contains(
                        "already contains",
                        StringComparison.OrdinalIgnoreCase
                    )

                return!
                    persist
                        workspace
                        profile
                        (Some runtime.Id)
                        runtime.Sha256
                        (view
                            (if conflict then EnbPhase.Conflict else EnbPhase.Failed)
                            "Lean ENB setup failed"
                            error.Message)
        }

    let rec advance workspace profile (token: CancellationToken) =
        task {
            let! saved = store.EnbSetups.ReadStatus(workspace, profile)

            match saved |> Option.bind _.ArtifactId with
            | None -> return defaultView ()
            | Some runtimeId ->
                let! runtimeResult = store.Artifacts.Read(workspace, runtimeId)

                match runtimeResult with
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
                                "Choose the downloaded ENBSeries archive again.")
                | Ok runtime ->
                    let! pending = pendingFor profile

                    if pending.IsEmpty then
                        return!
                            persist
                                workspace
                                profile
                                (Some runtime.Id)
                                runtime.Sha256
                                (view
                                    EnbPhase.Failed
                                    "Lean ENB sources are unavailable"
                                    "Refresh the setup to resolve its approved Nexus files again.")
                    else
                        let! available, missing, active, stopped = classifyPending workspace pending

                        match stopped with
                        | Some(status, detail) ->
                            return!
                                persist
                                    workspace
                                    profile
                                    (Some runtime.Id)
                                    runtime.Sha256
                                    (view EnbPhase.Failed status detail)
                        | None when available.Length = pending.Length ->
                            return! installReady workspace profile runtime available token
                        | None when active ->
                            return!
                                persist
                                    workspace
                                    profile
                                    (Some runtime.Id)
                                    runtime.Sha256
                                    (view
                                        EnbPhase.Acquiring
                                        "Downloading Lean ENB components"
                                        "The active setup remains unchanged until every archive is verified.")
                        | None ->
                            return! acquireNext workspace profile runtime saved missing.Head token
        }

    let beginAcquisition workspace profile (runtime: Artifact) token =
        task {
            let! resolved = resolveSources ()

            match resolved with
            | Error problem ->
                return!
                    persist
                        workspace
                        profile
                        (Some runtime.Id)
                        runtime.Sha256
                        (view
                            EnbPhase.Unavailable
                            "Lean ENB source unavailable"
                            (EnbProblem.message problem))
            | Ok(account, sources) ->
                do! store.EnbSetups.RemovePending(profile, None)

                for pin, modId, file in sources do
                    let pending: StoredEnbPendingSource =
                        { WorkspaceId = workspace
                          ProfileId = profile
                          RuntimeArtifactId = runtime.Id
                          RuntimeSha256 = runtime.Sha256.Value
                          Kind =
                            if pin.Kind = EnbComponentKind.Preset then
                                "preset"
                            else
                                "companion:" + string modId
                          NexusModId = modId
                          File = file
                          AccountId = account.Subject
                          CheckedAt = DateTimeOffset.UtcNow }

                    do! store.EnbSetups.SavePending pending

                return! advance workspace profile token
        }

    member _.Reference account modId file keyed = reference account modId file keyed
    member _.PendingFor profile = pendingFor profile
    member _.Advance workspace profile token = advance workspace profile token

    member _.Begin workspace profile runtime token =
        beginAcquisition workspace profile runtime token
