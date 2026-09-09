import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';

import 'generated/modconductor/v1/executables.pbgrpc.dart' as wire;
import 'completed_events.dart';
import 'executable_models.dart';
import 'game_launch_models.dart';
export 'executable_models.dart';

abstract interface class ExecutablesClient {
  Future<ExecutablePresetPage> list(String workspaceId, {String? after});
  Future<ExecutablePreset> readPreset(String workspaceId, String id);
  Future<ExecutablePreset> save(ExecutablePreset preset);
  Future<void> delete(String workspaceId, String id, int expectedRevision);
  Future<ExecutableRun> begin(ExecutableRunRequest request);
  Future<ExecutableRun> read(String workspaceId, String id);
  Future<ExecutableRunPage> recent(String workspaceId, {String? after});
  Stream<ExecutableRun> observe(String workspaceId, String id);
  Future<ExecutableRun> stopWaiting(String workspaceId, String id);
}

class GrpcExecutablesClient implements ExecutablesClient {
  GrpcExecutablesClient(ClientChannel channel, CallOptions options)
    : _client = wire.ExecutableOperationsClient(channel, options: options);
  final wire.ExecutableOperationsClient _client;
  @override
  Future<ExecutablePresetPage> list(String workspaceId, {String? after}) async {
    final response = await _client.listExecutablePresets(
      wire.ExecutablePageRequest(workspaceId: workspaceId, afterId: after),
    );
    if (response.hasProblem()) throw readExecutableProblem(response.problem);
    return ExecutablePresetPage(
      List.unmodifiable(response.presets.map(_preset)),
      response.hasNextId() ? response.nextId : null,
      List.unmodifiable(response.latestRuns.map(readExecutableRun)),
    );
  }

  @override
  Future<ExecutablePreset> readPreset(String workspaceId, String id) async {
    final response = await _client.readExecutablePreset(
      wire.ExecutablePresetRef(workspaceId: workspaceId, id: id),
    );
    return switch (response.whichResult()) {
      wire.ExecutablePresetReply_Result.preset => _preset(response.preset),
      wire.ExecutablePresetReply_Result.problem => throw readExecutableProblem(
        response.problem,
      ),
      _ => throw const FormatException(
        'The executable read reply is incomplete.',
      ),
    };
  }

  @override
  Future<ExecutablePreset> save(ExecutablePreset preset) async {
    final response = await _client.saveExecutablePreset(_presetWire(preset));
    return switch (response.whichResult()) {
      wire.ExecutablePresetReply_Result.preset => _preset(response.preset),
      wire.ExecutablePresetReply_Result.problem => throw readExecutableProblem(
        response.problem,
      ),
      _ => throw const FormatException(
        'The executable save reply is incomplete.',
      ),
    };
  }

  @override
  Future<void> delete(
    String workspaceId,
    String id,
    int expectedRevision,
  ) async {
    final response = await _client.deleteExecutablePreset(
      wire.DeleteExecutablePresetRequest(
        workspaceId: workspaceId,
        id: id,
        expectedRevision: Int64(expectedRevision),
      ),
    );
    if (response.hasProblem()) throw readExecutableProblem(response.problem);
  }

  @override
  Future<ExecutableRun> begin(ExecutableRunRequest request) async =>
      readExecutableRunReply(
        await _client.beginExecutableRun(_requestWire(request)),
      );
  @override
  Future<ExecutableRun> read(String workspaceId, String id) async =>
      readExecutableRunReply(
        await _client.readExecutableRun(
          wire.ExecutableRunRef(workspaceId: workspaceId, id: id),
        ),
      );
  @override
  Future<ExecutableRun> stopWaiting(String workspaceId, String id) async =>
      readExecutableRunReply(
        await _client.stopWaitingForExecutable(
          wire.ExecutableRunRef(workspaceId: workspaceId, id: id),
        ),
      );
  @override
  Future<ExecutableRunPage> recent(String workspaceId, {String? after}) async {
    final response = await _client.readExecutableRuns(
      wire.ExecutablePageRequest(workspaceId: workspaceId, afterId: after),
    );
    if (response.hasProblem()) throw readExecutableProblem(response.problem);
    return ExecutableRunPage(
      List.unmodifiable(response.runs.map(readExecutableRun)),
      response.hasNextId() ? response.nextId : null,
    );
  }

