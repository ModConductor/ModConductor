namespace ModConductor.Engine

open System
open System.Collections.Concurrent
open System.Threading
open System.Threading.Tasks
open ModConductor.ArtifactLibrary
open ModConductor.Fnis
open ModConductor.GameContexts
open ModConductor.HttpDownloads
open ModConductor.Nexus
open ModConductor.Persistence
open ModConductor.Protocol.V1

type FnisView =
    { Phase: FnisPhase
      Version: string
      Status: string
      Detail: string
      FileId: int64 option
      ArtifactId: Guid option }

type FnisCoordinator
    (nexus: NexusSession, downloads: DownloadSession, store: OperationStore, handoff: IOAuthHandoff)
    =
    let lifetime = new CancellationTokenSource()
    let workers = ConcurrentDictionary<Guid * Guid, CancellationTokenSource>()

    let phaseName =
        function
        | FnisPhase.Available -> "available"
        | FnisPhase.WaitingForNexus -> "waiting"
        | FnisPhase.Downloading -> "downloading"
        | FnisPhase.Installing -> "installing"
        | FnisPhase.Ready -> "ready"
        | FnisPhase.Failed -> "failed"
        | FnisPhase.UpdateAvailable -> "update"
        | FnisPhase.RecoveryRequired -> "recovery"
        | FnisPhase.SourceUnavailable -> "source-unavailable"
        | _ -> "unavailable"

    let phase =
        function
        | "available" -> FnisPhase.Available
        | "waiting" -> FnisPhase.WaitingForNexus
        | "downloading" -> FnisPhase.Downloading
        | "installing" -> FnisPhase.Installing
        | "ready" -> FnisPhase.Ready
        | "failed" -> FnisPhase.Failed
        | "update" -> FnisPhase.UpdateAvailable
        | "recovery" -> FnisPhase.RecoveryRequired
        | "source-unavailable" -> FnisPhase.SourceUnavailable
        | _ -> FnisPhase.Unavailable

    let fromStored (value: StoredFnisStatus) =
        { Phase = phase value.Phase
          Version = value.ComponentVersion
          Status = value.Status
          Detail = value.Detail
          FileId = value.NexusFileId
          ArtifactId = value.ArtifactId }

    let persist workspace profile value =
        task {
            do!
                store.FnisSetups.SaveStatus
                    { WorkspaceId = workspace
                      ProfileId = profile
                      Phase = phaseName value.Phase
                      ComponentVersion = value.Version
                      Status = value.Status
                      Detail = value.Detail
                      NexusFileId = value.FileId
                      ArtifactId = value.ArtifactId
                      CheckedAt = DateTimeOffset.UtcNow }

            return value
        }

    let unavailable workspace profile problem =
        persist
            workspace
            profile
            { Phase = FnisPhase.Unavailable
              Version = ""
              Status = "FNIS setup is unavailable"
              Detail = FnisProblem.message problem
              FileId = None
              ArtifactId = None }

    let failed workspace profile version file artifact status detail =
        persist
            workspace
            profile
            { Phase = FnisPhase.Failed
              Version = version
              Status = status
              Detail = detail
              FileId = file
              ArtifactId = artifact }

    let reference (selection: StoredFnisSelection) keyed =
        let release = selection.Selection.Release

        { Account = selection.AccountId
          Game = "skyrimspecialedition"
          ModId = release.ModId
          FileId = release.File.Id
          Keyed = keyed
          Version = Some release.File.Version }

    let resolve workspace profile =
        task {
            let! game = (store.GameContexts :> IGameContexts).Read(workspace, profile)

            match game with
            | Error _ -> return Error FnisProblem.GameUnavailable
            | Ok game ->
                match FnisCatalogue.eligibility game with
                | Error problem -> return Error problem
                | Ok() ->
                    let! source = nexus.ReadMod("skyrimspecialedition", FnisCatalogue.NexusModId)

                    return
                        source
                        |> Result.mapError (NexusProblem.message >> FnisProblem.SourceUnavailable)
                        |> Result.bind FnisCatalogue.release
                        |> Result.bind (fun release ->
                            FnisCatalogue.acquisition nexus.Status.Account
                            |> Result.map (fun acquisition ->
                                { ArtifactId = None
                                  WorkspaceId = workspace
                                  ProfileId = Some profile
                                  AccountId = nexus.Status.Account.Value.Subject
                                  Selection =
                                    { Release = release
                                      Acquisition = acquisition }
                                  CheckedAt = DateTimeOffset.UtcNow }))
        }

    let saveArtifact artifact selection =
        store.FnisSetups.SaveArtifactSelection(
            artifact,
            { selection with
                ArtifactId = Some artifact.Id }
        )

    let cached workspace profile =
        task {
            match nexus.Status.Account with
            | None -> return None
            | Some account ->
                let! value = store.FnisSetups.Cached(workspace, account.Subject)

                return
                    value
                    |> Option.map (fun selected ->
                        { selected with
                            ProfileId = Some profile })
        }

    let resume workspace (artifact: Artifact) =
        task {
            match artifact.State, artifact.Download with
            | ArtifactState.Incomplete, Some download when download.State = DownloadState.Paused ->
                let! resumed = downloads.Control(workspace, artifact.Id, DownloadAction.Resume)
                return resumed |> Result.defaultValue artifact
            | ArtifactState.Incomplete, Some download when download.State = DownloadState.Failed ->
                let! restarted = downloads.Control(workspace, artifact.Id, DownloadAction.Restart)
                return restarted |> Result.defaultValue artifact
            | _ -> return artifact
        }

    let monitor key (selection: StoredFnisSelection) (artifact: Artifact) =
        let local = CancellationTokenSource.CreateLinkedTokenSource(lifetime.Token)

        if workers.TryAdd(key, local) then
            (task {
                let release = selection.Selection.Release

                try
                    let waitForArtifact () =
                        Task.Run(fun () ->
                            let mutable current = artifact
                            let mutable waiting = true

                            while waiting do
                                local.Token.ThrowIfCancellationRequested()

                                match current.State, current.Download with
                                | (ArtifactState.Ready | ArtifactState.Installed), _ ->
                                    waiting <- false
                                | ArtifactState.Incomplete, Some download when
                                    download.State = DownloadState.Failed
                                    || download.State = DownloadState.Paused
                                    ->
                                    raise (
                                        IO.IOException(
                                            current.Problem
                                            |> Option.defaultValue "The FNIS download stopped."
                                        )
                                    )
                                | _ ->
                                    Task.Delay(100, local.Token).GetAwaiter().GetResult()

                                    current <-
                                        store.Artifacts
                                            .Read(fst key, current.Id)
                                            .GetAwaiter()
                                            .GetResult()
                                        |> Result.defaultWith (fun _ ->
                                            raise (
                                                IO.IOException "The FNIS archive is unavailable."
                                            ))

                            current)

                    let! current = waitForArtifact ()
                    do! saveArtifact current selection

                    let! _ =
                        persist
                            (fst key)
                            (snd key)
                            { Phase = FnisPhase.Installing
                              Version = string release.ComponentVersion
                              Status = "Installing FNIS"
                              Detail =
                                "The active profile stays unchanged until the new generation is ready."
                              FileId = Some release.File.Id
                              ArtifactId = Some current.Id }

                    let! _ = store.InstallFnis(fst key, snd key, release, current, local.Token)

                    let! _ =
                        persist
                            (fst key)
                            (snd key)
                            { Phase = FnisPhase.Ready
                              Version = string release.ComponentVersion
                              Status = "FNIS is ready"
                              Detail =
                                "The Windows generator is registered for this profile. Running it is a separate step."
                              FileId = Some release.File.Id
                              ArtifactId = Some current.Id }

                    ()
                with
                | :? OperationCanceledException when local.IsCancellationRequested -> ()
                | error ->
                    let pending = store.Deployments.Read(snd key).GetAwaiter().GetResult()

                    let recovery =
                        match pending with
                        | Ok state when state.PendingReceipt.IsSome -> true
                        | _ -> false

                    persist
                        (fst key)
                        (snd key)
                        { Phase =
                            if recovery then
                                FnisPhase.RecoveryRequired
                            else
                                FnisPhase.Failed
                          Version = string release.ComponentVersion
                          Status =
                            if recovery then
                                "FNIS setup needs recovery"
                            else
                                "FNIS setup failed"
                          Detail = error.Message
                          FileId = Some release.File.Id
                          ArtifactId = Some artifact.Id }
                    |> fun pending -> pending.GetAwaiter().GetResult() |> ignore

                let mutable removed = Unchecked.defaultof<CancellationTokenSource>
                workers.TryRemove(key, &removed) |> ignore
                local.Dispose()
            }
            :> Task)
            |> ignore
        else
            local.Dispose()

    let prepareArtifact key selection artifact label =
        task {
            let! artifact = resume (fst key) artifact
            do! saveArtifact artifact selection

            let! view =
                persist
                    (fst key)
                    (snd key)
                    { Phase = FnisPhase.Downloading
                      Version = string selection.Selection.Release.ComponentVersion
                      Status = label
                      Detail = "The archive and installation state are durable across restart."
                      FileId = Some selection.Selection.Release.File.Id
                      ArtifactId = Some artifact.Id }

            monitor key selection artifact
            return view
        }

    let installedState workspace profile (installed: StoredFnisGenerator) =
        task {
            let! resolved = resolve workspace profile

            match resolved with
            | Error problem ->
                return!
                    persist
                        workspace
                        profile
                        { Phase = FnisPhase.SourceUnavailable
                          Version = installed.ComponentVersion
                          Status = "FNIS is installed; update check unavailable"
                          Detail =
                            FnisProblem.message problem + " The active setup was not changed."
                          FileId = Some installed.NexusFileId
                          ArtifactId = None }
            | Ok selection when
                selection.Selection.Release.File.Id <> installed.NexusFileId
                || string selection.Selection.Release.ComponentVersion
                   <> installed.ComponentVersion
                ->
                return!
                    persist
                        workspace
                        profile
                        { Phase = FnisPhase.UpdateAvailable
                          Version = string selection.Selection.Release.ComponentVersion
                          Status = "FNIS update available"
                          Detail =
                            "The installed version remains active until you choose Update FNIS."
                          FileId = Some selection.Selection.Release.File.Id
                          ArtifactId = None }
            | Ok _ ->
                return!
                    persist
                        workspace
                        profile
                        { Phase = FnisPhase.Ready
                          Version = installed.ComponentVersion
                          Status = "FNIS is ready"
                          Detail =
                            "The Windows generator is registered for this profile. Running it is a separate step."
                          FileId = Some installed.NexusFileId
                          ArtifactId = None }
        }

    member this.Read(workspace, profile) =
        if not FnisCatalogue.TermsApproved then
            unavailable
                workspace
                profile
                (FnisProblem.SourceUnavailable "FNIS acquisition is disabled pending terms review.")
        else
            task {
                let key = workspace, profile
                let! game = (store.GameContexts :> IGameContexts).Read(workspace, profile)
                let! deployment = store.Deployments.Read profile

                match game, deployment with
                | Ok game, Ok deployment when
                    Result.isOk (FnisCatalogue.eligibility game)
                    && deployment.WorkspaceId = workspace
                    ->
                    if deployment.PendingReceipt.IsSome && not (workers.ContainsKey key) then
                        return!
                            persist
                                workspace
                                profile
                                { Phase = FnisPhase.RecoveryRequired
                                  Version = FnisCatalogue.SupportedVersion
                                  Status = "FNIS setup needs recovery"
                                  Detail = "Finish recovery before changing this setup."
                                  FileId = None
                                  ArtifactId = None }
                    else
                        let! saved = store.FnisSetups.ReadStatus(workspace, profile)

                        match saved with
                        | Some value when value.Phase = "waiting" || value.Phase = "failed" ->
                            return fromStored value
                        | Some value when
                            (value.Phase = "downloading" || value.Phase = "installing")
                            && value.ArtifactId.IsSome
                            ->
                            let! selection =
                                store.FnisSetups.SelectionForArtifact(
                                    workspace,
                                    value.ArtifactId.Value,
                                    profile
                                )

                            let! artifact = store.Artifacts.Read(workspace, value.ArtifactId.Value)

                            match selection, artifact with
                            | Some selection, Ok artifact ->
                                return! prepareArtifact key selection artifact "Resuming FNIS"
                            | _ ->
                                return!
                                    failed
                                        workspace
                                        profile
                                        value.ComponentVersion
                                        value.NexusFileId
                                        value.ArtifactId
                                        "FNIS setup could not resume"
                                        "The durable FNIS artifact is unavailable. The active setup was not changed."
                        | _ ->
                            let! installed =
                                store.FnisSetups.ReadStored(
                                    workspace,
                                    profile,
                                    deployment.ActiveGeneration
                                )

                            match installed with
                            | Some installed -> return! installedState workspace profile installed
                            | None ->
                                let! selected = resolve workspace profile

                                match selected with
                                | Ok selection ->
                                    let! existing =
                                        downloads.FindNexus(workspace, reference selection false)

                                    match existing with
                                    | Some artifact ->
                                        return!
                                            prepareArtifact key selection artifact "Preparing FNIS"
                                    | None ->
                                        return!
                                            persist
                                                workspace
                                                profile
                                                { Phase = FnisPhase.Available
                                                  Version =
                                                    string
                                                        selection.Selection.Release.ComponentVersion
                                                  Status = "FNIS Behavior SE 7.6 is available"
                                                  Detail =
                                                    if
                                                        selection.Selection.Acquisition = FnisAcquisition.Direct
                                                    then
                                                        "Download and installation can finish in Mod Conductor."
                                                    else
                                                        "Nexus Mods requires Mod Manager Download before installation can continue."
                                                  FileId = Some selection.Selection.Release.File.Id
                                                  ArtifactId = None }
                                | Error problem ->
                                    let! cached = cached workspace profile

                                    match cached with
                                    | Some cachedSelection ->
                                        let! artifact =
                                            store.Artifacts.Read(
                                                workspace,
                                                cachedSelection.ArtifactId.Value
                                            )

                                        match artifact with
                                        | Ok artifact ->
                                            return!
                                                prepareArtifact
                                                    key
                                                    cachedSelection
                                                    artifact
                                                    "Installing cached FNIS"
                                        | Error _ -> return! unavailable workspace profile problem
                                    | None -> return! unavailable workspace profile problem
                | _ -> return! unavailable workspace profile FnisProblem.GameUnavailable
            }

    member _.Install(workspace, profile) =
        task {
            let key = workspace, profile
            let! selected = resolve workspace profile

            match selected with
            | Error problem ->
                let! cached = cached workspace profile

                match cached with
                | Some selection ->
                    let! artifact = store.Artifacts.Read(workspace, selection.ArtifactId.Value)

                    match artifact with
                    | Ok artifact ->
                        return! prepareArtifact key selection artifact "Installing cached FNIS"
                    | Error _ -> return! unavailable workspace profile problem
                | None -> return! unavailable workspace profile problem
            | Ok selection ->
                let release = selection.Selection.Release
                let! existing = downloads.FindNexus(workspace, reference selection false)

                match existing with
                | Some artifact -> return! prepareArtifact key selection artifact "Preparing FNIS"
                | None when selection.Selection.Acquisition = FnisAcquisition.NexusPage ->
                    try
                        do!
                            handoff.Open(
                                Uri(
                                    FnisCatalogue.Source
                                    + "?tab=files&file_id="
                                    + string release.File.Id
                                ),
                                lifetime.Token
                            )

                        do! store.FnisSetups.SavePending selection

                        return!
                            persist
                                workspace
                                profile
                                { Phase = FnisPhase.WaitingForNexus
                                  Version = string release.ComponentVersion
                                  Status = "Waiting for Nexus Mods"
                                  Detail = "Select Mod Manager Download for FNIS Behavior SE 7.6."
                                  FileId = Some release.File.Id
                                  ArtifactId = None }
                    with error ->
                        return!
                            failed
                                workspace
                                profile
                                (string release.ComponentVersion)
                                (Some release.File.Id)
                                None
                                "Nexus Mods could not be opened"
                                error.Message
                | None ->
                    let! lease =
                        nexus.Resolve(
                            "skyrimspecialedition",
                            release.ModId,
                            release.File.Id,
                            selection.AccountId
                        )

                    match lease with
                    | Error problem ->
                        return!
                            failed
                                workspace
                                profile
                                (string release.ComponentVersion)
                                (Some release.File.Id)
                                None
                                "FNIS source unavailable"
                                (NexusProblem.message problem)
                    | Ok _ ->
                        let! started =
                            downloads.Start
                                { Id = Guid.NewGuid()
                                  WorkspaceId = workspace
                                  Name = release.File.Name
                                  Sources = [ DownloadSource.Nexus(reference selection false) ]
                                  ExpectedLength = release.File.Bytes
                                  ExpectedSha256 = None }

                        match started with
                        | Error problem ->
                            return!
                                failed
                                    workspace
                                    profile
                                    (string release.ComponentVersion)
                                    (Some release.File.Id)
                                    None
                                    "FNIS download could not start"
                                    (string problem)
                        | Ok artifact ->
                            return! prepareArtifact key selection artifact "Downloading FNIS"
        }

    member this.Cancel(workspace, profile) =
        task {
            let key = workspace, profile

            match workers.TryGetValue key with
            | true, cancellation -> cancellation.Cancel()
            | _ -> ()

            let deadline = DateTime.UtcNow.AddSeconds 5.

            while workers.ContainsKey key && DateTime.UtcNow < deadline do
                do! Task.Delay 10

            let! saved = store.FnisSetups.ReadStatus(workspace, profile)

            match saved |> Option.bind _.ArtifactId with
            | Some artifact ->
                let! _ = downloads.Control(workspace, artifact, DownloadAction.Pause)
                ()
            | None -> ()

            do! store.FnisSetups.RemovePending profile
            let! deployed = store.Deployments.Read profile

            match deployed with
            | Ok deployed ->
                let! installed =
                    store.FnisSetups.ReadStored(workspace, profile, deployed.ActiveGeneration)

                match installed with
                | Some installed -> return! installedState workspace profile installed
                | None ->
                    return!
                        persist
                            workspace
                            profile
                            { Phase = FnisPhase.Available
                              Version = FnisCatalogue.SupportedVersion
                              Status = "FNIS setup was cancelled"
                              Detail = "No active profile generation was changed."
                              FileId = None
                              ArtifactId = None }
            | Error _ -> return! this.Read(workspace, profile)
        }

    member this.Update(workspace, profile) = this.Install(workspace, profile)

    member this.Remove(workspace, profile, token) =
        task {
            try
                let! _ = store.RemoveFnis(workspace, profile, token)
                do! store.FnisSetups.RemovePending profile

                return!
                    persist
                        workspace
                        profile
                        { Phase = FnisPhase.Available
                          Version = FnisCatalogue.SupportedVersion
                          Status = "FNIS was removed"
                          Detail =
                            "Foreign game files and retained component versions were preserved."
                          FileId = None
                          ArtifactId = None }
            with error ->
                let! state = store.Deployments.Read profile

                let recovery =
                    match state with
                    | Ok value -> value.PendingReceipt.IsSome
                    | Error _ -> false

                return!
                    persist
                        workspace
                        profile
                        { Phase =
                            if recovery then
                                FnisPhase.RecoveryRequired
                            else
                                FnisPhase.Failed
                          Version = FnisCatalogue.SupportedVersion
                          Status =
                            if recovery then
                                "FNIS removal needs recovery"
                            else
                                "FNIS removal failed"
                          Detail = error.Message
                          FileId = None
                          ArtifactId = None }
        }

    member this.Recover(workspace, profile, token) =
        task {
            let key = workspace, profile

            while workers.ContainsKey key do
                do! Task.Delay(10, token)

            let! state = store.Deployments.Read profile

            match state with
            | Ok state when state.WorkspaceId = workspace && state.PendingReceipt.IsSome ->
                let! receipt = store.Deployments.Receipt(state.PendingReceipt.Value)

                match receipt with
                | Ok receipt ->
                    let! recovered =
                        store.Deployments.Recover(receipt.Id, receipt.Revision, true, ignore, token)

                    match recovered with
                    | Ok _ ->
                        let! deployed = store.Deployments.Read profile

                        match deployed with
                        | Ok deployed ->
                            let! installed =
                                store.FnisSetups.ReadStored(
                                    workspace,
                                    profile,
                                    deployed.ActiveGeneration
                                )

                            match installed with
                            | Some installed -> return! installedState workspace profile installed
                            | None ->
                                return!
                                    persist
                                        workspace
                                        profile
                                        { Phase = FnisPhase.Available
                                          Version = FnisCatalogue.SupportedVersion
                                          Status = "The previous FNIS setup was restored"
                                          Detail = "No active FNIS generator is registered."
                                          FileId = None
                                          ArtifactId = None }
                        | Error _ -> return! this.Read(workspace, profile)
                    | Error problem ->
                        return!
                            failed
                                workspace
                                profile
                                FnisCatalogue.SupportedVersion
                                None
                                None
                                "FNIS recovery failed"
                                (string problem)
                | Error problem ->
                    return!
                        failed
                            workspace
                            profile
                            FnisCatalogue.SupportedVersion
                            None
                            None
                            "FNIS recovery is unavailable"
                            (string problem)
            | _ -> return! this.Read(workspace, profile)
        }

    member _.AcceptNxm(id: Guid) =
        Task.Run(fun () ->
            task {
                let! pending = store.FnisSetups.Pending()

                let failPending title detail values =
                    task {
                        for selection: StoredFnisSelection in values do
                            let! _ =
                                failed
                                    selection.WorkspaceId
                                    selection.ProfileId.Value
                                    (string selection.Selection.Release.ComponentVersion)
                                    (Some selection.Selection.Release.File.Id)
                                    None
                                    title
                                    detail

                            do! store.FnisSetups.RemovePending selection.ProfileId.Value
                    }

                match nexus.ReadNxm id with
                | Error problem -> do! failPending problem.Title problem.Detail pending
                | Ok file ->
                    let expected =
                        pending
                        |> List.filter (fun selection ->
                            file.Game = "skyrimspecialedition"
                            && file.ModId = selection.Selection.Release.ModId
                            && file.FileId = selection.Selection.Release.File.Id)

                    match expected, nexus.Status.Account with
                    | [], _ ->
                        do!
                            failPending
                                "This Nexus link is not the expected FNIS file"
                                "Use Mod Manager Download for FNIS Behavior SE 7.6."
                                pending
                    | _, None ->
                        do!
                            failPending
                                "Sign in to Nexus Mods"
                                "Use the Nexus account that started this FNIS setup."
                                expected
                    | _, Some account ->
                        let matches =
                            expected
                            |> List.filter (fun value -> value.AccountId = account.Subject)

                        match matches with
                        | [] ->
                            do!
                                failPending
                                    "Nexus account changed"
                                    "Use the Nexus account that started this FNIS setup."
                                    expected
                        | selection :: _ ->
                            match nexus.AdmitNxm(id, account.Subject) with
                            | Error problem -> do! failPending problem.Title problem.Detail matches
                            | Ok admitted ->
                                use admitted = admitted
                                let! metadata = nexus.ReadFile(file.Game, file.ModId, file.FileId)

                                match metadata with
                                | Error problem ->
                                    do!
                                        failPending
                                            "FNIS file details are unavailable"
                                            (NexusProblem.message problem)
                                            matches
                                | Ok metadata ->
                                    let selection =
                                        { selection with
                                            Selection =
                                                { selection.Selection with
                                                    Release =
                                                        { selection.Selection.Release with
                                                            File = metadata } }
                                            CheckedAt = DateTimeOffset.UtcNow }

                                    let! started =
                                        downloads.Start
                                            { Id = Guid.NewGuid()
                                              WorkspaceId = selection.WorkspaceId
                                              Name = metadata.Name
                                              Sources =
                                                [ DownloadSource.Nexus(
                                                      reference selection file.Keyed
                                                  ) ]
                                              ExpectedLength = metadata.Bytes
                                              ExpectedSha256 = None }

                                    match started with
                                    | Error problem ->
                                        do!
                                            failPending
                                                "FNIS download could not start"
                                                (string problem)
                                                matches
                                    | Ok artifact ->
                                        admitted.Complete()

                                        do!
                                            store.FnisSetups.RemovePending
                                                selection.ProfileId.Value

                                        let! _ =
                                            prepareArtifact
                                                (selection.WorkspaceId, selection.ProfileId.Value)
                                                selection
                                                artifact
                                                "Downloading FNIS"

                                        ()
            }
            :> Task)
        |> ignore

    interface IDisposable with
        member _.Dispose() =
            lifetime.Cancel()

            for worker in workers.Values do
                try
                    worker.Cancel()
                with :? ObjectDisposedException ->
                    ()

            lifetime.Dispose()

