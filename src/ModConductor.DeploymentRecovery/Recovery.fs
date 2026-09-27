namespace ModConductor.DeploymentRecovery

open System
open System.IO
open System.Collections.Generic
open System.Threading
open System.Threading.Tasks

/// Coordinates MC-owned entries; unrelated writers must not replace the same entry during an effect.
type internal Recovery(repository: IRecoveryRepository) =
    let gate = obj ()
    let active = HashSet<Guid>()
    let mutable closed = false

    let enter id =
        lock gate (fun () -> not closed && active.Count < 2 && active.Add id)

    let leave id =
        lock gate (fun () -> active.Remove id |> ignore)

    let required value =
        value
        |> Option.defaultWith (fun () -> raise (RecoveryException RecoveryError.NotFound))

    let convert =
        function
        | RecoveryException error -> Some error
        | :? IOException as error -> Some(RecoveryError.Unavailable error.Message)
        | :? UnauthorizedAccessException as error -> Some(RecoveryError.Unavailable error.Message)
        | :? OperationCanceledException ->
            Some(RecoveryError.Unavailable "Deployment preparation was cancelled.")
        | :? PlatformNotSupportedException ->
            Some(RecoveryError.Unavailable "Symbolic-link operations are unavailable.")
        | _ -> None

    let restoring (receipt: Receipt) requested =
        requested
        || receipt.Phase = ReceiptPhase.Restoring
        || (receipt.Changes
            |> List.exists (fun change ->
                change.Phase = EntryPhase.RestoreIntent || change.Phase = EntryPhase.Restored))

    let verifyCompleted cancellation (receipt: Receipt) restoring =
        receipt.Changes
        |> List.choose (fun change ->
            let state, observed =
                if restoring then
                    change.Before, change.RestoredEntry
                else
                    change.After, change.Observed

            let checkedState =
                match state with
                | EntryState.Link(spec, _) ->
                    let entry =
                        observed
                        |> Option.defaultWith (fun () ->
                            RecoveryFiles.fail "A completed link has no observed identity.")

                    EntryState.Link(spec, Some entry)
                | _ -> state

            if
                not (
                    RecoveryFiles.stateMatches
                        cancellation
                        receipt.Context
                        change.Target
                        checkedState
                        (RecoveryFiles.observe receipt.Context change.Target)
                )
            then
                match checkedState with
                | EntryState.Link _ -> RecoveryFiles.fail "A completed link changed."
                | _ -> RecoveryFiles.fail "A completed path changed."

            match checkedState with
            | EntryState.Link(spec, Some entry) ->
                Some
                    { Target = change.Target
                      Spec = spec
                      Entry = entry }
            | _ -> None)

    let completedContext (receipt: Receipt) restoring links =
        { receipt.Context with
            Revision = receipt.Context.Revision + 1L
            Active =
                (if restoring then
                     receipt.Previous
                 else
                     Some receipt.Proposed)
            Links = links
            Directories = RecoveryParents.completed receipt restoring
            Originals =
                (if restoring then
                     receipt.Context.Originals
                 else
                     receipt.Originals)
            Pending = None }

    member _.Start(request: SwitchRequest, ?cancellation: CancellationToken) =
        task {
            if not (enter request.Id) then
                return Error RecoveryError.Busy
            else
                try
                    try
                        let! context = repository.Context request.ContextId
                        let token = defaultArg cancellation CancellationToken.None

                        let! prepared =
                            Task.Run(fun () -> Preparation.prepare token context request)

                        match prepared with
                        | Error error -> return Error error
                        | Ok receipt ->
                            token.ThrowIfCancellationRequested()

                            let! saved =
                                repository.Begin(
                                    context,
                                    receipt,
                                    request.Generation,
                                    request.ExpectedSources
                                )

                            return saved
                    with error ->
                        match convert error with
                        | Some failure -> return Error failure
                        | None -> return raise error
                finally
                    leave request.Id
        }

    member _.Read(id) = repository.Read id
    member _.Context(id) = repository.Context id
    member _.Generation(context, id) = repository.Generation(context, id)
    member _.Pending(after) = repository.Pending after

    member _.Run
        (id, revision, restore, cancellation: CancellationToken, afterEffect: string -> int -> unit)
        =
        task {
            if not (enter id) then
                return Error RecoveryError.Busy
            else
                let mutable current: Receipt option = None

                let save receipt =
                    task {
                        let! saved = repository.Save receipt

                        match saved with
                        | Ok value -> current <- Some value
                        | Error _ -> ()

                        return saved
                    }

                let boundary name index =
                    afterEffect name index
                    cancellation.ThrowIfCancellationRequested()

                try
                    try
                        return!
                            RecoveryResultTask.resultTask {
                                let! claimedResult = repository.Claim(id, revision)
                                let! claimed = claimedResult
                                current <- Some claimed

                                if
                                    claimed.Phase = ReceiptPhase.Complete
                                    || claimed.Phase = ReceiptPhase.Restored
                                then
                                    return claimed
                                else
                                    let! proposed =
                                        repository.Generation(claimed.Context.Id, claimed.Proposed)

                                    let proposed = required proposed

                                    if
                                        proposed.PlanFingerprint <> claimed.PlanFingerprint
                                        || List.sort proposed.Roots
                                           <> (claimed.Context.Roots
                                               |> List.map (fun root -> root.Root)
                                               |> List.sort)
                                    then
                                        RecoveryFiles.fail
                                            "The recorded generation differs from the activation context."

                                    RecoveryFiles.verifyGenerationWith cancellation proposed

                                    RecoveryFiles.verifyObservedWith
                                        cancellation
                                        { claimed.Context with
                                            Originals = claimed.Originals }
                                        proposed

                                    match claimed.Previous with
                                    | Some previous ->
                                        let! old =
                                            repository.Generation(claimed.Context.Id, previous)

                                        RecoveryFiles.verifyGenerationWith
                                            cancellation
                                            (required old)
                                    | None -> ()

                                    let restoring = restoring claimed restore

                                    let! startingResult =
                                        save
                                            { claimed with
                                                Phase =
                                                    (if restoring then
                                                         ReceiptPhase.Restoring
                                                     else
                                                         ReceiptPhase.Applying)
                                                Detail = "" }

                                    let! starting = startingResult
                                    boundary "intent" -1

                                    let! parentResult =
                                        RecoveryParents.create save boundary starting restoring

                                    let! parentReady = parentResult

                                    let! stepResult =
                                        RecoverySteps.run
                                            save
                                            boundary
                                            cancellation
                                            parentReady
                                            restoring

                                    let! stepped = stepResult

                                    let! removeResult =
                                        RecoveryParents.remove save boundary stepped restoring

                                    let! receipt = removeResult
                                    let links = verifyCompleted cancellation receipt restoring
                                    boundary "verified" -1
                                    let context = completedContext receipt restoring links
                                    boundary "publication" -1

                                    let! finishResult =
                                        repository.Finish(
                                            { receipt with
                                                Phase =
                                                    (if restoring then
                                                         ReceiptPhase.Restored
                                                     else
                                                         ReceiptPhase.Complete) },
                                            context
                                        )

                                    let! finished = finishResult
                                    current <- Some finished
                                    afterEffect "committed" -1
                                    return finished
                            }
                    with error ->
                        let failure =
                            if error :? OperationCanceledException then
                                Some(
                                    RecoveryError.Unavailable
                                        "The operation stopped at a recorded boundary."
                                )
                            else
                                convert error

                        match failure with
                        | None -> return raise error
                        | Some reason ->
                            let mutable saveFailure = None

                            match current with
                            | Some receipt when
                                receipt.Phase <> ReceiptPhase.Complete
                                && receipt.Phase <> ReceiptPhase.Restored
                                ->
                                let detail =
                                    match reason with
                                    | RecoveryError.Mismatch text
                                    | RecoveryError.Unavailable text
                                    | RecoveryError.Corrupt text -> text
                                    | _ -> "The receipt cannot proceed."

                                let! blocked =
                                    save
                                        { receipt with
                                            Phase = ReceiptPhase.Blocked
                                            Detail = detail }

                                match blocked with
                                | Error error -> saveFailure <- Some error
                                | Ok _ -> ()
                            | _ -> ()

                            return Error(Option.defaultValue reason saveFailure)
                finally
                    if current.IsSome then
                        repository.Release(id).GetAwaiter().GetResult()

                    leave id
        }

    member _.TryClose() =
        lock gate (fun () ->
            if active.Count <> 0 then
                false
            else
                closed <- true
                true)
