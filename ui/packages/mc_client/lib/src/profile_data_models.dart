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
  });
  final ProfileDataRef reference;
  final ProfileDataOptions options;
  final String settingsPath, savesPath;
  final int settingsFiles, saveFiles;
  final String? inUseProfileId, pendingActionId, problem;
  final bool pendingProfileChange;
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
    this.problem,
  });
  final String id;
  final ProfileDataState state;
  final bool complete;
  final int completedFiles;
  final String? problem;
}
