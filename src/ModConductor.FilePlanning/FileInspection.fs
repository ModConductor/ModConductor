namespace ModConductor.FilePlanning

open System.Text
open ModConductor.Platform
open ModConductor.GameContexts
open ModConductor.DeploymentPlanning

module internal InspectionProjection =
    let size (row: InspectedCopy) =
        Encoding.UTF8.GetByteCount row.Name
        + Encoding.UTF8.GetByteCount row.VersionLabel
        + PlanSnapshotPaging.pathBytes row.SourcePath
        + (row.Copy
           |> Option.map (fun copy -> PlanSnapshotPaging.pathBytes copy.Path)
           |> Option.defaultValue 0)
        + 512

    let bounded (inspection: FileInspection) =
        if
            (inspection.FocusedCopy |> Option.exists (fun row -> size row > Limits.pageBytes))
            || (inspection.Copies |> List.exists (fun row -> size row > Limits.pageBytes))
        then
            Error(FilePlanError.LimitExceeded "A file record exceeds the reply limit.")
        else
            Ok inspection

    let private inspectionRow
        (snapshot: PlanSnapshot)
        (target: LogicalPath)
        (value: Choice<ModFile, SourcePin * SnapshotFile>)
        =
        let invalid = snapshot.Problems.Length <> 0
        let writable = snapshot.Index.Writable.Contains target

        let winner =
            Visibility.files snapshot.Visibility
            |> Map.tryFind
                { Root = snapshot.Sources.Stamp.WorkspaceId
                  Path = target }
            |> Option.flatten
            |> Option.map _.Winner.Source

        match value with
        | Choice1Of2 id ->
            let row = snapshot.Index.Records[id]
            let label = snapshot.Index.Labels[id.ModId]
            let hidden = (Visibility.hidden snapshot.Visibility).Contains id

            { Source =
                FilePreviewSource.ManagedCopy
                    { Copy = id
                      SourcePath = id.Path
                      Target = target
                      PayloadId = row.Entry.Payload.Id
                      Length = row.Entry.Payload.Length
                      Sha256 = row.Entry.Payload.Sha256
                      ModRevision = label.Revision }
              Standing =
                if
                    not invalid
                    && not writable
                    && winner = Some(SourcePin.Mod(id.ModId, id.VersionId, row.Entry))
                then
                    FileSourceStanding.Winner
                elif hidden || not row.Enabled then
                    FileSourceStanding.Unavailable
                else
                    FileSourceStanding.Alternative
              Copy = Some id
              SourcePath = id.Path
              Name = label.Name
              VersionLabel = label.Version
              Priority = Some row.Priority
              Enabled = row.Enabled
              Hidden = hidden
              Winner =
                not invalid
                && not writable
                && winner = Some(SourcePin.Mod(id.ModId, id.VersionId, row.Entry))
              Historical = false
              Length = row.Entry.Payload.Length
              Sha256 = Some row.Entry.Payload.Sha256
              CanHide =
                not hidden
                && not invalid
                && (TargetPolicy.problems Skyrim.definition.TargetPolicy id.Path).IsEmpty
              CanUnhide = hidden }
        | Choice2Of2(source, file) ->
            let snapshotId, generation, kind =
                match source with
                | SourcePin.Snapshot(id, generation, pinned) when pinned = file ->
                    id, generation, ReadOnlyLayerKind.Base
                | _ -> invalidOp "Expected a checked game-file source."

            { Source =
                FilePreviewSource.CheckedGameFile
                    { SnapshotId = snapshotId
                      Generation = generation
                      Kind = kind
                      SourcePath = file.Path
                      Target = target
                      Length = SnapshotFile.length file }
              Standing =
                if not invalid && not writable && winner = Some source then
                    FileSourceStanding.Winner
                else
                    FileSourceStanding.Alternative
              Copy = None
              SourcePath = file.Path
              Name = "Game folder"
              VersionLabel = ""
              Priority = None
              Enabled = true
              Hidden = false
              Winner = not invalid && not writable && winner = Some source
              Historical = false
              Length = SnapshotFile.length file
              Sha256 = None
              CanHide = false
              CanUnhide = false }

    let inspectCopy target copy snapshot =
        inspectionRow snapshot target (Choice1Of2 copy)

    let inspect target cursor (snapshot: PlanSnapshot) =
        let sources = snapshot.Sources
        let modCopies = snapshot.Index.Copies.TryFind target |> Option.defaultValue [||]

        let gameCopies =
            Visibility.sources
                { Root = sources.Stamp.WorkspaceId
                  Path = target }
                snapshot.Visibility
            |> List.choose (fun contribution ->
                match contribution.Source with
                | SourcePin.Mod _ -> None
                | SourcePin.Snapshot(_, _, file) -> Some(Choice2Of2(contribution.Source, file)))
            |> List.toArray


        PlanSnapshotPaging.page
            (PlanSnapshotPaging.queryIdentity snapshot "inspect" (Some target) "")
            cursor
            size
            (modCopies.Length + gameCopies.Length)
            (fun index ->
                inspectionRow
                    snapshot
                    target
                    (if index < modCopies.Length then
                         Choice1Of2 modCopies[index]
                     else
                         gameCopies[index - modCopies.Length]))
