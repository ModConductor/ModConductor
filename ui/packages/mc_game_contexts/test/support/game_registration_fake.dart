import 'package:mc_client/mc_client.dart';

class GameRegistrationFake
    implements GameCatalogueClient, GameRegistrationClient {
  static const path = '/games/SteamLibrary/steamapps/common/ExampleGame';
  final saved = <CustomGameDraft>[];
  final reads = <String>[];
  final detected = <String>[];
  int searches = 0;
  bool manual = false;
  final games = <GameDefinitionInfo>[
    game('custom-11111111111111111111111111111111'),
    game('custom-22222222222222222222222222222222'),
  ];
  static GameDefinitionInfo game(String id) => GameDefinitionInfo(
    id: id,
    revision: 1,
    name: 'Example Game',
    storefront: 'Steam',
    declaredSteamAppId: 990001,
    capabilities: const [],
  );
  static final candidate = SteamInstallationCandidate(
    'installation',
    const SteamDirectory(path, path, null),
    const [
      SteamInstallationOrigin(
        root: SteamSearchRoot('/steam', 'Fixture'),
        steamRoot: SteamDirectory('/steam', '/steam', null),
        library: SteamDirectory('/steam', '/steam', null),
        manifest: SteamManifestEvidence(
          path: '/steam/appmanifest_990001.acf',
          nativeIdentity: 'fixture',
          sha256: '',
          appId: 990001,
          installDirectory: 'ExampleGame',
          name: 'Example Game',
        ),
      ),
    ],
  );
  @override
  Future<List<GameDefinitionInfo>> read() async => games;
  @override
  Future<String?> openScriptExtenderPage(String id) async => null;
  @override
  Future<SteamSearchResult> installedGames(List<String> roots) async =>
      SteamSearchResult(
        appId: 0,
        roots: const [],
        candidates: [candidate],
        diagnostics: const [],
        limited: false,
      );
  @override
  Future<GameDetection> detectGame(
    String path,
    String name,
    int app,
    String metadata,
  ) async {
    detected.add(path);
    return GameDetection(
      CustomGameDraft(
        name: name.isEmpty ? 'Example Game' : name,
        steamAppId: app,
        executable: 'ExampleGame.exe',
        content: 'ExampleGame_Data',
        mechanism: manual ? '' : 'unity-il2cpp',
        windowsRuntime: 'GameAssembly.dll',
        metadata: 'il2cpp_data/Metadata/global-metadata.dat',
        unityMetadata: 'globalgamemanagers',
      ),
      const [],
      null,
      detectedEngine: 'unity-il2cpp',
    );
  }

  @override
  Future<ThunderstoreGamesResult> searchGames(String query) async {
    searches++;
    return ThunderstoreGamesResult([
      ThunderstoreGameInfo(
        id: 'example:0',
        name: 'Example Game',
        community: 'example',
        suppliesSetup: true,
      ),
      ThunderstoreGameInfo(
        id: 'community:0',
        name: 'Example Game: Community Hub',
        community: 'community',
        suppliesSetup: false,
      ),
    ], null);
  }

  @override
  Future<CustomGameDraft?> readCustomGame(String id) async {
    reads.add(id);
    return CustomGameDraft(
      id: id,
      revision: 1,
      name: 'Example Game',
      mechanism: 'ue4ss',
      executable: 'Example.exe',
      content: 'Example/Content',
    );
  }

  @override
  Future<GameRegistrationResult> saveCustomGame(CustomGameDraft draft) async {
    saved.add(CustomGameDraft.fromBuffer(draft.writeToBuffer()));
    final result = game(
      draft.id.isEmpty ? 'custom-33333333333333333333333333333333' : draft.id,
    );
    games.removeWhere((row) => row.id == result.id);
    games.add(result);
    return GameRegistrationResult(result, null);
  }
}
