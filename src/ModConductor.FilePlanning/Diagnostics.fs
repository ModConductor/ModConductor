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

    let private code =
        function
        | PlanningIssue.IncompleteSelection -> "incomplete-selection"
        | PlanningIssue.DuplicateRoot _ -> "duplicate-root"
        | PlanningIssue.DuplicateLayer _ -> "duplicate-layer"
        | PlanningIssue.MissingVersion _ -> "missing-version"
        | PlanningIssue.WrongModVersion _ -> "wrong-version"
        | PlanningIssue.IncompleteManifest _ -> "incomplete-manifest"
        | PlanningIssue.IncompleteSnapshot _ -> "incomplete-game-files"
        | PlanningIssue.InvalidContent _ -> "invalid-content"
        | PlanningIssue.InconsistentPayload _ -> "inconsistent-content"
        | PlanningIssue.MissingTargetRoot _ -> "missing-target"
        | PlanningIssue.UnmappedFile _ -> "unmapped-file"
        | PlanningIssue.AmbiguousMapping _ -> "ambiguous-mapping"
        | PlanningIssue.FileMappedToRoot _ -> "file-at-root"
        | PlanningIssue.InvalidTargetName _ -> "invalid-target-name"
        | PlanningIssue.InvalidArchiveAnnotation _ -> "invalid-archive-source"
        | PlanningIssue.TargetAlias _ -> "target-alias"
        | PlanningIssue.PrecedenceTie _ -> "priority-tie"
        | PlanningIssue.DirectorySpellingTie _ -> "directory-name-tie"
        | PlanningIssue.FileDirectoryConflict _ -> "file-directory-conflict"
        | PlanningIssue.WritableDirectorySpellingTie _ -> "writable-name-tie"
        | PlanningIssue.DuplicateWritableId _ -> "duplicate-writable"
        | PlanningIssue.OverlappingWritableTargets _ -> "overlapping-writable"
        | PlanningIssue.WritableStructureConflict _ -> "writable-conflict"

    let private targetPath =
        function
        | PlanningIssue.InvalidTargetName(value, _)
        | PlanningIssue.TargetAlias(value, _)
        | PlanningIssue.PrecedenceTie(value, _)
        | PlanningIssue.DirectorySpellingTie(value, _)
        | PlanningIssue.FileDirectoryConflict value
        | PlanningIssue.WritableStructureConflict(_, value) -> Some value.Path
        | PlanningIssue.InvalidContent(_, value)
        | PlanningIssue.UnmappedFile(_, value)
        | PlanningIssue.AmbiguousMapping(_, value)
        | PlanningIssue.FileMappedToRoot(_, value)
        | PlanningIssue.InvalidArchiveAnnotation(_, value) -> Some value
        | PlanningIssue.IncompleteSelection
        | PlanningIssue.DuplicateRoot _
        | PlanningIssue.DuplicateLayer _
        | PlanningIssue.MissingVersion _
        | PlanningIssue.WrongModVersion _
        | PlanningIssue.IncompleteManifest _
        | PlanningIssue.IncompleteSnapshot _
        | PlanningIssue.InconsistentPayload _
        | PlanningIssue.MissingTargetRoot _
        | PlanningIssue.WritableDirectorySpellingTie _
        | PlanningIssue.DuplicateWritableId _
        | PlanningIssue.OverlappingWritableTargets _ -> None

    let private diagnosticSources (sources: PlanSources) =
        function
        | PlanningIssue.PrecedenceTie(_, contributions) ->
            let labels = sources.Mods |> Seq.map (fun value -> value.Id, value) |> Map.ofSeq

            contributions
            |> List.choose (fun contribution ->
                match contribution.Source with
                | SourcePin.Snapshot _ -> None
                | SourcePin.Mod(modId, versionId, entry) ->
                    let copy =
                        { ModId = modId
                          VersionId = versionId
                          Path = entry.Path }

                    let label = labels |> Map.tryFind modId

                    Some
                        { Copy = copy
                          Name = label |> Option.map _.Name |> Option.defaultValue "Saved mod"
                          VersionLabel =
                            label |> Option.map _.Version |> Option.defaultValue "Saved version"
                          Priority = contribution.Precedence.Priority
                          Hidden = sources.Hidden.Contains copy })
        | _ -> []

    let project sources issue =
        let code = code issue
        let path = targetPath issue

        { Id =
            match path with
            | Some path -> code + ":" + LogicalPath.display path
            | None -> code
          Code = code
          Title = describe issue
          Target = path
          Sources = diagnosticSources sources issue }
