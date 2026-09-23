import 'file_plan_models.dart';

class ProfileDataRef {
  const ProfileDataRef({
    required this.workspaceId,
    required this.profileId,
    required this.contextId,
    required this.revision,
  });
  final String workspaceId, profileId, contextId;
  final int revision;
}

class ProfileDataOptions {
  const ProfileDataOptions({required this.settings, required this.saves});
  final bool settings, saves;
}

enum InitialProfileSaves { empty, copyGlobal }

enum DisabledProfileFiles { keep, delete }

enum ProfileDataProblemKind {
  notFound,
  busy,
  stale,
  cancelled,
  invalid,
  unavailable,
  conflict,
}

class ProfileDataProblem implements Exception {
  const ProfileDataProblem(this.kind, this.detail);
  final ProfileDataProblemKind kind;
  final String detail;
  @override
  String toString() => detail;
}

class ProfileDataState {
  const ProfileDataState({
    required this.reference,
    required this.options,
    required this.settingsPath,
    required this.savesPath,
    required this.settingsFiles,
    required this.saveFiles,
    this.inUseProfileId,
    this.pendingActionId,
    this.problem,
    this.pendingProfileChange = false,
    this.settingsInitialized = false,
    this.savesInitialized = false,
    this.pendingConfiguration,
  });
  final ProfileDataRef reference;
  final ProfileDataOptions options;
  final String settingsPath, savesPath;
  final int settingsFiles, saveFiles;
  final String? inUseProfileId, pendingActionId, problem, pendingConfiguration;
  final bool pendingProfileChange, settingsInitialized, savesInitialized;
}

class ProfileConfigurationFile {
  const ProfileConfigurationFile(this.name, this.exists, this.bytes);
  final String name;
  final bool exists;
  final int bytes;
}

class ProfileConfigurationDocument {
  const ProfileConfigurationDocument({
    required this.previewId,
    required this.expected,
    required this.name,
    required this.exists,
    required this.length,
    required this.document,
    this.sha256,
  });
  final String previewId, name;
  final ProfileDataRef expected;
  final bool exists;
  final int length;
  final String? sha256;
  final TextDocument document;
}

sealed class ProfileDataEvent {
  const ProfileDataEvent();
}

class ProfileDataProgress extends ProfileDataEvent {
  const ProfileDataProgress(this.files, this.bytes);
  final int files, bytes;
}

class ProfileDataResult extends ProfileDataEvent {
  const ProfileDataResult({
    required this.id,
    required this.state,
    required this.complete,
    required this.completedFiles,
    this.noChange = false,
    this.problem,
  });
  final String id;
  final ProfileDataState state;
  final bool complete;
  final bool noChange;
  final int completedFiles;
  final String? problem;
}

class ProfileSaveEntry {
  const ProfileSaveEntry(this.name, this.directory, this.bytes);
  final String name;
  final bool directory;
  final int bytes;
}

class ProfileSavePage {
  const ProfileSavePage(this.entries, this.next);
  final List<ProfileSaveEntry> entries;
  final String? next;
}

enum ProfileSaveSource { global, profile }

enum ProfileSaveEntryKind { save, directory, other }

class ProfileSavePath {
  const ProfileSavePath(this.hostPath, this.windowsPath);
  final String hostPath;
  final String? windowsPath;
}

class ProfileSaveGroupEntry {
  const ProfileSaveGroupEntry({
    required this.id,
    required this.name,
    required this.kind,
    required this.bytes,
    required this.companionBytes,
    required this.actionable,
    this.companion,
    this.problem,
  });
  final String id, name;
  final ProfileSaveEntryKind kind;
  final int bytes, companionBytes;
  final bool actionable;
  final String? companion, problem;
}

class ProfileSaveGroupPage {
  const ProfileSaveGroupPage(this.source, this.path, this.entries, this.next);
  final ProfileSaveSource source;
  final ProfileSavePath path;
  final List<ProfileSaveGroupEntry> entries;
  final String? next;
}

enum SkyrimSaveCompression { uncompressed, zlib, lz4 }

class SkyrimSaveMetadata {
  const SkyrimSaveMetadata({
    required this.headerVersion,
    required this.formVersion,
    required this.compression,
    required this.saveNumber,
    required this.character,
    required this.level,
    required this.location,
    required this.gameTime,
    required this.fullPlugins,
    required this.lightPlugins,
  });
  final int headerVersion, formVersion, saveNumber, level;
  final SkyrimSaveCompression compression;
  final String character, location, gameTime;
  final List<String> fullPlugins, lightPlugins;
}

enum SavePluginState { missing, inactive }

class SavePluginIssue {
  const SavePluginIssue(this.name, this.state, this.source);
  final String name;
  final SavePluginState state;
  final String? source;
}

class ProfileSaveInspection {
  const ProfileSaveInspection({
    required this.source,
    required this.path,
    required this.entry,
    required this.pluginIssues,
    this.metadata,
    this.metadataProblem,
    this.pluginCheckProblem,
  });
  final ProfileSaveSource source;
  final ProfileSavePath path;
  final ProfileSaveGroupEntry entry;
  final SkyrimSaveMetadata? metadata;
  final String? metadataProblem, pluginCheckProblem;
  final List<SavePluginIssue> pluginIssues;
}

enum ProfileSaveAction { copyToProfile, deleteFromProfile }

class ProfileSaveActionFile {
  const ProfileSaveActionFile(this.name, this.bytes);
  final String name;
  final int bytes;
}

class ProfileSaveActionPreview {
  const ProfileSaveActionPreview({
    required this.id,
    required this.expected,
    required this.action,
    required this.source,
    required this.files,
    required this.bytes,
    this.destination,
  });
  final String id;
  final ProfileDataRef expected;
  final ProfileSaveAction action;
  final ProfileSavePath source;
  final ProfileSavePath? destination;
  final List<ProfileSaveActionFile> files;
  final int bytes;
}
