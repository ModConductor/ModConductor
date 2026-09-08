namespace ModConductor.DeploymentRecovery

open System.Threading
open System.Threading.Tasks

module internal RecoverySteps =
    let private update index change (receipt: Receipt) =
        { receipt with
            Changes =
                receipt.Changes
                |> List.mapi (fun i value -> if i = index then change else value) }

    let run
        (save: Receipt -> Task<Receipt>)
        (boundary: string -> int -> unit)
        (cancellation: CancellationToken)
        starting
        restoring
        =
        task {
            let mutable receipt = starting

            let order =
                [ 0 .. receipt.Changes.Length - 1 ]
                |> fun values -> if restoring then List.rev values else values

            for index in order do
                cancellation.ThrowIfCancellationRequested()
                let mutable change = receipt.Changes[index]

                if restoring then
                    if change.Phase <> EntryPhase.Restored then
                        change <-
                            { change with
                                Phase = EntryPhase.RestoreIntent }

                        let! next = save (update index change receipt)
                        receipt <- next
                        boundary "restore-intent" index

                        let actual = RecoveryFiles.observe receipt.Context change.Target

                        let before = change.Before

                        if
                            not (
                                RecoveryFiles.stateMatches
                                    receipt.Context
                                    change.Target
                                    before
                                    actual
                            )
                        then
                            match actual with
                            | None -> ()
                            | Some entry ->
                                let after =
                                    match change.After with
                                    | EntryState.Link(spec, _) ->
                                        EntryState.Link(spec, change.Observed)
                                    | state -> state

                                if
                                    not (
                                        RecoveryFiles.stateMatches
                                            receipt.Context
                                            change.Target
                                            after
                                            actual
                                    )
                                then
                                    RecoveryFiles.fail
                                        "The changed entry cannot be restored automatically."

                                match after with
                                | EntryState.Link _ ->
                                    RecoveryFiles.remove receipt.Context change.Target entry
                                | EntryState.Original original ->
                                    RecoveryFiles.preserve receipt.Context original
                                | EntryState.Missing ->
                                    RecoveryFiles.fail
                                        "An unexpected entry occupies the restore path."

                        let observed = RecoveryFiles.install receipt.Context change.Target before

                        boundary "restored" index

                        let! next =
                            save (
                                update
                                    index
                                    { change with
                                        Phase = EntryPhase.Restored
                                        RestoredEntry = observed }
                                    receipt
                            )

                        receipt <- next
                else
                    if change.Phase = EntryPhase.Pending then
                        change <-
                            { change with
                                Phase = EntryPhase.RemoveIntent }

                        let! next = save (update index change receipt)
                        receipt <- next
                        boundary "remove-intent" index

                    if change.Phase = EntryPhase.RemoveIntent then
                        match
                            change.Before, RecoveryFiles.observe receipt.Context change.Target
                        with
                        | EntryState.Missing, None -> ()
                        | EntryState.Link _, None -> ()
                        | EntryState.Link(spec, Some expected), Some actual when
                            expected = actual && RecoveryFiles.linkMatches spec actual
                            ->
                            RecoveryFiles.remove receipt.Context change.Target actual
                        | EntryState.Original original, _ ->
                            RecoveryFiles.preserve receipt.Context original
                        | _ -> RecoveryFiles.fail "The entry changed before removal."

                        boundary "removed" index

                        change <-
                            { change with
                                Phase = EntryPhase.Cleared }

                        let! next = save (update index change receipt)
                        receipt <- next

                    if change.Phase = EntryPhase.Cleared then
                        change <-
                            { change with
                                Phase = EntryPhase.InstallIntent }

                        let! next = save (update index change receipt)
                        receipt <- next
                        boundary "install-intent" index

                    if change.Phase = EntryPhase.InstallIntent then
                        let observed =
                            RecoveryFiles.install receipt.Context change.Target change.After

                        boundary "installed" index

                        change <-
                            { change with
                                Phase = EntryPhase.Installed
                                Observed = observed }

                        let! next = save (update index change receipt)
                        receipt <- next

            return receipt
        }
