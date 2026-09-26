namespace ModConductor.Persistence

open System
open System.IO
open System.Threading
open ModConductor.Fnis
open ModConductor.ModLibrary

type internal FnisExecutionStore
    (
        directory: string,
        database: StateDatabase,
        access: LibraryAccess,
        publication: LibraryPublication,
        setups: FnisStore
    ) =
    let claim = FnisRunClaim(directory, database)
    let lifecycle = FnisExecutionLifecycle(database, access)
    let publisher = FnisOutputPublisher(database, access, publication)

    member _.CleanupStage(id: Guid) = claim.CleanupStage id
    member _.Interrupted(profile: Guid) = lifecycle.Interrupted profile
    member _.Defer(runId: Guid) = lifecycle.Defer runId
    member _.Complete(runId: Guid) = lifecycle.Complete runId
    member _.MarkCurrent(runId: Guid) = lifecycle.MarkCurrent runId
    member _.PruneCandidate(runId: Guid) = lifecycle.PruneCandidate runId
    member _.PrunePrevious(runId: Guid) = lifecycle.PrunePrevious runId

    member _.Inspect(workspace, profile, generation) =
        task {
            let! installed = setups.ReadStored(workspace, profile, Some generation)

            match installed with
            | None -> return Error FnisExecutionError.NotFound
            | Some generator ->
                try
                    let! value = FnisInputInspection.inspection database workspace profile generator
                    return Ok value
                with :? InvalidDataException as error ->
                    return Error(FnisExecutionError.Unavailable error.Message)
        }

    member _.Begin(request: FnisRunRequest, generator: StoredFnisGenerator, fingerprint) =
        claim.Begin(request, generator, fingerprint)

    member _.Fail
        (id, phase, exitCode, stdout: byte array, stderr: byte array, runLog: byte array, problem)
        =
        claim.Fail(id, phase, exitCode, stdout, stderr, runLog, problem)

    member _.Publish
        (
            run: FnisRunStage,
            exitCode,
            stdout: byte array,
            stderr: byte array,
            runLog: byte array,
            token: CancellationToken
        ) =
        publisher.Publish(run, exitCode, stdout, stderr, runLog, token)
