namespace ModConductor.GameLaunching

open System
open ModConductor.GameContexts
open ModConductor.Deployment
open ModConductor.Executables
open ModConductor.Platform

module internal RegisteredTool =
    let private projectPath sourceRoot runnableRoot (path: string) =
        let relative = IO.Path.GetRelativePath(sourceRoot, path)

        if
            IO.Path.IsPathFullyQualified relative
            || relative = ".."
            || relative.StartsWith(".." + string IO.Path.DirectorySeparatorChar)
        then
            path
        else
            IO.Path.Combine(runnableRoot, relative)

    let projectWithHost hostWindows hostLinux runtime state runnableRoot (launch: NativeLaunch) =
        match state.Binding with
        | Some binding when not binding.NeedsCheck && binding.Evidence.Valid ->
            let executable =
                projectPath binding.Evidence.RootPath runnableRoot launch.Executable

            let directory =
                projectPath binding.Evidence.RootPath runnableRoot launch.WorkingDirectory

            match runtime with
            | ExecutableRuntime.Native ->
                Ok
                    { launch with
                        Executable = executable
                        WorkingDirectory = directory }
            | ExecutableRuntime.Wine when binding.Evidence.Platform <> ContextPlatform.Wine ->
                Error "Select and check a Wine installation context for this profile."
            | ExecutableRuntime.Proton when binding.Evidence.Platform <> ContextPlatform.Proton ->
                Error "Select and check a Proton installation context for this profile."
            | _ ->
                Descriptor.createWithHost hostWindows hostLinux state runnableRoot None None
                |> Result.map (fun (_, _, runtimeLaunch) ->
                    let projected =
                        Descriptor.projectTool
                            binding.Evidence.Platform
                            executable
                            launch.Arguments
                            runtimeLaunch

                    { projected with
                        WorkingDirectory = directory
                        Environment = runtimeLaunch.Environment @ launch.Environment })
        | _ -> Error "Select and check the installation before running this tool."

type RegisteredToolSession
    (
        contexts: IGameContexts,
        deployments: IDeploymentBackend,
        validateContext: GameContextState -> Result<InstallationEvidence, string>,
        resolveOutput:
            Guid * Guid * string option
                -> System.Threading.Tasks.Task<Result<string option, ExecutableError>>
    ) =
    interface IExecutableLaunchProjection with
        member _.Project run =
            task {
                match run.Source with
                | RunSource.Game _ -> return Ok(run.Launch, None)
                | RunSource.Preset(_, tool) ->
                    let usesGame =
                        tool.Launch.Arguments |> List.exists (fun arg -> arg.Contains("{game}"))

                    if
                        tool.Runtime = ExecutableRuntime.Native
                        && tool.OutputName.IsNone
                        && not usesGame
                    then
                        return Ok(tool.Launch, None)
                    else
                        match run.ProfileId with
                        | None ->
                            return
                                Error(
                                    ExecutableError.Unavailable
                                        "Select a profile before running this tool."
                                )
                        | Some profile ->
                            let! output = resolveOutput (run.WorkspaceId, profile, tool.OutputName)
                            let! context = contexts.Read(run.WorkspaceId, profile)
                            let! deployed = deployments.Read profile

                            match output, context, deployed with
                            | Error error, _, _ -> return Error error
                            | Ok output, Ok state, Ok view when
                                view.WorkspaceId = run.WorkspaceId && state.Binding.IsSome
                                ->
                                let valid = validateContext state

                                if usesGame && view.ActiveGeneration.IsNone then
                                    return
                                        Error(
                                            ExecutableError.Unavailable
                                                "Deploy the selected profile before using {game}."
                                        )
                                else
                                    return
                                        valid
                                        |> Result.bind (fun evidence ->
                                            ToolArguments.substitute
                                                tool.Runtime
                                                evidence
                                                (if view.ActiveGeneration.IsSome then
                                                     Some view.RunnableRoot
                                                 else
                                                     None)
                                                output
                                                tool.Launch.Arguments)
                                        |> Result.bind (fun arguments ->
                                            RegisteredTool.projectWithHost
                                                (OperatingSystem.IsWindows())
                                                (OperatingSystem.IsLinux())
                                                tool.Runtime
                                                state
                                                view.RunnableRoot
                                                { tool.Launch with
                                                    Arguments = arguments })
                                        |> Result.map (fun launch -> launch, output)
                                        |> Result.mapError ExecutableError.Unavailable
                            | _ ->
                                return
                                    Error(
                                        ExecutableError.Unavailable
                                            "Select and check the profile installation and runtime before running this tool."
                                    )
            }
