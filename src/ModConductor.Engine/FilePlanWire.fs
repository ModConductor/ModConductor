namespace ModConductor.Engine

open System
open ModConductor.FilePlanning
open ModConductor.DeploymentPlanning
open ModConductor.Protocol.V1

module internal FilePlanWire =
    let readCopy (value: ManagedFileCopy) : ModFile =
        if isNull value then
            ModLibraryWire.reject "Select a saved file copy."

        { ModId = ModLibraryWire.id value.ModId
          VersionId = ModLibraryWire.id value.VersionId
          Path = ModLibraryWire.path value.Path }

    let copy (value: ModFile) =
        ManagedFileCopy(
            ModId = value.ModId.ToString "N",
            VersionId = value.VersionId.ToString "N",
            Path = ModLibraryWire.logical value.Path
        )

    let private checkedLength (value: uint64) =
        if value > uint64 System.Int64.MaxValue then
            ModLibraryWire.reject "The file length is invalid."

        int64 value

    let private checkedHash (value: string) =
        if
            value.Length <> 64
            || value |> Seq.exists (fun c -> not (System.Uri.IsHexDigit c))
        then
            ModLibraryWire.reject "The file identity is invalid."

        value.ToLowerInvariant()

    let standing =
        function
        | ModConductor.FilePlanning.FileSourceStanding.Winner -> FileSourceStanding.Winner
        | ModConductor.FilePlanning.FileSourceStanding.Alternative -> FileSourceStanding.Alternative
        | ModConductor.FilePlanning.FileSourceStanding.Selected -> FileSourceStanding.Selected
        | ModConductor.FilePlanning.FileSourceStanding.Previous -> FileSourceStanding.Previous
        | ModConductor.FilePlanning.FileSourceStanding.Unavailable -> FileSourceStanding.Unavailable

    let source (value: ModConductor.FilePlanning.FilePreviewSource) =
        match value with
        | ModConductor.FilePlanning.FilePreviewSource.ManagedCopy managed ->
            FilePreviewSource(
                Managed =
                    ManagedPreviewSource(
                        Copy = copy managed.Copy,
                        SourcePath = ModLibraryWire.logical managed.SourcePath,
                        Target = ModLibraryWire.logical managed.Target,
                        Length = uint64 managed.Length,
                        Sha256 = managed.Sha256,
                        PayloadId = managed.PayloadId.ToString "N"
                    )
            )
        | ModConductor.FilePlanning.FilePreviewSource.CheckedGameFile game ->
            FilePreviewSource(
                Game =
                    CheckedGamePreviewSource(
                        SnapshotId = game.SnapshotId.ToString "N",
                        Generation = game.Generation,
                        Kind = (if game.Kind = ReadOnlyLayerKind.Base then 1u else 2u),
                        SourcePath = ModLibraryWire.logical game.SourcePath,
                        Target = ModLibraryWire.logical game.Target,
                        Length = uint64 game.Length,
                        Sha256 = game.Sha256
                    )
            )
        | ModConductor.FilePlanning.FilePreviewSource.QualifiedArchiveEntry archive ->
            FilePreviewSource(
                ArchiveEntry =
                    QualifiedArchiveEntryPreviewSource(
                        WorkspaceId = archive.WorkspaceId.ToString "N",
                        ArtifactId = archive.ArtifactId.ToString "N",
                        ArtifactRevision = uint64 archive.ArtifactRevision,
                        ArchiveSha256 = archive.ArchiveSha256,
                        Format = archive.Format,
                        Index = uint32 archive.Index,
                        Path = ModLibraryWire.logical archive.Path,
                        Length = uint64 archive.Length
                    )
            )

    let readSource (value: FilePreviewSource) =
        if isNull value then
            ModLibraryWire.reject "Select a file source."

        match value.SourceCase with
        | FilePreviewSource.SourceOneofCase.Managed ->
            let item = value.Managed

            ModConductor.FilePlanning.FilePreviewSource.ManagedCopy
                { Copy = readCopy item.Copy
                  SourcePath = ModLibraryWire.path item.SourcePath
                  Target = ModLibraryWire.path item.Target
                  PayloadId = ModLibraryWire.id item.PayloadId
                  Length = checkedLength item.Length
                  Sha256 = checkedHash item.Sha256 }
        | FilePreviewSource.SourceOneofCase.Game ->
            let item = value.Game

            let kind =
                match item.Kind with
                | 1u -> ReadOnlyLayerKind.Base
                | 2u -> ReadOnlyLayerKind.Secondary
                | _ -> ModLibraryWire.reject "The checked game-file source is invalid."

            ModConductor.FilePlanning.FilePreviewSource.CheckedGameFile
                { SnapshotId = ModLibraryWire.id item.SnapshotId
                  Generation = item.Generation
                  Kind = kind
                  SourcePath = ModLibraryWire.path item.SourcePath
                  Target = ModLibraryWire.path item.Target
                  Length = checkedLength item.Length
                  Sha256 = checkedHash item.Sha256 }
        | FilePreviewSource.SourceOneofCase.ArchiveEntry ->
            let item = value.ArchiveEntry

            ModConductor.FilePlanning.FilePreviewSource.QualifiedArchiveEntry
                { WorkspaceId = ModLibraryWire.id item.WorkspaceId
                  ArtifactId = ModLibraryWire.id item.ArtifactId
                  ArtifactRevision = ModLibraryWire.number item.ArtifactRevision
                  ArchiveSha256 = checkedHash item.ArchiveSha256
                  Format = item.Format
                  Index = ModLibraryWire.count item.Index
                  Path = ModLibraryWire.path item.Path
                  Length = checkedLength item.Length }
        | _ -> ModLibraryWire.reject "Select a file source."

    let readRepresentation =
        function
        | FilePreviewRepresentation.Text -> ModConductor.FilePlanning.FilePreviewRepresentation.Text
        | FilePreviewRepresentation.Image ->
            ModConductor.FilePlanning.FilePreviewRepresentation.Image
        | FilePreviewRepresentation.Hex -> ModConductor.FilePlanning.FilePreviewRepresentation.Hex
        | _ -> ModLibraryWire.reject "Select text, image or hex preview."

    let readCursor (value: FilePlanCursor) : FileCursor option =
        if isNull value then
            None
        else
            if value.Identity.Length <> 64 then
                ModLibraryWire.reject "The file page cursor is invalid."

            Some
                { Identity = value.Identity
                  Offset = ModLibraryWire.count value.Offset }

    let cursor (value: FileCursor) =
        FilePlanCursor(Identity = value.Identity, Offset = uint32 value.Offset)

    let fault =
        function
        | FilePlanError.NotFound ->
            FilePlanFault(
                Code = FilePlanFaultCode.FilePlanFaultNotFound,
                Detail = "The workspace or profile was not found."
            )
        | FilePlanError.Busy ->
            FilePlanFault(
                Code = FilePlanFaultCode.FilePlanFaultBusy,
                Detail = "A file check is in progress. Try again."
            )
        | FilePlanError.Expired ->
            FilePlanFault(
                Code = FilePlanFaultCode.FilePlanFaultExpired,
                Detail = "The file view expired. Load files again."
            )
        | FilePlanError.Stale ->
            FilePlanFault(
                Code = FilePlanFaultCode.FilePlanFaultStale,
                Detail = "The file inputs changed. Reload the file view."
            )
        | FilePlanError.ContextUnavailable detail ->
            FilePlanFault(Code = FilePlanFaultCode.FilePlanFaultContextUnavailable, Detail = detail)
        | FilePlanError.FileUnavailable detail ->
            FilePlanFault(Code = FilePlanFaultCode.FilePlanFaultFileUnavailable, Detail = detail)
        | FilePlanError.LimitExceeded detail ->
            FilePlanFault(Code = FilePlanFaultCode.FilePlanFaultLimitExceeded, Detail = detail)
        | FilePlanError.Cancelled ->
            FilePlanFault(
                Code = FilePlanFaultCode.FilePlanFaultCancelled,
                Detail = "The file check was cancelled."
            )
        | FilePlanError.InvalidCopy ->
            FilePlanFault(
                Code = FilePlanFaultCode.FilePlanFaultInvalidCopy,
                Detail = "The saved file copy changed or is unavailable."
            )
        | FilePlanError.Blocked ->
            FilePlanFault(
                Code = FilePlanFaultCode.FilePlanFaultBlocked,
                Detail =
                    "This file cannot be hidden until the file view is complete and its problems are resolved."
            )

    let previewResult (value: ModConductor.FilePlanning.FilePreview) =
        let result =
            FilePreviewResult(
                Source = source value.Source,
                Standing = standing value.Standing,
                Target = ModLibraryWire.logical value.Target
            )

        match value.Outcome with
        | ModConductor.FilePlanning.FilePreviewOutcome.Ready content ->
            result.Status <- FilePreviewStatus.Ready

            match content with
            | ModConductor.FilePlanning.FilePreviewContent.Text text ->
                result.Text <-
                    FilePreviewText(
                        Content = text.Content,
                        Encoding = text.Encoding,
                        Lines = uint32 text.Lines
                    )
            | ModConductor.FilePlanning.FilePreviewContent.Image image ->
                result.Image <-
                    FilePreviewImage(
                        Content = Google.Protobuf.ByteString.CopyFrom image.Content,
                        Format = image.Format,
                        Width = uint32 image.Width,
                        Height = uint32 image.Height
                    )
            | ModConductor.FilePlanning.FilePreviewContent.Hex hex ->
                result.Hex <-
                    FilePreviewHex(
                        Content = Google.Protobuf.ByteString.CopyFrom hex.Content,
                        TotalLength = uint64 hex.TotalLength,
                        Truncated = hex.Truncated
                    )
        | ModConductor.FilePlanning.FilePreviewOutcome.Unsupported detail ->
            result.Status <- FilePreviewStatus.Unsupported
            result.Detail <- detail
        | ModConductor.FilePlanning.FilePreviewOutcome.TooLarge detail ->
            result.Status <- FilePreviewStatus.TooLarge
            result.Detail <- detail
        | ModConductor.FilePlanning.FilePreviewOutcome.Changed detail ->
            result.Status <- FilePreviewStatus.Changed
            result.Detail <- detail

        result

    let preview =
        function
        | Ok value -> FilePreviewReply(Preview = previewResult value)
        | Error error -> FilePreviewReply(Fault = fault error)

    let state (value: FilePlanSummary) =
        let result =
            FilePlanState(
                SnapshotId = value.Id.ToString "N",
                WorkspaceId = value.WorkspaceId.ToString "N",
                ProfileId = value.ProfileId.ToString "N",
                Fingerprint = value.Fingerprint,
                Loaded = value.Loaded,
                Stale = value.Stale,
                PlannedFiles = uint32 value.PlannedFiles,
                AbsentTargets = uint32 value.AbsentTargets,
                InspectedFiles = uint32 value.InspectedFiles,
                ProblemCount = uint32 value.ProblemCount
            )

        result.Problems.AddRange value.Problems

        value.ObservedAt
        |> Option.iter (fun time -> result.ObservedAtUnixMs <- time.ToUnixTimeMilliseconds())

        result

    let reply =
        function
        | Ok value -> FilePlanReply(State = state value)
        | Error error -> FilePlanReply(Fault = fault error)

    let node (value: FileNode) =
        PlannedFileNode(
            Path = ModLibraryWire.logical value.Path,
            Directory = value.Directory,
            SourceName = value.SourceName,
            Copies = uint32 value.Copies,
            Disposition =
                (match value.Disposition with
                 | FileDisposition.Writable -> PlannedFileDisposition.Writable
                 | FileDisposition.Planned -> PlannedFileDisposition.Planned
                 | FileDisposition.Absent -> PlannedFileDisposition.Absent
                 | FileDisposition.Unresolved -> PlannedFileDisposition.Unresolved)
        )

    let page =
        function
        | Error error -> FilePlanPageReply(Fault = fault error)
        | Ok(value: FilePage) ->
            let result = PlannedFilePage(State = state value.Snapshot)
            result.Nodes.AddRange(value.Nodes |> Seq.map node)
            value.Next |> Option.iter (fun next -> result.Next <- cursor next)
            FilePlanPageReply(Page = result)

    let inspected (value: InspectedCopy) =
        let result =
            InspectedFileCopy(
                SourcePath = ModLibraryWire.logical value.SourcePath,
                Name = value.Name,
                VersionLabel = value.VersionLabel,
                Enabled = value.Enabled,
                Hidden = value.Hidden,
                Winner = value.Winner,
                Historical = value.Historical,
                Length = uint64 value.Length,
                Sha256 = value.Sha256,
                CanHide = value.CanHide,
                CanUnhide = value.CanUnhide,
                Source = source value.Source,
                Standing = standing value.Standing
            )

        value.Copy |> Option.iter (fun id -> result.Copy <- copy id)

        value.Priority
        |> Option.iter (fun priority -> result.Priority <- uint32 priority)

        result

    let inspection =
        function
        | Error error -> FilePlanInspectionReply(Fault = fault error)
        | Ok(value: FileInspection) ->
            let result =
                PlannedFileInspection(
                    State = state value.Snapshot,
                    Target = ModLibraryWire.logical value.Target,
                    Writable = value.Writable
                )

            result.Copies.AddRange(value.Copies |> Seq.map inspected)

            value.FocusedCopy
            |> Option.iter (fun copy -> result.FocusedCopy <- inspected copy)

            value.Next |> Option.iter (fun next -> result.Next <- cursor next)
            FilePlanInspectionReply(Inspection = result)

    let change =
        function
        | Error error -> FileVisibilityReply(Fault = fault error)
        | Ok(value: VisibilityChange) ->
            let result = FileVisibilityChange(State = state value.Snapshot)
            value.Changed |> Option.iter (fun changed -> result.Changed <- node changed)
            FileVisibilityReply(Change = result)

    let problems =
        function
        | Error error -> FilePlanProblemsReply(Fault = fault error)
        | Ok(values, next) ->
            let result = FilePlanProblems()
            result.Problems.AddRange(values: string list)
            next |> Option.iter (fun next -> result.Next <- cursor next)
            FilePlanProblemsReply(Problems = result)

    let history =
        function
        | Error error -> FileVisibilityHistoryReply(Fault = fault error)
        | Ok(page: FileHistoryPage) ->
            let result = FileVisibilityHistory()

            result.Changes.AddRange(
                page.Changes
                |> Seq.map (fun value ->
                    FileVisibilityAudit(
                        Id = uint64 value.Id,
                        Copy = copy value.Copy,
                        Hidden = value.Hidden,
                        BeforeHidden = value.BeforeHidden,
                        ProfileId = value.ProfileId.ToString "N",
                        BeforeFingerprint = value.BeforeFingerprint,
                        AfterFingerprint = value.AfterFingerprint,
                        RecordedAtUnixMs = value.RecordedAt.ToUnixTimeMilliseconds()
                    ))
            )

            page.NextBeforeId |> Option.iter (fun id -> result.NextBeforeId <- uint64 id)

            FileVisibilityHistoryReply(History = result)
