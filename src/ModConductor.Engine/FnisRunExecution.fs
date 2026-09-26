namespace ModConductor.Engine

open System
open System.IO
open System.Threading
open System.Threading.Tasks
open ModConductor.Fnis
open ModConductor.GameLaunching
open ModConductor.Persistence
open ModConductor.Platform

module internal FnisRunExecution =
    let execute
        (store: OperationStore)
        timeout
        publicationCheckpoint
        candidateCheckpoint
        activationCheckpoint
        (stage: FnisRunStage)
        (token: CancellationToken)
        =
        task {
            let mutable stdout = Array.empty<byte>
            let mutable stderr = Array.empty<byte>
            let mutable runLog = Array.empty<byte>
            let mutable candidatePublished = false

            try
                let arguments = [ "RedirectFiles=" + stage.Directory; "InstantExecute=1" ]

                let! projected =
                    store.ToolLaunching.Project(
                        stage.Request.WorkspaceId,
                        stage.Request.ProfileId,
                        stage.GenerationId,
                        stage.Generator,
                        arguments
                    )

                match projected with
                | Error problem ->
                    let detail =
                        match problem with
                        | ModConductor.Executables.ExecutableError.Unavailable detail
                        | ModConductor.Executables.ExecutableError.Invalid detail -> detail
                        | _ -> "The selected FNIS launch context changed."

                    do!
                        store.FnisExecution.Fail(
                            stage.Request.Id,
                            FnisOutputPhase.Failed,
                            None,
                            stdout,
                            stderr,
                            runLog,
                            detail
                        )

                    ()
                | Ok projected ->
                    let beforeLogs = FnisRunLogs.logSnapshot projected.ToolExecutable

                    let! result =
                        task {
                            try
                                FnisRunLogs.makeWritable beforeLogs.Directory true

                                let temporary = Path.Combine(beforeLogs.Directory, "temporary_logs")

                                if Directory.Exists temporary then
                                    FnisRunLogs.makeWritable temporary true

                                return!
                                    NativeToolLaunch.runIn
                                        stage.Directory
                                        projected.Launch
                                        Array.empty
                                        { InputBytes = 1
                                          OutputBytes = 256 * 1024
                                          ErrorBytes = 256 * 1024
                                          Timeout = timeout }
                                        token
                            finally
                                runLog <-
                                    FnisRunLogs.captureAndRestoreLogs
                                        projected.ToolExecutable
                                        beforeLogs
                        }

                    match result with
                    | Error NativeToolError.Cancelled ->
                        do!
                            store.FnisExecution.Fail(
                                stage.Request.Id,
                                FnisOutputPhase.Cancelled,
                                None,
                                stdout,
                                stderr,
                                runLog,
                                "FNIS was cancelled. The previous generated output remains active."
                            )

                        ()
                    | Error NativeToolError.TimedOut ->
                        do!
                            store.FnisExecution.Fail(
                                stage.Request.Id,
                                FnisOutputPhase.Failed,
                                None,
                                stdout,
                                stderr,
                                runLog,
                                "FNIS timed out. The previous generated output remains active."
                            )

                        ()
                    | Error NativeToolError.OutputLimit ->
                        do!
                            store.FnisExecution.Fail(
                                stage.Request.Id,
                                FnisOutputPhase.Failed,
                                None,
                                stdout,
                                stderr,
                                runLog,
                                "FNIS standard output exceeded 256 KiB."
                            )

                        ()
                    | Error NativeToolError.ErrorLimit ->
                        do!
                            store.FnisExecution.Fail(
                                stage.Request.Id,
                                FnisOutputPhase.Failed,
                                None,
                                stdout,
                                stderr,
                                runLog,
                                "FNIS standard error exceeded 256 KiB."
                            )

                        ()
                    | Error(NativeToolError.LaunchFailed detail) ->
                        do!
                            store.FnisExecution.Fail(
                                stage.Request.Id,
                                FnisOutputPhase.Failed,
                                None,
                                stdout,
                                stderr,
                                runLog,
                                detail
                            )

                        ()
                    | Ok result ->
                        stdout <- result.Output
                        stderr <- result.Error
                        publicationCheckpoint stage.Request

                        let! published =
                            store.FnisExecution.Publish(
                                stage,
                                result.ExitCode,
                                stdout,
                                stderr,
                                runLog,
                                token
                            )

                        match published with
                        | Ok() ->
                            candidatePublished <- true
                            candidateCheckpoint stage.Request
                            let! deployment = store.Deployments.Read stage.Request.ProfileId

                            let! refreshed =
                                match deployment with
                                | Error _ ->
                                    Task.FromResult(
                                        Error ModConductor.Deployment.DeploymentError.Stale
                                    )
                                | Ok state ->
                                    store.Deployments.RefreshFnis(
                                        stage.Request.Id,
                                        state.Sources,
                                        stage.Request.Id,
                                        ignore,
                                        token
                                    )

                            match refreshed with
                            | Ok _ ->
                                activationCheckpoint stage.Request
                                do! store.FnisExecution.Complete stage.Request.Id
                                let! _ = store.FnisExecution.PrunePrevious stage.Request.Id
                                do! store.FnisExecution.MarkCurrent stage.Request.Id
                                ()
                            | Error error ->
                                let! restored =
                                    FnisRunRecovery.restorePending
                                        store
                                        stage.Request.ProfileId
                                        stage.Request.Id

                                if not restored then
                                    do! store.FnisExecution.Defer stage.Request.Id

                                let detail =
                                    match error with
                                    | ModConductor.Deployment.DeploymentError.Cancelled ->
                                        "FNIS output activation was cancelled. The previous output remains active."
                                    | _ ->
                                        "FNIS output could not be activated. The previous output remains active."

                                if restored then
                                    do!
                                        store.FnisExecution.Fail(
                                            stage.Request.Id,
                                            (if
                                                 error = ModConductor.Deployment.DeploymentError.Cancelled
                                             then
                                                 FnisOutputPhase.Cancelled
                                             else
                                                 FnisOutputPhase.Failed),
                                            (Some result.ExitCode),
                                            stdout,
                                            stderr,
                                            runLog,
                                            detail
                                        )

                                    let! _ = store.FnisExecution.PruneCandidate stage.Request.Id
                                    ()

                                ()
                        | Error error ->
                            let detail =
                                match error with
                                | FnisExecutionError.Stale ->
                                    "FNIS inputs changed before the generated output could be selected. The previous generated output remains active."
                                | FnisExecutionError.Cancelled ->
                                    "FNIS output publication was cancelled. The previous generated output remains active."
                                | FnisExecutionError.SourceInspectionFailed detail ->
                                    detail + " The previous generated output remains active."
                                | FnisExecutionError.Invalid detail
                                | FnisExecutionError.Unavailable detail -> detail
                                | _ ->
                                    "FNIS output could not be selected. The previous generated output remains active."

                            let exitCode =
                                match error with
                                | FnisExecutionError.SourceInspectionFailed _ -> None
                                | _ -> Some result.ExitCode

                            do!
                                store.FnisExecution.Fail(
                                    stage.Request.Id,
                                    (if error = FnisExecutionError.Cancelled then
                                         FnisOutputPhase.Cancelled
                                     else
                                         FnisOutputPhase.Failed),
                                    exitCode,
                                    stdout,
                                    stderr,
                                    runLog,
                                    detail
                                )

                            ()

                    FnisRunLogs.restoreLogMetadata beforeLogs
            with
            | :? OperationCanceledException ->
                if candidatePublished then
                    do! store.FnisExecution.Defer stage.Request.Id
                else
                    do!
                        store.FnisExecution.Fail(
                            stage.Request.Id,
                            FnisOutputPhase.Cancelled,
                            None,
                            stdout,
                            stderr,
                            runLog,
                            "FNIS was cancelled. The previous generated output remains active."
                        )

                    ()
            | error ->
                if candidatePublished then
                    do! store.FnisExecution.Defer stage.Request.Id
                else
                    do!
                        store.FnisExecution.Fail(
                            stage.Request.Id,
                            FnisOutputPhase.Failed,
                            None,
                            stdout,
                            stderr,
                            runLog,
                            (error.Message + " The previous generated output remains active.")
                        )

                    ()
        }