  @override
  Stream<ExecutableRun> observe(String workspaceId, String id) =>
      completedEvents(
        _client.observeExecutableRun(
          wire.ExecutableRunRef(workspaceId: workspaceId, id: id),
        ),
        (event) =>
            !event.hasRun() ||
            ![
              wire.ExecutableRunPhase.EXECUTABLE_RUN_PHASE_STARTING,
              wire.ExecutableRunPhase.EXECUTABLE_RUN_PHASE_RUNNING,
              wire.ExecutableRunPhase.EXECUTABLE_RUN_PHASE_WAITING_FOR_CHILDREN,
            ].contains(event.run.phase),
        readExecutableRunReply,
      );
}

ExecutableException readExecutableProblem(wire.ExecutableProblem value) =>
    ExecutableException(switch (value.code) {
      wire.ExecutableProblemCode.EXECUTABLE_PROBLEM_CODE_NOT_FOUND =>
        ExecutableFailure.notFound,
      wire.ExecutableProblemCode.EXECUTABLE_PROBLEM_CODE_STALE_REVISION =>
        ExecutableFailure.staleRevision,
      wire.ExecutableProblemCode.EXECUTABLE_PROBLEM_CODE_IDENTITY_CONFLICT =>
        ExecutableFailure.identityConflict,
      wire.ExecutableProblemCode.EXECUTABLE_PROBLEM_CODE_CAPACITY =>
        ExecutableFailure.capacity,
      wire.ExecutableProblemCode.EXECUTABLE_PROBLEM_CODE_INVALID =>
        ExecutableFailure.invalid,
      wire.ExecutableProblemCode.EXECUTABLE_PROBLEM_CODE_UNAVAILABLE =>
        ExecutableFailure.unavailable,
      _ => throw const FormatException(
        'The executable failure code is unsupported.',
      ),
    }, value.detail);
ExecutablePreset _preset(wire.ExecutablePreset value) => ExecutablePreset(
  id: value.id,
  workspaceId: value.workspaceId,
  revision: value.revision.toInt(),
  name: value.name,
  executable: value.executable,
  workingDirectory: value.workingDirectory,
  arguments: value.arguments,
  environment: [
    for (final setting in value.environment)
      ExecutableEnvironment(
        setting.name,
        setting.hasValue() ? setting.value : null,
      ),
  ],
);
wire.ExecutablePreset _presetWire(ExecutablePreset value) =>
    wire.ExecutablePreset(
      id: value.id,
      workspaceId: value.workspaceId,
      revision: Int64(value.revision),
      name: value.name,
      executable: value.executable,
      workingDirectory: value.workingDirectory,
      arguments: value.arguments,
      environment: [
        for (final setting in value.environment)
          wire.ExecutableEnvironmentSetting(
            name: setting.name,
            value: setting.value,
          ),
      ],
    );
wire.ExecutableRunRequest _requestWire(ExecutableRunRequest value) =>
    wire.ExecutableRunRequest(
      id: value.id,
      workspaceId: value.workspaceId,
      workspaceRevision: Int64(value.workspaceRevision),
      presetId: value.presetId,
      presetRevision: Int64(value.presetRevision),
    );
ExecutableRun readExecutableRunReply(wire.ExecutableRunReply value) =>
    switch (value.whichResult()) {
      wire.ExecutableRunReply_Result.run => readExecutableRun(value.run),
      wire.ExecutableRunReply_Result.problem => throw readExecutableProblem(
        value.problem,
      ),
      _ => throw const FormatException(
        'The executable run reply is incomplete.',
      ),
    };
