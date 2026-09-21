namespace ModConductor.Engine

open System
open ModConductor
open ModConductor.GeneratedOutputs

module internal OutputWire =
    let fault error =
        let code, detail =
            match error with
            | OutputError.NotFound ->
                Protocol.V1.OutputFaultCode.OutputFaultNotFound, "The output record is unavailable."
            | OutputError.Busy ->
                Protocol.V1.OutputFaultCode.OutputFaultBusy, "Wait for the current operation."
            | OutputError.Stale ->
                Protocol.V1.OutputFaultCode.OutputFaultStale,
                "Refresh the output files before continuing."
            | OutputError.Cancelled ->
                Protocol.V1.OutputFaultCode.OutputFaultCancelled,
                "The output operation was cancelled. Check its result before retrying."
            | OutputError.Invalid text -> Protocol.V1.OutputFaultCode.OutputFaultInvalid, text
            | OutputError.Unavailable text ->
                Protocol.V1.OutputFaultCode.OutputFaultUnavailable, text
            | OutputError.LimitExceeded ->
                Protocol.V1.OutputFaultCode.OutputFaultLimitExceeded,
                "The output request exceeds its supported limit."

        Protocol.V1.OutputFault(Code = code, Detail = detail)

    let reference (value: OutputScope) =
        Protocol.V1.OutputScopeRef(
            WorkspaceId = value.WorkspaceId.ToString("N"),
            ProfileId = value.ProfileId.ToString("N"),
            ContextId = value.ContextId.ToString("N"),
            Revision = uint64 value.Revision,
            ContextRevision = uint64 value.ContextRevision
        )

    let location (value: OutputLocation) =
        let result =
            Protocol.V1.OutputLocation(
                Id = value.Id.ToString("N"),
                WorkspaceId = value.WorkspaceId.ToString("N"),
                ContextId = value.ContextId.ToString("N"),
                Name = value.Name,
                Revision = uint64 value.Revision,
                PhysicalPath = value.PhysicalPath
            )

        match value.Purpose with
        | OutputPurpose.ToolFolder -> result.Kind <- Protocol.V1.OutputLocationKind.ToolFolder
        | OutputPurpose.WritableFile path ->
            result.Kind <- Protocol.V1.OutputLocationKind.WritableFile
            result.Target <- ModLibraryWire.logical path

        result.Status <-
            match value.State with
            | OutputLocationState.Uninitialized -> Protocol.V1.OutputLocationStatus.Uninitialized
            | OutputLocationState.Ready -> Protocol.V1.OutputLocationStatus.Ready
            | OutputLocationState.Stopped -> Protocol.V1.OutputLocationStatus.Stopped

        result

    let scope (value: OutputScope) =
        let result =
            Protocol.V1.OutputScope(Reference = reference value, Installation = value.Installation)

        result.Locations.AddRange(value.Locations |> Seq.map location)

        result.Contexts.AddRange(
            value.Contexts
            |> Seq.map (fun value ->
                Protocol.V1.OutputContext(
                    Id = value.Id.ToString("N"),
                    Installation = value.Installation,
                    Current = value.Current
                ))
        )

        result.PendingActions.AddRange(value.PendingActions |> Seq.map (fun id -> id.ToString("N")))
        result

    let snapshot (value: OutputSnapshot) =
        Protocol.V1.OutputSnapshot(
            Id = value.Id.ToString("N"),
            Scope = scope value.Scope,
            ObservedAtUnixMs = value.ObservedAt.ToUnixTimeMilliseconds(),
            Files = uint32 value.Files,
            Entries = uint32 value.Entries,
            Unreviewed = uint32 value.Unreviewed
        )

    let file (value: OutputFile) =
        let result =
            Protocol.V1.OutputFile(
                LocationId = value.LocationId.ToString("N"),
                Path = ModLibraryWire.logical value.Path,
                Length = uint64 value.Length,
                Sha256 = value.Sha256,
                ObservedAtUnixMs = value.ObservedAt.ToUnixTimeMilliseconds()
            )

        result.Status <-
            match value.State with
            | OutputFileState.New -> Protocol.V1.OutputFileStatus.New
            | OutputFileState.Changed -> Protocol.V1.OutputFileStatus.Changed
            | OutputFileState.Kept -> Protocol.V1.OutputFileStatus.Kept
            | OutputFileState.Absent -> Protocol.V1.OutputFileStatus.Absent

        value.DeploymentId
        |> Option.iter (fun id -> result.DeploymentId <- id.ToString("N"))

        result

    let scopeReply =
        function
        | Ok value -> Protocol.V1.OutputScopeReply(Scope = scope value)
        | Error error -> Protocol.V1.OutputScopeReply(Fault = fault error)

    let locationReply =
        function
        | Ok value -> Protocol.V1.OutputLocationReply(Location = location value)
        | Error error -> Protocol.V1.OutputLocationReply(Fault = fault error)

    let snapshotReply =
        function
        | Ok value -> Protocol.V1.OutputSnapshotReply(Snapshot = snapshot value)
        | Error error -> Protocol.V1.OutputSnapshotReply(Fault = fault error)

    let pageReply =
        function
        | Error error -> Protocol.V1.OutputPageReply(Fault = fault error)
        | Ok(value: OutputPage) ->
            let result =
                Protocol.V1.OutputPage(
                    Snapshot = snapshot value.Snapshot,
                    Matching = uint32 value.MatchedEntries,
                    Files = uint32 value.Files,
                    Unreviewed = uint32 value.Unreviewed
                )

            result.Entries.AddRange(value.Entries |> Seq.map file)
            value.NextCursor |> Option.iter (fun cursor -> result.NextCursor <- cursor)
            Protocol.V1.OutputPageReply(Page = result)

    let previewReply =
        function
        | Error error -> Protocol.V1.OutputPromotionReply(Fault = fault error)
        | Ok(value: OutputPromotionPreview) ->
            let result =
                Protocol.V1.OutputPromotionPreview(
                    Selected = uint32 value.Selected,
                    RegisteredSource = value.RegisteredSource
                )

            result.Replaced.AddRange(value.Replaced |> Seq.map ModLibraryWire.logical)

            value.PreviousVersion
            |> Option.iter (fun id -> result.PreviousVersion <- id.ToString("N"))

            Protocol.V1.OutputPromotionReply(Preview = result)

    let selection (value: OutputSelection) =
        Protocol.V1.OutputSelection(
            LocationId = value.LocationId.ToString("N"),
            Path = ModLibraryWire.logical value.Path
        )

    let actionReply =
        function
        | Error error -> Protocol.V1.OutputActionReply(Fault = fault error)
        | Ok(value: OutputActionResult) ->
            let result =
                Protocol.V1.OutputActionResult(
                    Id = value.Id.ToString("N"),
                    Published = value.Published,
                    Complete = value.Complete
                )

            value.VersionId |> Option.iter (fun id -> result.VersionId <- id.ToString("N"))

            result.Entries.AddRange(
                value.Entries
                |> Seq.map (fun value ->
                    let disposition =
                        match value.Disposition with
                        | OutputDisposition.Kept -> Protocol.V1.OutputDisposition.Kept
                        | OutputDisposition.Discarded -> Protocol.V1.OutputDisposition.Discarded
                        | OutputDisposition.Moved -> Protocol.V1.OutputDisposition.Moved
                        | OutputDisposition.Copied -> Protocol.V1.OutputDisposition.Copied
                        | OutputDisposition.Changed -> Protocol.V1.OutputDisposition.Changed
                        | OutputDisposition.Pending -> Protocol.V1.OutputDisposition.Pending

                    Protocol.V1.OutputActionEntry(
                        File = selection value.File,
                        Disposition = disposition
                    ))
            )

            Protocol.V1.OutputActionReply(Result = result)

    let readSelection (values: Collections.Generic.ICollection<Protocol.V1.OutputSelection>) =
        if values.Count > 512 then
            ModLibraryWire.reject "Select at most 512 output files."

        values
        |> Seq.map (fun value ->
            { LocationId = ModLibraryWire.id value.LocationId
              Path = ModLibraryWire.path value.Path })
        |> Seq.toList

    let private destination (value: Protocol.V1.OutputDestination) =
        if isNull value then
            ModLibraryWire.reject "Select a destination mod."

        match value.DestinationCase with
        | Protocol.V1.OutputDestination.DestinationOneofCase.ExistingMod ->
            OutputDestination.ExistingMod(
                ModLibraryWire.id value.ExistingMod.ModId,
                ModLibraryWire.number value.ExistingMod.Revision,
                value.ExistingMod.VersionLabel
            )
        | Protocol.V1.OutputDestination.DestinationOneofCase.NewMod ->
            OutputDestination.NewMod(
                ModLibraryWire.id value.NewMod.ModId,
                value.NewMod.Name,
                value.NewMod.VersionLabel
            )
        | _ -> ModLibraryWire.reject "Select a destination mod."

    let readAction (value: Protocol.V1.OutputActionSpec) =
        if isNull value then
            ModLibraryWire.reject "Select an output action."

        match value.Kind with
        | Protocol.V1.OutputActionKind.Keep -> OutputAction.Keep
        | Protocol.V1.OutputActionKind.Discard -> OutputAction.Discard
        | Protocol.V1.OutputActionKind.MoveToMod ->
            OutputAction.MoveToMod(destination value.Destination)
        | Protocol.V1.OutputActionKind.SaveCopyToMod ->
            OutputAction.SaveCopyToMod(destination value.Destination)
        | _ -> ModLibraryWire.reject "Select an output action."
