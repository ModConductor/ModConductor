namespace ModConductor.Engine

open System
open Grpc.Core
open ModConductor.ModLibrary
open ModConductor.Platform
open ModConductor.Protocol.V1

module internal ModLibraryWire =
    let reject message =
        raise (RpcException(Status(StatusCode.InvalidArgument, message)))

    let id value =
        match Guid.TryParseExact(value, "N") with
        | true, id when id <> Guid.Empty -> id
        | _ -> reject "Invalid mod, version, workspace or profile ID."

    let number value =
        if value > uint64 Int64.MaxValue then
            reject "Invalid revision or offset."
        else
            int64 value

    let count value =
        if value > uint32 Int32.MaxValue then
            reject "Invalid limit."
        else
            int value

    let path (value: ModLogicalPath) =
        if isNull value || value.Components.Count > 128 then
            reject "Choose a relative source folder."

        match LogicalPath.create (List.ofSeq value.Components) with
        | Ok value -> value
        | Error _ -> reject "Choose a relative source folder."

    let logical value =
        let result = ModLogicalPath()
        result.Components.AddRange(LogicalPath.components value)
        result

    let metadata (value: InventoryModMetadata) : ModMetadata =
        if isNull value then
            reject "Enter mod details."

        { Name = value.Name
          Notes = value.Notes
          Comment = value.Comment
          Version = value.Version
          Source = value.Source
          Category = value.Category }

    let kind =
        function
        | ModKind.Regular -> InventoryModKind.Regular
        | ModKind.Separator -> InventoryModKind.Separator
        | ModKind.Backup -> InventoryModKind.Backup
        | ModKind.Unmanaged -> InventoryModKind.Unmanaged
        | ModKind.GeneratedOutput -> InventoryModKind.GeneratedOutput

    let entry (value: ModEntry) =
        let result =
            InventoryMod(
                ModId = value.Id.ToString("N"),
                WorkspaceId = value.WorkspaceId.ToString("N"),
                Kind = kind value.Kind,
                Metadata =
                    InventoryModMetadata(
                        Name = value.Metadata.Name,
                        Notes = value.Metadata.Notes,
                        Comment = value.Metadata.Comment,
                        Version = value.Metadata.Version,
                        Source = value.Metadata.Source,
                        Category = value.Metadata.Category
                    ),
                Revision = uint64 value.Revision,
                Status =
                    match value.Status with
                    | InventoryStatus.Ready -> ModInventoryStatus.Ready
                    | InventoryStatus.Detached -> ModInventoryStatus.Detached
                    | InventoryStatus.Changed -> ModInventoryStatus.Changed
                    | InventoryStatus.Unproved -> ModInventoryStatus.Unproved
                    | InventoryStatus.Publishing -> ModInventoryStatus.Publishing
            )

        value.SourcePath |> Option.iter (fun path -> result.SourcePath <- logical path)

        value.CurrentVersion
        |> Option.iter (fun id -> result.CurrentVersionId <- id.ToString("N"))

        result.Actions.AddRange(
            value.Actions
            |> Seq.map (function
                | ModAction.EditMetadata -> InventoryModAction.EditMetadata
                | ModAction.Publish -> InventoryModAction.Publish
                | ModAction.ReadVersion -> InventoryModAction.ReadVersion)
        )

        result

    let fault error =
        let code, detail =
            match error with
            | LibraryError.NotFound ->
                ModLibraryFaultCode.NotFound, "The mod or version was not found."
            | LibraryError.StaleRevision -> ModLibraryFaultCode.StaleRevision, "The mod changed."
            | LibraryError.IdentityConflict ->
                ModLibraryFaultCode.IdentityConflict, "This ID already belongs to different data."
            | LibraryError.InvalidMetadata ->
                ModLibraryFaultCode.InvalidMetadata, "Check the mod details."
            | LibraryError.InvalidSource ->
                ModLibraryFaultCode.InvalidSource,
                "Choose a source folder inside this workspace, outside its library."
            | LibraryError.UnprovedOwnership ->
                ModLibraryFaultCode.UnprovedOwnership, "Mod Conductor cannot verify these files."
            | LibraryError.SourceChanged ->
                ModLibraryFaultCode.SourceChanged, "The source files changed."
            | LibraryError.UnsupportedAction ->
                ModLibraryFaultCode.UnsupportedAction, "This action is not available for this item."
            | LibraryError.Busy ->
                ModLibraryFaultCode.Busy, "A library change is still in progress."
            | LibraryError.LimitExceeded ->
                ModLibraryFaultCode.LimitExceeded, "The requested limit is too large or invalid."
            | LibraryError.FileUnavailable ->
                ModLibraryFaultCode.FileUnavailable,
                "The source or published files are unavailable or changed."
            | LibraryError.Cancelled -> ModLibraryFaultCode.Cancelled, "Publication was cancelled."

        ModLibraryFault(Code = code, Detail = detail)

    let modReply =
        function
        | Ok value -> ModReply(Mod = entry value)
        | Error error -> ModReply(Fault = fault error)

    let registration (request: RegisterModRequest) =
        match request.Kind with
        | InventoryModKind.Regular
        | InventoryModKind.Unmanaged
        | InventoryModKind.GeneratedOutput when not request.HasBackupVersionId ->
            let kind =
                if request.Kind = InventoryModKind.Regular then
                    ModKind.Regular
                elif request.Kind = InventoryModKind.Unmanaged then
                    ModKind.Unmanaged
                else
                    ModKind.GeneratedOutput

            if request.HasNativeSourcePath then
                if not (isNull request.SourcePath) then
                    reject "Choose one source folder."

                match HostPath.create request.NativeSourcePath with
                | Ok candidate -> Registration.NativeDirectory(kind, candidate)
                | Error message -> reject message
            else
                Registration.Directory(kind, path request.SourcePath)
        | InventoryModKind.Separator when
            isNull request.SourcePath
            && not request.HasBackupVersionId
            && not request.HasNativeSourcePath
            ->
            Registration.Separator
        | InventoryModKind.Backup when
            isNull request.SourcePath
            && request.HasBackupVersionId
            && not request.HasNativeSourcePath
            ->
            Registration.Backup(id request.BackupVersionId)
        | _ -> reject "Choose a valid mod type and source."

    let publication =
        function
        | Error error -> PublicationReply(Fault = fault error)
        | Ok(value: PublicationReceipt) ->
            let phase =
                match value.Phase with
                | PublicationPhase.Intent -> ModPublicationPhase.Intent
                | PublicationPhase.Observed -> ModPublicationPhase.Observed
                | PublicationPhase.Complete -> ModPublicationPhase.Complete
                | PublicationPhase.Interrupted -> ModPublicationPhase.Interrupted
                | PublicationPhase.Cancelled -> ModPublicationPhase.Cancelled

            PublicationReply(
                Receipt =
                    ModPublicationReceipt(
                        VersionId = value.VersionId.ToString("N"),
                        ModId = value.ModId.ToString("N"),
                        ExpectedRevision = uint64 value.ExpectedRevision,
                        Phase = phase
                    )
            )
