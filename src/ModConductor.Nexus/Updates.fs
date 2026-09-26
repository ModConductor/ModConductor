namespace ModConductor.Nexus

open System.Collections.Generic

module NexusUpdates =
    let candidates (installed: InstalledNexusFile option) (metadata: NexusMetadata) =
        match installed with
        | None -> []
        | Some file ->
            let next = Dictionary<int64, ResizeArray<int64>>()

            for edge in metadata.Updates do
                if not (next.ContainsKey edge.Previous) then
                    next[edge.Previous] <- ResizeArray()

                next[edge.Previous].Add edge.Next

            let visited, active, leaves = HashSet<int64>(), HashSet<int64>(), HashSet<int64>()
            let mutable invalid = false
            let pending = Stack<int64 * bool>()
            pending.Push(file.Id, false)

            while pending.Count > 0 do
                let id, leaving = pending.Pop()

                if leaving then
                    active.Remove id |> ignore
                elif active.Contains id then
                    invalid <- true
                elif visited.Add id then
                    active.Add id |> ignore
                    pending.Push(id, true)

                    match next.TryGetValue id with
                    | true, children ->
                        for child in children do
                            pending.Push(child, false)
                    | _ ->
                        if id <> file.Id then
                            leaves.Add id |> ignore

            if invalid then
                []
            else
                metadata.Files
                |> List.filter (fun entry ->
                    leaves.Contains entry.File.Id && entry.CategoryId >= 1 && entry.CategoryId <= 3)
                |> List.sortByDescending (fun entry -> entry.Uploaded, entry.File.Id)
