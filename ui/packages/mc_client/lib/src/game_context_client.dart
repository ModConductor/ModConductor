import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';

import 'generated/modconductor/v1/game_contexts.pbgrpc.dart' as wire;
import 'generated/modconductor/v1/game_catalogue.pbgrpc.dart' as catalogue;
import 'game_context_models.dart';
import 'proton_context_models.dart';
import 'proton_context_wire.dart';
export 'game_context_models.dart';

abstract interface class GameCatalogueClient {
  Future<List<GameDefinitionInfo>> read();
  Future<String?> openScriptExtenderPage(String gameId);
}

class GrpcGameCatalogueClient implements GameCatalogueClient {
  GrpcGameCatalogueClient(ClientChannel channel, CallOptions options)
    : _client = catalogue.GameCatalogueClient(channel, options: options);
  final catalogue.GameCatalogueClient _client;
  @override
  Future<String?> openScriptExtenderPage(String gameId) async {
    final reply = await _client.openScriptExtenderPage(
      catalogue.OpenScriptExtenderPageRequest(gameId: gameId),
    );
    return reply.problem.isEmpty ? null : reply.problem;
  }

  @override
  Future<List<GameDefinitionInfo>> read() async => List.unmodifiable(
    (await _client.readGameCatalogue(catalogue.ReadGameCatalogueRequest()))
        .games
        .map(decodeGameDefinition),
  );
}

abstract interface class GameContextsClient {
  Future<GameContextState> read(String workspaceId, String profileId);
  Future<GameContextState> save(
    String workspaceId,
    String profileId,
    String gameId,
    int revision,
    String path, {
    ProtonSelection? proton,
    WineSelection? wine,
  });
  Future<GameContextState> refresh(
    String workspaceId,
    String profileId,
    int revision,
  );
}

