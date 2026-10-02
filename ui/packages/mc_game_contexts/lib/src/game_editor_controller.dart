import 'package:flutter/foundation.dart';
import 'package:mc_client/mc_client.dart';

import 'catalogue_controller.dart';

enum GameRegistrationSource { steam, folder }

class RegisteredGame {
  const RegisteredGame(this.game, this.path);
  final GameDefinitionInfo game;
  final String path;
}

class GameEditorController extends ChangeNotifier {
  GameEditorController(this.client, this.catalogue, {this.editId});
  final GameRegistrationClient client;
  final GameCatalogueController catalogue;
  final String? editId;
  GameRegistrationSource source = GameRegistrationSource.steam;
  CustomGameDraft draft = _emptyDraft();
  static CustomGameDraft _emptyDraft() => CustomGameDraft(
    unityMetadata: 'globalgamemanagers',
    linuxWrapper: 'start_game_bepinex.sh',
    proxy: 'dwmapi.dll',
    core: 'ue4ss',
    mods: 'ue4ss/Mods',
    settingsFile: 'ue4ss/UE4SS-settings.ini',
    log: 'ue4ss/UE4SS.log',
    gameFeatureField: 'GameFeature',
  );
  Set<String> missing = {
    'mechanism',
    'executable',
    'content',
    'windowsRuntime',
    'metadata',
  };
  bool searching = false, searched = false;
  bool detected = false;
  String detectedEngine = '';
  List<SteamInstallationCandidate> installations = const [];
  List<ThunderstoreGameInfo> matches = const [];
  List<String> executables = const [];
  String path = '', query = '', metadataId = '', _executableOverride = '';
  String? problem, _nameOverride;
  bool busy = false, searchVisible = false, advanced = false, _disposed = false;
  int _generation = 0;
  bool needsRead = false;
  bool get canSave =>
      !needsRead &&
      !busy &&
      draft.name.trim().isNotEmpty &&
      draft.mechanism.isNotEmpty &&
      draft.executable.isNotEmpty &&
      draft.content.isNotEmpty;
  bool get editing => editId != null;
  Future<void> load() async {
    busy = true;
    notifyListeners();
    try {
      if (editId case final id?) {
        final saved = await client.readCustomGame(id);
        if (_disposed) return;
        if (saved == null) {
          problem = 'This custom game is not available.';
        } else {
          draft = saved;
          source = saved.steamAppId == 0
              ? GameRegistrationSource.folder
              : GameRegistrationSource.steam;
          advanced = true;
          missing = {};
        }
      } else {
        final result = await client.installedGames(const []);
        if (_disposed) return;
        installations = result.candidates;
        if (result.limited) problem = 'Some Steam libraries could not be read.';
      }
    } on Exception {
      if (!_disposed) problem = 'The game source could not be read.';
    } finally {
      if (!_disposed) {
        busy = false;
        notifyListeners();
      }
    }
  }

  void changeSource(GameRegistrationSource value) {
    if (busy || editing || value == source) return;
    _generation++;
    source = value;
    path = '';
    metadataId = '';
    _executableOverride = '';
    _nameOverride = null;
    draft = _emptyDraft();
    detected = false;
    detectedEngine = '';
    missing = {
      'mechanism',
      'executable',
      'content',
      'windowsRuntime',
      'metadata',
    };
    matches = const [];
    searched = false;
    problem = null;
    notifyListeners();
  }

  void changed() => notifyListeners();
  void chooseName(String value) {
    draft.name = value;
    _nameOverride = value;
    notifyListeners();
  }

  void chooseExecutable(String value) {
    draft.executable = value;
    _executableOverride = value;
    notifyListeners();
  }

  void showSearch() {
    searchVisible = !searchVisible;
    notifyListeners();
  }

  String installationName(SteamInstallationCandidate row) =>
      row.origins.first.manifest.name ??
      'Steam ${row.origins.first.manifest.appId}';
  Future<void> selectInstallation(SteamInstallationCandidate row) {
    draft.name = installationName(row);
    draft.steamAppId = row.origins.first.manifest.appId;
    metadataId = '';
    _executableOverride = '';
    _nameOverride = null;
    return inspect(row.directory.canonicalPath);
  }

  Future<void> inspect(String folder) async {
    if (editing || busy) return;
    path = folder;
    final generation = ++_generation;
    busy = true;
    problem = null;
    notifyListeners();
    try {
      final result = await client.detectGame(
        path,
        draft.name,
        draft.steamAppId,
        metadataId,
      );
      if (_disposed || generation != _generation) return;
      draft = result.draft;
      if (_nameOverride case final name?) {
        draft.name = name;
      }
      if (_executableOverride.isNotEmpty) {
        draft.executable = _executableOverride;
      }
      detectedEngine = result.detectedEngine;
      detected = detectedEngine.isNotEmpty;
      missing = {
        if (draft.mechanism.isEmpty) 'mechanism',
        if (draft.executable.isEmpty) 'executable',
        if (draft.content.isEmpty) 'content',
        if (draft.windowsRuntime.isEmpty) 'windowsRuntime',
        if (draft.metadata.isEmpty) 'metadata',
      };
      executables = result.executables;
      problem = result.problem;
    } on Exception {
      if (!_disposed && generation == _generation) problem = 'The game folder could not be checked. Enter the missing setup fields.';
    } finally {
      if (!_disposed && generation == _generation) {
        busy = false;
        notifyListeners();
      }
    }
  }

  Future<void> search(String value) async {
    final generation = ++_generation;
    busy = true;
    searching = true;
    searched = false;
    problem = null;
    notifyListeners();
    try {
      final result = await client.searchGames(value);
      if (_disposed || generation != _generation) return;
      matches = result.games;
      searched = true;
      problem = result.problem;
    } on Exception {
      if (!_disposed) {
        problem =
            'Thunderstore is not available. Enter the missing setup fields.';
      }
    } finally {
      if (!_disposed && generation == _generation) {
        busy = false;
        searching = false;
        notifyListeners();
      }
    }
  }

  Future<void> selectMetadata(ThunderstoreGameInfo game) {
    metadataId = game.id;
    searchVisible = false;
    if (draft.name.isEmpty) draft.name = game.name;
    return inspect(path);
  }

  Future<RegisteredGame?> save() async {
    if (!canSave) return null;
    busy = true;
    problem = null;
    notifyListeners();
    try {
      final result = await client.saveCustomGame(draft);
      if (_disposed) return null;
      problem = result.problem;
      if (result.game case final game?) {
        catalogue.registered(game);
        return RegisteredGame(game, path);
      }
    } on Exception {
      if (!_disposed) {
        needsRead = true;
        problem = 'The game definition did not return a result. Reopen Games before another change.';
      }
    } finally {
      if (!_disposed) {
        busy = false;
        notifyListeners();
      }
    }
    return null;
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
