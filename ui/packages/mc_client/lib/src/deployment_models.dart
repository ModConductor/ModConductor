enum DeploymentFailure {
  notFound,
  busy,
  stale,
  cancelled,
  blocked,
  unavailable,
}

class DeploymentException implements Exception {
  const DeploymentException(this.failure, this.detail);
  final DeploymentFailure failure;
  final String detail;
}

enum DeploymentPhase {
  preparing,
  applying,
  restoring,
  complete,
  restored,
  blocked,
}

class DeploymentProfile {
  const DeploymentProfile(this.id, this.name, this.revision, this.enabledMods);
  final String id, name;
  final int revision, enabledMods;
}

class SavedDeployment {
  const SavedDeployment(
    this.id,
    this.preparedAt,
    this.profile,
    this.known,
    this.active,
    this.fingerprint,
    this.canRestore, {this.unavailable}
  );
  final String id, fingerprint;
  final String? unavailable;
  final DateTime? preparedAt;
  final DeploymentProfile? profile;
  final bool known, active, canRestore;
}

class DeploymentState {
  const DeploymentState(
    this.workspaceId,
    this.revision,
    this.active,
    this.pendingReceipt,
    this.sourceToken,
  );
  final String workspaceId, sourceToken;
  final int revision;
  final SavedDeployment? active;
  final String? pendingReceipt;
}

class SavedDeploymentsPage {
  const SavedDeploymentsPage(this.entries, this.nextBefore);
  final List<SavedDeployment> entries;
  final int? nextBefore;
}

class PreparedDeployment {
  const PreparedDeployment(
    this.id,
    this.workspaceId,
    this.fingerprint,
    this.sourceToken,
    this.profile,
    this.writableFiles,
    this.changedPaths,
    this.preservedOriginals,
    this.managedLinks,
    this.copiedBytes,
    this.requiredBytes,
  );
  final String id, workspaceId, fingerprint, sourceToken;
  final DeploymentProfile? profile;
  final int writableFiles,
      changedPaths,
      preservedOriginals,
      managedLinks,
      copiedBytes,
      requiredBytes;
}

class DeploymentReceipt {
  const DeploymentReceipt(
    this.id,
    this.workspaceId,
    this.revision,
    this.phase,
    this.previous,
    this.proposed,
    this.completed,
    this.total,
    this.detail,
  );
  final String id, workspaceId, proposed, detail;
  final String? previous;
  final int revision, completed, total;
  final DeploymentPhase phase;
}

sealed class DeploymentEvent {
  const DeploymentEvent();
}

class DeploymentProgress extends DeploymentEvent {
  const DeploymentProgress(this.phase, this.completed, this.total, this.bytes);
  final DeploymentPhase phase;
  final int completed, total, bytes;
}

class DeploymentPrepared extends DeploymentEvent {
  const DeploymentPrepared(this.prepared);
  final PreparedDeployment prepared;
}

class DeploymentFinished extends DeploymentEvent {
  const DeploymentFinished(this.receipt);
  final DeploymentReceipt receipt;
}
