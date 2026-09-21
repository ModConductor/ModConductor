import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';

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

wire.FilePreviewSource encodeSource(FilePreviewSource source) =>
    switch (source) {
      ManagedPreviewSource value => wire.FilePreviewSource(
        managed: wire.ManagedPreviewSource(
          copy: encodeCopy(value.copy),
          sourcePath: modwire.ModLogicalPath(components: value.sourcePath),
          target: modwire.ModLogicalPath(components: value.target),
          length: Int64(value.length),
          sha256: value.sha256,
          payloadId: value.payloadId,
          modRevision: Int64(value.modRevision),
        ),
      ),
      CheckedGamePreviewSource value => wire.FilePreviewSource(
        game: wire.CheckedGamePreviewSource(
          snapshotId: value.snapshotId,
          generation: value.generation,
          kind: value.kind,
          sourcePath: modwire.ModLogicalPath(components: value.sourcePath),
          target: modwire.ModLogicalPath(components: value.target),
          length: Int64(value.length),
        ),
      ),
      QualifiedArchiveEntryPreviewSource value => wire.FilePreviewSource(
        archiveEntry: wire.QualifiedArchiveEntryPreviewSource(
          workspaceId: value.workspaceId,
          artifactId: value.artifactId,
          artifactRevision: Int64(value.artifactRevision),
          archiveSha256: value.archiveSha256,
          format: value.format,
          index: value.index,
          path: modwire.ModLogicalPath(components: value.sourcePath),
          length: Int64(value.length),
        ),
      ),
    };
FilePreviewSource decodeSource(wire.FilePreviewSource source) =>
    switch (source.whichSource()) {
      wire.FilePreviewSource_Source.managed => ManagedPreviewSource(
        copy: decodeCopy(source.managed.copy),
        sourcePath: List.unmodifiable(source.managed.sourcePath.components),
        target: List.unmodifiable(source.managed.target.components),
        length: source.managed.length.toInt(),
        sha256: source.managed.sha256,
        payloadId: source.managed.payloadId,
        modRevision: source.managed.modRevision.toInt(),
      ),
      wire.FilePreviewSource_Source.game => CheckedGamePreviewSource(
        snapshotId: source.game.snapshotId,
        generation: source.game.generation,
        kind: source.game.kind,
        sourcePath: List.unmodifiable(source.game.sourcePath.components),
        target: List.unmodifiable(source.game.target.components),
        length: source.game.length.toInt(),
      ),
      wire.FilePreviewSource_Source.archiveEntry =>
        QualifiedArchiveEntryPreviewSource(
          workspaceId: source.archiveEntry.workspaceId,
          artifactId: source.archiveEntry.artifactId,
          artifactRevision: source.archiveEntry.artifactRevision.toInt(),
          archiveSha256: source.archiveEntry.archiveSha256,
          format: source.archiveEntry.format,
          index: source.archiveEntry.index,
          sourcePath: List.unmodifiable(source.archiveEntry.path.components),
          length: source.archiveEntry.length.toInt(),
        ),
      wire.FilePreviewSource_Source.notSet => throw const FormatException(
        'Missing file source.',
      ),
    };
FileSourceStanding decodeStanding(wire.FileSourceStanding value) =>
    switch (value) {
      wire.FileSourceStanding.FILE_SOURCE_STANDING_WINNER =>
        FileSourceStanding.winner,
      wire.FileSourceStanding.FILE_SOURCE_STANDING_ALTERNATIVE =>
        FileSourceStanding.alternative,
      wire.FileSourceStanding.FILE_SOURCE_STANDING_SELECTED =>
        FileSourceStanding.selected,
      wire.FileSourceStanding.FILE_SOURCE_STANDING_PREVIOUS =>
        FileSourceStanding.previous,
      wire.FileSourceStanding.FILE_SOURCE_STANDING_UNAVAILABLE =>
        FileSourceStanding.unavailable,
      _ => throw const FormatException('Unknown file source standing.'),
    };
