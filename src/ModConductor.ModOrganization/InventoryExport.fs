namespace ModConductor.ModOrganization

open System
open System.Collections.Generic
open System.Globalization
open System.IO
open System.Text
open System.Threading
open System.Threading.Tasks
open ModConductor.ModLibrary
open ModConductor.ModSelection
open ModConductor.Platform
open ModConductor.Workspaces

type private InventorySnapshot =
    { Id: Guid
      Created: DateTimeOffset
      Capture: InventoryExportCapture
      Fields: InventoryExportField list
      Rows: OrganizedMod list
      Destinations: Dictionary<Guid, AtomicOutputDestination>
      mutable Busy: bool
      mutable CancelRequested: bool
      mutable Cancellation: CancellationTokenSource option }

type InventoryExportSession
    (
        workspaces: IWorkspaceState,
        organization: IModOrganization,
        ?commitBoundary: AtomicOutputCommitBoundary
    ) =
    let gate = obj ()
    let snapshots = Dictionary<Guid, InventorySnapshot>()
    let lifetime = TimeSpan.FromMinutes 5.0

    let boundary =
        defaultArg
            commitBoundary
            { BeforeReplace = ignore
              AfterReplace = ignore }

    let removeExpired now =
        snapshots.Values
        |> Seq.filter (fun value -> now - value.Created > lifetime)
        |> Seq.map _.Id
        |> Seq.toList
        |> List.iter (fun id -> snapshots.Remove id |> ignore)

    let find id =
        lock gate (fun () ->
            removeExpired DateTimeOffset.UtcNow

            match snapshots.TryGetValue id with
            | true, value -> Some value
            | _ -> None)

    let validateWorkspace (capture: InventoryExportCapture) =
        task {
            let! current = workspaces.Read(capture.WorkspaceId, None)

            return
                match current with
                | Ok page when
                    page.Workspace.Revision = capture.WorkspaceRevision
                    && page.Workspace.SelectedProfile
                       |> Option.exists (fun profile -> profile.Id = capture.ProfileId)
                    ->
                    Ok()
                | Ok _ -> Error InventoryExportError.Stale
                | Error WorkspaceError.NotFound -> Error InventoryExportError.NotFound
                | Error _ -> Error InventoryExportError.Stale
        }

    let queryFor (capture: InventoryExportCapture) =
        let empty =
            { Text = ""
              Mode = FilterMode.All
              Filters = []
              View = OrganizationView.Flat
              Sort = OrganizationSort.Priority }

        match capture.Scope with
        | InventoryExportScope.Selected
        | InventoryExportScope.All -> empty
        | InventoryExportScope.Enabled ->
            { empty with
                Filters = [ ModFilter.Enabled(Some true) ] }
        | InventoryExportScope.CurrentQuery ->
            { capture.Query with
                View = OrganizationView.Flat
                Sort = OrganizationSort.Priority }

    let drain (capture: InventoryExportCapture) =
        task {
            match OrganizationPolicy.normalize capture.Query with
            | Error _ -> return Error InventoryExportError.InvalidRequest
            | Ok normalized when
                OrganizationPolicy.identity capture.ProfileId normalized
                <> capture.QueryIdentity
                ->
                return Error InventoryExportError.Stale
            | Ok _ ->
                let rows = ResizeArray<OrganizedMod>()
                let mutable cursor = None
                let mutable complete = false
                let mutable failed = None

                while not complete && failed.IsNone do
                    let! page =
                        organization.Query(capture.ProfileId, queryFor capture, cursor, None)

                    match page with
                    | Error LibraryError.NotFound -> failed <- Some InventoryExportError.NotFound
                    | Error LibraryError.StaleRevision -> failed <- Some InventoryExportError.Stale
                    | Error LibraryError.LimitExceeded ->
                        failed <- Some InventoryExportError.LimitExceeded
                    | Error _ -> failed <- Some InventoryExportError.InvalidRequest
                    | Ok page when
                        page.CatalogueRevision <> capture.CatalogueRevision
                        || page.SelectionRevision <> capture.SelectionRevision
                        ->
                        failed <- Some InventoryExportError.Stale
                    | Ok page ->
                        rows.AddRange page.Entries

                        if rows.Count > InventoryExportCsv.maximumRows then
                            failed <- Some InventoryExportError.LimitExceeded
                        else
                            match page.Next with
                            | Some next when
                                cursor
                                |> Option.exists (fun previous -> next.Offset <= previous.Offset)
                                ->
                                failed <- Some InventoryExportError.Stale
                            | Some next -> cursor <- Some next
                            | None -> complete <- true

                match failed with
                | Some error -> return Error error
                | None ->
                    let values = List.ofSeq rows

                    if capture.Scope = InventoryExportScope.Selected then
                        let selected = Set.ofList capture.SelectedModIds

                        let available =
                            values |> List.map (fun row -> row.Entry.Mod.Id) |> Set.ofList

                        if
                            selected.IsEmpty
                            || selected.Count <> capture.SelectedModIds.Length
                            || not (Set.isSubset selected available)
                        then
                            return Error InventoryExportError.Stale
                        else
                            return
                                Ok(
                                    values
                                    |> List.filter (fun row ->
                                        Set.contains row.Entry.Mod.Id selected)
                                )
                    else
                        return Ok values
        }

    member _.Prepare(capture: InventoryExportCapture) =
        task {
            let fields = InventoryExportCsv.canonical capture.Fields

            if
                fields.IsEmpty
                || (not (List.contains InventoryExportField.ModId fields)
                    && not (List.contains InventoryExportField.Name fields))
                || capture.QueryIdentity.Length <> 64
                || capture.SelectedModIds.Length > InventoryExportCsv.maximumRows
                || (capture.Scope = InventoryExportScope.Selected && capture.SelectedModIds.IsEmpty)
            then
                return Error InventoryExportError.InvalidRequest
            else
                match! validateWorkspace capture with
                | Error error -> return Error error
                | Ok() ->
                    match! drain capture with
                    | Error error -> return Error error
                    | Ok rows ->
                        let length = InventoryExportCsv.byteLength fields rows

                        if length > InventoryExportCsv.maximumBytes then
                            return Error InventoryExportError.LimitExceeded
                        else
                            let snapshot =
                                { Id = Guid.NewGuid()
                                  Created = DateTimeOffset.UtcNow
                                  Capture = capture
                                  Fields = fields
                                  Rows = rows
                                  Destinations = Dictionary()
                                  Busy = false
                                  CancelRequested = false
                                  Cancellation = None }

                            lock gate (fun () ->
                                removeExpired DateTimeOffset.UtcNow

                                if snapshots.Count >= 4 then
                                    snapshots.Values
                                    |> Seq.filter (fun value -> not value.Busy)
                                    |> Seq.sortBy _.Created
                                    |> Seq.tryHead
                                    |> Option.iter (fun value ->
                                        snapshots.Remove value.Id |> ignore)

                                if snapshots.Count < 4 then
                                    snapshots.Add(snapshot.Id, snapshot))

                            if find snapshot.Id |> Option.isNone then
                                return Error InventoryExportError.Busy
                            else
                                return
                                    Ok
                                        { Id = snapshot.Id
                                          RowCount = rows.Length
                                          Fields = fields }
        }

    member _.Inspect(id, path: HostPath) =
        task {
            let claimed =
                lock gate (fun () ->
                    removeExpired DateTimeOffset.UtcNow

                    match snapshots.TryGetValue id with
                    | true, snapshot when not snapshot.Busy ->
                        snapshot.Busy <- true
                        Some snapshot
                    | _ -> None)

            match claimed with
            | None ->
                return
                    if find id |> Option.isSome then
                        Error InventoryExportError.Busy
                    else
                        Error InventoryExportError.NotFound
            | Some snapshot ->
                try
                    match AtomicOutput.inspect path with
                    | Error AtomicOutputError.DestinationChanged ->
                        return Error InventoryExportError.DestinationChanged
                    | Error _ -> return Error InventoryExportError.DestinationUnavailable
                    | Ok destination ->
                        lock gate (fun () ->
                            snapshot.Destinations.Clear()
                            snapshot.Destinations.Add(destination.Id, destination))

                        return
                            Ok
                                { Id = destination.Id
                                  FileName = destination.FileName
                                  Exists = destination.Exists }
                finally
                    lock gate (fun () -> snapshot.Busy <- false)
        }

    member _.Write
        (
            id,
            destinationId,
            replace,
            progress: InventoryExportProgress -> Task,
            token: CancellationToken
        ) =
        task {
            let claimed =
                lock gate (fun () ->
                    match find id with
                    | Some snapshot when not snapshot.Busy ->
                        match snapshot.Destinations.TryGetValue destinationId with
                        | true, destination ->
                            let cancellation =
                                CancellationTokenSource.CreateLinkedTokenSource token

                            snapshot.Cancellation <- Some cancellation

                            if snapshot.CancelRequested then
                                cancellation.Cancel()

                            snapshot.Busy <- true
                            Some(snapshot, destination, cancellation)
                        | _ -> None
                    | _ -> None)

            match claimed with
            | None -> return Error InventoryExportError.Busy
            | Some(snapshot, destination, cancellation) ->
                let mutable terminal = false

                try
                    match! validateWorkspace snapshot.Capture with
                    | Error error ->
                        terminal <- true
                        return Error error
                    | Ok() ->
                        match! drain snapshot.Capture with
                        | Error error ->
                            terminal <- true
                            return Error error
                        | Ok current when current <> snapshot.Rows ->
                            terminal <- true
                            return Error InventoryExportError.Stale
                        | Ok _ ->
                            let! result =
                                AtomicOutput.writeWithBoundary
                                    boundary
                                    destination
                                    replace
                                    (fun output cancellation ->
                                        InventoryExportCsv.write
                                            output
                                            snapshot.Fields
                                            snapshot.Rows
                                            progress
                                            cancellation)
                                    cancellation.Token

                            match result with
                            | Ok value ->
                                terminal <- true

                                return
                                    Ok
                                        { FileName = destination.FileName
                                          RowCount = snapshot.Rows.Length
                                          Length = value.Length }
                            | Error AtomicOutputError.ReplacementRequired ->
                                return Error InventoryExportError.ReplacementRequired
                            | Error AtomicOutputError.DestinationChanged ->
                                return Error InventoryExportError.DestinationChanged
                            | Error AtomicOutputError.Cancelled ->
                                terminal <- true
                                return Error InventoryExportError.Cancelled
                            | Error AtomicOutputError.InvalidPath
                            | Error AtomicOutputError.ParentUnavailable
                            | Error AtomicOutputError.UnsupportedDestination ->
                                return Error InventoryExportError.DestinationUnavailable
                            | Error AtomicOutputError.WriteFailed ->
                                return Error InventoryExportError.WriteFailed
                finally
                    lock gate (fun () ->
                        snapshot.Busy <- false
                        snapshot.CancelRequested <- false
                        snapshot.Cancellation <- None

                        if terminal then
                            snapshots.Remove snapshot.Id |> ignore)

                    cancellation.Dispose()
        }

    member _.Cancel id =
        let found, cancellation =
            lock gate (fun () ->
                removeExpired DateTimeOffset.UtcNow

                match snapshots.TryGetValue id with
                | true, snapshot ->
                    snapshot.CancelRequested <- true
                    true, snapshot.Cancellation
                | _ -> false, None)

        cancellation |> Option.iter _.Cancel()
        found

    member _.Discard id =
        lock gate (fun () ->
            match snapshots.TryGetValue id with
            | true, snapshot when not snapshot.Busy -> snapshots.Remove id
            | _ -> false)