class GrpcGameContextsClient implements GameContextsClient {
  GrpcGameContextsClient(ClientChannel channel, CallOptions options)
    : _client = wire.GameContextOperationsClient(channel, options: options);
  final wire.GameContextOperationsClient _client;
  @override
  Future<GameContextState> read(String workspaceId, String profileId) async =>
      _reply(
        await _client.readGameContext(
          wire.ReadGameContextRequest(
            workspaceId: workspaceId,
            profileId: profileId,
          ),
        ),
      );
  @override
  Future<GameContextState> save(
    String workspaceId,
    String profileId,
    String gameId,
    int revision,
    String path, {
    ProtonSelection? proton,
    WineSelection? wine,
  }) async => _reply(
    await _client.saveGameContext(
      wire.SaveGameContextRequest(
        workspaceId: workspaceId,
        profileId: profileId,
        gameId: gameId,
        expectedRevision: Int64(revision),
        path: path,
        proton: proton == null ? null : encodeProtonSelection(proton),
        wine: wine == null
            ? null
            : wire.WineSelectionInfo(
                executable: wine.executable,
                prefix: wine.prefix,
              ),
      ),
      options: CallOptions(timeout: const Duration(seconds: 30)),
    ),
  );
  @override
  Future<GameContextState> refresh(
    String workspaceId,
    String profileId,
    int revision,
  ) async => _reply(
    await _client.refreshGameContext(
      wire.RefreshGameContextRequest(
        workspaceId: workspaceId,
        profileId: profileId,
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
        wire.GameContextPlatform.GAME_CONTEXT_PLATFORM_WINE =>
          GameContextPlatform.wine,
        _ => throw const FormatException('Unknown game platform.'),
      },
      rootPath: e.rootPath,
      proton: e.hasProton() ? decodeProtonEvidence(e.proton) : null,
      wine: e.hasWine()
          ? WineSelection(
              executable: e.wine.selection.executable,
              prefix: e.wine.selection.prefix,
            )
          : null,
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

GameContextPlatform? _platform(wire.GameContextPlatform value) =>
    switch (value) {
      wire.GameContextPlatform.GAME_CONTEXT_PLATFORM_WINDOWS =>
        GameContextPlatform.windows,
      wire.GameContextPlatform.GAME_CONTEXT_PLATFORM_PROTON =>
        GameContextPlatform.proton,
      wire.GameContextPlatform.GAME_CONTEXT_PLATFORM_WINE =>
        GameContextPlatform.wine,
      _ => null,
    };

GameCapability _capability(wire.GameCapabilityInfo value) => GameCapability(
  id: GameCapabilityId.fromWire(value.capabilityId),
  revision: value.revision,
  name: value.name,
  kind: switch (value.kind) {
    wire.GameCapabilityKind.GAME_CAPABILITY_KIND_CORE_OUTCOME =>
      GameCapabilityKind.coreOutcome,
    wire.GameCapabilityKind.GAME_CAPABILITY_KIND_GAME_ADAPTER =>
      GameCapabilityKind.gameAdapter,
    wire.GameCapabilityKind.GAME_CAPABILITY_KIND_OPTIONAL_LEGACY =>
      GameCapabilityKind.optionalLegacy,
    wire.GameCapabilityKind.GAME_CAPABILITY_KIND_OBSOLETE_MECHANISM =>
      GameCapabilityKind.obsolete,
    _ => GameCapabilityKind.unknown,
  },
  contexts: List.unmodifiable(
    value.contexts.map(
      (context) => GameCapabilityContext(
        definitionId: context.definitionId,
        platforms: List.unmodifiable(context.platforms.map(_platform).nonNulls),
      ),
    ),
  ),
  disposition: switch (value.disposition) {
    wire.GameCapabilityDisposition.GAME_CAPABILITY_DISPOSITION_AVAILABLE =>
      GameCapabilityDisposition.available,
    wire.GameCapabilityDisposition.GAME_CAPABILITY_DISPOSITION_UNAVAILABLE =>
      GameCapabilityDisposition.unavailable,
    wire.GameCapabilityDisposition.GAME_CAPABILITY_DISPOSITION_UNSUPPORTED =>
      GameCapabilityDisposition.unsupported,
    _ => GameCapabilityDisposition.unsupported,
  },
  reason: value.hasReason()
      ? value.reason
      : value.disposition ==
            wire
                .GameCapabilityDisposition
                .GAME_CAPABILITY_DISPOSITION_UNSPECIFIED
      ? 'This capability is not supported by this version of Mod Conductor.'
      : null,
);

GameDefinitionInfo decodeGameDefinition(wire.GameDefinitionInfo d) =>
    GameDefinitionInfo(
      id: d.definitionId,
      revision: d.revision,
      name: d.name,
      storefront: d.storefront,
      declaredSteamAppId: d.declaredSteamAppId,
      capabilities: List.unmodifiable(d.capabilities.map(_capability)),
      artworkUrl: d.artworkUrl,
      settingsIni: d.settingsIni,
      pluginOrdering: d.pluginOrdering,
      saveExtension: d.saveExtension,
      extenderName: d.extenderName,
      extenderLoader: d.extenderLoader,
      supportsLight: d.supportsLightPlugins,
      supportsMedium: d.supportsMediumPlugins,
      archiveInvalidation: d.archiveInvalidation,
    );

GameContextState _reply(wire.GameContextReply reply) {
  switch (reply.whichOutcome()) {
    case wire.GameContextReply_Outcome.state:
      final s = reply.state;
      final d = s.definition;
      return GameContextState(
        workspaceId: s.workspaceId,
        profileId: s.profileId,
        revision: s.revision.toInt(),
        definition: s.hasDefinition() ? decodeGameDefinition(d) : null,
        binding: s.hasBinding()
            ? GameBindingInfo(
                id: s.binding.bindingId,
                path: s.binding.path,
                proton: s.binding.hasProton()
                    ? decodeProtonSelection(s.binding.proton)
                    : null,
                wine: s.binding.hasWine()
                    ? WineSelection(
                        executable: s.binding.wine.executable,
                        prefix: s.binding.wine.prefix,
                      )
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
