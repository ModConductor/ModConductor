namespace ModConductor.FilePlanning

open System
open ModConductor.Platform
open ModConductor.DeploymentPlanning

module Diagnostics =
    let private target (value: TargetFile) = LogicalPath.display value.Path

    let describe =
        function
        | PlanningIssue.IncompleteSelection -> "The profile selection is incomplete."
        | PlanningIssue.DuplicateRoot _ -> "The plan contains a repeated target root."
        | PlanningIssue.DuplicateLayer _ -> "The plan contains a repeated source."
        | PlanningIssue.MissingVersion id ->
            "An enabled mod has no saved version: " + id.ToString "N"
        | PlanningIssue.WrongModVersion _ -> "A saved version belongs to a different mod."
        | PlanningIssue.IncompleteManifest _ -> "A saved manifest is incomplete."
        | PlanningIssue.IncompleteSnapshot _ -> "Game-folder files are not loaded."
        | PlanningIssue.InvalidContent(_, path) ->
            "Content evidence is invalid for " + LogicalPath.display path + "."
        | PlanningIssue.InconsistentPayload _ -> "A payload has inconsistent content evidence."
        | PlanningIssue.MissingTargetRoot _ -> "A file mapping has no target root."
        | PlanningIssue.UnmappedFile(_, path) ->
            "No target exists for " + LogicalPath.display path + "."
        | PlanningIssue.AmbiguousMapping(_, path) ->
            "Multiple mappings apply to " + LogicalPath.display path + "."
        | PlanningIssue.FileMappedToRoot _ -> "A file cannot replace the Data directory."
        | PlanningIssue.InvalidTargetName(path, _) ->
            "The game cannot use the file name " + target path + "."
        | PlanningIssue.InvalidArchiveAnnotation _ -> "Archive information has an invalid source."
        | PlanningIssue.TargetAlias(path, entries) ->
            "Conflicting names for "
            + target path
            + ": "
            + (entries
               |> Seq.map (fun entry -> LogicalPath.display entry.MappedTarget.Path)
               |> Seq.distinct
               |> Seq.truncate 2
               |> String.concat " / ")
            + "."
        | PlanningIssue.PrecedenceTie(path, _) ->
            "Multiple sources have the same priority for " + target path + "."
        | PlanningIssue.DirectorySpellingTie(path, _) ->
            "Directory spelling is ambiguous for " + target path + "."
        | PlanningIssue.FileDirectoryConflict path ->
            "A file and directory share the target " + target path + "."
        | PlanningIssue.WritableDirectorySpellingTie(path, _) ->
            "Writable directory spelling is ambiguous for " + target path + "."
        | PlanningIssue.DuplicateWritableId _ -> "The plan repeats a writable destination."
        | PlanningIssue.OverlappingWritableTargets _ -> "Writable destinations overlap."
        | PlanningIssue.WritableStructureConflict(_, path) ->
            "A writable destination conflicts with " + target path + "."

    let issues visibility =
        match Visibility.original visibility with
        | PlanningResult.Ready _ -> []
        | PlanningResult.Blocked blocked -> blocked.Issues
