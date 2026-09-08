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
        | :? PlatformNotSupportedException ->
            Some(RecoveryError.Unavailable "Symbolic-link operations are unavailable.")
        | _ -> None

    member _.Start(request: SwitchRequest) =
        task {
            if not (enter request.Id) then
                return Error RecoveryError.Busy
            else
                try
                    try
                        let! context = repository.Context request.ContextId
                        let! receipt = Task.Run(fun () -> Preparation.prepare context request)
                        let! saved = repository.Begin(context, receipt, request.Generation)
                        return Ok saved
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
                        current <- Some saved
                        return saved
                    }

                let boundary name index =
                    afterEffect name index
                    cancellation.ThrowIfCancellationRequested()

                try
                    try
                        let! claimed = repository.Claim(id, revision)
                        current <- Some claimed

                        if
                            claimed.Phase = ReceiptPhase.Complete
                            || claimed.Phase = ReceiptPhase.Restored
                        then
                            return Ok claimed
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

                            RecoveryFiles.verifyGeneration proposed

                            match claimed.Previous with
                            | Some previous ->
                                let! old = repository.Generation(claimed.Context.Id, previous)
                                RecoveryFiles.verifyGeneration (required old)
                            | None -> ()

                            let restoring =
                                restore
                                || claimed.Phase = ReceiptPhase.Restoring
                                || (claimed.Changes
                                    |> List.exists (fun change ->
                                        change.Phase = EntryPhase.RestoreIntent
                                        || change.Phase = EntryPhase.Restored))

                            let! starting =
                                save
                                    { claimed with
                                        Phase =
                                            (if restoring then
                                                 ReceiptPhase.Restoring
                                             else
                                                 ReceiptPhase.Applying)
                                        Detail = "" }

                            boundary "intent" -1

                            let! receipt =
                                RecoverySteps.run save boundary cancellation starting restoring

                            let links =
                                receipt.Changes
                                |> List.choose (fun change ->
                                    let state, observed =
                                        if restoring then
                                            change.Before, change.RestoredEntry
                                        else
                                            change.After, change.Observed

                                    match state with
                                    | EntryState.Link(spec, _) ->
                                        let entry =
                                            observed
                                            |> Option.defaultWith (fun () ->
                                                RecoveryFiles.fail
                                                    "A completed link has no observed identity.")

                                        if
                                            not (
                                                RecoveryFiles.stateMatches
                                                    receipt.Context
                                                    change.Target
                                                    (EntryState.Link(spec, Some entry))
                                                    (RecoveryFiles.observe
                                                        receipt.Context
                                                        change.Target)
                                            )
                                        then
                                            RecoveryFiles.fail "A completed link changed."

                                        Some
                                            { Target = change.Target
                                              Spec = spec
                                              Entry = entry }
                                    | _ ->
                                        if
                                            not (
                                                RecoveryFiles.stateMatches
                                                    receipt.Context
                                                    change.Target
                                                    state
                                                    (RecoveryFiles.observe
                                                        receipt.Context
                                                        change.Target)
                                            )
                                        then
                                            RecoveryFiles.fail "A completed path changed."

                                        None)

                            boundary "verified" -1

                            let context =
                                { receipt.Context with
                                    Revision = receipt.Context.Revision + 1L
                                    Active =
                                        (if restoring then
                                             receipt.Previous
                                         else
                                             Some receipt.Proposed)
                                    Links = links
                                    Originals =
                                        (if restoring then
                                             receipt.Context.Originals
                                         else
                                             receipt.Originals)
                                    Pending = None }

                            let! finished =
                                repository.Finish(
                                    { receipt with
                                        Phase =
                                            (if restoring then
                                                 ReceiptPhase.Restored
                                             else
                                                 ReceiptPhase.Complete) },
                                    context
                                )

                            current <- Some finished
                            afterEffect "committed" -1
                            return Ok finished
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

                                let! _ =
                                    save
                                        { receipt with
                                            Phase = ReceiptPhase.Blocked
                                            Detail = detail }

                                ()
                            | _ -> ()

                            return Error reason
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
