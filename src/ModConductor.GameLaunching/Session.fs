namespace ModConductor.GameLaunching

open System
open ModConductor.GameContexts
open ModConductor.Deployment
open ModConductor.Executables
open ModConductor.ProfileGameData
open System.Security.Cryptography
open System.Text

type GameLaunchSession
    (
        contexts: IGameContexts,
        deployment: DeploymentBackend,
        executables: ExecutableSession,
        profiles: ProfileGameDataSession,
        loaders: IComponentLoaderSelection,
        ?configuration: IComponentLaunchConfigurationSelection
    ) =
    let runs = executables :> IExecutables
    let deployments = deployment :> IDeploymentBackend

    let launchConfiguration workspace profile generation =
        match configuration with
        | Some owner -> owner.Read(workspace, profile, generation)
        | None -> System.Threading.Tasks.Task.FromResult None

    let token sources revision generation =
        SHA256.HashData(
            Encoding.UTF8.GetBytes(
                SourceIdentity.token sources
                + ":"
                + string revision
                + ":"
                + (generation |> Option.map string |> Option.defaultValue "")
            )
        )
        |> Convert.ToHexString
        |> fun value -> value.ToLowerInvariant()

    let context workspace profile =
        task {
            let! result = contexts.Read(workspace, profile)

            return
                result
                |> Result.mapError (fun _ ->
                    ExecutableError.Unavailable "The selected game installation is unavailable.")
        }

    interface IGameLaunching with
        member _.Read(workspace, profile) =
            task {
                let! state = context workspace profile
                let! deployed = deployments.Read profile

                match state, deployed with
                | Ok state, Ok deployed when deployed.WorkspaceId = workspace ->
                    let! latest = executables.LatestGame workspace
                    let! dataRevision = profiles.Revision(workspace, profile)
                    let! loader = loaders.Read(workspace, profile, deployed.ActiveGeneration)
                    let! launch = launchConfiguration workspace profile deployed.ActiveGeneration

                    let runtime, problem =
                        match Descriptor.createWith state loader launch with
                        | Ok(_, runtime, _) -> runtime, None
                        | Error error -> "", Some error

                    return
                        Ok
                            { WorkspaceId = workspace
                              ProfileId = profile
                              ContextRevision = state.Revision
                              SourceToken =
                                token
                                    deployed.Sources
                                    (dataRevision |> Result.defaultValue -1L)
                                    deployed.ActiveGeneration
                              Name = Skyrim.definition.Name
                              Runtime = runtime
                              Problem = problem
                              Latest = latest }
                | Error error, _ -> return Error error
                | _, Error error ->
                    return Error(ExecutableError.Unavailable(Preparation.error error))
                | Ok _, Ok _ -> return Error ExecutableError.NotFound
            }

        member _.Begin request =
            task {
                if
                    request.Id = Guid.Empty
                    || request.WorkspaceId = Guid.Empty
                    || request.ProfileId = Guid.Empty
                    || request.WorkspaceRevision < 0L
                    || request.ContextRevision < 1L
                    || request.SourceToken.Length <> 64
                then
                    return Error(ExecutableError.Invalid "The game launch request is invalid.")
                else
                    let! existing = runs.Read(request.WorkspaceId, request.Id)

                    match existing with
                    | Ok value ->
                        match value.Source with
                        | RunSource.Game previous when previous.Request = request -> return Ok value
                        | _ -> return Error ExecutableError.IdentityConflict
                    | Error ExecutableError.NotFound ->
                        let! state = context request.WorkspaceId request.ProfileId
                        let! deployed = deployments.Read request.ProfileId

                        let! dataRevision =
                            profiles.Revision(request.WorkspaceId, request.ProfileId)

                        let! loader =
                            loaders.Read(
                                request.WorkspaceId,
                                request.ProfileId,
                                deployed |> Result.toOption |> Option.bind _.ActiveGeneration
                            )

                        let! launch =
                            launchConfiguration
                                request.WorkspaceId
                                request.ProfileId
                                (deployed |> Result.toOption |> Option.bind _.ActiveGeneration)

                        match state, deployed with
                        | Ok state, Ok deployed when
                            deployed.WorkspaceId = request.WorkspaceId
                            && state.Revision = request.ContextRevision
                            && Result.isOk dataRevision
                            && token
                                deployed.Sources
                                (dataRevision |> Result.defaultValue -1L)
                                deployed.ActiveGeneration = request.SourceToken
                            ->
                            match Descriptor.createWith state loader launch with
                            | Error error -> return Error(ExecutableError.Unavailable error)
                            | Ok(context, runtime, launch) ->
                                let game =
                                    { Request = request
                                      ContextId = context
                                      Name = Skyrim.definition.Name
                                      GameDirectory = launch.WorkingDirectory
                                      Runtime = runtime
                                      Launch = launch
                                      Preparation =
                                        { Phase = GamePreparationPhase.Preparing
                                          Completed = 0
                                          Total = 0 }
                                      Files = None
                                      ProfileDataRevision = dataRevision |> Result.defaultValue -1L
                                      ProfileData = None }

                                return!
                                    executables.BeginGame(
                                        game,
                                        Preparation.run deployment profiles deployed.Sources
                                    )
                        | Error error, _ -> return Error error
                        | _, Error error ->
                            return Error(ExecutableError.Unavailable(Preparation.error error))
                        | Ok _, Ok _ -> return Error ExecutableError.StaleRevision
                    | Error error -> return Error error
            }

        member _.Cancel(workspace, run) = executables.CancelGame(workspace, run)

    interface IToolLaunchProjection with
        member _.Project(workspace, profile, generation, executable, arguments) =
            task {
                let! state = context workspace profile
                let! deployed = deployments.Read profile

                match state, deployed with
                | Ok state, Ok deployed when
                    deployed.WorkspaceId = workspace
                    && deployed.ActiveGeneration = Some generation
                    ->
                    let! loader = loaders.Read(workspace, profile, Some generation)
                    let! launch = launchConfiguration workspace profile (Some generation)

                    return
                        Descriptor.createToolWith
                            state
                            loader
                            launch
                            generation
                            executable
                            arguments
                        |> Result.mapError ExecutableError.Unavailable
                | Error error, _ -> return Error error
                | _, Error error ->
                    return Error(ExecutableError.Unavailable(Preparation.error error))
                | _ -> return Error ExecutableError.StaleRevision
            }
