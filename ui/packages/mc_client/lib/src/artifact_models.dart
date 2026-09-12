enum ArtifactStorage { reference, copy }

enum ArtifactState { incomplete, ready, detached, installed }

class ArtifactLink {
  const ArtifactLink(
    this.modId,
    this.versionId,
    this.modName,
    this.versionLabel,
  );
  final String modId, versionId, modName, versionLabel;
}

class Artifact {
  const Artifact({
    required this.id,
    required this.workspaceId,
    required this.revision,
    required this.originalName,
    required this.originalPath,
    required this.path,
    required this.storage,
    required this.state,
    required this.links,
    required this.canRetry,
    required this.canLocate,
    required this.canDeleteCopy,
    required this.canRemove,
    this.length,
    this.sha256,
    this.problem,
  });
  final String id, workspaceId, originalName, originalPath, path;
  final int revision;
  final ArtifactStorage storage;
  final ArtifactState state;
  final int? length;
  final String? sha256, problem;
  final List<ArtifactLink> links;
  final bool canRetry, canLocate, canDeleteCopy, canRemove;
}

class ArtifactPage {
  const ArtifactPage(this.entries, this.next);
  final List<Artifact> entries;
  final String? next;
}

class ArtifactLinkPage {
  const ArtifactLinkPage(this.entries, this.next);
  final List<ArtifactLink> entries;
  final String? next;
}

class ArtifactProblem implements Exception {
  const ArtifactProblem(this.detail);
  final String detail;
}
