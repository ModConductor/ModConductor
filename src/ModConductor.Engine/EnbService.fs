namespace ModConductor.Engine

open System
open System.Collections.Concurrent
open System.Threading
open System.Threading.Tasks
open ModConductor.ArtifactLibrary
open ModConductor.ArchiveInspection
open ModConductor.Deployment
open ModConductor.Enb
open ModConductor.GameContexts
open ModConductor.HttpDownloads
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
        nexus: NexusSession,
        downloads: DownloadSession,
        store: OperationStore,
        handoff: IOAuthHandoff,
        row: EnbCompatibilityRow,
        ?eligibilityOverride: Guid * Guid -> Task<Result<unit, EnbProblem>>
    ) as this =
    let lifetime = new CancellationTokenSource()
    let operations = ConcurrentDictionary<Guid * Guid, CancellationTokenSource>()
    let changed = Event<Guid * Guid>()

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

            changed.Trigger(workspace, profile)
            return value
        }

    let defaultView () =
        view
            EnbPhase.Available
            "Lean ENB is available"
            "Open the ENBSeries author page, download version 0.505, then choose the archive."

    let adoptionView () =
        view
            EnbPhase.Blocked
            "Lean ENB setup is not approved"
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
                let! context =
                    (store.GameContexts :> IGameContexts).Read(workspace, profile)
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

    let reference account modId (file: NexusFile) keyed =
        { Account = account
          Game = "skyrimspecialedition"
          ModId = modId
          FileId = file.Id
          Keyed = keyed
          Version = Some file.Version }

    let resolveSources () =
        task {
            match nexus.Status.Account with
            | None -> return Error EnbProblem.SignInRequired
            | Some account ->
                let mutable resolved = Ok []

                for pin in row.Preset :: row.Companions do
                    match resolved, pin.NexusModId with
                    | Error _, _ -> ()
                    | Ok _, None ->
                        resolved <-
                            Error(
                                EnbProblem.SourceUnavailable(
                                    pin.Name + " has no approved provider identity."
                                )
                            )
                    | Ok values, Some modId ->
                        let! source = nexus.ReadMod("skyrimspecialedition", modId)

                        resolved <-
                            source
                            |> Result.mapError (
                                NexusProblem.message >> EnbProblem.SourceUnavailable
                            )
                            |> Result.bind (EnbCatalogue.resolveNexusFile pin)
                            |> Result.map (fun file -> values @ [ pin, modId, file ])

                return resolved |> Result.map (fun values -> account, values)
        }

    let pendingFor profile =
        task {
            let! pending = store.EnbSetups.Pending()
            return pending |> List.filter (fun value -> value.ProfileId = profile)
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
                        let mutable available = []
                        let mutable missing = []
                        let mutable active = false
                        let mutable stopped: (string * string) option = None

                        for source in pending do
                            let r = reference source.AccountId source.NexusModId source.File false
                            let! artifact = downloads.FindNexus(workspace, r)

                            match artifact with
                            | Some artifact when
                                artifact.State = ArtifactState.Ready
                                || artifact.State = ArtifactState.Installed
                                ->
                                let pin =
                                    (row.Preset :: row.Companions)
                                    |> List.find (fun pin ->
                                        pin.NexusModId = Some source.NexusModId)

                                available <- available @ [ pin, source.File, artifact ]
                            | Some artifact when
                                artifact.Download
                                |> Option.exists (fun download ->
                                    download.State = DownloadState.Failed
                                    || download.State = DownloadState.Paused)
                                ->
                                stopped <-
                                    Some(
                                        source.File.Name + " download stopped",
                                        artifact.Problem
                                        |> Option.defaultValue "Retry the Nexus download."
                                    )
                            | Some _ -> active <- true
                            | None -> missing <- missing @ [ source ]

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
                                let! _ =
                                    store.InstallEnb(
                                        workspace,
                                        profile,
                                        row,
                                        runtime,
                                        available,
                                        token
                                    )

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
                                    error.Message.Contains(
                                        "owns",
                                        StringComparison.OrdinalIgnoreCase
                                    )
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
                            let next = missing.Head

                            match nexus.Status.Account with
                            | None ->
                                return!
                                    persist
                                        workspace
                                        profile
                                        (Some runtime.Id)
                                        runtime.Sha256
                                        (view
                                            EnbPhase.Unavailable
                                            "Nexus Mods is unavailable"
                                            (EnbProblem.message EnbProblem.SignInRequired))
                            | Some account when account.Subject <> next.AccountId ->
                                return!
                                    persist
                                        workspace
                                        profile
                                        (Some runtime.Id)
                                        runtime.Sha256
                                        (view
                                            EnbPhase.Unavailable
                                            "Nexus account changed"
                                            "Use the Nexus account that started this ENB setup.")
                            | Some account when account.Premium = Some true ->
                                let! lease =
                                    nexus.Resolve(
                                        "skyrimspecialedition",
                                        next.NexusModId,
                                        next.File.Id,
                                        account.Subject
                                    )

                                match lease with
                                | Error problem ->
                                    return!
                                        persist
                                            workspace
                                            profile
                                            (Some runtime.Id)
                                            runtime.Sha256
                                            (view
                                                EnbPhase.Unavailable
                                                "Nexus source unavailable"
                                                (NexusProblem.message problem))
                                | Ok _ ->
                                    let! started =
                                        downloads.Start
                                            { Id = Guid.NewGuid()
                                              WorkspaceId = workspace
                                              Name = next.File.Name
                                              Sources =
                                                [ DownloadSource.Nexus(
                                                      reference
                                                          account.Subject
                                                          next.NexusModId
                                                          next.File
                                                          false
                                                  ) ]
                                              ExpectedLength = next.File.Bytes
                                              ExpectedSha256 = None }

                                    match started with
                                    | Error problem ->
                                        return!
                                            persist
                                                workspace
                                                profile
                                                (Some runtime.Id)
                                                runtime.Sha256
                                                (view
                                                    EnbPhase.Failed
                                                    "The Nexus download could not start"
                                                    (string problem))
                                    | Ok _ ->
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
                            | Some _ ->
                                match saved with
                                | Some state when
                                    state.Status = "Waiting for Nexus Mods"
                                    && state.Detail.Contains(
                                        next.File.Name,
                                        StringComparison.Ordinal
                                    )
                                    ->
                                    return fromStored state
                                | _ ->
                                    try
                                        do!
                                            handoff.Open(
                                                Uri(
                                                    "https://www.nexusmods.com/skyrimspecialedition/mods/"
                                                    + string next.NexusModId
                                                    + "?tab=files&file_id="
                                                    + string next.File.Id
                                                ),
                                                token
                                            )

                                        return!
                                            persist
                                                workspace
                                                profile
                                                (Some runtime.Id)
                                                runtime.Sha256
                                                (view
                                                    EnbPhase.Acquiring
                                                    "Waiting for Nexus Mods"
                                                    ("Select Mod Manager Download for "
                                                     + next.File.Name
                                                     + "."))
                                    with error ->
                                        return!
                                            persist
                                                workspace
                                                profile
                                                (Some runtime.Id)
                                                runtime.Sha256
                                                (view
                                                    EnbPhase.Failed
                                                    "Nexus Mods could not be opened"
                                                    error.Message)
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

    let selectArchive (runtimeOnly: bool) (workspace, profile, operation, path: string, token) =
        if not row.TermsApproved then
            Task.FromResult(adoptionView ())
        else
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
                else
                    let fileName = IO.Path.GetFileName(path)

                    if
                        not (
                            fileName.Contains("0505", StringComparison.OrdinalIgnoreCase)
                            || fileName.Contains("0.505", StringComparison.OrdinalIgnoreCase)
                        )
                    then
                        return!
                            persist
                                workspace
                                profile
                                None
                                None
                                (view
                                    EnbPhase.Failed
                                    "The ENBSeries archive was refused"
                                    "Choose the official ENBSeries 0.505 Skyrim SE archive. No files were changed.")
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
                                | Ok _ when runtimeOnly ->
                                    let! _ =
                                        persist
                                            workspace
                                            profile
                                            (Some artifact.Id)
                                            artifact.Sha256
                                            { view EnbPhase.Installing "Installing ENBSeries" "" with PresetVersion = "" }

                                    try
                                        let! _ = store.InstallEnb(workspace, profile, row, artifact, [], token, runtimeOnly = true)

                                        return!
                                            persist
                                                workspace
                                                profile
                                                (Some artifact.Id)
                                                artifact.Sha256
                                                { view EnbPhase.Ready "ENBSeries is installed" "" with PresetVersion = "" }
                                    with error ->
                                        return!
                                            persist
                                                workspace
                                                profile
                                                (Some artifact.Id)
                                                artifact.Sha256
                                                { view EnbPhase.Failed "ENBSeries setup failed" error.Message with PresetVersion = "" }
                                | Ok _ ->
                                    let! _ =
                                        persist
                                            workspace
                                            profile
                                            (Some artifact.Id)
                                            artifact.Sha256
                                            (view
                                                EnbPhase.Acquiring
                                                "ENBSeries 0.505 was validated"
                                                "Resolving Lean ENB and its declared companion through Nexus Mods.")

                                    return! beginAcquisition workspace profile artifact token
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
                                        (view
                                            EnbPhase.Failed
                                            "The ENBSeries archive was refused"
                                            detail)
            }


    let runAdvance workspace profile =
        task {
            let key = workspace, profile
            let cancellation = CancellationTokenSource.CreateLinkedTokenSource(lifetime.Token)
            let! saved = store.EnbSetups.ReadStatus(workspace, profile)

            if operations.TryAdd(key, cancellation) then
                Task.Run(fun () ->
                    task {
                        try
                            try
                                let mutable acquiring = true

                                while acquiring do
                                    let! current = advance workspace profile cancellation.Token

                                    if current.Phase = EnbPhase.Acquiring then
                                        let! pending = pendingFor profile
                                        let! artifacts =
                                            pending
                                            |> List.map (fun source ->
                                                downloads.FindNexus(
                                                    workspace,
                                                    reference source.AccountId source.NexusModId source.File false
                                                ))
                                            |> Task.WhenAll

                                        let revisions =
                                            artifacts
                                            |> Array.choose (Option.map (fun artifact -> artifact.Id, artifact.Revision))
                                            |> Array.toList

                                        if revisions.IsEmpty then
                                            acquiring <- false
                                        else
                                            do! downloads.WaitForChange(workspace, revisions, cancellation.Token)
                                    else
                                        acquiring <- false
                            with :? OperationCanceledException when
                                cancellation.IsCancellationRequested ->
                                ()
                        finally
                            match operations.TryRemove key with
                            | true, owned -> owned.Dispose()
                            | _ -> ()
                            changed.Trigger key
                    }
                    :> Task)
                |> ignore
            else
                cancellation.Dispose()

            return saved |> Option.map fromStored |> Option.defaultWith defaultView
        }

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
                | Some _, Some value when operations.ContainsKey key -> return fromStored value
                | Some _, None when operations.ContainsKey key ->
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
        if not row.TermsApproved then
            Task.FromResult(adoptionView ())
        else
            task {
                let key = workspace, profile

                match operations.TryGetValue key with
                | true, cancellation -> cancellation.Cancel()
                | _ -> ()

                let deadline = DateTime.UtcNow.AddSeconds 10.

                while operations.ContainsKey key && DateTime.UtcNow < deadline do
                    do! Task.Delay 20

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
            task {
                let key = workspace, profile

                use cancellation =
                    CancellationTokenSource.CreateLinkedTokenSource(lifetime.Token, token)

                if operations.TryAdd(key, cancellation) then
                    try
                        return!
                            selectArchive false (workspace, profile, operation, path, cancellation.Token)
                    finally
                        match operations.TryRemove key with
                        | true, owned -> owned.Dispose()
                        | _ -> ()
                else
                    return! this.Read(workspace, profile)
            }

    member _.SelectRuntimeArchive(workspace, profile, operation, path: string, token) =
        if not row.TermsApproved then
            Task.FromResult(adoptionView ())
        else
            task {
                let key = workspace, profile
                use cancellation =
                    CancellationTokenSource.CreateLinkedTokenSource(lifetime.Token, token)

                if operations.TryAdd(key, cancellation) then
                    try
                        return!
                            selectArchive true (workspace, profile, operation, path, cancellation.Token)
                    finally
                        match operations.TryRemove key with
                        | true, owned -> owned.Dispose()
                        | _ -> ()
                else
                    return! this.Read(workspace, profile)
            }

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
                    | Ok value -> return! beginAcquisition workspace profile value lifetime.Token
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
                    let! _ = store.RemoveEnb(workspace, profile, token, runtimeOnly = defaultArg runtimeOnly false)
                    do! store.EnbSetups.RemovePending(profile, None)
                    return! persist workspace profile None None (defaultView ())
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
            task {
                let! operation = store.EnbSetups.ConfigurationOperation(workspace, profile)
                let! state = store.Deployments.Read profile

                let restoreConfiguration operation success =
                    task {
                        do!
                            store.EnbSetups.UpdateConfiguration(
                                operation.ReceiptId,
                                "restore_pending",
                                None,
                                operation.Detail
                            )

                        let! actionRecovered = store.RecoverEnbConfigurationAction(operation, token)

                        let! restored =
                            match actionRecovered with
                            | Ok() -> store.RestoreEnbConfiguration(operation, token)
                            | Error detail -> Task.FromResult(Error detail)

                        let outcome =
                            match restored with
                            | Ok() -> success
                            | Error detail ->
                                view EnbPhase.Conflict "Skyrim settings need attention" detail

                        let! saved = store.EnbSetups.ReadStatus(workspace, profile)

                        return!
                            persist
                                workspace
                                profile
                                (if operation.Kind = "remove" then
                                     None
                                 else
                                     saved |> Option.bind _.ArtifactId)
                                (if operation.Kind = "remove" then
                                     None
                                 else
                                     saved |> Option.bind _.ArchiveSha256)
                                outcome
                    }

                match state, operation with
                | Ok state, operation when
                    state.WorkspaceId = workspace && state.PendingReceipt.IsSome
                    ->
                    let! receipt = store.Deployments.Receipt(state.PendingReceipt.Value)

                    match receipt with
                    | Ok receipt ->
                        let! recovered =
                            store.Deployments.Recover(
                                receipt.Id,
                                receipt.Revision,
                                true,
                                ignore,
                                token
                            )

                        match recovered, operation with
                        | Error problem, _ ->
                            return
                                view
                                    EnbPhase.Failed
                                    "ENB recovery did not complete"
                                    (string problem)
                        | Ok _, Some operation when operation.Kind = "install" ->
                            return!
                                restoreConfiguration
                                    operation
                                    (view
                                        EnbPhase.Failed
                                        "The previous setup was restored"
                                        "Refresh ENB setup when you are ready to try again.")
                        | Ok _, Some operation ->
                            do! store.EnbSetups.RemoveConfiguration operation.ReceiptId
                            let! saved = store.EnbSetups.ReadStatus(workspace, profile)

                            return!
                                persist
                                    workspace
                                    profile
                                    (saved |> Option.bind _.ArtifactId)
                                    (saved |> Option.bind _.ArchiveSha256)
                                    (view
                                        EnbPhase.Ready
                                        "The previous ENB setup was restored"
                                        "Removal did not complete; the active setup and Skyrim settings are unchanged.")
                        | Ok _, None ->
                            return
                                view
                                    EnbPhase.Failed
                                    "The previous setup was restored"
                                    "Refresh ENB setup when you are ready to try again."
                    | Error problem ->
                        return view EnbPhase.Failed "ENB recovery is unavailable" (string problem)
                | _, Some operation ->
                    let! receipt = store.EnbConfigurationDeploymentState operation.ReceiptId

                    match operation.Kind, receipt with
                    | "install", Some "complete" ->
                        do! store.EnbSetups.RemoveConfiguration operation.ReceiptId
                        let! saved = store.EnbSetups.ReadStatus(workspace, profile)

                        return!
                            persist
                                workspace
                                profile
                                (saved |> Option.bind _.ArtifactId)
                                (saved |> Option.bind _.ArchiveSha256)
                                (view
                                    EnbPhase.Ready
                                    "Lean ENB is ready"
                                    "Play uses the selected profile generation and its preserved runtime settings.")
                    | "remove", Some "complete" ->
                        return!
                            restoreConfiguration
                                operation
                                (view
                                    EnbPhase.Available
                                    "Lean ENB was removed"
                                    "The previous Skyrim settings were restored.")
                    | "remove", _ ->
                        do! store.EnbSetups.RemoveConfiguration operation.ReceiptId
                        let! saved = store.EnbSetups.ReadStatus(workspace, profile)

                        return!
                            persist
                                workspace
                                profile
                                (saved |> Option.bind _.ArtifactId)
                                (saved |> Option.bind _.ArchiveSha256)
                                (view
                                    EnbPhase.Ready
                                    "The previous ENB setup was restored"
                                    "Removal did not complete; the active setup and Skyrim settings are unchanged.")
                    | _ ->
                        return!
                            restoreConfiguration
                                operation
                                (view
                                    EnbPhase.Failed
                                    "The previous setup was restored"
                                    "Refresh ENB setup when you are ready to try again.")
                | _ -> return! this.Read(workspace, profile)
            }

    member _.AcceptNxm(id: Guid) =
        if not row.TermsApproved then
            ()
        else
            Task.Run(fun () ->
                task {
                    let! pending = store.EnbSetups.Pending()

                    let failSources title detail (sources: StoredEnbPendingSource list) =
                        task {
                            for source in sources do
                                let! _ =
                                    persist
                                        source.WorkspaceId
                                        source.ProfileId
                                        (Some source.RuntimeArtifactId)
                                        (Some source.RuntimeSha256)
                                        (view EnbPhase.Failed title detail)

                                ()
                        }

                    match nexus.ReadNxm id, nexus.Status.Account with
                    | Ok file, Some account ->
                        let expected =
                            pending
                            |> List.filter (fun value ->
                                value.NexusModId = file.ModId && value.File.Id = file.FileId)

                        let matches =
                            expected
                            |> List.filter (fun value -> value.AccountId = account.Subject)

                        match matches, expected with
                        | source :: _, _ ->
                            match nexus.AdmitNxm(id, account.Subject) with
                            | Ok admitted ->
                                use admitted = admitted
                                let! metadata = nexus.ReadFile(file.Game, file.ModId, file.FileId)

                                match metadata with
                                | Ok metadata ->
                                    let! started =
                                        downloads.Start
                                            { Id = Guid.NewGuid()
                                              WorkspaceId = source.WorkspaceId
                                              Name = metadata.Name
                                              Sources =
                                                [ DownloadSource.Nexus(
                                                      reference
                                                          account.Subject
                                                          source.NexusModId
                                                          metadata
                                                          file.Keyed
                                                  ) ]
                                              ExpectedLength = metadata.Bytes
                                              ExpectedSha256 = None }

                                    if Result.isOk started then
                                        admitted.Complete()
                                    else
                                        do!
                                            failSources
                                                "The Nexus download could not start"
                                                "Retry Mod Manager Download for this Lean ENB component."
                                                [ source ]
                                | Error problem ->
                                    do!
                                        failSources
                                            "Nexus file details are unavailable"
                                            (NexusProblem.message problem)
                                            [ source ]
                            | Error problem ->
                                do!
                                    failSources
                                        "The Nexus download was refused"
                                        problem.Detail
                                        [ source ]
                        | [], _ :: _ ->
                            do!
                                failSources
                                    "Nexus account changed"
                                    "Use the Nexus account that started this ENB setup."
                                    expected
                        | [], [] -> ()
                    | Ok file, None ->
                        let expected =
                            pending
                            |> List.filter (fun value ->
                                value.NexusModId = file.ModId && value.File.Id = file.FileId)

                        do!
                            failSources
                                "Sign in to Nexus Mods"
                                "Use the Nexus account that started this ENB setup."
                                expected
                    | Error _, _ -> ()
                }
                :> Task)
            |> ignore

    interface IDisposable with
        member _.Dispose() =
            lifetime.Cancel()

            for cancellation in operations.Values do
                cancellation.Cancel()

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
                (value.Phase = EnbPhase.Available
                 || value.Phase = EnbPhase.WaitingForArchive
                 || value.Phase = EnbPhase.Failed),
            CanSelectArchive =
                (value.Phase = EnbPhase.WaitingForArchive || value.Phase = EnbPhase.Failed),
            CanCancel = (value.Phase = EnbPhase.WaitingForArchive),
            CanUpdate = (value.Phase = EnbPhase.Ready),
            CanRemove = (value.Phase = EnbPhase.Ready),
            CanRecover = (value.Phase = EnbPhase.Failed || value.Phase = EnbPhase.Conflict)
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

    override _.UpdateEnb(request, _) =
        task {
            let workspace, profile = ids request
            let! value = coordinator.Update(workspace, profile)
            return wire value
        }

    override _.RemoveEnb(request, context) =
        task {
            let workspace, profile = ids request
            let! value = coordinator.Remove(workspace, profile, context.CancellationToken)
            return wire value
        }

    override _.RecoverEnb(request, context) =
        task {
            let workspace, profile = ids request
            let! value = coordinator.Recover(workspace, profile, context.CancellationToken)
            return wire value
        }