type internal FnisService(coordinator: FnisCoordinator, execution: IFnisExecution) =
    inherit FnisOperations.FnisOperationsBase()

    let ids (request: FnisRequest) =
        ModLibraryWire.id request.WorkspaceId, ModLibraryWire.id request.ProfileId

    let outputPhase (value: ModConductor.Fnis.FnisOutputPhase) : ModConductor.Protocol.V1.FnisOutputPhase =
        match value with
        | ModConductor.Fnis.FnisOutputPhase.Unavailable -> ModConductor.Protocol.V1.FnisOutputPhase.Unavailable
        | ModConductor.Fnis.FnisOutputPhase.Missing -> ModConductor.Protocol.V1.FnisOutputPhase.Missing
        | ModConductor.Fnis.FnisOutputPhase.Stale -> ModConductor.Protocol.V1.FnisOutputPhase.Stale
        | ModConductor.Fnis.FnisOutputPhase.Current -> ModConductor.Protocol.V1.FnisOutputPhase.Current
        | ModConductor.Fnis.FnisOutputPhase.Running -> ModConductor.Protocol.V1.FnisOutputPhase.Running
        | ModConductor.Fnis.FnisOutputPhase.Failed -> ModConductor.Protocol.V1.FnisOutputPhase.Failed
        | ModConductor.Fnis.FnisOutputPhase.Cancelled -> ModConductor.Protocol.V1.FnisOutputPhase.Cancelled
        | ModConductor.Fnis.FnisOutputPhase.Abandoned -> ModConductor.Protocol.V1.FnisOutputPhase.Abandoned

    let wire value output =
        let reply =
            FnisState(
                Phase = value.Phase,
                Version = value.Version,
                Status = value.Status,
                Detail = value.Detail,
                CanInstall = (value.Phase = FnisPhase.Available || value.Phase = FnisPhase.Failed),
                CanCancel =
                    (value.Phase = FnisPhase.WaitingForNexus
                     || value.Phase = FnisPhase.Downloading
                     || value.Phase = FnisPhase.Installing),
                CanUpdate =
                    (value.Phase = FnisPhase.UpdateAvailable || value.Phase = FnisPhase.Ready),
                CanRemove =
                    (value.Phase = FnisPhase.Ready
                     || value.Phase = FnisPhase.UpdateAvailable
                     || value.Phase = FnisPhase.SourceUnavailable),
                CanRecover = (value.Phase = FnisPhase.RecoveryRequired)
            )

        value.FileId |> Option.iter (fun id -> reply.NexusFileId <- id)

        output
        |> Option.iter (fun (value: FnisInspection) ->
            reply.OutputPhase <- outputPhase value.Phase
            reply.OutputStatus <- value.Status
            reply.OutputDetail <- value.Detail
            reply.CanRun <- value.Phase <> ModConductor.Fnis.FnisOutputPhase.Running
            reply.CanCancelRun <- value.Phase = ModConductor.Fnis.FnisOutputPhase.Running
            value.LatestRunId |> Option.iter (fun id -> reply.RunId <- id.ToString("N"))
            value.ExitCode |> Option.iter (fun code -> reply.ExitCode <- code)
            reply.StandardOutput <- value.StandardOutput
            reply.StandardError <- value.StandardError
            reply.RunLog <- value.RunLog)

        reply

    let read workspace profile token =
        task {
            let! value = coordinator.Read(workspace, profile)

            let! output =
                if
                    value.Phase = FnisPhase.Ready
                    || value.Phase = FnisPhase.UpdateAvailable
                    || value.Phase = FnisPhase.SourceUnavailable
                then
                    task {
                        let! result = execution.Inspect(workspace, profile, token)
                        return Result.toOption result
                    }
                else
                    Task.FromResult None

            return wire value output
        }

    override _.ReadFnis(request, context) =
        let workspace, profile = ids request
        read workspace profile context.CancellationToken

    override _.InstallFnis(request, _) =
        task {
            let workspace, profile = ids request
            let! value = coordinator.Install(workspace, profile)
            return wire value None
        }

    override _.CancelFnis(request, _) =
        task {
            let workspace, profile = ids request
            let! value = coordinator.Cancel(workspace, profile)
            return wire value None
        }

    override _.UpdateFnis(request, _) =
        task {
            let workspace, profile = ids request
            let! value = coordinator.Update(workspace, profile)
            return wire value None
        }

    override _.RemoveFnis(request, context) =
        task {
            let workspace, profile = ids request
            let! value = coordinator.Remove(workspace, profile, context.CancellationToken)
            return wire value None
        }

    override _.RecoverFnis(request, context) =
        task {
            let workspace, profile = ids request
            let! value = coordinator.Recover(workspace, profile, context.CancellationToken)
            return wire value None
        }

    override _.RunFnis(request, context) =
        task {
            let workspace = ModLibraryWire.id request.WorkspaceId
            let profile = ModLibraryWire.id request.ProfileId

            let! output =
                execution.Run(
                    { Id = ModLibraryWire.id request.Id
                      WorkspaceId = workspace
                      ProfileId = profile },
                    context.CancellationToken
                )

            let! setup = coordinator.Read(workspace, profile)
            return wire setup (Result.toOption output)
        }

    override _.CancelFnisRun(request, _) =
        task {
            let workspace, profile = ids request
            let! output = execution.Cancel(workspace, profile)
            let! setup = coordinator.Read(workspace, profile)
            return wire setup (Result.toOption output)
        }
