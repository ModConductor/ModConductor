namespace ModConductor.DeploymentPlanning

open System
open System.Collections.Generic
open ModConductor.Platform

/// A read location, not a full-content pin and never a deployment input.
type ObservedFileSource =
    { Root: HostPath
      RootIdentity: FileIdentity
      Path: LogicalPath
      Identity: FileIdentity }

type ObservedCandidate =
    { Target: LogicalPath
      Source: ObservedFileSource }

[<RequireQualifiedAccess>]
type CandidateSource =
    | Pinned of SourcePin
    | Observed of ObservedFileSource

type CandidateProblem =
    { Target: TargetFile
      Sources: FileContribution<CandidateSource> list
      Detail: string }

type CandidatePlan =
    { Files: ResolvedTarget<CandidateSource> list
      Problems: CandidateProblem list
      InputProblems: PlanningIssue list }

module Candidates =
    let private path =
        function
        | CandidateSource.Pinned pin -> PlanningPaths.sourcePath pin
        | CandidateSource.Observed source -> source.Path

    /// Uses the deployable planner's mapping and winner rules without inventing content hashes.
    let resolve (input: VisibilityInput) observedRoot (observed: ObservedCandidate list) =
        let roots, managed, inputIssues = InputProjection.project input.Planning

        for candidate in observed do
            match roots.TryGetValue observedRoot with
            | true, policy ->
                match TargetPolicy.problems policy candidate.Target with
                | [] -> ()
                | problems ->
                    inputIssues.Add(
                        PlanningIssue.InvalidTargetName(
                            { Root = observedRoot
                              Path = candidate.Target },
                            problems
                        )
                    )
            | false, _ -> inputIssues.Add(PlanningIssue.MissingTargetRoot observedRoot)

        let contributions =
            (managed
             |> List.map (fun source ->
                 { LayerId = source.LayerId
                   Precedence = source.Precedence
                   Source = CandidateSource.Pinned source.Source
                   MappedTarget = source.MappedTarget
                   Archives = source.Archives }))
            @ (observed
               |> List.filter (fun source ->
                   roots.ContainsKey observedRoot
                   && (TargetPolicy.problems roots[observedRoot] source.Target).IsEmpty)
               |> List.map (fun source ->
                   { LayerId = observedRoot
                     Precedence = { Tier = LayerTier.Base; Priority = 0 }
                     Source = CandidateSource.Observed source.Source
                     MappedTarget =
                       { Root = observedRoot
                         Path = source.Target }
                     Archives = [] }))

        let issues = ResizeArray()
        let files, _ = TargetResolution.resolveCore path roots contributions issues

        let eligible (source: FileContribution<CandidateSource>) =
            match source.Source with
            | CandidateSource.Pinned pin -> Visibility.eligible input.Hidden pin
            | CandidateSource.Observed _ -> true

        let visible =
            files
            |> List.choose (fun file ->
                TargetResolution.select file.Target eligible (file.Winner :: file.Alternatives))

        let problems =
            issues
            |> Seq.map (function
                | ResolutionIssue.TargetAlias(target, sources) ->
                    { Target = target
                      Sources = sources
                      Detail = "Multiple file names identify the same plugin." }
                | ResolutionIssue.PrecedenceTie(target, sources) ->
                    { Target = target
                      Sources = sources
                      Detail = "Multiple sources have the same priority." }
                | ResolutionIssue.DirectorySpellingTie(target, sources) ->
                    { Target = target
                      Sources = sources
                      Detail = "The source directory spelling is ambiguous." }
                | ResolutionIssue.FileDirectoryConflict target ->
                    { Target = target
                      Sources = []
                      Detail = "A file and directory share this name." })
            |> Seq.toList

        let writable, readOnly =
            visible
            |> List.partition (fun file ->
                input.Planning.Writable
                |> List.exists (fun declaration ->
                    WritableResolution.covers roots[file.Target.Root] declaration file.Target))

        let writableProblems =
            writable
            |> List.map (fun file ->
                { Target = file.Target
                  Sources = file.Winner :: file.Alternatives
                  Detail = "A writable plugin source cannot be inspected here." })

        let grouped =
            roots
            |> Seq.map (fun pair -> pair.Key, PlanningPaths.table<CandidateProblem> pair.Value)
            |> Map.ofSeq

        for problem in problems @ writableProblems do
            let table = grouped[problem.Target.Root]
            let key = PlanningPaths.key roots[problem.Target.Root] problem.Target.Path

            match table.TryGetValue key with
            | false, _ -> table.Add(key, problem)
            | true, previous ->
                table[key] <-
                    { previous with
                        Sources = List.distinct (previous.Sources @ problem.Sources)
                        Detail =
                            String.concat " " (List.distinct [ previous.Detail; problem.Detail ]) }

        { Files =
            readOnly
            |> List.filter (fun file ->
                not (
                    grouped[file.Target.Root]
                        .ContainsKey(PlanningPaths.key roots[file.Target.Root] file.Target.Path)
                ))
          Problems =
            grouped
            |> Map.toList
            |> List.collect (fun (_, table) -> List.ofSeq table.Values)
          InputProblems = List.ofSeq inputIssues }
