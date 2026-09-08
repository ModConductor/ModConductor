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
                CanUnhide = value.CanUnhide
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
                    Target = ModLibraryWire.logical value.Target
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
