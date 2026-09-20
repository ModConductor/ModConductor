namespace ModConductor.Engine

open System
open System.Collections.Concurrent
open System.Threading
open System.Threading.Tasks
open ModConductor.Fnis
open ModConductor.GameLaunching
open ModConductor.Persistence
open ModConductor.Platform

type FnisRunner(store: OperationStore) =
    let active = ConcurrentDictionary<Guid * Guid, CancellationTokenSource>()

    let inspect (workspace: Guid) (profile: Guid) (token: CancellationToken) =
        task {
            token.ThrowIfCancellationRequested()
            let! deployment = store.Deployments.Read profile

            match deployment with
            | Error _ -> return Error FnisExecutionError.NotFound
            | Ok deployment when deployment.WorkspaceId <> workspace ->
                return Error FnisExecutionError.NotFound
            | Ok deployment ->
                match deployment.ActiveGeneration with
                | None -> return Error FnisExecutionError.NotFound
                | Some generation -> return! store.FnisExecution.Inspect(workspace, profile, generation)
        }

    let failure id phase exitCode stdout stderr detail =
        task {
            do! store.FnisExecution.Fail(id, phase, exitCode, stdout, stderr, detail)
            return Error(FnisExecutionError.Unavailable detail)
        }

    interface IFnisInspection with
        member _.Inspect(workspace, profile, token) = inspect workspace profile token

    interface IFnisExecution with
        member _.Run(request, token) =
            task {
                if
                    request.Id = Guid.Empty
                    || request.WorkspaceId = Guid.Empty
                    || request.ProfileId = Guid.Empty
                then
                    return Error(FnisExecutionError.Invalid "The FNIS run identity is invalid.")
                else
                    let! observed = inspect request.WorkspaceId request.ProfileId token

                    match observed with
                    | Error error -> return Error error
                    | Ok observed ->
                        let! generator =
                            store.FnisSetups.ReadStored(
                                request.WorkspaceId,
                                request.ProfileId,
                                Some observed.GenerationId
                            )

                        match generator with
                        | None -> return Error FnisExecutionError.NotFound
                        | Some generator ->
                            let! begun =
                                store.FnisExecution.Begin(request, generator, observed.Fingerprint)

                            match begun with
                            | Error error -> return Error error
                            | Ok(_, false, _) ->
                                return! inspect request.WorkspaceId request.ProfileId token
                            | Ok(stage, true, _) ->
                                use local = CancellationTokenSource.CreateLinkedTokenSource token
                                let key = request.WorkspaceId, request.ProfileId

                                if not (active.TryAdd(key, local)) then
                                    do!
                                        store.FnisExecution.Fail(
                                            request.Id,
                                            FnisOutputPhase.Failed,
                                            None,
                                            Array.empty,
                                            Array.empty,
                                            "Another FNIS run already owns this profile."
                                        )

                                    return Error FnisExecutionError.Busy
                                else
                                    try
                                        let arguments =
                                            [ "RedirectFiles=" + stage.Directory
                                              "InstantExecute=1" ]

                                        let! projected =
                                            store.ToolLaunching.Project(
                                                request.WorkspaceId,
                                                request.ProfileId,
                                                stage.GenerationId,
                                                stage.Generator,
                                                arguments
                                            )

                                        match projected with
                                        | Error problem ->
                                            return!
                                                failure
                                                    request.Id
                                                    FnisOutputPhase.Failed
                                                    None
                                                    Array.empty
                                                    Array.empty
                                                    (match problem with
                                                     | ModConductor.Executables.ExecutableError.Unavailable detail
                                                     | ModConductor.Executables.ExecutableError.Invalid detail -> detail
                                                     | _ -> "The selected FNIS launch context changed.")
                                        | Ok projected ->
                                            let! result =
                                                NativeToolLaunch.runIn
                                                    stage.Directory
                                                    projected.Launch
                                                    Array.empty
                                                    { InputBytes = 1
                                                      OutputBytes = 256 * 1024
                                                      ErrorBytes = 256 * 1024
                                                      Timeout = TimeSpan.FromMinutes 5. }
                                                    local.Token

                                            match result with
                                            | Error NativeToolError.Cancelled ->
                                                do!
                                                    store.FnisExecution.Fail(
                                                        request.Id,
                                                        FnisOutputPhase.Cancelled,
                                                        None,
                                                        Array.empty,
                                                        Array.empty,
                                                        "FNIS was cancelled. The previous generated output remains active."
                                                    )

                                                return! inspect request.WorkspaceId request.ProfileId CancellationToken.None
                                            | Error NativeToolError.TimedOut ->
                                                return!
                                                    failure
                                                        request.Id
                                                        FnisOutputPhase.Failed
                                                        None
                                                        Array.empty
                                                        Array.empty
                                                        "FNIS timed out. The previous generated output remains active."
                                            | Error NativeToolError.OutputLimit ->
                                                return!
                                                    failure
                                                        request.Id
                                                        FnisOutputPhase.Failed
                                                        None
                                                        Array.empty
                                                        Array.empty
                                                        "FNIS standard output exceeded 256 KiB."
                                            | Error NativeToolError.ErrorLimit ->
                                                return!
                                                    failure
                                                        request.Id
                                                        FnisOutputPhase.Failed
                                                        None
                                                        Array.empty
                                                        Array.empty
                                                        "FNIS standard error exceeded 256 KiB."
                                            | Error(NativeToolError.LaunchFailed detail) ->
                                                return!
                                                    failure
                                                        request.Id
                                                        FnisOutputPhase.Failed
                                                        None
                                                        Array.empty
                                                        Array.empty
                                                        detail
                                            | Ok result when result.ExitCode <> 0 ->
                                                return!
                                                    failure
                                                        request.Id
                                                        FnisOutputPhase.Failed
                                                        (Some result.ExitCode)
                                                        result.Output
                                                        result.Error
                                                        ("FNIS exited with code " + string result.ExitCode + ".")
                                            | Ok result ->
                                                let! published =
                                                    store.FnisExecution.Publish(
                                                        stage,
                                                        result.ExitCode,
                                                        result.Output,
                                                        result.Error,
                                                        local.Token
                                                    )

                                                match published with
                                                | Error error ->
                                                    let detail =
                                                        match error with
                                                        | FnisExecutionError.Stale ->
                                                            "FNIS inputs changed before the generated output could be selected."
                                                        | FnisExecutionError.Cancelled ->
                                                            "FNIS output publication was cancelled."
                                                        | FnisExecutionError.Invalid detail
                                                        | FnisExecutionError.Unavailable detail -> detail
                                                        | _ -> "FNIS output could not be selected."

                                                    do!
                                                        store.FnisExecution.Fail(
                                                            request.Id,
                                                            (if error = FnisExecutionError.Cancelled then
                                                                 FnisOutputPhase.Cancelled
                                                             else
                                                                 FnisOutputPhase.Failed),
                                                            Some result.ExitCode,
                                                            result.Output,
                                                            result.Error,
                                                            detail
                                                        )

                                                    return Error error
                                                | Ok() ->
                                                    return!
                                                        inspect
                                                            request.WorkspaceId
                                                            request.ProfileId
                                                            CancellationToken.None
                                    finally
                                        let mutable removed = Unchecked.defaultof<CancellationTokenSource>
                                        active.TryRemove(key, &removed) |> ignore
            }

        member _.Cancel(workspace, profile) =
            task {
                match active.TryGetValue((workspace, profile)) with
                | true, cancellation -> cancellation.Cancel()
                | _ -> ()

                let deadline = DateTime.UtcNow.AddSeconds 10.

                while active.ContainsKey((workspace, profile)) && DateTime.UtcNow < deadline do
                    do! Task.Delay 20

                return! inspect workspace profile CancellationToken.None
            }
