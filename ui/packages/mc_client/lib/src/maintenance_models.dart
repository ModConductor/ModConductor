enum UpdateMode { merge, replace }

enum UpdateChange { add, replace, remove, keep }

class UpdateFile {
  const UpdateFile(
    this.path,
    this.change,
    this.existingBytes,
    this.incomingBytes,
    this.existingPaths,
    this.hasIncoming,
  );
  final List<String> path;
  final UpdateChange change;
  final int? existingBytes, incomingBytes;
  final List<List<String>> existingPaths;
  final bool hasIncoming;
}

class UpdatePreview {
  const UpdatePreview({
    required this.id,
    required this.workspaceId,
    required this.modId,
    required this.name,
    required this.currentVersion,
    required this.nextVersion,
    required this.mode,
    required this.files,
    required this.keep,
    required this.requiredBytes,
    required this.sourceNotices,
  });
  final String id, workspaceId, modId, name, currentVersion, nextVersion;
  final UpdateMode mode;
  final List<UpdateFile> files;
  final List<List<String>> keep;
  final int requiredBytes;
  final List<String> sourceNotices;
}

enum DeletionFileKind { payload, archive, temporary, generationLink }

class DeletionFile {
  const DeletionFile(this.label, this.kind, this.bytes, this.shared);
  final String label;
  final DeletionFileKind kind;
  final int? bytes;
  final bool shared;
}

class DeletionProfile {
  const DeletionProfile(this.id, this.name);
  final String id, name;
}

class DeletionDeployment {
  const DeletionDeployment(
    this.contextId,
    this.id,
    this.name,
    this.preparedAt,
    this.active,
  );
  final String contextId, id, name;
  final DateTime? preparedAt;
  final bool active;
}

class DeletionPreview {
  const DeletionPreview({
    required this.id,
    required this.workspaceId,
    required this.modId,
    required this.revision,
    required this.name,
    required this.versions,
    required this.backups,
    required this.profiles,
    required this.deployments,
    required this.files,
    required this.external,
    this.blocked,
  });
  final String id, workspaceId, modId, name;
  final int revision, versions;
  final List<String> backups, external;
  final List<DeletionProfile> profiles;
  final List<DeletionDeployment> deployments;
  final List<DeletionFile> files;
  final String? blocked;
}

enum DeletionPhase { running, incomplete, complete }

class DeletionStatus {
  const DeletionStatus({
    required this.id,
    required this.workspaceId,
    required this.modId,
    required this.name,
    required this.phase,
    required this.remaining,
    this.problem,
  });
  final String id, workspaceId, modId, name;
  final DeletionPhase phase;
  final int remaining;
  final String? problem;
}
