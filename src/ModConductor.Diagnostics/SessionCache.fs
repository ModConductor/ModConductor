namespace ModConductor.Diagnostics

open System
open System.Collections.Generic

[<Struct>]
type internal StoredSnapshot =
    { View: DiagnosticSnapshot
      Request: DiagnosticRequest }

type internal SessionCache() =
    let gate = obj ()
    let snapshots = Dictionary<Guid, StoredSnapshot>()
    let previews = Dictionary<Guid, StoredPreview>()

    let trim now =
        let expired =
            previews
            |> Seq.choose (fun entry ->
                if entry.Value.View.ExpiresAt <= now then
                    Some entry.Key
                else
                    None)
            |> Seq.toArray

        for id in expired do
            previews.Remove id |> ignore

    let removeOldestSnapshot () =
        if snapshots.Count >= Limits.previews then
            snapshots
            |> Seq.minBy (fun entry -> entry.Value.View.CapturedAt)
            |> _.Key
            |> snapshots.Remove
            |> ignore

    let removeOldestPreview () =
        if previews.Count >= Limits.previews then
            previews
            |> Seq.minBy (fun entry -> entry.Value.View.ExpiresAt)
            |> _.Key
            |> previews.Remove
            |> ignore

    member _.RememberSnapshot(view: DiagnosticSnapshot, request: DiagnosticRequest) =
        lock gate (fun () ->
            trim DateTimeOffset.UtcNow
            removeOldestSnapshot ()
            snapshots[view.Id] <- { View = view; Request = request })

    member _.ReadSnapshot(id: Guid) : StoredSnapshot option =
        lock gate (fun () ->
            trim DateTimeOffset.UtcNow

            match snapshots.TryGetValue id with
            | true, value -> Some value
            | _ -> None)

    member _.RememberPreview(value: StoredPreview) =
        lock gate (fun () ->
            trim DateTimeOffset.UtcNow
            removeOldestPreview ()
            previews[value.View.Id] <- value)

    member _.ClaimPreview(id: Guid) : StoredPreview option =
        lock gate (fun () ->
            trim DateTimeOffset.UtcNow

            match previews.TryGetValue id with
            | true, value ->
                previews.Remove id |> ignore
                Some value
            | _ -> None)
