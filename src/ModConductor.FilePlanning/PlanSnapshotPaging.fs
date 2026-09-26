namespace ModConductor.FilePlanning

open System
open System.IO
open System.Security.Cryptography
open System.Text
open ModConductor.Platform
open ModConductor.DeploymentPlanning

module internal PlanSnapshotPaging =
    let pathBytes path =
        LogicalPath.components path
        |> List.sumBy (fun part -> Encoding.UTF8.GetByteCount part + 4)


    let summary stale (snapshot: PlanSnapshot) =
        let problems = snapshot.Problems
        let mutable bytes = 0

        let preview =
            problems
            |> Seq.truncate Limits.pageRows
            |> Seq.takeWhile (fun text ->
                bytes <- bytes + Encoding.UTF8.GetByteCount text + 8
                bytes <= Limits.pageBytes)
            |> Seq.toList

        { Id = snapshot.Id
          WorkspaceId = snapshot.Sources.Stamp.WorkspaceId
          ProfileId = snapshot.Sources.Stamp.ProfileId
          Fingerprint = Visibility.fingerprint snapshot.Visibility
          Loaded = snapshot.Game.IsSome
          Stale = stale
          PlannedFiles = if Array.isEmpty problems then snapshot.Planned else 0
          AbsentTargets =
            if Array.isEmpty problems then
                snapshot.Index.Targets.Count - snapshot.Planned
            else
                0
          InspectedFiles = snapshot.Index.Targets.Count
          Problems = preview
          ProblemCount = problems.Length
          ObservedAt = snapshot.Game |> Option.map _.ObservedAt }

    let queryIdentity (snapshot: PlanSnapshot) kind parent (query: string) =
        use data = new MemoryStream()
        use writer = new BinaryWriter(data, Encoding.UTF8, true)
        writer.Write(snapshot.PagingId.ToString "N")
        writer.Write(kind: string)
        writer.Write(query.Trim())

        match parent with
        | None -> writer.Write 0
        | Some path ->
            let parts = LogicalPath.components path
            writer.Write parts.Length

            for name in parts do
                writer.Write name

        writer.Flush()

        SHA256.HashData(data.GetBuffer().AsSpan(0, int data.Length))
        |> Convert.ToHexStringLower

    let page identity (cursor: FileCursor option) size count project =
        let offset = cursor |> Option.map _.Offset |> Option.defaultValue 0

        if
            offset < 0
            || offset > count
            || (cursor |> Option.exists (fun c -> c.Identity <> identity))
        then
            Error FilePlanError.Stale
        else
            let mutable bytes = 0
            let mutable position = offset
            let selected = ResizeArray<_>()
            let mutable fits = true

            while fits && position < count && selected.Count < Limits.pageRows do
                let row = project position
                let rowBytes = size row

                if bytes + rowBytes > Limits.pageBytes then
                    fits <- false
                else
                    bytes <- bytes + rowBytes
                    selected.Add row
                    position <- position + 1

            if selected.Count = 0 && offset < count then
                Error(FilePlanError.LimitExceeded "A file record exceeds the reply limit.")
            else
                Ok(
                    List.ofSeq selected,
                    if position < count then
                        Some
                            { Identity = identity
                              Offset = position }
                    else
                        None
                )

    let children parent (query: string) cursor (snapshot: PlanSnapshot) =
        let query = query.Trim()

        if query.Length > 4096 then
            Error(FilePlanError.LimitExceeded "The file filter is too long.")
        else
            let identity = queryIdentity snapshot "children" parent query

            let included =
                lock snapshot.Queries (fun () ->
                    match snapshot.Queries.TryGetValue query with
                    | true, values -> values
                    | false, _ ->
                        let values =
                            if query = "" then
                                snapshot.Index.Children
                            else
                                FileIndex.matching snapshot.Index query

                        if snapshot.Queries.Count >= 2 then
                            snapshot.Queries.Clear()

                        snapshot.Queries.Add(query, values)
                        values)

            let paths = included.TryFind parent |> Option.defaultValue [||]

            page
                identity
                cursor
                (fun (row: FileNode) ->
                    pathBytes row.Path + Encoding.UTF8.GetByteCount row.SourceName + 128)
                paths.Length
                (fun index ->
                    FileIndex.node snapshot.Sources snapshot.Visibility snapshot.Index paths[index])

    let problems cursor (snapshot: PlanSnapshot) =
        page
            (queryIdentity snapshot "problems" None "")
            cursor
            (fun text -> Encoding.UTF8.GetByteCount(text: string) + 8)
            snapshot.Problems.Length
            (fun index -> snapshot.Problems[index])

    let diagnosticProblems (snapshot: PlanSnapshot) =
        snapshot.DiagnosticProblems |> Array.truncate Limits.pageRows |> Array.toList

    let historyPage (changes: FileChange list) =
        let values = List.toArray changes

        page
            "history"
            None
            (fun (change: FileChange) -> pathBytes change.Copy.Path + 512)
            values.Length
            (fun index -> values[index])
        |> Result.map (fun (included, next) ->
            { Changes = included
              NextBeforeId =
                if next.IsSome || values.Length = Limits.pageRows then
                    included |> List.tryLast |> Option.map _.Id
                else
                    None })
