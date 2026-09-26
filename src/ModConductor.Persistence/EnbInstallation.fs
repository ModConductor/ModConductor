namespace ModConductor.Persistence

open System
open System.Threading
open System.Threading.Tasks

type internal EnbInstallation
    (
        preparation: EnbPreparation,
        componentInstaller: EnbComponentInstaller,
        publication: EnbInstallDeployment
    ) =
    member internal this.InstallEnb
        (
            workspace: Guid,
            profile: Guid,
            row: ModConductor.Enb.EnbCompatibilityRow,
            runtimeArtifact: ModConductor.ArtifactLibrary.Artifact,
            acquired:
                (ModConductor.Enb.EnbComponentPin *
                ModConductor.Nexus.NexusFile *
                ModConductor.ArtifactLibrary.Artifact) list,
            token: Threading.CancellationToken,
            ?runtimeOnly: bool
        ) =
        task {
            let runtimeOnly = defaultArg runtimeOnly false
            let! target = preparation.PrepareTarget(workspace, profile, token)

            match target with
            | Error detail -> return Error detail
            | Ok(gameRoot, evidence, active, priorComponents) ->
                let install pin fileId artifact =
                    componentInstaller.Install(workspace, gameRoot, pin, fileId, artifact, token)

                let! runtime = install row.Runtime None runtimeArtifact

                match runtime with
                | Error detail -> return Error detail
                | Ok runtime ->
                    let mutable installed = Ok [ runtime ]

                    for pin, file, artifact in acquired do
                        if Result.isOk installed then
                            let! value = install pin (Some file.Id) artifact

                            installed <-
                                match installed, value with
                                | Ok values, Ok value -> Ok(values @ [ value ])
                                | _, Error detail -> Error detail
                                | Error detail, _ -> Error detail

                    match installed with
                    | Error detail -> return Error detail
                    | Ok installed ->
                        let components = installed |> List.map fst

                        let records =
                            (installed |> List.map snd)
                            @ (if runtimeOnly then
                                   priorComponents
                                   |> List.filter (fun value -> value.Kind <> "runtime")
                               else
                                   [])

                        let! selection =
                            preparation.PrepareSelection(
                                workspace,
                                profile,
                                active,
                                records,
                                priorComponents
                            )

                        match selection with
                        | Error detail -> return Error detail
                        | Ok(sources, desired, retained) ->
                            return!
                                publication.Publish(
                                    workspace,
                                    profile,
                                    row,
                                    evidence,
                                    active,
                                    records,
                                    sources,
                                    desired,
                                    retained,
                                    components,
                                    token
                                )
        }
