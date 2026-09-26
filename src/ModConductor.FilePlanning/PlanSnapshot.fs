namespace ModConductor.FilePlanning

open System
open System.Collections.Generic
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
      DiagnosticProblems: FileDiagnosticProblem array
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
              Writable = sources.Writable }

        let visibility =
            Visibility.prepare
                { Planning = input
                  Hidden = sources.Hidden }

        let index = FileIndex.build sources visibility

        let issues = Diagnostics.issues visibility

        let problems =
            Array.ofList (
                (contextProblem sources |> Option.toList)
                @ (issues |> List.map Diagnostics.describe)
            )

        let diagnosticProblems =
            [ yield!
                  contextProblem sources
                  |> Option.map (fun title ->
                      { Id = "game-setup"
                        Code = "game-setup"
                        Title = title
                        Target = None
                        Sources = [] })
                  |> Option.toList
              yield! issues |> List.map (Diagnostics.project sources) ]
            |> Array.ofList

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

        if
            problems
            |> Array.exists (fun text -> Encoding.UTF8.GetByteCount text + 8 > Limits.pageBytes)
        then
            Error(FilePlanError.LimitExceeded "A file problem exceeds the reply limit.")
        elif bytes > Limits.snapshotBytes then
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
                  DiagnosticProblems = diagnosticProblems
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
                        DiagnosticProblems =
                            snapshot.DiagnosticProblems
                            |> Array.map (fun problem ->
                                { problem with
                                    Sources =
                                        problem.Sources
                                        |> List.map (fun source ->
                                            match
                                                labels
                                                |> List.tryFind (fun row ->
                                                    row.Id = source.Copy.ModId)
                                            with
                                            | Some label ->
                                                { source with
                                                    Name = label.Name
                                                    VersionLabel = label.Version }
                                            | None -> source) })
                        Index =
                            { snapshot.Index with
                                Labels = labels |> Seq.map (fun row -> row.Id, row) |> Map.ofSeq }
                        EncodedBytes = bytes }
