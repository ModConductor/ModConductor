namespace ModConductor.Engine

open System
open System.Threading.Tasks
open ModConductor.ArtifactLibrary
open ModConductor.Enb
open ModConductor.HttpDownloads
open ModConductor.Nexus
open ModConductor.Persistence
open ModConductor.Protocol.V1

type internal EnbSources
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

    let classifyPending workspace (pending: StoredEnbPendingSource list) =
        task {
            let mutable available = []
            let mutable missing = []
            let mutable active = false
            let mutable stopped: (string * string) option = None

            for source in pending do
                let sourceReference = reference source.AccountId source.NexusModId source.File false
                let! artifact = downloads.FindNexus(workspace, sourceReference)

                match artifact with
                | Some artifact when
                    artifact.State = ArtifactState.Ready || artifact.State = ArtifactState.Installed
                    ->
                    let pin =
                        (row.Preset :: row.Companions)
                        |> List.find (fun pin -> pin.NexusModId = Some source.NexusModId)

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
                            artifact.Problem |> Option.defaultValue "Retry the Nexus download."
                        )
                | Some _ -> active <- true
                | None -> missing <- missing @ [ source ]

            return available, missing, active, stopped
        }

    let acquirePremium
        workspace
        profile
        (runtime: Artifact)
        (next: StoredEnbPendingSource)
        (account: Account)
        token
        =
        task {
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
                                  reference account.Subject next.NexusModId next.File false
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
        }

    let openNexusPage
        workspace
        profile
        (runtime: Artifact)
        (saved: StoredEnbStatus option)
        (next: StoredEnbPendingSource)
        token
        =
        task {
            match saved with
            | Some state when
                state.Status = "Waiting for Nexus Mods"
                && state.Detail.Contains(next.File.Name, StringComparison.Ordinal)
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
                                ("Select Mod Manager Download for " + next.File.Name + "."))
                with error ->
                    return!
                        persist
                            workspace
                            profile
                            (Some runtime.Id)
                            runtime.Sha256
                            (view EnbPhase.Failed "Nexus Mods could not be opened" error.Message)
        }

    let acquireNext
        workspace
        profile
        (runtime: Artifact)
        (saved: StoredEnbStatus option)
        (next: StoredEnbPendingSource)
        token
        =
        task {
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
                return! acquirePremium workspace profile runtime next account token
            | Some _ -> return! openNexusPage workspace profile runtime saved next token
        }

    member _.Reference account modId file keyed = reference account modId file keyed
    member _.Resolve() = resolveSources ()
    member _.PendingFor profile = pendingFor profile
    member _.Classify workspace pending = classifyPending workspace pending

    member _.AcquireNext workspace profile runtime saved next token =
        acquireNext workspace profile runtime saved next token
