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
