namespace ModConductor.DeploymentRecovery

open System.Threading.Tasks
open ModConductor.Platform
open ModConductor.DeploymentPlanning

module internal RecoveryParents =
    let private depth (target: TargetFile) =
        LogicalPath.components target.Path |> List.length

    let prepare (context: Context) targets =
        let required =
            targets
            |> List.collect (fun target ->
                let parts = LogicalPath.components target.Path

                [ for count in 1 .. parts.Length - 1 do
                      yield
                          { target with
                              Path =
                                  LogicalPath.create (List.take count parts)
                                  |> Result.defaultWith (fun _ -> invalidOp "Invalid parent path.") } ])
            |> Set.ofList

        let existing =
            context.Directories
            |> List.map (fun row -> row.Target, row.Identity)
            |> Map.ofList

        let all = Set.union required (existing.Keys |> Set.ofSeq)

        if all.Count > 4096 then
            raise (RecoveryException RecoveryError.Limit)

        all
        |> Seq.choose (fun target ->
            match existing.TryFind target, RecoveryFiles.observe context target with
            | Some expected, Some actual when
                actual.Kind = EntryKind.Directory && actual.Identity = expected
                ->
                Some
                    { Target = target
                      Before = Some expected
                      Desired = required.Contains target
                      Observed = Some expected
                      Restored = None
                      Phase = EntryPhase.Pending }
            | Some _, _ -> RecoveryFiles.fail "An owned target directory changed."
            | None, None ->
                Some
                    { Target = target
                      Before = None
                      Desired = true
                      Observed = None
                      Restored = None
                      Phase = EntryPhase.Pending }
            | None, Some actual when actual.Kind = EntryKind.Directory -> None
            | None, Some _ -> RecoveryFiles.fail "A target parent is not a real directory.")
        |> Seq.sortBy (fun change -> depth change.Target, change.Target)
        |> Seq.toList

    let private update index change (receipt: Receipt) =
        { receipt with
            Parents = receipt.Parents |> List.mapi (fun i row -> if i = index then change else row) }

    let create (save: Receipt -> Task<Receipt>) boundary (starting: Receipt) restoring =
        task {
            let mutable receipt = starting

            for index in 0 .. receipt.Parents.Length - 1 do
                let mutable change = receipt.Parents[index]
                let needed = if restoring then change.Before.IsSome else change.Desired

                if needed then
                    let expected =
                        if restoring then
                            Option.orElse change.Before change.Restored
                        else
                            change.Observed

                    match RecoveryFiles.observe receipt.Context change.Target with
                    | Some actual when
                        actual.Kind = EntryKind.Directory && expected = Some actual.Identity
                        ->
                        ()
                    | Some _ ->
                        RecoveryFiles.fail
                            "An unrecorded or changed directory occupies a deployment parent."
                    | None ->
                        let removedByThisOperation =
                            restoring
                            && not change.Desired
                            && (change.Phase = EntryPhase.RemoveIntent
                                || change.Phase = EntryPhase.Cleared
                                || change.Phase = EntryPhase.RestoreIntent)

                        if expected.IsSome && not removedByThisOperation then
                            RecoveryFiles.fail "A recorded deployment parent is missing."

                        change <-
                            { change with
                                Phase =
                                    if restoring then
                                        EntryPhase.RestoreIntent
                                    else
                                        EntryPhase.InstallIntent }

                        let! intent = save (update index change receipt)
                        receipt <- intent
                        boundary "parent-create-intent" index

                        let identity =
                            RecoveryFiles.withParent
                                (RecoveryFiles.binding receipt.Context change.Target).Directory
                                change.Target.Path
                                (fun parent name ->
                                    use child = parent.CreateDirectory name
                                    child.Identity)

                        boundary "parent-created" index

                        change <-
                            if restoring then
                                { change with
                                    Restored = Some identity
                                    Phase = EntryPhase.Restored }
                            else
                                { change with
                                    Observed = Some identity
                                    Phase = EntryPhase.Installed }

                        let! updated = save (update index change receipt)
                        receipt <- updated

            return receipt
        }

    let remove (save: Receipt -> Task<Receipt>) boundary (starting: Receipt) restoring =
        task {
            let mutable receipt = starting

            for index in [ 0 .. receipt.Parents.Length - 1 ] |> List.rev do
                let mutable change = receipt.Parents[index]
                let needed = if restoring then change.Before.IsSome else change.Desired

                if not needed then
                    let actual = RecoveryFiles.observe receipt.Context change.Target

                    match actual with
                    | None when
                        change.Observed.IsNone
                        || change.Phase = EntryPhase.RemoveIntent
                        || change.Phase = EntryPhase.Cleared
                        || change.Phase = EntryPhase.RestoreIntent
                        || change.Phase = EntryPhase.Restored
                        ->
                        ()
                    | None -> RecoveryFiles.fail "A recorded deployment parent is missing."
                    | Some actual when
                        actual.Kind = EntryKind.Directory && change.Observed = Some actual.Identity
                        ->
                        change <-
                            { change with
                                Phase =
                                    if restoring then
                                        EntryPhase.RestoreIntent
                                    else
                                        EntryPhase.RemoveIntent }

                        let! intent = save (update index change receipt)
                        receipt <- intent
                        boundary "parent-remove-intent" index

                        RecoveryFiles.withParent
                            (RecoveryFiles.binding receipt.Context change.Target).Directory
                            change.Target.Path
                            (fun parent name ->
                                let empty =
                                    use child = parent.Directory(name, Some actual.Identity)
                                    Seq.isEmpty child.Names

                                if not empty then
                                    RecoveryFiles.fail
                                        "An owned parent is not empty; its contents were left untouched."

                                parent.RemoveDirectory(name, actual.Identity))

                        boundary "parent-removed" index

                        change <-
                            { change with
                                Phase =
                                    if restoring then
                                        EntryPhase.Restored
                                    else
                                        EntryPhase.Cleared }

                        let! updated = save (update index change receipt)
                        receipt <- updated
                    | Some _ -> RecoveryFiles.fail "A changed deployment parent was left untouched."

            return receipt
        }

    let completed (receipt: Receipt) restoring =
        receipt.Parents
        |> List.choose (fun change ->
            let identity =
                if restoring then
                    Option.orElse change.Before change.Restored
                else if change.Desired then
                    change.Observed
                else
                    None

            identity
            |> Option.map (fun value ->
                { Target = change.Target
                  Identity = value }))
