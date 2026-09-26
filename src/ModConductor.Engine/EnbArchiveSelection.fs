namespace ModConductor.Engine

open System
open System.Threading
open System.Threading.Tasks
open ModConductor.ArtifactLibrary
open ModConductor.ArchiveInspection
open ModConductor.Enb
open ModConductor.Persistence
open ModConductor.Protocol.V1

type internal EnbArchiveSelection
    (
        store: OperationStore,
        row: EnbCompatibilityRow,
        eligibility: Guid -> Guid -> Task<Result<unit, EnbProblem>>,
        persist: Guid -> Guid -> Guid option -> string option -> EnbView -> Task<EnbView>,
        view: EnbPhase -> string -> string -> EnbView,
        adoptionView: unit -> EnbView,
        beginAcquisition: Guid -> Guid -> Artifact -> CancellationToken -> Task<EnbView>
    ) =
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
                                            { view EnbPhase.Installing "Installing ENBSeries" "" with
                                                PresetVersion = "" }

                                    try
                                        let! installed =
                                            store.InstallEnb(
                                                workspace,
                                                profile,
                                                row,
                                                artifact,
                                                [],
                                                token,
                                                runtimeOnly = true
                                            )

                                        match installed with
                                        | Ok _ ->
                                            return!
                                                persist
                                                    workspace
                                                    profile
                                                    (Some artifact.Id)
                                                    artifact.Sha256
                                                    { view
                                                          EnbPhase.Ready
                                                          "ENBSeries is installed"
                                                          "" with
                                                        PresetVersion = "" }
                                        | Error detail ->
                                            return!
                                                persist
                                                    workspace
                                                    profile
                                                    (Some artifact.Id)
                                                    artifact.Sha256
                                                    { view
                                                          EnbPhase.Failed
                                                          "ENBSeries setup failed"
                                                          detail with
                                                        PresetVersion = "" }
                                    with error ->
                                        return!
                                            persist
                                                workspace
                                                profile
                                                (Some artifact.Id)
                                                artifact.Sha256
                                                { view
                                                      EnbPhase.Failed
                                                      "ENBSeries setup failed"
                                                      error.Message with
                                                    PresetVersion = "" }
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


    member _.Select runtimeOnly args = selectArchive runtimeOnly args
