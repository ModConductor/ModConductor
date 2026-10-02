import 'package:grpc/grpc.dart';

import 'generated/modconductor/v1/game_registration.pbgrpc.dart' as wire;
import 'game_context_client.dart';
import 'steam_discovery_client.dart';
export 'generated/modconductor/v1/game_registration.pb.dart'
    show CustomGameDraft, ThunderstoreGameInfo;

class GameDetection {
  const GameDetection(
    this.draft,
    this.executables,
    this.problem, {
    this.detectedEngine = '',
  });
  final String detectedEngine;
  final wire.CustomGameDraft draft;
  final List<String> executables;
  final String? problem;
}

class GameRegistrationResult {
  const GameRegistrationResult(this.game, this.problem);
  final GameDefinitionInfo? game;
  final String? problem;
}

class ThunderstoreGamesResult {
  const ThunderstoreGamesResult(this.games, this.problem);
  final List<wire.ThunderstoreGameInfo> games;
  final String? problem;
}

abstract interface class GameRegistrationClient {
  Future<SteamSearchResult> installedGames(List<String> roots);
  Future<ThunderstoreGamesResult> searchGames(String query);
  Future<GameDetection> detectGame(
    String path,
    String name,
    int appId,
    String metadataId,
  );
  Future<wire.CustomGameDraft?> readCustomGame(String id);
  Future<GameRegistrationResult> saveCustomGame(wire.CustomGameDraft draft);
}

class GrpcGameRegistrationClient implements GameRegistrationClient {
  GrpcGameRegistrationClient(ClientChannel channel, CallOptions options)
    : _client = wire.GameRegistrationClient(channel, options: options);
  final wire.GameRegistrationClient _client;
  @override
  Future<SteamSearchResult> installedGames(List<String> roots) async =>
      decodeSteamSearchResult(
        await _client.listInstalledGames(
          wire.ListInstalledGamesRequest(additionalRoots: roots),
        ),
      );
  @override
  Future<ThunderstoreGamesResult> searchGames(String query) async {
    final result = await _client.searchThunderstoreGames(
      wire.SearchThunderstoreGamesRequest(query: query),
    );
    return ThunderstoreGamesResult(
      result.games,
      result.problem.isEmpty ? null : result.problem,
    );
  }

  @override
  Future<GameDetection> detectGame(
    String path,
    String name,
    int appId,
    String metadataId,
  ) async {
    final result = await _client.detectGame(
      wire.DetectGameRequest(
        path: path,
        name: name,
        steamAppId: appId,
        thunderstoreId: metadataId,
      ),
    );
    return GameDetection(
      result.draft,
      result.executableChoices,
      result.problem.isEmpty ? null : result.problem,
      detectedEngine: result.detectedEngine,
    );
  }

  @override
  Future<wire.CustomGameDraft?> readCustomGame(String id) async {
    final result = await _client.readCustomGame(
      wire.ReadCustomGameRequest(id: id),
    );
    return result.hasDraft() ? result.draft : null;
  }

  @override
  Future<GameRegistrationResult> saveCustomGame(
    wire.CustomGameDraft draft,
  ) async {
    final result = await _client.saveCustomGame(
      wire.SaveCustomGameRequest(draft: draft),
    );
    return GameRegistrationResult(
      result.hasGame() ? decodeGameDefinition(result.game) : null,
      result.problem.isEmpty ? null : result.problem,
    );
  }
}
