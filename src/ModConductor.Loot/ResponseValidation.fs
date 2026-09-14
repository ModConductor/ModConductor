namespace ModConductor.Loot

open System
open System.Collections.Generic

module internal ResponseValidation =
    let validate
        (correlation: string)
        (fingerprint: string)
        (metadata: LootMetadata)
        (current: string list)
        (response: LootJson.Response)
        =
        let invalid detail = Error(LootError.InvalidResponse detail)

        if response.Correlation <> correlation then
            invalid "The LOOT helper returned another correlation ID."
        elif response.Capability <> "skyrim-se-steam" then
            invalid "The LOOT helper returned another game capability."
        elif response.Fingerprint <> fingerprint then
            invalid "The LOOT helper returned stale source evidence."
        elif response.MetadataRevision <> metadata.Revision then
            invalid "The LOOT helper returned another metadata revision."
        elif
            response.HelperRevision <> "0.1.0"
            || response.LiblootVersion <> "0.29.6"
            || response.LiblootRevision <> "136f3983"
        then
            invalid "The LOOT helper version is not the pinned version."
        elif response.Current <> current then
            invalid "The LOOT helper changed the current-order echo."
        elif response.Sorted.Length <> current.Length then
            invalid "The LOOT helper changed the plugin count."
        else
            let comparer = StringComparer.OrdinalIgnoreCase
            let expected = HashSet<string>(current, comparer)
            let actual = HashSet<string>(response.Sorted, comparer)

            if expected.Count <> current.Length || actual.Count <> response.Sorted.Length then
                invalid "The LOOT helper returned duplicate plugin names."
            elif not (expected.SetEquals actual) then
                invalid "The LOOT helper changed the plugin set."
            elif response.Moves.Length > current.Length || response.Messages.Length > 4096 then
                invalid "The LOOT helper response exceeds its entry limit."
            else
                let currentPositions = Dictionary<string, int>(comparer)
                let proposedPositions = Dictionary<string, int>(comparer)

                current
                |> List.iteri (fun index plugin -> currentPositions.Add(plugin, index + 1))

                response.Sorted
                |> List.iteri (fun index plugin -> proposedPositions.Add(plugin, index + 1))

                let changed = Dictionary<string, int * int>(comparer)

                for plugin in current do
                    let before = currentPositions[plugin]
                    let after = proposedPositions[plugin]

                    if before <> after then
                        changed.Add(plugin, (before, after))

                let supplied = HashSet<string>(comparer)

                if response.Moves.Length <> changed.Count then
                    invalid "The LOOT helper returned an incomplete move set."
                elif
                    response.Moves
                    |> List.exists (fun move ->
                        match changed.TryGetValue move.Plugin with
                        | false, _ -> true
                        | true, (before, after) ->
                            not (supplied.Add move.Plugin)
                            || move.Current <> before
                            || move.Proposed <> after)
                then
                    invalid "The LOOT helper returned an inconsistent move set."
                else
                    Ok response
