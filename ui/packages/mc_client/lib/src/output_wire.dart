import 'package:fixnum/fixnum.dart';

import 'generated/modconductor/v1/generated_outputs.pb.dart' as wire;
import 'generated/modconductor/v1/mod_library.pb.dart' as modwire;
import 'output_models.dart';

Never reject(wire.OutputFault fault) => throw OutputException(
  switch (fault.code) {
    wire.OutputFaultCode.OUTPUT_FAULT_NOT_FOUND => OutputFailure.notFound,
    wire.OutputFaultCode.OUTPUT_FAULT_BUSY => OutputFailure.busy,
    wire.OutputFaultCode.OUTPUT_FAULT_STALE => OutputFailure.stale,
    wire.OutputFaultCode.OUTPUT_FAULT_CANCELLED => OutputFailure.cancelled,
    wire.OutputFaultCode.OUTPUT_FAULT_INVALID => OutputFailure.invalid,
    wire.OutputFaultCode.OUTPUT_FAULT_UNAVAILABLE => OutputFailure.unavailable,
    wire.OutputFaultCode.OUTPUT_FAULT_LIMIT_EXCEEDED =>
      OutputFailure.limitExceeded,
    _ => throw const FormatException('Unknown output failure.'),
  },
  fault.detail,
);
wire.OutputScopeRef reference(OutputScopeRef value) => wire.OutputScopeRef(
  workspaceId: value.workspaceId,
  contextId: value.contextId,
  revision: Int64(value.revision),
  contextRevision: Int64(value.contextRevision),
);
OutputLocation location(wire.OutputLocation value) => OutputLocation(
  id: value.id,
  workspaceId: value.workspaceId,
  contextId: value.contextId,
  name: value.name,
  kind: switch (value.kind) {
    wire.OutputLocationKind.OUTPUT_LOCATION_KIND_TOOL_FOLDER =>
      OutputLocationKind.toolFolder,
    wire.OutputLocationKind.OUTPUT_LOCATION_KIND_WRITABLE_FILE =>
      OutputLocationKind.writableFile,
    _ => throw const FormatException('Unknown output location kind.'),
  },
  revision: value.revision.toInt(),
  status: switch (value.status) {
    wire.OutputLocationStatus.OUTPUT_LOCATION_STATUS_UNINITIALIZED =>
      OutputLocationStatus.uninitialized,
    wire.OutputLocationStatus.OUTPUT_LOCATION_STATUS_READY =>
      OutputLocationStatus.ready,
    wire.OutputLocationStatus.OUTPUT_LOCATION_STATUS_STOPPED =>
      OutputLocationStatus.stopped,
    _ => throw const FormatException('Unknown output location status.'),
  },
  physicalPath: value.physicalPath,
  target: value.hasTarget() ? List.unmodifiable(value.target.components) : null,
);
OutputScope scope(wire.OutputScope value) => OutputScope(
  OutputScopeRef(
    value.reference.workspaceId,
    value.reference.contextId,
    value.reference.revision.toInt(),
    value.reference.contextRevision.toInt(),
  ),
  value.installation,
  List.unmodifiable(value.locations.map(location)),
  List.unmodifiable(
    value.contexts.map(
      (value) => OutputContext(value.id, value.installation, value.current),
    ),
  ),
  List.unmodifiable(value.pendingActions),
);
OutputSnapshot snapshot(wire.OutputSnapshot value) => OutputSnapshot(
  value.id,
  scope(value.scope),
  DateTime.fromMillisecondsSinceEpoch(
    value.observedAtUnixMs.toInt(),
    isUtc: true,
  ),
  value.files,
  value.entries,
  value.unreviewed,
);
OutputFile file(wire.OutputFile value) => OutputFile(
  value.locationId,
  List.unmodifiable(value.path.components),
  switch (value.status) {
    wire.OutputFileStatus.OUTPUT_FILE_STATUS_NEW => OutputFileStatus.newFile,
    wire.OutputFileStatus.OUTPUT_FILE_STATUS_CHANGED =>
      OutputFileStatus.changed,
    wire.OutputFileStatus.OUTPUT_FILE_STATUS_KEPT => OutputFileStatus.kept,
    wire.OutputFileStatus.OUTPUT_FILE_STATUS_ABSENT => OutputFileStatus.absent,
    _ => throw const FormatException('Unknown output file status.'),
  },
  value.length.toInt(),
  value.sha256,
  DateTime.fromMillisecondsSinceEpoch(
    value.observedAtUnixMs.toInt(),
    isUtc: true,
  ),
  value.hasDeploymentId() ? value.deploymentId : null,
);
wire.OutputSelection selection(OutputSelection value) => wire.OutputSelection(
  locationId: value.locationId,
  path: modwire.ModLogicalPath(components: value.path),
);
wire.OutputDestination destination(OutputDestination value) => switch (value) {
  ExistingOutputMod() => wire.OutputDestination(
    existingMod: wire.ExistingOutputMod(
      modId: value.id,
      revision: Int64(value.revision),
      versionLabel: value.versionLabel,
    ),
  ),
  NewOutputMod() => wire.OutputDestination(
    newMod: wire.NewOutputMod(
      modId: value.id,
      name: value.name,
      versionLabel: value.versionLabel,
    ),
  ),
};
wire.OutputActionSpec action(OutputAction value) => switch (value) {
  KeepOutput() => wire.OutputActionSpec(
    kind: wire.OutputActionKind.OUTPUT_ACTION_KIND_KEEP,
  ),
  DiscardOutput() => wire.OutputActionSpec(
    kind: wire.OutputActionKind.OUTPUT_ACTION_KIND_DISCARD,
  ),
  MoveOutputToMod() => wire.OutputActionSpec(
    kind: wire.OutputActionKind.OUTPUT_ACTION_KIND_MOVE_TO_MOD,
    destination: destination(value.destination),
  ),
  SaveOutputCopy() => wire.OutputActionSpec(
    kind: wire.OutputActionKind.OUTPUT_ACTION_KIND_SAVE_COPY_TO_MOD,
    destination: destination(value.destination),
  ),
};
OutputActionResult result(wire.OutputActionResult value) => OutputActionResult(
  value.id,
  value.hasVersionId() ? value.versionId : null,
  value.published,
  List.unmodifiable(
    value.entries.map(
      (value) => OutputActionEntry(
        OutputSelection(
          value.file.locationId,
          List.unmodifiable(value.file.path.components),
        ),
        switch (value.disposition) {
          wire.OutputDisposition.OUTPUT_DISPOSITION_KEPT =>
            OutputDisposition.kept,
          wire.OutputDisposition.OUTPUT_DISPOSITION_DISCARDED =>
            OutputDisposition.discarded,
          wire.OutputDisposition.OUTPUT_DISPOSITION_MOVED =>
            OutputDisposition.moved,
          wire.OutputDisposition.OUTPUT_DISPOSITION_COPIED =>
            OutputDisposition.copied,
          wire.OutputDisposition.OUTPUT_DISPOSITION_CHANGED =>
            OutputDisposition.changed,
          wire.OutputDisposition.OUTPUT_DISPOSITION_PENDING =>
            OutputDisposition.pending,
          _ => throw const FormatException('Unknown output disposition.'),
        },
      ),
    ),
  ),
  value.complete,
);
OutputScope scopeReply(wire.OutputScopeReply value) =>
    switch (value.whichOutcome()) {
      wire.OutputScopeReply_Outcome.scope => scope(value.scope),
      wire.OutputScopeReply_Outcome.fault => reject(value.fault),
      wire.OutputScopeReply_Outcome.notSet => throw const FormatException(
        'Missing output locations.',
      ),
    };
OutputLocation locationReply(wire.OutputLocationReply value) =>
    switch (value.whichOutcome()) {
      wire.OutputLocationReply_Outcome.location => location(value.location),
      wire.OutputLocationReply_Outcome.fault => reject(value.fault),
      wire.OutputLocationReply_Outcome.notSet => throw const FormatException(
        'Missing output location.',
      ),
    };
OutputActionResult actionReply(wire.OutputActionReply value) =>
    switch (value.whichOutcome()) {
      wire.OutputActionReply_Outcome.result => result(value.result),
      wire.OutputActionReply_Outcome.fault => reject(value.fault),
      wire.OutputActionReply_Outcome.notSet => throw const FormatException(
        'Missing output action result.',
      ),
    };
OutputSnapshot snapshotReply(wire.OutputSnapshotReply value) =>
    switch (value.whichOutcome()) {
      wire.OutputSnapshotReply_Outcome.snapshot => snapshot(value.snapshot),
      wire.OutputSnapshotReply_Outcome.fault => reject(value.fault),
      wire.OutputSnapshotReply_Outcome.notSet => throw const FormatException(
        'Missing output observation.',
      ),
    };
