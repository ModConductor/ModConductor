namespace ModConductor.Persistence

open System
open System.Threading
open System.Threading.Tasks

type internal EnbPrepareComponents =
    Guid *
    ModConductor.FilePlanning.SourceStamp *
    ModConductor.DeploymentPlanning.ReviewedComponent list *
    (ModConductor.Deployment.DeploymentProgress -> unit) *
    CancellationToken *
    ModConductor.DeploymentRecovery.SavedProfile option
        -> Task<
            Result<
                ModConductor.Deployment.PreparedState,
                ModConductor.DeploymentRecovery.RecoveryError
             >
         >

type internal EnbPreparation
    (
        database: StateDatabase,
        gameContexts: GameContextStore,
        deploymentRepository: DeploymentBackendRepository,
        enbSetups: EnbStore,
        profileGameData: ModConductor.ProfileGameData.ProfileGameDataSession
    ) =
    member internal _.PrepareTarget(workspace, profile, token) =
        task {
            let! contextResult =
                (gameContexts :> ModConductor.GameContexts.IGameContexts).Read(workspace, profile)

            match contextResult |> Result.toOption |> Option.bind _.Binding with
            | None -> return Error "The checked Skyrim installation is unavailable."
            | Some binding ->
                let evidence = binding.Evidence

                match ModConductor.GameContexts.ComponentRoots.gameRootId workspace evidence with
                | Error detail -> return Error detail
                | Ok gameRoot ->
                    let! read =
                        (deploymentRepository :> ModConductor.Deployment.IDeploymentRepository).Read
                            profile

                    match read with
                    | Error error -> return Error(DeploymentPreparation.refusalMessage error)
                    | Ok(sources, existing) ->
                        if sources.Stamp.WorkspaceId <> workspace then
                            return Error "The profile deployment is unavailable."
                        else
                            let active = existing |> Option.bind _.Active
                            let! owner = enbSetups.Owner(workspace, active)

                            if owner |> Option.exists ((<>) profile) then
                                return
                                    Error
                                        "Another profile owns the active renderer targets. Remove its ENB setup first."
                            else
                                let! priorComponents =
                                    enbSetups.Components(workspace, profile, active)

                                let conflict =
                                    if priorComponents.IsEmpty then
                                        [ "d3d11.dll"
                                          "d3dcompiler_46e.dll"
                                          "dxgi.dll"
                                          IO.Path.Combine(
                                              "Data",
                                              "SKSE",
                                              "Plugins",
                                              "CommunityShaders.dll"
                                          ) ]
                                        |> List.tryFind (fun name ->
                                            IO.File.Exists(
                                                IO.Path.Combine(evidence.RootPath, name)
                                            ))
                                    else
                                        None

                                match conflict with
                                | Some name ->
                                    return
                                        Error(
                                            ModConductor.Enb.EnbProblem.message (
                                                ModConductor.Enb.EnbProblem.ForeignDllConflict name
                                            )
                                        )
                                | None ->
                                    let profiles =
                                        profileGameData
                                        :> ModConductor.ProfileGameData.IProfileGameData

                                    let! profileState = profiles.Read(workspace, profile)

                                    match profileState with
                                    | Error problem -> return Error(EnbProfile.error problem)
                                    | Ok profileState ->
                                        if
                                            profileState.Options.Settings
                                            && profileState.SettingsInitialized
                                        then
                                            return Ok(gameRoot, evidence, active, priorComponents)
                                        else
                                            let! initialized =
                                                profiles.Edit(
                                                    { Id = Guid.NewGuid()
                                                      Expected = profileState.Reference
                                                      Options =
                                                        { profileState.Options with
                                                            Settings = true }
                                                      InitialSaves =
                                                        ModConductor.ProfileGameData.InitialSaves.Empty
                                                      DisabledFiles =
                                                        ModConductor.ProfileGameData.DisabledFiles.Keep },
                                                    ignore,
                                                    token
                                                )

                                            match initialized with
                                            | Error problem ->
                                                return Error(EnbProfile.error problem)
                                            | Ok initialized when not initialized.Complete ->
                                                return
                                                    Error(
                                                        initialized.Problem
                                                        |> Option.defaultValue
                                                            "The profile settings could not be initialized."
                                                    )
                                            | Ok _ ->
                                                return
                                                    Ok(gameRoot, evidence, active, priorComponents)
        }

    member internal _.PrepareSelection
        (
            workspace,
            profile,
            active,
            records: StoredEnbComponent list,
            priorComponents: StoredEnbComponent list
        ) =
        task {
            let! read =
                (deploymentRepository :> ModConductor.Deployment.IDeploymentRepository)
                    .Read(profile)

            match read with
            | Error error -> return Error(DeploymentPreparation.refusalMessage error)
            | Ok(sources, existing) ->
                if
                    sources.Stamp.WorkspaceId <> workspace
                    || (existing |> Option.bind _.Active) <> active
                then
                    return
                        Error "The profile deployment changed while ENB components were installed."
                else
                    let previousIds = priorComponents |> List.map _.ModId |> Set.ofList
                    let nextIds = records |> List.map _.ModId |> Set.ofList

                    let desired =
                        ((previousIds - nextIds) |> Set.toList |> List.map (fun id -> id, false))
                        @ (nextIds |> Set.toList |> List.map (fun id -> id, true))

                    let stagedMods =
                        sources.Profile.Mods
                        |> List.map (fun selected ->
                            match desired |> List.tryFind (fst >> (=) selected.ModId) with
                            | Some(_, enabled) -> { selected with Enabled = enabled }
                            | None -> selected)

                    if
                        nextIds
                        |> Set.forall (fun id ->
                            stagedMods |> List.exists (fun selected -> selected.ModId = id))
                        |> not
                    then
                        return Error "An installed ENB component is unavailable to this profile."
                    else
                        let! profileName =
                            database.Enqueue(fun () ->
                                use query =
                                    Sqlite.command
                                        database.Connection
                                        null
                                        "SELECT name FROM profiles WHERE id=$id"
                                        [ "$id", box (string profile) ]

                                match query.ExecuteScalar() with
                                | :? string as value -> Some value
                                | _ -> None)

                        match profileName with
                        | None -> return Error "The selected profile is unavailable."
                        | Some profileName ->
                            let retained: ModConductor.DeploymentRecovery.SavedProfile =
                                { Id = profile
                                  Name = profileName
                                  Revision = sources.Profile.Revision
                                  Mods =
                                    stagedMods
                                    |> List.map (fun selected ->
                                        { ModId = selected.ModId
                                          VersionId = selected.Version |> Option.map _.Id
                                          Priority = selected.Priority
                                          Enabled = selected.Enabled })
                                  Hidden = sources.Hidden }

                            return Ok(sources, desired, retained)
        }
