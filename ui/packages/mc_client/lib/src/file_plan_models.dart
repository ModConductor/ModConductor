class ManagedFileCopy {
  ManagedFileCopy(this.modId, this.versionId, List<String> path)
    : path = List.unmodifiable(path);
  final String modId, versionId;
  final List<String> path;
  @override
  bool operator ==(Object other) =>
      other is ManagedFileCopy &&
      modId == other.modId &&
      versionId == other.versionId &&
      path.length == other.path.length &&
      Iterable<int>.generate(path.length)
          .every((index) => path[index] == other.path[index]);
  @override
  int get hashCode => Object.hash(modId, versionId, Object.hashAll(path));
}

class FilePlanCursor {
  const FilePlanCursor(this.identity, this.offset);
  final String identity;
  final int offset;
}

class FilePlanState {
  const FilePlanState({
    required this.id,
    required this.workspaceId,
    required this.profileId,
    required this.fingerprint,
    required this.loaded,
    required this.stale,
    required this.plannedFiles,
    required this.absentTargets,
    required this.inspectedFiles,
    required this.problems,
    required this.problemCount,
    this.observedAt,
  });
  final String id, workspaceId, profileId, fingerprint;
  final bool loaded, stale;
  final int plannedFiles, absentTargets, inspectedFiles, problemCount;
  final List<String> problems;
  final DateTime? observedAt;
}

enum PlannedFileDisposition { planned, absent, unresolved }

class PlannedFileNode {
  const PlannedFileNode({
    required this.path,
    required this.directory,
    required this.disposition,
    required this.sourceName,
    required this.copies,
  });
  final List<String> path;
  final bool directory;
  final PlannedFileDisposition disposition;
  final String sourceName;
  final int copies;
}

class FilePlanPage {
  const FilePlanPage(this.state, this.nodes, this.next);
  final FilePlanState state;
  final List<PlannedFileNode> nodes;
  final FilePlanCursor? next;
}

class InspectedFileCopy {
  const InspectedFileCopy({
    this.copy,
    required this.sourcePath,
    required this.name,
    required this.versionLabel,
    this.priority,
    required this.enabled,
    required this.hidden,
    required this.winner,
    required this.historical,
    required this.length,
    required this.sha256,
    required this.canHide,
    required this.canUnhide,
  });
  final ManagedFileCopy? copy;
  final List<String> sourcePath;
  final String name, versionLabel, sha256;
  final int? priority;
  final int length;
  final bool enabled, hidden, winner, historical, canHide, canUnhide;
}

class FilePlanInspection {
  const FilePlanInspection(
    this.state,
    this.target,
    this.copies,
    this.next, {
    this.focusedCopy,
  });
  final FilePlanState state;
  final List<String> target;
  final List<InspectedFileCopy> copies;
  final InspectedFileCopy? focusedCopy;
  final FilePlanCursor? next;
}

class FileVisibilityChange {
  const FileVisibilityChange(this.state, this.changed);
  final FilePlanState state;
  final PlannedFileNode? changed;
}

class FileVisibilityAudit {
  const FileVisibilityAudit({
    required this.id,
    required this.copy,
    required this.hidden,
    required this.beforeHidden,
    required this.profileId,
    required this.beforeFingerprint,
    required this.afterFingerprint,
    required this.recordedAt,
  });
  final int id;
  final ManagedFileCopy copy;
  final bool hidden, beforeHidden;
  final String profileId, beforeFingerprint, afterFingerprint;
  final DateTime recordedAt;
}

class FileVisibilityHistory {
  const FileVisibilityHistory(this.changes, this.nextBeforeId);
  final List<FileVisibilityAudit> changes;
  final int? nextBeforeId;
}

class FilePlanProblems {
  const FilePlanProblems(this.problems, this.next);
  final List<String> problems;
  final FilePlanCursor? next;
}

sealed class FilePlanLoadEvent {
  const FilePlanLoadEvent();
}

class FilePlanProgress extends FilePlanLoadEvent {
  const FilePlanProgress(
    this.files,
    this.totalFiles,
    this.bytes,
    this.totalBytes,
  );
  final int files, totalFiles, bytes, totalBytes;
}

class FilePlanLoaded extends FilePlanLoadEvent {
  const FilePlanLoaded(this.state);
  final FilePlanState state;
}

enum FilePlanFailure {
  notFound,
  busy,
  expired,
  stale,
  contextUnavailable,
  fileUnavailable,
  limitExceeded,
  cancelled,
  invalidCopy,
  blocked,
}

class FilePlanException implements Exception {
  const FilePlanException(this.failure, this.detail);
  final FilePlanFailure failure;
  final String detail;
}
