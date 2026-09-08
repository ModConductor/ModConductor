import 'generated/modconductor/v1/deployments.pb.dart' as wire;
import 'deployment_models.dart';

Never reject(wire.DeploymentFault value) => throw DeploymentException(
  switch (value.code) {
    wire.DeploymentFaultCode.DEPLOYMENT_FAULT_NOT_FOUND =>
      DeploymentFailure.notFound,
    wire.DeploymentFaultCode.DEPLOYMENT_FAULT_BUSY => DeploymentFailure.busy,
    wire.DeploymentFaultCode.DEPLOYMENT_FAULT_STALE => DeploymentFailure.stale,
    wire.DeploymentFaultCode.DEPLOYMENT_FAULT_CANCELLED =>
      DeploymentFailure.cancelled,
    wire.DeploymentFaultCode.DEPLOYMENT_FAULT_BLOCKED =>
      DeploymentFailure.blocked,
    wire.DeploymentFaultCode.DEPLOYMENT_FAULT_UNAVAILABLE =>
      DeploymentFailure.unavailable,
    _ => throw const FormatException('Unknown deployment failure.'),
  },
  value.detail,
);
DeploymentProfile profile(wire.DeploymentProfile value) => DeploymentProfile(
  value.id,
  value.name,
  value.revision.toInt(),
  value.enabledMods,
);
SavedDeployment saved(wire.SavedDeployment value) => SavedDeployment(
  value.id,
  value.hasPreparedAtUnixMs()
      ? DateTime.fromMillisecondsSinceEpoch(
          value.preparedAtUnixMs.toInt(),
          isUtc: true,
        )
      : null,
  value.hasProfile() ? profile(value.profile) : null,
  value.known,
  value.active,
  value.fingerprint,
  value.canRestore,
);
DeploymentPhase phase(wire.DeploymentPhase value) => switch (value) {
  wire.DeploymentPhase.DEPLOYMENT_PHASE_PREPARING => DeploymentPhase.preparing,
  wire.DeploymentPhase.DEPLOYMENT_PHASE_APPLYING => DeploymentPhase.applying,
  wire.DeploymentPhase.DEPLOYMENT_PHASE_RESTORING => DeploymentPhase.restoring,
  wire.DeploymentPhase.DEPLOYMENT_PHASE_COMPLETE => DeploymentPhase.complete,
  wire.DeploymentPhase.DEPLOYMENT_PHASE_RESTORED => DeploymentPhase.restored,
  wire.DeploymentPhase.DEPLOYMENT_PHASE_BLOCKED => DeploymentPhase.blocked,
  _ => throw const FormatException('Unknown deployment phase.'),
};
DeploymentProgress progress(wire.DeploymentProgress value) =>
    DeploymentProgress(
      phase(value.phase),
      value.completed,
      value.total,
      value.bytes.toInt(),
    );
DeploymentState stateReply(wire.DeploymentStateReply value) =>
    switch (value.whichOutcome()) {
      wire.DeploymentStateReply_Outcome.state => DeploymentState(
        value.state.workspaceId,
        value.state.revision.toInt(),
        value.state.hasActive() ? saved(value.state.active) : null,
        value.state.hasPendingReceipt() ? value.state.pendingReceipt : null,
        value.state.sourceToken,
      ),
      wire.DeploymentStateReply_Outcome.fault => reject(value.fault),
      wire.DeploymentStateReply_Outcome.notSet => throw const FormatException(
        'Missing deployment state.',
      ),
    };
PreparedDeployment preparedReply(wire.PreparedDeploymentReply value) =>
    switch (value.whichOutcome()) {
      wire.PreparedDeploymentReply_Outcome.prepared => PreparedDeployment(
        value.prepared.id,
        value.prepared.workspaceId,
        value.prepared.fingerprint,
        value.prepared.sourceToken,
        value.prepared.hasProfile() ? profile(value.prepared.profile) : null,
        value.prepared.writableFiles,
        value.prepared.changedPaths,
        value.prepared.preservedOriginals,
        value.prepared.managedLinks,
        value.prepared.copiedBytes.toInt(),
        value.prepared.requiredBytes.toInt(),
      ),
      wire.PreparedDeploymentReply_Outcome.fault => reject(value.fault),
      wire.PreparedDeploymentReply_Outcome.notSet =>
        throw const FormatException('Missing prepared deployment.'),
    };
DeploymentReceipt receiptReply(wire.DeploymentReceiptReply value) =>
    switch (value.whichOutcome()) {
      wire.DeploymentReceiptReply_Outcome.receipt => DeploymentReceipt(
        value.receipt.id,
        value.receipt.workspaceId,
        value.receipt.revision.toInt(),
        phase(value.receipt.phase),
        value.receipt.hasPrevious() ? value.receipt.previous : null,
        value.receipt.proposed,
        value.receipt.completed,
        value.receipt.total,
        value.receipt.detail,
      ),
      wire.DeploymentReceiptReply_Outcome.fault => reject(value.fault),
      wire.DeploymentReceiptReply_Outcome.notSet => throw const FormatException(
        'Missing deployment receipt.',
      ),
    };
