enum ArtifactStorage { reference, copy }

enum ArtifactState { incomplete, ready, detached, installed }

class ArtifactLink {
  const ArtifactLink(
    this.modId,
    this.versionId,
    this.modName,
    this.versionLabel, {
    this.installed = false,
  });
  final String modId, versionId, modName, versionLabel;
  final bool installed;
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
    this.download,
  });
  final String id, workspaceId, originalName, originalPath, path;
  final int revision;
  final ArtifactStorage storage;
  final ArtifactState state;
  final int? length;
  final String? sha256, problem;
  final List<ArtifactLink> links;
  final bool canRetry, canLocate, canDeleteCopy, canRemove;
  final ArtifactDownload? download;
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

enum DownloadPhase { queued, running, waiting, paused, failed, complete }

enum DownloadAction { pause, resume, restart }

class ArtifactDownload {
  const ArtifactDownload({
    required this.phase,
    required this.bytes,
    required this.source,
    required this.checksumMatched,
    required this.restartRequired,
    this.total,
    this.expectedSha256,
    this.retryAt,
  });
  final DownloadPhase phase;
  final int bytes;
  final int? total;
  final String source;
  final String? expectedSha256;
  final bool checksumMatched, restartRequired;
  final DateTime? retryAt;
  bool get active =>
      phase == DownloadPhase.queued ||
      phase == DownloadPhase.running ||
      phase == DownloadPhase.waiting;
}

class ArchiveDownloadRequest {
  const ArchiveDownloadRequest({
    required this.name,
    required this.sources,
    this.expectedLength,
    this.expectedSha256,
  });
  final String name;
  final List<String> sources;
  final int? expectedLength;
  final String? expectedSha256;
}
