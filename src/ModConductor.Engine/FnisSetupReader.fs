namespace ModConductor.Engine

open System
open System.Threading.Tasks
open ModConductor.ArtifactLibrary
open ModConductor.Fnis
open ModConductor.GameContexts
open ModConductor.HttpDownloads
open ModConductor.Persistence
open ModConductor.Protocol.V1

type internal FnisSetupReader
    (
        store: OperationStore,
        downloads: DownloadSession,
        sources: FnisSources,
        persist: Guid -> Guid -> FnisView -> Task<FnisView>,
        unavailable: Guid -> Guid -> FnisProblem -> Task<FnisView>,
        failed:
            Guid
                -> Guid
                -> string
                -> int64 option
                -> Guid option
                -> string
                -> string
                -> Task<FnisView>,
        prepareArtifact:
            (Guid * Guid) -> StoredFnisSelection -> Artifact -> string -> Task<FnisView>,
        isActive: (Guid * Guid) -> bool
    ) =
    let installedState workspace profile (installed: StoredFnisGenerator) =
        task {
            let! resolved = sources.Resolve(workspace, profile)

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

    let cachedState workspace profile problem =
        task {
            let! cached = sources.Cached(workspace, profile)

            match cached with
            | None -> return! unavailable workspace profile problem
            | Some selection ->
                let! artifact = store.Artifacts.Read(workspace, selection.ArtifactId.Value)

                match artifact with
                | Ok artifact ->
                    return!
                        prepareArtifact
                            (workspace, profile)
                            selection
                            artifact
                            "Installing cached FNIS"
                | Error _ -> return! unavailable workspace profile problem
        }

    let selectedState workspace profile selection =
        task {
            let! existing = downloads.FindNexus(workspace, sources.Reference(selection, false))

            match existing with
            | Some artifact ->
                return! prepareArtifact (workspace, profile) selection artifact "Preparing FNIS"
            | None ->
                return!
                    persist
                        workspace
                        profile
                        { Phase = FnisPhase.Available
                          Version = string selection.Selection.Release.ComponentVersion
                          Status = "FNIS Behavior SE 7.6 is available"
                          Detail =
                            if selection.Selection.Acquisition = FnisAcquisition.Direct then
                                "Download and installation can finish in Mod Conductor."
                            else
                                "Nexus Mods requires Mod Manager Download before installation can continue."
                          FileId = Some selection.Selection.Release.File.Id
                          ArtifactId = None }
        }

    let availableState workspace profile =
        task {
            let! selected = sources.Resolve(workspace, profile)

            match selected with
            | Ok selection -> return! selectedState workspace profile selection
            | Error problem -> return! cachedState workspace profile problem
        }

    let savedArtifactState workspace profile (saved: StoredFnisStatus) =
        task {
            let artifactId = saved.ArtifactId.Value
            let! selection = store.FnisSetups.SelectionForArtifact(workspace, artifactId, profile)
            let! artifact = store.Artifacts.Read(workspace, artifactId)

            match selection, artifact with
            | Some selection, Ok artifact ->
                return! prepareArtifact (workspace, profile) selection artifact "Resuming FNIS"
            | _ ->
                return!
                    failed
                        workspace
                        profile
                        saved.ComponentVersion
                        saved.NexusFileId
                        saved.ArtifactId
                        "FNIS setup could not resume"
                        "The durable FNIS artifact is unavailable. The active setup was not changed."
        }

    let savedState workspace profile generation =
        task {
            let! saved = store.FnisSetups.ReadStatus(workspace, profile)

            match saved with
            | Some value when value.Phase = "waiting" || value.Phase = "failed" ->
                return FnisStatus.fromStored value
            | Some value when
                (value.Phase = "downloading" || value.Phase = "installing")
                && value.ArtifactId.IsSome
                ->
                return! savedArtifactState workspace profile value
            | _ ->
                let! installed = store.FnisSetups.ReadStored(workspace, profile, generation)

                match installed with
                | Some installed -> return! installedState workspace profile installed
                | None -> return! availableState workspace profile
        }

    member _.InstalledState(workspace, profile, installed) =
        installedState workspace profile installed

    member _.Read(workspace, profile) =
        if not FnisCatalogue.TermsApproved then
            unavailable
                workspace
                profile
                (FnisProblem.SourceUnavailable "FNIS acquisition is disabled pending terms review.")
        else
            task {
                let! game = (store.GameContexts :> IGameContexts).Read(workspace, profile)
                let! deployment = store.Deployments.Read profile

                match game, deployment with
                | Ok game, Ok deployment when
                    Result.isOk (FnisCatalogue.eligibility game)
                    && deployment.WorkspaceId = workspace
                    ->
                    if deployment.PendingReceipt.IsSome && not (isActive (workspace, profile)) then
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
                        return! savedState workspace profile deployment.ActiveGeneration
                | _ -> return! unavailable workspace profile FnisProblem.GameUnavailable
            }
