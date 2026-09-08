import 'generated/modconductor/v1/file_plans.pb.dart' as wire;
import 'generated/modconductor/v1/mod_library.pb.dart' as modwire;
import 'file_plan_models.dart';

wire.ManagedFileCopy encodeCopy(ManagedFileCopy copy) => wire.ManagedFileCopy(
  modId: copy.modId,
  versionId: copy.versionId,
  path: modwire.ModLogicalPath(components: copy.path),
);
ManagedFileCopy decodeCopy(wire.ManagedFileCopy copy) =>
    ManagedFileCopy(copy.modId, copy.versionId, copy.path.components);
wire.FilePlanCursor? encodeCursor(FilePlanCursor? cursor) => cursor == null
    ? null
    : wire.FilePlanCursor(identity: cursor.identity, offset: cursor.offset);
FilePlanCursor decodeCursor(wire.FilePlanCursor cursor) =>
    FilePlanCursor(cursor.identity, cursor.offset);
FilePlanState state(wire.FilePlanState value) => FilePlanState(
  id: value.snapshotId,
  workspaceId: value.workspaceId,
  profileId: value.profileId,
  fingerprint: value.fingerprint,
  loaded: value.loaded,
  stale: value.stale,
  plannedFiles: value.plannedFiles,
  absentTargets: value.absentTargets,
  inspectedFiles: value.inspectedFiles,
  problems: List.unmodifiable(value.problems),
  problemCount: value.problemCount,
  observedAt: value.hasObservedAtUnixMs()
      ? DateTime.fromMillisecondsSinceEpoch(
          value.observedAtUnixMs.toInt(),
          isUtc: true,
        )
      : null,
);
PlannedFileNode node(wire.PlannedFileNode value) => PlannedFileNode(
  path: List.unmodifiable(value.path.components),
  directory: value.directory,
  sourceName: value.sourceName,
  copies: value.copies,
  disposition: switch (value.disposition) {
    wire.PlannedFileDisposition.PLANNED_FILE_DISPOSITION_PLANNED =>
      PlannedFileDisposition.planned,
    wire.PlannedFileDisposition.PLANNED_FILE_DISPOSITION_ABSENT =>
      PlannedFileDisposition.absent,
    wire.PlannedFileDisposition.PLANNED_FILE_DISPOSITION_UNRESOLVED =>
      PlannedFileDisposition.unresolved,
    _ => throw const FormatException('Unknown file disposition.'),
  },
);
InspectedFileCopy inspected(wire.InspectedFileCopy value) => InspectedFileCopy(
  copy: value.hasCopy() ? decodeCopy(value.copy) : null,
  sourcePath: List.unmodifiable(value.sourcePath.components),
  name: value.name,
  versionLabel: value.versionLabel,
  priority: value.hasPriority() ? value.priority : null,
  enabled: value.enabled,
  hidden: value.hidden,
  winner: value.winner,
  historical: value.historical,
  length: value.length.toInt(),
  sha256: value.sha256,
  canHide: value.canHide,
  canUnhide: value.canUnhide,
);
FileVisibilityAudit audit(wire.FileVisibilityAudit value) =>
    FileVisibilityAudit(
      id: value.id.toInt(),
      copy: decodeCopy(value.copy),
      hidden: value.hidden,
      beforeHidden: value.beforeHidden,
      profileId: value.profileId,
      beforeFingerprint: value.beforeFingerprint,
      afterFingerprint: value.afterFingerprint,
      recordedAt: DateTime.fromMillisecondsSinceEpoch(
        value.recordedAtUnixMs.toInt(),
        isUtc: true,
      ),
    );
Never reject(
  wire.FilePlanFault fault,
) => throw FilePlanException(switch (fault.code) {
  wire.FilePlanFaultCode.FILE_PLAN_FAULT_NOT_FOUND => FilePlanFailure.notFound,
  wire.FilePlanFaultCode.FILE_PLAN_FAULT_BUSY => FilePlanFailure.busy,
  wire.FilePlanFaultCode.FILE_PLAN_FAULT_EXPIRED => FilePlanFailure.expired,
  wire.FilePlanFaultCode.FILE_PLAN_FAULT_STALE => FilePlanFailure.stale,
  wire.FilePlanFaultCode.FILE_PLAN_FAULT_CONTEXT_UNAVAILABLE =>
    FilePlanFailure.contextUnavailable,
  wire.FilePlanFaultCode.FILE_PLAN_FAULT_FILE_UNAVAILABLE =>
    FilePlanFailure.fileUnavailable,
  wire.FilePlanFaultCode.FILE_PLAN_FAULT_LIMIT_EXCEEDED =>
    FilePlanFailure.limitExceeded,
  wire.FilePlanFaultCode.FILE_PLAN_FAULT_CANCELLED => FilePlanFailure.cancelled,
  wire.FilePlanFaultCode.FILE_PLAN_FAULT_INVALID_COPY =>
    FilePlanFailure.invalidCopy,
  wire.FilePlanFaultCode.FILE_PLAN_FAULT_BLOCKED => FilePlanFailure.blocked,
  _ => throw const FormatException('Unknown file planning failure.'),
}, fault.detail);
FilePlanState reply(wire.FilePlanReply reply) => switch (reply.whichOutcome()) {
  wire.FilePlanReply_Outcome.state => state(reply.state),
  wire.FilePlanReply_Outcome.fault => reject(reply.fault),
  wire.FilePlanReply_Outcome.notSet => throw const FormatException(
    'Missing file plan result.',
  ),
};
FilePlanInspection inspection(wire.FilePlanInspectionReply reply) =>
    switch (reply.whichOutcome()) {
      wire.FilePlanInspectionReply_Outcome.inspection => FilePlanInspection(
        state(reply.inspection.state),
        List.unmodifiable(reply.inspection.target.components),
        List.unmodifiable(reply.inspection.copies.map(inspected)),
        reply.inspection.hasNext() ? decodeCursor(reply.inspection.next) : null,
        focusedCopy: reply.inspection.hasFocusedCopy()
            ? inspected(reply.inspection.focusedCopy)
            : null,
      ),
      wire.FilePlanInspectionReply_Outcome.fault => reject(reply.fault),
      wire.FilePlanInspectionReply_Outcome.notSet =>
        throw const FormatException('Missing file inspection result.'),
    };
