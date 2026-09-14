import 'game_launch_models.dart';

enum ExecutableFailure {
  notFound,
  staleRevision,
  identityConflict,
  capacity,
  invalid,
  unavailable,
}

class ExecutableException implements Exception {
  const ExecutableException(this.failure, this.detail);
  final ExecutableFailure failure;
  final String detail;
}

class ExecutableEnvironment {
  const ExecutableEnvironment(this.name, this.value);
  final String name;
  final String? value;
}

class ExecutablePreset {
  ExecutablePreset({
    required this.id,
    required this.workspaceId,
    required this.revision,
    required this.name,
    required this.executable,
    required this.workingDirectory,
    required List<String> arguments,
    required List<ExecutableEnvironment> environment,
  }) : arguments = List.unmodifiable(arguments),
       environment = List.unmodifiable(environment);
  final String id, workspaceId, name, executable, workingDirectory;
  final int revision;
  final List<String> arguments;
  final List<ExecutableEnvironment> environment;
}

class ExecutablePresetPage {
  const ExecutablePresetPage(this.presets, this.next, this.latestRuns);
  final List<ExecutableRun> latestRuns;
  final List<ExecutablePreset> presets;
  final String? next;
}

class ExecutableRunRequest {
  const ExecutableRunRequest({
    required this.id,
    required this.workspaceId,
    required this.workspaceRevision,
    required this.presetId,
    required this.presetRevision,
  });
  final String id, workspaceId, presetId;
  final int workspaceRevision, presetRevision;
}

enum ExecutableRunPhase {
  starting,
  running,
  waitingForChildren,
  finished,
  failed,
  cancelled,
  detached,
  trackingUnavailable,
}

class ExecutableRun {
  const ExecutableRun({
    required this.request,
    required this.revision,
    required this.preset,
    this.game,
    required this.profileId,
    required this.profileName,
    required this.requestedAt,
    required this.phase,
    required this.processId,
    required this.scope,
    required this.rootExitCode,
    required this.observedProcessCount,
    required this.problem,
  });
  final ExecutableRunRequest? request;
  final GameRunInfo? game;
  final int revision;
  final ExecutablePreset? preset;
  String get id => request?.id ?? game!.request.id;
  String get workspaceId => request?.workspaceId ?? game!.request.workspaceId;
  String get name => preset?.name ?? game!.name;
  String get executable => preset?.executable ?? game!.executable;
  String get workingDirectory =>
      preset?.workingDirectory ?? game!.workingDirectory;
  List<String> get arguments => preset?.arguments ?? game!.arguments;
  List<ExecutableEnvironment> get environment =>
      preset?.environment ?? game!.environment;
  final String? profileId, profileName, scope, problem;
  final DateTime requestedAt;
  final ExecutableRunPhase phase;
  final int? processId, rootExitCode, observedProcessCount;
  bool get terminal => switch (phase) {
    ExecutableRunPhase.starting ||
    ExecutableRunPhase.running ||
    ExecutableRunPhase.waitingForChildren => false,
    ExecutableRunPhase.finished ||
    ExecutableRunPhase.failed ||
    ExecutableRunPhase.cancelled ||
    ExecutableRunPhase.detached ||
    ExecutableRunPhase.trackingUnavailable => true,
  };
}

class ExecutableRunPage {
  const ExecutableRunPage(this.runs, this.next);
  final List<ExecutableRun> runs;
  final String? next;
}
