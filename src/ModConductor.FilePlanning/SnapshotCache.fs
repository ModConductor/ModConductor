namespace ModConductor.FilePlanning

open System
open System.Collections.Generic

/// Session observations are disposable. A cache miss requires a new explicit acquisition.
type internal SnapshotCache() =
    let gate = obj ()
    let snapshots = LinkedList<PlanSnapshot>()
    let staleGames = HashSet<string>(StringComparer.Ordinal)

    let gameKey (snapshot: PlanSnapshot) =
        snapshot.Game |> Option.map (fun game -> game.Snapshot.Generation)

    member _.Find id =
        lock gate (fun () -> snapshots |> Seq.tryFind (fun snapshot -> snapshot.Id = id))

    member _.Matching stamp =
        lock gate (fun () ->
            snapshots |> Seq.tryFind (fun snapshot -> snapshot.Sources.Stamp = stamp))

    member _.Game workspace identity fingerprint =
        lock gate (fun () ->
            snapshots
            |> Seq.tryPick (fun snapshot ->
                if snapshot.Sources.Stamp.WorkspaceId <> workspace then
                    None
                else
                    snapshot.Game
                    |> Option.filter (fun game ->
                        Some game.Identity = identity && game.ContextFingerprint = fingerprint)))

    member _.GameStale(game: GameObservation) =
        lock gate (fun () -> staleGames.Contains game.Snapshot.Generation)

    member _.MarkGameStale(game: GameObservation) =
        lock gate (fun () -> staleGames.Add game.Snapshot.Generation |> ignore)

    member _.Stale snapshot =
        lock gate (fun () -> gameKey snapshot |> Option.exists staleGames.Contains)

    member _.MarkStale snapshot =
        lock gate (fun () -> gameKey snapshot |> Option.iter (staleGames.Add >> ignore))

    member _.Put(snapshot, freshGame) =
        lock gate (fun () ->
            if freshGame then
                gameKey snapshot |> Option.iter (staleGames.Remove >> ignore)

            snapshots.AddFirst snapshot |> ignore
            let workspace = snapshot.Sources.Stamp.WorkspaceId

            while snapshots
                  |> Seq.filter (fun entry -> entry.Sources.Stamp.WorkspaceId = workspace)
                  |> Seq.length > 2 do
                snapshots
                |> Seq.rev
                |> Seq.find (fun entry -> entry.Sources.Stamp.WorkspaceId = workspace)
                |> snapshots.Remove
                |> ignore

            while snapshots.Count > 8 || snapshots |> Seq.sumBy _.EncodedBytes > Limits.cacheBytes do
                snapshots.RemoveLast()

            let retained = snapshots |> Seq.choose gameKey |> Set.ofSeq
            staleGames.RemoveWhere(fun value -> not (retained.Contains value)) |> ignore)
