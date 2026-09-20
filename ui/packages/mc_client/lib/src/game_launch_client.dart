import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';

import 'generated/modconductor/v1/game_launch.pbgrpc.dart' as wire;
import 'generated/modconductor/v1/executables.pb.dart' as execution;
import 'executable_client.dart';
import 'game_launch_models.dart';
export 'game_launch_models.dart';

abstract interface class GameLaunchingClient {
  Future<GameLaunchState> read(String workspaceId, String profileId);
  Future<ExecutableRun> play(
    GameRunRequest request, {
    bool continueStaleFnis = false,
  });
  Future<ExecutableRun> cancel(String workspaceId, String id);
}

class GrpcGameLaunchingClient implements GameLaunchingClient {
  GrpcGameLaunchingClient(ClientChannel channel, CallOptions options)
    : _client = wire.GameLaunchOperationsClient(channel, options: options);
  final wire.GameLaunchOperationsClient _client;
  @override
  Future<GameLaunchState> read(String workspaceId, String profileId) async {
    final response = await _client.readGameLaunch(
      wire.GameLaunchStateRequest(
        workspaceId: workspaceId,
        profileId: profileId,
      ),
    );
    if (response.hasProblem()) throw readExecutableProblem(response.problem);
    if (!response.hasState()) {
      throw const FormatException('The game launch state is missing.');
    }
    final value = response.state;
    return GameLaunchState(
      workspaceId: value.workspaceId,
      profileId: value.profileId,
      contextRevision: value.contextRevision.toInt(),
      sourceToken: value.sourceToken,
      name: value.name,
      runtime: value.runtime,
      problem: value.hasProblem() ? value.problem : null,
      latest: value.hasLatest() ? readExecutableRun(value.latest) : null,
      fnisStale: value.fnisStale,
      fnisStatus: value.fnisStatus,
      canRunFnis: value.canRunFnis,
    );
  }

  @override
  Future<ExecutableRun> play(
    GameRunRequest request, {
    bool continueStaleFnis = false,
  }) async => readExecutableRunReply(
    await (continueStaleFnis
        ? _client.playGameContinuingFnis
        : _client.playGame)(
      execution.GameRunRequest(
        id: request.id,
        workspaceId: request.workspaceId,
        workspaceRevision: Int64(request.workspaceRevision),
        profileId: request.profileId,
        contextRevision: Int64(request.contextRevision),
        sourceToken: request.sourceToken,
      ),
    ),
  );
  @override
  Future<ExecutableRun> cancel(String workspaceId, String id) async =>
      readExecutableRunReply(
        await _client.cancelGameLaunch(
          execution.ExecutableRunRef(workspaceId: workspaceId, id: id),
        ),
      );
}
