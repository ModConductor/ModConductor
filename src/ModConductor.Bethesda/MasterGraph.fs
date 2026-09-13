namespace ModConductor.Bethesda

open System
open System.Collections.Generic

module MasterGraph =
    let resolve (entries: PluginEntry list) =
        let index = Dictionary<string, PluginEntry>(StringComparer.OrdinalIgnoreCase)

        for entry in entries do
            index.Add(entry.Name, entry)

        let state name =
            match index.TryGetValue name with
            | false, _ -> MasterState.Missing, None
            | true, entry when entry.Ambiguity.IsSome -> MasterState.Ambiguous, None
            | true, entry ->
                match entry.Header with
                | Error _ -> MasterState.Unavailable, entry.Winner
                | Ok _ -> MasterState.Found, entry.Winner

        let edges = Dictionary<string, string list>(StringComparer.OrdinalIgnoreCase)

        for entry in entries do
            edges.Add(
                entry.Name,
                match entry.Header with
                | Error _ -> []
                | Ok header ->
                    header.Masters
                    |> List.filter (fun master -> fst (state master) = MasterState.Found)
            )
        // Two iterative graph passes find strongly connected components without recursion.
        let reverse =
            Dictionary<string, ResizeArray<string>>(StringComparer.OrdinalIgnoreCase)

        for entry in entries do
            reverse.Add(entry.Name, ResizeArray())

        for KeyValue(name, targets) in edges do
            for target in targets do
                reverse[target].Add name

        let visited = HashSet<string>(StringComparer.OrdinalIgnoreCase)
        let finished = ResizeArray<string>()

        for entry in entries do
            let work = Stack<string * bool>()
            work.Push(entry.Name, false)

            while work.Count > 0 do
                let name, finish = work.Pop()

                if finish then
                    finished.Add name
                elif visited.Add name then
                    work.Push(name, true)

                    for target in List.rev edges[name] do
                        work.Push(target, false)

        let groups = Dictionary<string, int>(StringComparer.OrdinalIgnoreCase)
        let sizes = ResizeArray<int>()

        for name in Seq.rev finished do
            if not (groups.ContainsKey name) then
                let id = sizes.Count
                let mutable size = 0
                let work = Stack<string>()
                work.Push name

                while work.Count > 0 do
                    let name = work.Pop()

                    if groups.TryAdd(name, id) then
                        size <- size + 1

                        for source in reverse[name] do
                            work.Push source

                sizes.Add size

        let cyclic source target =
            groups[source] = groups[target]
            && (sizes[groups[source]] > 1
                || String.Equals(source, target, StringComparison.OrdinalIgnoreCase))

        entries
        |> List.map (fun entry ->
            let masters =
                match entry.Header with
                | Error _ -> []
                | Ok header ->
                    header.Masters
                    |> List.map (fun name ->
                        let found, source = state name

                        { Name = name
                          State =
                            if found = MasterState.Found && cyclic entry.Name name then
                                MasterState.Cyclic
                            else
                                found
                          Source = source })

            { entry with Masters = masters })
