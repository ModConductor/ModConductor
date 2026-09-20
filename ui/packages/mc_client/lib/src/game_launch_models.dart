import 'executable_models.dart';

class GameRunRequest {
  const GameRunRequest({
    required this.id,
    required this.workspaceId,
    required this.workspaceRevision,
    required this.profileId,
    required this.contextRevision,
    required this.sourceToken,
  });
  final String id, workspaceId, profileId, sourceToken;
  final int workspaceRevision, contextRevision;
}

enum GamePreparationPhase { preparing, applying, ready, profileData }

class GameRunFiles {
  const GameRunFiles(this.receiptId, this.generationId, this.fingerprint);
  final String receiptId, generationId, fingerprint;
}

class GameRunProfileData {
  const GameRunProfileData(
    this.receiptId,
    this.revision,
    this.completedFiles,
    this.complete,
  );
  final String receiptId;
  final int revision, completedFiles;
  final bool complete;
}

class GameRunInfo {
  const GameRunInfo({
    required this.request,
    required this.contextId,
    required this.name,
    required this.gameDirectory,
    required this.runtime,
    required this.executable,
    required this.arguments,
    required this.workingDirectory,
    required this.environment,
    required this.preparation,
    required this.completed,
    required this.total,
    required this.files,
    this.profileDataRevision = 0,
    this.profileData,
  });
  final GameRunRequest request;
  final String contextId,
      name,
      gameDirectory,
      runtime,
      executable,
      workingDirectory;
  final List<String> arguments;
  final List<ExecutableEnvironment> environment;
  final GamePreparationPhase preparation;
  final int completed, total;
  final GameRunFiles? files;
  final int profileDataRevision;
  final GameRunProfileData? profileData;
}

class GameLaunchState {
  const GameLaunchState({
    required this.workspaceId,
    required this.profileId,
    required this.contextRevision,
    required this.sourceToken,
    required this.name,
    required this.runtime,
    required this.problem,
    required this.latest,
    this.fnisStale = false,
    this.fnisStatus = '',
    this.canRunFnis = false,
  });
  final String workspaceId, profileId, sourceToken, name, runtime;
  final int contextRevision;
  final String? problem;
  final ExecutableRun? latest;
  final bool fnisStale, canRunFnis;
  final String fnisStatus;
}
