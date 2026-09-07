import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';

import 'generated/modconductor/v1/game_contexts.pbgrpc.dart' as wire;
import 'game_context_models.dart';
import 'proton_context_models.dart';
import 'proton_context_wire.dart';
export 'game_context_models.dart';

abstract interface class GameContextsClient {
  Future<GameContextState> read(String workspaceId);
  Future<GameContextState> save(
    String workspaceId,
    int revision,
    String path, {
    ProtonSelection? proton,
  });
  Future<GameContextState> refresh(String workspaceId, int revision);
}

class GrpcGameContextsClient implements GameContextsClient {
  GrpcGameContextsClient(ClientChannel channel, CallOptions options)
    : _client = wire.GameContextOperationsClient(channel, options: options);
  final wire.GameContextOperationsClient _client;
  @override
  Future<GameContextState> read(String workspaceId) async => _reply(
    await _client.readGameContext(
      wire.ReadGameContextRequest(workspaceId: workspaceId),
    ),
  );
  @override
  Future<GameContextState> save(
    String workspaceId,
    int revision,
    String path, {
    ProtonSelection? proton,
  }) async => _reply(
    await _client.saveGameContext(
      wire.SaveGameContextRequest(
        workspaceId: workspaceId,
        expectedRevision: Int64(revision),
        path: path,
        proton: proton == null ? null : encodeProtonSelection(proton),
      ),
      options: CallOptions(timeout: const Duration(seconds: 30)),
    ),
  );
  @override
  Future<GameContextState> refresh(String workspaceId, int revision) async =>
      _reply(
        await _client.refreshGameContext(
          wire.RefreshGameContextRequest(
            workspaceId: workspaceId,
            expectedRevision: Int64(revision),
          ),
          options: CallOptions(timeout: const Duration(seconds: 30)),
        ),
      );
}

GameLocation _location(wire.GameLocation value) =>
    switch (value.whichResult()) {
      wire.GameLocation_Result.located => LocatedGameFolder(
        value.located.path,
        value.located.exists,
      ),
      wire.GameLocation_Result.unavailableReason => UnavailableGameLocation(
        value.unavailableReason,
      ),
      wire.GameLocation_Result.notSet => throw const FormatException(
        'Missing game location result.',
      ),
    };
GameInstallationEvidence _evidence(wire.GameInstallationEvidence e) =>
    GameInstallationEvidence(
      definitionId: e.definitionId,
      definitionRevision: e.definitionRevision,
      platform: switch (e.platform) {
        wire.GameContextPlatform.GAME_CONTEXT_PLATFORM_WINDOWS =>
          GameContextPlatform.windows,
        wire.GameContextPlatform.GAME_CONTEXT_PLATFORM_PROTON =>
          GameContextPlatform.proton,
        _ => throw const FormatException('Unknown game platform.'),
      },
      rootPath: e.rootPath,
      proton: e.hasProton() ? decodeProtonEvidence(e.proton) : null,
      dataPath: e.hasDataPath() ? e.dataPath : null,
      executable: e.hasExecutable()
          ? GameExecutableEvidence(
              path: e.executable.path,
              sha256: e.executable.sha256,
              length: e.executable.length.toInt(),
              fileVersion: e.executable.fileVersion,
              productVersion: e.executable.productVersion,
            )
          : null,
      launcherPath: e.hasLauncherPath() ? e.launcherPath : null,
      documents: _location(e.documents),
      saves: _location(e.saves),
      localAppData: _location(e.localAppData),
      problems: List.unmodifiable(
        e.problems.map((p) => GameValidationProblem(p.path, p.detail)),
      ),
      checkedAt: DateTime.fromMillisecondsSinceEpoch(
        e.checkedAtUnixMs.toInt(),
        isUtc: true,
      ),
      fingerprint: e.fingerprint,
    );
GameContextState _reply(wire.GameContextReply reply) {
  switch (reply.whichOutcome()) {
    case wire.GameContextReply_Outcome.state:
      final s = reply.state;
      final d = s.definition;
      return GameContextState(
        workspaceId: s.workspaceId,
        revision: s.revision.toInt(),
        definition: GameDefinitionInfo(
          id: d.definitionId,
          revision: d.revision,
          name: d.name,
          storefront: d.storefront,
          declaredSteamAppId: d.declaredSteamAppId,
          unavailableCapabilities: List.unmodifiable(
            d.unavailableCapabilities.map(
              (c) => UnavailableGameCapability(c.name, c.reason),
            ),
          ),
        ),
        binding: s.hasBinding()
            ? GameBindingInfo(
                id: s.binding.bindingId,
                path: s.binding.path,
                proton: s.binding.hasProton()
                    ? decodeProtonSelection(s.binding.proton)
                    : null,
                evidence: _evidence(s.binding.evidence),
                needsCheck: s.binding.needsCheck,
                failure: s.binding.hasFailure() ? s.binding.failure : null,
              )
            : null,
      );
    case wire.GameContextReply_Outcome.fault:
      final f = reply.fault;
      final code = switch (f.code) {
        wire.GameContextFaultCode.GAME_CONTEXT_FAULT_NOT_FOUND =>
          GameContextFailure.notFound,
        wire.GameContextFaultCode.GAME_CONTEXT_FAULT_STALE_REVISION =>
          GameContextFailure.stale,
        wire.GameContextFaultCode.GAME_CONTEXT_FAULT_WORKSPACE_UNAVAILABLE =>
          GameContextFailure.workspaceUnavailable,
        wire.GameContextFaultCode.GAME_CONTEXT_FAULT_INVALID_INSTALLATION =>
          GameContextFailure.invalidInstallation,
        wire.GameContextFaultCode.GAME_CONTEXT_FAULT_BUSY =>
          GameContextFailure.busy,
        _ => throw const FormatException('Unknown game context failure.'),
      };
      throw GameContextException(
        code,
        f.detail,
        candidate: f.hasCandidate() ? _evidence(f.candidate) : null,
      );
    case wire.GameContextReply_Outcome.notSet:
      throw const FormatException('Missing game context reply.');
  }
}
