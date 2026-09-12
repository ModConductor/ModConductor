import 'archive_inspection_models.dart';

class InstallationFile {
  const InstallationFile(this.index, this.destination);
  final int index;
  final List<String> destination;
}

class InstallationDraft {
  const InstallationDraft({
    required this.id,
    required this.workspaceId,
    required this.revision,
    required this.artifactId,
    required this.archiveName,
    required this.manifest,
    required this.root,
    required this.files,
    required this.name,
    required this.version,
    required this.bytes,
    required this.canInstall,
  });
  final String id, workspaceId, artifactId, archiveName, name, version;
  final int revision, bytes;
  final InspectedArchive manifest;
  final List<String> root;
  final List<InstallationFile> files;
  final bool canInstall;
}

sealed class InstallationLayoutChange {
  const InstallationLayoutChange();
}

class InstallationRootChange extends InstallationLayoutChange {
  const InstallationRootChange(this.components);
  final List<String> components;
}

class InstallationInclusionChange extends InstallationLayoutChange {
  const InstallationInclusionChange(this.source, this.included);
  final List<String> source;
  final bool included;
}

class InstallationDestinationChange extends InstallationLayoutChange {
  const InstallationDestinationChange(this.source, this.destination);
  final List<String> source, destination;
}

class InstallationMetadataChange extends InstallationLayoutChange {
  const InstallationMetadataChange(this.name, this.version);
  final String name, version;
}

enum InstallationPhase { running, stopped, complete, discarded }

class InstallationStatus {
  const InstallationStatus({
    required this.id,
    required this.workspaceId,
    required this.artifactId,
    required this.archiveName,
    required this.name,
    required this.version,
    required this.phase,
    required this.files,
    required this.totalFiles,
    required this.bytes,
    required this.totalBytes,
    this.isUpdate = false,
    this.temporaryBytes,
    this.problem,
    this.modId,
    this.versionId,
  });
  final String id, workspaceId, artifactId, archiveName, name, version;
  final String? problem, modId, versionId;
  final bool isUpdate;
  final InstallationPhase phase;
  final int files, totalFiles, bytes, totalBytes;
  final int? temporaryBytes;
}

class InstallationPreparation {
  const InstallationPreparation(this.result, this.cancel);
  final Future<InstallationDraft> result;
  final Future<void> Function() cancel;
}
