import 'package:flutter/foundation.dart';
import 'package:mc_client/mc_client.dart';

class GameCatalogueController extends ChangeNotifier {
  GameCatalogueClient? _client;
  List<GameDefinitionInfo> games = const [];
  String? problem;
  bool loading = false;
  bool _disposed = false;

  void attach(GameCatalogueClient? client) {
    if (identical(client, _client)) return;
    _client = client;
    loading = false;
    games = const [];
    problem = null;
    if (client != null) load();
  }

  Future<void> load() async {
    final client = _client;
    if (client == null || loading) return;
    loading = true;
    notifyListeners();
    try {
      final result = await client.read();
      if (!_disposed && identical(client, _client)) {
        games = result;
        problem = null;
      }
    } on Exception {
      if (!_disposed && identical(client, _client)) {
        problem = 'The game list could not be loaded.';
      }
    } finally {
      if (!_disposed && identical(client, _client)) {
        loading = false;
        notifyListeners();
      }
    }
  }

  void registered(GameDefinitionInfo game) {
    games = List.unmodifiable([
      ...games.where((row) => row.id != game.id),
      game,
    ]);
    notifyListeners();
  }

  Future<String?> registerPortable(
    GameCatalogueClient? client,
    CustomGameDraft draft,
  ) async {
    if (client is! GameRegistrationClient) {
      return 'Game registration is not available.';
    }
    final registration = client as GameRegistrationClient;
    try {
      final existing = await registration.readCustomGame(draft.id);
      if (existing != null) {
        return existing == draft
            ? null
            : 'A different game definition already uses this identity.';
      }
      final result = await registration.saveCustomGame(draft);
      if (result.game case final game?) {
        registered(game);
        return null;
      }
      return result.problem ?? 'The game definition could not be added.';
    } on Exception {
      return 'The game definition did not return a result. Reopen Games before another change.';
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
