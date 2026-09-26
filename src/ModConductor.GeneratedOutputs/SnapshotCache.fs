namespace ModConductor.GeneratedOutputs

open System
open System.Collections.Generic
open ModConductor.Platform

type internal OutputQuery =
    { Identity: string
      Entries: OutputObservation array
      Files: int
      Unreviewed: int }

type internal CachedOutput =
    { Snapshot: OutputSnapshot
      Files: OutputObservation list
      Index: Map<Guid * LogicalPath, OutputObservation>
      Bytes: int64
      mutable Query: OutputQuery option }

type internal OutputSnapshotCache(gate: obj) =
    let snapshots = Dictionary<Guid, CachedOutput>()
    let order = Queue<Guid>()

    let queryIdentity view query =
        (match view with
         | OutputView.ToolOutputs -> "tools:"
         | OutputView.WritableFiles -> "writable:")
        + query

    let matchingFiles (value: CachedOutput) view (query: string) =
        let included (observation: OutputObservation) =
            let purposeMatches =
                match observation.Backing.Location.Purpose, view with
                | OutputPurpose.ToolFolder, OutputView.ToolOutputs
                | OutputPurpose.WritableFile _, OutputView.WritableFiles -> true
                | _ -> false

            purposeMatches
            && String
                .Join("/", LogicalPath.components observation.File.Path)
                .Contains(query, StringComparison.OrdinalIgnoreCase)

        let files = value.Files |> List.filter included |> List.toArray

        { Identity = queryIdentity view query
          Entries = files
          Files = files |> Array.filter (fun file -> file.File.Identity.IsSome) |> Array.length
          Unreviewed =
            files
            |> Array.filter (fun file ->
                file.File.State = OutputFileState.New
                || file.File.State = OutputFileState.Changed)
            |> Array.length }

    member _.Find(id) =
        lock gate (fun () ->
            match snapshots.TryGetValue id with
            | true, value -> Ok value
            | _ -> Error OutputError.Stale)

    member this.Select(snapshot, selected, action) =
        OutputPolicy.selection selected
        |> Result.bind (fun selected ->
            this.Find snapshot
            |> Result.bind (fun value ->
                this.SelectFiles(value, selected, action)
                |> Result.map (fun files -> value, files)))

    member _.SelectFiles(value: CachedOutput, selected, action) =
        match OutputPolicy.action value.Snapshot.Scope.Locations selected action with
        | Error error -> Error error
        | Ok() ->
            let files =
                selected
                |> List.choose (fun file -> value.Index.TryFind(file.LocationId, file.Path))

            if files.Length <> selected.Length then
                Error OutputError.Stale
            elif files |> List.exists (fun file -> file.File.Identity.IsNone) then
                Error(OutputError.Invalid "Select files that are present.")
            else
                Ok files

    member _.Page(value: CachedOutput, view, cursor, filter) =
        OutputPaging.query filter
        |> Result.bind (fun query ->
            let identity = queryIdentity view query

            let matching =
                lock gate (fun () ->
                    match value.Query with
                    | Some previous when previous.Identity = identity -> previous
                    | _ ->
                        let matching = matchingFiles value view query
                        value.Query <- Some matching
                        matching)

            OutputPaging.page
                value.Snapshot
                matching.Entries
                matching.Identity
                matching.Files
                matching.Unreviewed
                cursor)

    member _.Remember(value) =
        lock gate (fun () ->
            let bytes () = snapshots.Values |> Seq.sumBy _.Bytes

            let count () =
                snapshots.Values
                |> Seq.filter (fun cached ->
                    cached.Snapshot.Scope.WorkspaceId = value.Snapshot.Scope.WorkspaceId)
                |> Seq.length

            while order.Count > 0
                  && (snapshots.Count >= 8
                      || count () >= 2
                      || bytes () + value.Bytes > OutputLimits.cache) do
                snapshots.Remove(order.Dequeue()) |> ignore

            snapshots.Add(value.Snapshot.Id, value)
            order.Enqueue value.Snapshot.Id)

    member _.Clear() = snapshots.Clear()
