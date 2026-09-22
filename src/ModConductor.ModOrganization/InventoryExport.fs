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

[<RequireQualifiedAccess>]
type InventoryExportScope =
    | Selected
    | Enabled
    | CurrentQuery
    | All

[<RequireQualifiedAccess>]
type InventoryExportField =
    | ModId
    | Name
    | Kind
    | Status
    | Priority
    | Enabled
    | Version
    | Source
    | SourcePath
    | Notes
    | Comment
    | Categories

type InventoryExportCapture =
    { WorkspaceId: Guid
      WorkspaceRevision: int64
      ProfileId: Guid
      Scope: InventoryExportScope
      SelectedModIds: Guid list
      Query: ModQuery
      QueryIdentity: string
      CatalogueRevision: int64
      SelectionRevision: int64
      Fields: InventoryExportField list }

type PreparedInventoryExport =
    { Id: Guid
      RowCount: int
      Fields: InventoryExportField list }

type InventoryExportDestination =
    { Id: Guid
      FileName: string
      Exists: bool }

type InventoryExportProgress = { Written: int; Total: int }

type InventoryExportResult =
    { FileName: string
      RowCount: int
      Length: int64 }

[<RequireQualifiedAccess>]
type InventoryExportError =
    | InvalidRequest
    | NotFound
    | Stale
    | Busy
    | LimitExceeded
    | DestinationUnavailable
    | DestinationChanged
    | ReplacementRequired
    | Cancelled
    | WriteFailed

module InventoryExportCsv =
    let maximumRows = 100000
    let maximumBytes = 64L * 1024L * 1024L

    let fields =
        [ InventoryExportField.ModId
          InventoryExportField.Name
          InventoryExportField.Kind
          InventoryExportField.Status
          InventoryExportField.Priority
          InventoryExportField.Enabled
          InventoryExportField.Version
          InventoryExportField.Source
          InventoryExportField.SourcePath
          InventoryExportField.Notes
          InventoryExportField.Comment
          InventoryExportField.Categories ]

    let header =
        function
        | InventoryExportField.ModId -> "mod_id"
        | InventoryExportField.Name -> "name"
        | InventoryExportField.Kind -> "kind"
        | InventoryExportField.Status -> "status"
        | InventoryExportField.Priority -> "priority"
        | InventoryExportField.Enabled -> "enabled"
        | InventoryExportField.Version -> "version"
        | InventoryExportField.Source -> "source"
        | InventoryExportField.SourcePath -> "source_path"
        | InventoryExportField.Notes -> "notes"
        | InventoryExportField.Comment -> "comment"
        | InventoryExportField.Categories -> "categories"

    let canonical requested =
        let selected = Set.ofList requested
        fields |> List.filter (fun field -> Set.contains field selected)

    let private formulaPrefix (value: string) =
        let mutable index = 0

        while index < value.Length
              && int value[index] <= 0x7f
              && Char.IsWhiteSpace value[index] do
            index <- index + 1

        if index < value.Length && "=+-@".Contains value[index] then
            "'" + value
        else
            value

    let private quote (value: string) =
        "\"" + value.Replace("\"", "\"\"") + "\""

    let private kind =
        function
        | ModKind.Regular -> "regular"
        | ModKind.Separator -> "separator"
        | ModKind.Backup -> "backup"
        | ModKind.Unmanaged -> "unmanaged"
        | ModKind.GeneratedOutput -> "generated_output"

    let private status =
        function
        | InventoryStatus.Ready -> "ready"
        | InventoryStatus.Detached -> "detached"
        | InventoryStatus.Changed -> "changed"
        | InventoryStatus.Unproved -> "unproved"
        | InventoryStatus.Publishing -> "publishing"

    let private priority =
        function
        | SelectionState.Managed(value, _)
        | SelectionState.Separator value -> string (value + 1)
        | SelectionState.Locked _ -> ""

    let private enabled =
        function
        | SelectionState.Managed(_, value) -> if value then "true" else "false"
        | SelectionState.Separator _
        | SelectionState.Locked _ -> ""

    let private categories (values: CategoryReference list) =
        values
        |> List.sortBy _.Id
        |> List.map (fun value -> value.Label + " [" + value.Id.ToString("N") + "]")
        |> String.concat " | "

    let private value field (row: OrganizedMod) =
        let modValue = row.Entry.Mod

        match field with
        | InventoryExportField.ModId -> modValue.Id.ToString("N"), false
        | InventoryExportField.Name -> modValue.Metadata.Name, true
        | InventoryExportField.Kind -> kind modValue.Kind, false
        | InventoryExportField.Status -> status modValue.Status, false
        | InventoryExportField.Priority -> priority row.Entry.Selection, false
        | InventoryExportField.Enabled -> enabled row.Entry.Selection, false
        | InventoryExportField.Version -> modValue.Metadata.Version, true
        | InventoryExportField.Source -> modValue.Metadata.Source, true
        | InventoryExportField.SourcePath ->
            modValue.SourcePath |> Option.map LogicalPath.display |> Option.defaultValue "", true
        | InventoryExportField.Notes -> modValue.Metadata.Notes, true
        | InventoryExportField.Comment -> modValue.Metadata.Comment, true
        | InventoryExportField.Categories -> categories modValue.Metadata.Categories, true

    let private line values =
        values
        |> List.map (fun (value, untrusted) ->
            value |> (if untrusted then formulaPrefix else id) |> quote)
        |> String.concat ","

    let headerLine selected =
        selected |> List.map (header >> fun value -> value, false) |> line

    let rowLine selected row =
        selected |> List.map (fun field -> value field row) |> line

    let byteLength selected rows =
        let utf8 = UTF8Encoding(false, true)
        let mutable total = int64 (utf8.GetByteCount(headerLine selected) + 2)

        for row in rows do
            total <- total + int64 (utf8.GetByteCount(rowLine selected row) + 2)

        total

    let write
        (output: FileStream)
        selected
        rows
        (progress: InventoryExportProgress -> Task)
        (token: CancellationToken)
        =
        task {
            use writer = new StreamWriter(output, UTF8Encoding(false, true), 16384, true)
            writer.NewLine <- "\r\n"
            do! writer.WriteLineAsync((headerLine selected).AsMemory(), token)
            let mutable written = 0
            let total = List.length rows

            for row in rows do
                token.ThrowIfCancellationRequested()
                do! writer.WriteLineAsync((rowLine selected row).AsMemory(), token)
                written <- written + 1

                if written = total || written % 32 = 0 then
                    do! progress { Written = written; Total = total }

            do! writer.FlushAsync token
            return output.Position
        }

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

    let validateWorkspace capture =
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

    let queryFor capture =
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

    let drain capture =
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