wire.FilePreviewRepresentation encodeRepresentation(
  FilePreviewRepresentation value,
) => switch (value) {
  FilePreviewRepresentation.text =>
    wire.FilePreviewRepresentation.FILE_PREVIEW_REPRESENTATION_TEXT,
  FilePreviewRepresentation.image =>
    wire.FilePreviewRepresentation.FILE_PREVIEW_REPRESENTATION_IMAGE,
  FilePreviewRepresentation.hex =>
    wire.FilePreviewRepresentation.FILE_PREVIEW_REPRESENTATION_HEX,
};
FilePreviewResult preview(wire.FilePreviewReply reply) =>
    switch (reply.whichOutcome()) {
      wire.FilePreviewReply_Outcome.preview => FilePreviewResult(
        source: decodeSource(reply.preview.source),
        standing: decodeStanding(reply.preview.standing),
        target: List.unmodifiable(reply.preview.target.components),
        status: switch (reply.preview.status) {
          wire.FilePreviewStatus.FILE_PREVIEW_STATUS_READY =>
            FilePreviewStatus.ready,
          wire.FilePreviewStatus.FILE_PREVIEW_STATUS_UNSUPPORTED =>
            FilePreviewStatus.unsupported,
          wire.FilePreviewStatus.FILE_PREVIEW_STATUS_TOO_LARGE =>
            FilePreviewStatus.tooLarge,
          wire.FilePreviewStatus.FILE_PREVIEW_STATUS_CHANGED =>
            FilePreviewStatus.changed,
          _ => throw const FormatException('Unknown file preview status.'),
        },
        detail: reply.preview.detail.isEmpty ? null : reply.preview.detail,
        content: switch (reply.preview.whichContent()) {
          wire.FilePreviewResult_Content.text => FilePreviewText(
            reply.preview.text.content,
            reply.preview.text.encoding,
            reply.preview.text.lines,
          ),
          wire.FilePreviewResult_Content.image => FilePreviewImage(
            Uint8List.fromList(reply.preview.image.content),
            reply.preview.image.format,
            reply.preview.image.width,
            reply.preview.image.height,
          ),
          wire.FilePreviewResult_Content.hex => FilePreviewHex(
            Uint8List.fromList(reply.preview.hex.content),
            reply.preview.hex.totalLength.toInt(),
            reply.preview.hex.truncated,
          ),
          wire.FilePreviewResult_Content.notSet => null,
        },
      ),
      wire.FilePreviewReply_Outcome.fault => reject(reply.fault),
      wire.FilePreviewReply_Outcome.notSet => throw const FormatException(
        'Missing file preview result.',
      ),
    };

TextDocument textDocument(wire.TextDocument value) => TextDocument(
  content: value.content,
  encoding: switch (value.encoding) {
    wire.TextDocumentEncoding.TEXT_DOCUMENT_ENCODING_UTF8 =>
      TextDocumentEncoding.utf8,
    wire.TextDocumentEncoding.TEXT_DOCUMENT_ENCODING_UTF8_BOM =>
      TextDocumentEncoding.utf8Bom,
    wire.TextDocumentEncoding.TEXT_DOCUMENT_ENCODING_UTF16_LITTLE =>
      TextDocumentEncoding.utf16Little,
    wire.TextDocumentEncoding.TEXT_DOCUMENT_ENCODING_UTF16_BIG =>
      TextDocumentEncoding.utf16Big,
    _ => throw const FormatException('Unknown text encoding.'),
  },
  newline: switch (value.newline) {
    wire.TextDocumentNewline.TEXT_DOCUMENT_NEWLINE_NO_LINE_BREAKS =>
      TextDocumentNewline.noLineBreaks,
    wire.TextDocumentNewline.TEXT_DOCUMENT_NEWLINE_LF => TextDocumentNewline.lf,
    wire.TextDocumentNewline.TEXT_DOCUMENT_NEWLINE_CRLF =>
      TextDocumentNewline.crlf,
    _ => throw const FormatException('Unknown text line endings.'),
  },
  finalTerminator: value.finalTerminator,
  lines: value.lines,
);

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
    wire.PlannedFileDisposition.PLANNED_FILE_DISPOSITION_WRITABLE =>
      PlannedFileDisposition.writable,
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
  sha256: value.hasSha256() ? value.sha256 : null,
  canHide: value.canHide,
  canUnhide: value.canUnhide,
  source: decodeSource(value.source),
  standing: decodeStanding(value.standing),
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
  wire.FilePlanFaultCode.FILE_PLAN_FAULT_UNSUPPORTED =>
    FilePlanFailure.unsupported,
  wire.FilePlanFaultCode.FILE_PLAN_FAULT_INVALID_EDIT =>
    FilePlanFailure.invalidEdit,
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
        writable: reply.inspection.writable,
        focusedCopy: reply.inspection.hasFocusedCopy()
            ? inspected(reply.inspection.focusedCopy)
            : null,
      ),
      wire.FilePlanInspectionReply_Outcome.fault => reject(reply.fault),
      wire.FilePlanInspectionReply_Outcome.notSet =>
        throw const FormatException('Missing file inspection result.'),
    };