ExecutableRun readExecutableRun(wire.ExecutableRun value) {
  if (value.hasGame()
      ? (value.hasPreset() || value.hasRequest())
      : (!value.hasPreset() || !value.hasRequest())) {
    throw const FormatException('The executable run is incomplete.');
  }
  final request = value.request;
  return ExecutableRun(
    request: value.hasGame()
        ? null
        : ExecutableRunRequest(
            id: request.id,
            workspaceId: request.workspaceId,
            workspaceRevision: request.workspaceRevision.toInt(),
            presetId: request.presetId,
            presetRevision: request.presetRevision.toInt(),
          ),
    revision: value.revision.toInt(),
    preset: value.hasGame() ? null : _preset(value.preset),
    game: value.hasGame() ? readGameRun(value.game) : null,
    profileId: value.hasProfileId() ? value.profileId : null,
    profileName: value.hasProfileName() ? value.profileName : null,
    requestedAt: DateTime.parse(value.requestedAt),
    phase: switch (value.phase) {
      wire.ExecutableRunPhase.EXECUTABLE_RUN_PHASE_STARTING =>
        ExecutableRunPhase.starting,
      wire.ExecutableRunPhase.EXECUTABLE_RUN_PHASE_RUNNING =>
        ExecutableRunPhase.running,
      wire.ExecutableRunPhase.EXECUTABLE_RUN_PHASE_WAITING_FOR_CHILDREN =>
        ExecutableRunPhase.waitingForChildren,
      wire.ExecutableRunPhase.EXECUTABLE_RUN_PHASE_FINISHED =>
        ExecutableRunPhase.finished,
      wire.ExecutableRunPhase.EXECUTABLE_RUN_PHASE_FAILED =>
        ExecutableRunPhase.failed,
      wire.ExecutableRunPhase.EXECUTABLE_RUN_PHASE_DETACHED =>
        ExecutableRunPhase.detached,
      wire.ExecutableRunPhase.EXECUTABLE_RUN_PHASE_TRACKING_UNAVAILABLE =>
        ExecutableRunPhase.trackingUnavailable,
      _ => throw const FormatException(
        'The executable run phase is unsupported.',
      ),
    },
    processId: value.hasProcessId() ? value.processId : null,
    scope: value.hasScope() ? value.scope : null,
    rootExitCode: value.hasRootExitCode() ? value.rootExitCode : null,
    observedProcessCount: value.hasObservedProcessCount()
        ? value.observedProcessCount
        : null,
    problem: value.hasProblem() ? value.problem : null,
  );
}

GameRunInfo readGameRun(wire.GameRunInfo value) {
  if (!value.hasRequest()) {
    throw const FormatException('The game run request is missing.');
  }
  final request = value.request;
  return GameRunInfo(
    request: GameRunRequest(
      id: request.id,
      workspaceId: request.workspaceId,
      workspaceRevision: request.workspaceRevision.toInt(),
      profileId: request.profileId,
      contextRevision: request.contextRevision.toInt(),
      sourceToken: request.sourceToken,
    ),
    contextId: value.contextId,
    name: value.name,
    gameDirectory: value.gameDirectory,
    runtime: value.runtime,
    executable: value.executable,
    arguments: List.unmodifiable(value.arguments),
    workingDirectory: value.workingDirectory,
    environment: List.unmodifiable(
      value.environment.map(
        (v) => ExecutableEnvironment(v.name, v.hasValue() ? v.value : null),
      ),
    ),
    preparation: switch (value.preparation) {
      wire.GamePreparationPhase.GAME_PREPARATION_PHASE_PREPARING =>
        GamePreparationPhase.preparing,
      wire.GamePreparationPhase.GAME_PREPARATION_PHASE_APPLYING =>
        GamePreparationPhase.applying,
      wire.GamePreparationPhase.GAME_PREPARATION_PHASE_READY =>
        GamePreparationPhase.ready,
      _ => throw const FormatException(
        'The game preparation phase is unsupported.',
      ),
    },
    completed: value.completed,
    total: value.total,
    files: value.hasFiles()
        ? GameRunFiles(
            value.files.receiptId,
            value.files.generationId,
            value.files.fingerprint,
          )
        : null,
  );
}
