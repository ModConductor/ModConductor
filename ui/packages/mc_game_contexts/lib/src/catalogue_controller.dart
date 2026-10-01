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

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
