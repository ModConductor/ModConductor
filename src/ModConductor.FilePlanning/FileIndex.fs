namespace ModConductor.FilePlanning

open System
open System.Collections.Generic
open System.Text
open ModConductor.Platform
open ModConductor.DeploymentPlanning
open ModConductor.ModLibrary

type internal CopyRecord =
    { Entry: ManifestEntry
      Priority: int
      Enabled: bool }

/// Immutable target and copy identity indexes are shared by visibility-only transitions.
type internal FileIndex =
    { Directories: Set<LogicalPath>
      Targets: Set<LogicalPath>
      Writable: Set<LogicalPath>
      Copies: Map<LogicalPath, ModFile array>
      CopyTargets: Map<ModFile, LogicalPath>
      Children: Map<LogicalPath option, LogicalPath array>
      Parents: Map<LogicalPath, LogicalPath option>
      Records: Map<ModFile, CopyRecord>
      Labels: Map<Guid, ModLabel>
      EncodedBytes: int64 }

module internal FileIndex =
    let build (sources: PlanSources) visibility =
        let policy = ModConductor.GameContexts.Skyrim.definition.TargetPolicy
        let canonical = Dictionary<string, LogicalPath>(TargetPolicy.comparer policy)
        let folders = HashSet<LogicalPath>()
        let targets = HashSet<LogicalPath>()
        let copies = Dictionary<LogicalPath, ResizeArray<ModFile>>()
        let records = ResizeArray<ModFile * CopyRecord>()
        let labels = sources.Mods |> Seq.map (fun row -> row.Id, row) |> Map.ofSeq
        let copyTargets = ResizeArray<ModFile * LogicalPath>()

        let register path =
            let key = TargetPolicy.key policy path

            match canonical.TryGetValue key with
            | true, path -> path
            | false, _ ->
                canonical.Add(key, path)
                path

        let original =
            match Visibility.original visibility with
            | PlanningResult.Ready plan -> Planner.view plan
            | PlanningResult.Blocked blocked -> blocked.Draft

        for path in original.Directories do
            folders.Add(register path.Path) |> ignore

        for file in original.ReadOnlyFiles do
            targets.Add(register file.Target.Path) |> ignore

        for layer in sources.Profile.Mods do
            match layer.Version with
            | None -> ()
            | Some version ->
                for entry in version.Entries do
                    let target = register entry.Path

                    let id =
                        { ModId = layer.ModId
                          VersionId = version.Id
                          Path = entry.Path }

                    records.Add(
                        id,
                        { Entry = entry
                          Priority = layer.Priority
                          Enabled = layer.Enabled }
                    )

                    copyTargets.Add(id, target)

                    if not (copies.ContainsKey target) then
                        copies.Add(target, ResizeArray())

                    copies[target].Add id

                    if layer.Enabled then
                        targets.Add target |> ignore

        let writable =
            sources.Writable
            |> List.choose (fun declaration ->
                match declaration.Target with
                | WritableTarget.File(_, path) -> Some(register path)
                | WritableTarget.Subtree _ -> None)
            |> Set.ofList

        for path in writable do
            targets.Add path |> ignore

        for path in targets do
            let parts = LogicalPath.components path

            for length in 1 .. parts.Length - 1 do
                let path =
                    LogicalPath.create (parts |> List.take length)
                    |> Result.defaultWith (fun _ -> invalidOp "A prefix must be a logical path.")

                folders.Add(register path) |> ignore

        let all = Set.union (Set.ofSeq folders) (Set.ofSeq targets)

        let parents =
            all
            |> Seq.map (fun path ->
                let parts = LogicalPath.components path

                path,
                (if parts.Length = 1 then
                     None
                 else
                     LogicalPath.create (List.take (parts.Length - 1) parts)
                     |> Result.toOption
                     |> Option.map register))
            |> Map.ofSeq

        let children =
            all
            |> Seq.groupBy (fun path -> parents[path])
            |> Seq.map (fun (parent, children) ->
                parent,
                children
                |> Seq.sortWith (fun a b ->
                    let folder = compare (not (folders.Contains a)) (not (folders.Contains b))

                    if folder <> 0 then
                        folder
                    else
                        StringComparer.Ordinal.Compare(
                            LogicalPath.display a,
                            LogicalPath.display b
                        ))
                |> Seq.toArray)
            |> Map.ofSeq

        let records = Map.ofSeq records

        { Directories = Set.ofSeq folders
          Targets = Set.ofSeq targets
          Writable = writable
          Copies =
            copies
            |> Seq.map (fun pair ->
                pair.Key,
                pair.Value |> Seq.sortBy (fun id -> -records[id].Priority, id) |> Seq.toArray)
            |> Map.ofSeq
          CopyTargets = Map.ofSeq copyTargets
          Children = children
          Parents = parents
          Records = records
          Labels = labels
          EncodedBytes =
            all
            |> Seq.sumBy (fun path ->
                int64 (Encoding.UTF8.GetByteCount(LogicalPath.display path) + 128)) }

    let node (sources: PlanSources) visibility (index: FileIndex) path =
        let resolved =
            Visibility.files visibility
            |> Map.tryFind
                { Root = sources.Stamp.WorkspaceId
                  Path = path }
            |> Option.flatten

        let label id =
            index.Labels.TryFind id
            |> Option.map (fun row -> row.Name)
            |> Option.defaultValue "Mod"

        { Path = path
          Directory = index.Directories.Contains path
          Disposition =
            if not (Diagnostics.issues visibility).IsEmpty then
                FileDisposition.Unresolved
            elif index.Writable.Contains path then
                FileDisposition.Writable
            elif resolved.IsSome then
                FileDisposition.Planned
            else
                FileDisposition.Absent
          SourceName =
            if index.Writable.Contains path then
                "Writable file"
            else
                resolved
                |> Option.map (fun file ->
                    match file.Winner.Source with
                    | SourcePin.Mod(id, _, _) -> label id
                    | SourcePin.Snapshot _ -> "Game folder")
                |> Option.defaultValue ""
          Copies =
            (index.Copies.TryFind path |> Option.defaultValue [||]).Length
            + (Visibility.sources
                { Root = sources.Stamp.WorkspaceId
                  Path = path }
                visibility
               |> List.filter (fun entry ->
                   match entry.Source with
                   | SourcePin.Snapshot _ -> true
                   | SourcePin.Mod _ -> false)
               |> List.length) }

    let matching (index: FileIndex) (query: string) =
        let included = HashSet<LogicalPath>()

        for path in index.Targets do
            if (LogicalPath.display path).Contains(query, StringComparison.OrdinalIgnoreCase) then
                let mutable next = Some path

                while next.IsSome do
                    let path = next.Value

                    if included.Add path then
                        next <- index.Parents[path]
                    else
                        next <- None

        index.Children
        |> Map.map (fun _ children -> children |> Array.filter included.Contains)
