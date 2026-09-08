namespace ModConductor.FilePlanning

open System
open System.Collections.Generic
open System.IO
open System.Security.Cryptography
open System.Text
open ModConductor.Platform
open ModConductor.GameContexts
open ModConductor.DeploymentPlanning

type internal PlanSnapshot =
    { Id: Guid
      PagingId: Guid
      Sources: PlanSources
      Game: GameObservation option
      Visibility: FileVisibility
      Index: FileIndex
      Planned: int
      Problems: string array
      EncodedBytes: int64
      Queries: Dictionary<string, Map<LogicalPath option, LogicalPath array>> }

module internal PlanSnapshot =
    let private contextProblem (sources: PlanSources) =
        match sources.Context.Binding with
        | None -> Some "Select a game installation."
        | Some binding when binding.NeedsCheck || not binding.Evidence.Valid ->
            Some "Refresh the saved game installation."
        | Some binding when
            binding.Evidence.DefinitionId <> Skyrim.definition.Id
            || binding.Evidence.DefinitionRevision <> Skyrim.definition.Revision
            ->
            Some "Select a supported Skyrim installation."
        | Some binding when
            binding.Evidence.Platform = ContextPlatform.Proton
            && (binding.Proton.IsNone || binding.Evidence.Proton.IsNone)
            ->
            Some "Select and save the Proton data and runtime folders."
        | Some _ -> None

    let context (sources: PlanSources) =
        match contextProblem sources with
        | Some problem -> Error(FilePlanError.ContextUnavailable problem)
        | None -> Ok sources.Context.Binding.Value.Evidence

    let create (sources: PlanSources) (game: GameObservation option) =
        let root = sources.Stamp.WorkspaceId

        let snapshot =
            game
            |> Option.map _.Snapshot
            |> Option.defaultValue
                { Id = root
                  Generation = "Not loaded"
                  Kind = ReadOnlyLayerKind.Base
                  Priority = 0
                  Complete = false
                  Files = []
                  Mappings =
                    [ { SourcePrefix = PlanPath.Root
                        TargetRoot = root
                        TargetPrefix = PlanPath.Root } ]
                  Archives = [] }

        let input =
            { Profile = sources.Profile
              Roots =
                [ { Id = root
                    Policy = Skyrim.definition.TargetPolicy } ]
              ReadOnly = [ snapshot ]
              Writable = [] }

        let visibility =
            Visibility.prepare
                { Planning = input
                  Hidden = sources.Hidden }

        let index = FileIndex.build sources visibility

        let problems =
            Array.ofList (
                (contextProblem sources |> Option.toList)
                @ (Diagnostics.issues visibility |> List.map Diagnostics.describe)
            )

        let bytes =
            (problems
             |> Array.sumBy (fun text -> int64 (Encoding.UTF8.GetByteCount text + 8)))
            + index.EncodedBytes
            + (game |> Option.map _.EncodedBytes |> Option.defaultValue 0L)
            + (sources.Profile.Mods
               |> List.sumBy (fun row ->
                   row.Version
                   |> Option.map (fun version ->
                       version.Entries
                       |> List.sumBy (fun entry ->
                           int64 (
                               Encoding.UTF8.GetByteCount(LogicalPath.display entry.Path) + 256
                           )))
                   |> Option.defaultValue 0L))
            + (sources.Mods
               |> List.sumBy (fun row ->
                   int64 (
                       Encoding.UTF8.GetByteCount(row.Name)
                       + Encoding.UTF8.GetByteCount(row.Version)
                       + 128
                   )))

        if bytes > Limits.snapshotBytes then
            Error(FilePlanError.LimitExceeded "The file view exceeds the metadata limit.")
        else
            Ok
                { Id = Guid.NewGuid()
                  PagingId = Guid.NewGuid()
                  Sources = sources
                  Game = game
                  Visibility = visibility
                  Index = index
                  Problems = problems
                  Planned =
                    Visibility.files visibility
                    |> Map.toSeq
                    |> Seq.filter (snd >> Option.isSome)
                    |> Seq.length
                  EncodedBytes = bytes
                  Queries = Dictionary(StringComparer.Ordinal) }

    let withLabels (labels: ModLabel list) (snapshot: PlanSnapshot) =
        if labels = snapshot.Sources.Mods then
            Ok snapshot
        else
            let size rows =
                rows
                |> List.sumBy (fun (row: ModLabel) ->
                    int64 (
                        Encoding.UTF8.GetByteCount row.Name
                        + Encoding.UTF8.GetByteCount row.Version
                        + 128
                    ))

            let bytes = snapshot.EncodedBytes - size snapshot.Sources.Mods + size labels

            if bytes > Limits.snapshotBytes then
                Error(FilePlanError.LimitExceeded "The file labels exceed the metadata limit.")
            else
                Ok
                    { snapshot with
                        Id = Guid.NewGuid()
                        Sources = { snapshot.Sources with Mods = labels }
                        Index =
                            { snapshot.Index with
                                Labels = labels |> Seq.map (fun row -> row.Id, row) |> Map.ofSeq }
                        EncodedBytes = bytes }

    let summary stale (snapshot: PlanSnapshot) =
        let problems = snapshot.Problems

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
          Problems = problems |> Seq.truncate Limits.pageRows |> Seq.toList
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
                    Encoding.UTF8.GetByteCount(LogicalPath.display row.Path)
                    + Encoding.UTF8.GetByteCount row.SourceName
                    + 128)
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
