import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_game_contexts/mc_game_contexts.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';
import 'package:mc_workspaces/mc_workspaces.dart';

const game = ProfileSetupGame(
  id: 'skyrim-se-steam',
  name: 'Skyrim Special Edition',
  storefront: 'Steam',
  steamAppId: 489830,
  variants: [
    GameDefinitionInfo(
      id: 'skyrim-se-steam',
      revision: 1,
      name: 'Skyrim Special Edition',
      storefront: 'Steam',
      declaredSteamAppId: 489830,
      capabilities: [],
    ),
    GameDefinitionInfo(
      id: 'skyrim-se-gog',
      revision: 1,
      name: 'Skyrim Special Edition',
      storefront: 'GOG Windows',
      declaredSteamAppId: 0,
      capabilities: [],
    ),
    GameDefinitionInfo(
      id: 'skyrim-se-direct',
      revision: 1,
      name: 'Skyrim Special Edition',
      storefront: 'DRM-free Windows',
      declaredSteamAppId: 0,
      capabilities: [],
    ),
  ],
);

SteamInstallationCandidate candidate(String id, String path) =>
    SteamInstallationCandidate(
      id,
      SteamDirectory(path, path, 'identity-$id'),
      const [],
    );

class Discovery implements SteamDiscoveryClient {
  Discovery(this.candidates);

  final List<SteamInstallationCandidate> candidates;
  int searches = 0;
  String? requestedGame;
  int cancellations = 0;

  @override
  SteamSearch search(String definitionId, List<String> additionalRoots) {
    searches++;
    requestedGame = definitionId;
    return SteamSearch(
      Future.value(
        SteamSearchResult(
          appId: 489830,
          roots: const [],
          candidates: candidates,
          diagnostics: const [],
          limited: false,
        ),
      ),
      () async => cancellations++,
    );
  }
}

class ProtonDiscovery implements ProtonContextsClient {
  @override
  ProtonSearch search(
    String definitionId,
    String gamePath,
    List<String> roots,
  ) => ProtonSearch(
    Future.value(
      const ProtonSearchResult(
        prefixes: [],
        tools: [],
        mappings: [],
        problems: [],
        limited: false,
      ),
    ),
    () async {},
  );
}

Future<void> mount(
  WidgetTester tester, {
  required Discovery discovery,
  required Future<String?> Function(String?) chooseDirectory,
  required ProfileSetupSubmit onSubmit,
  ProtonContextsClient? protonContexts,
  VoidCallback? onCancel,
  VoidCallback? onComplete,
  GameInstallationSource initialSource = GameInstallationSource.steam,
  String? initialInstallation,
  List<ProfileSetupGame> games = const [game],
  WineSelection? initialWine,
  Size size = const Size(1000, 760),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      theme: mcTheme(Brightness.light),
      home: Scaffold(
        body: ProfileSetupSurface(
          initialName: '',
          initialSource: initialSource,
          initialInstallation: initialInstallation,
          initialWine: initialWine,
          games: games,
          discovery: discovery,
          chooseDirectory: chooseDirectory,
          onSubmit: onSubmit,
          protonContexts: protonContexts,
          actionLabel: 'Create profile',
          canCancel: true,
          onCancel: onCancel,
          onComplete: onComplete,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> findInstallations(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const ValueKey('profile-setup-name')),
    'Northern Roads',
  );
  await tester.tap(find.byKey(const ValueKey('find-profile-installation')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'switching a Wine profile draft to a native Mono game submits native context',
    (tester) async {
      const native = ProfileSetupGame(
        id: 'valheim-steam',
        name: 'Valheim',
        storefront: 'Steam',
        steamAppId: 892970,
        variants: [
          GameDefinitionInfo(
            id: 'valheim-steam',
            revision: 1,
            name: 'Valheim',
            storefront: 'Steam',
            declaredSteamAppId: 892970,
            capabilities: [
              GameCapability(
                id: GameCapabilityId.unityMono,
                revision: 1,
                name: 'Unity Mono',
                kind: GameCapabilityKind.gameAdapter,
                contexts: [
                  GameCapabilityContext(
                    definitionId: 'valheim-steam',
                    platforms: [
                      GameContextPlatform.nativeLinux,
                      GameContextPlatform.windows,
                    ],
                  ),
                ],
                disposition: GameCapabilityDisposition.available,
              ),
            ],
          ),
        ],
      );
      ProfileSetupSelection? submitted;
      await mount(
        tester,
        discovery: Discovery(const []),
        chooseDirectory: (_) async => '/games/Valheim',
        games: const [game, native],
        initialSource: GameInstallationSource.gog,
        initialWine: const WineSelection(
          executable: '/bin/wine',
          prefix: '/prefix',
        ),
        onSubmit: (value) async {
          submitted = value;
          return null;
        },
      );
      await tester.enterText(
        find.byKey(const ValueKey('profile-setup-name')),
        'Builder',
      );
      await tester.tap(find.text('Skyrim Special Edition').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Valheim').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('find-profile-installation')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('choose-installation-folder')),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('submit-profile-setup')),
      );
      await tester.tap(find.byKey(const ValueKey('submit-profile-setup')));
      await tester.pumpAndSettle();
      expect(submitted?.gameId, native.id);
      expect(submitted?.installation, '/games/Valheim');
      expect(submitted?.wine, isNull);
      expect(submitted?.proton, isNull);
    },
    skip: !Platform.isLinux,
  );

  testWidgets(
    'the selected New Vegas registration drives discovery and saving',
    (tester) async {
      final games = ProfileSetupGame.fromCatalogue(const [
        GameDefinitionInfo(
          id: 'new-vegas-steam',
          revision: 1,
          name: 'Fallout: New Vegas',
          storefront: 'Steam',
          declaredSteamAppId: 22380,
          capabilities: [],
        ),
        GameDefinitionInfo(
          id: 'new-vegas-gog',
          revision: 1,
          name: 'Fallout: New Vegas',
          storefront: 'GOG Windows',
          declaredSteamAppId: 0,
          capabilities: [],
        ),
      ]);
      final discovery = Discovery([candidate('nv', '/games/new-vegas')]);
      ProfileSetupSelection? submitted;
      await mount(
        tester,
        discovery: discovery,
        games: games,
        chooseDirectory: (_) async => null,
        onSubmit: (selection) async {
          submitted = selection;
          return null;
        },
      );
      await findInstallations(tester);
      await tester.tap(find.byKey(const ValueKey('submit-profile-setup')));
      await tester.pumpAndSettle();
      expect(discovery.requestedGame, 'new-vegas-steam');
      expect(submitted?.gameId, 'new-vegas-steam');
      expect(find.text('Fallout: New Vegas'), findsOneWidget);
      expect(find.text('Skyrim Special Edition'), findsNothing);
      expect(games.single.sources, [
        GameInstallationSource.steam,
        GameInstallationSource.gog,
      ]);
      expect(
        games.single.forSource(GameInstallationSource.gog),
        'new-vegas-gog',
      );
    },
  );

  testWidgets(
    'GOG profile creation retains a partial Wine selection without Steam discovery',
    (tester) async {
      final discovery = Discovery(const []);
      ProfileSetupSelection? submitted;
      await mount(
        tester,
        discovery: discovery,
        chooseDirectory: (_) async => null,
        initialSource: GameInstallationSource.gog,
        initialInstallation: '/games/gog',
        onSubmit: (value) async {
          submitted = value;
          return null;
        },
      );
      await tester.enterText(
        find.byKey(const ValueKey('profile-setup-name')),
        'GOG',
      );
      await tester.enterText(
        find.byKey(const ValueKey('wine-executable')),
        '/bin/wine',
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('submit-profile-setup')),
      );
      await tester.tap(find.byKey(const ValueKey('submit-profile-setup')));
      await tester.pumpAndSettle();
      expect(submitted?.gameId, 'skyrim-se-gog');
      expect(submitted?.installation, '/games/gog');
      expect(
        submitted?.wine,
        const WineSelection(executable: '/bin/wine', prefix: ''),
      );
      expect(submitted?.proton, isNull);
      expect(discovery.searches, 0);
    },
    skip: !Platform.isLinux,
  );

  testWidgets(
    'a same-folder context replacement updates setup source and runtime',
    (tester) async {
      final discovery = Discovery(const []);
      ProfileSetupSelection? submitted;
      Future<String?> submit(ProfileSetupSelection value) async {
        submitted = value;
        return null;
      }

      await mount(
        tester,
        discovery: discovery,
        chooseDirectory: (_) async => null,
        initialInstallation: '/games/same',
        onSubmit: submit,
      );
      await mount(
        tester,
        discovery: discovery,
        chooseDirectory: (_) async => null,
        initialInstallation: '/games/same',
        initialSource: GameInstallationSource.gog,
        initialWine: const WineSelection(
          executable: '/bin/wine',
          prefix: '/prefix',
        ),
        onSubmit: submit,
      );
      await tester.enterText(
        find.byKey(const ValueKey('profile-setup-name')),
        'GOG',
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('submit-profile-setup')),
      );
      await tester.tap(find.byKey(const ValueKey('submit-profile-setup')));
      await tester.pumpAndSettle();
      expect(submitted?.gameId, 'skyrim-se-gog');
      expect(
        submitted?.wine,
        const WineSelection(executable: '/bin/wine', prefix: '/prefix'),
      );
      expect(submitted?.proton, isNull);
    },
    skip: !Platform.isLinux,
  );

  testWidgets('Linux profile setup allows Proton to be selected later', (
    tester,
  ) async {
    ProfileSetupSelection? submitted;
    await mount(
      tester,
      discovery: Discovery([candidate('only', '/games/skyrim')]),
      protonContexts: ProtonDiscovery(),
      chooseDirectory: (_) async => null,
      onSubmit: (value) async {
        submitted = value;
        return null;
      },
    );
    await findInstallations(tester);
    await tester.tap(find.byKey(const ValueKey('submit-profile-setup')));
    await tester.pumpAndSettle();

    expect(submitted?.installation, '/games/skyrim');
    expect(submitted?.proton, isNull);
  }, skip: !Platform.isLinux);

  testWidgets('Linux profile setup saves the selected Proton folders', (
    tester,
  ) async {
    ProfileSetupSelection? submitted;
    await mount(
      tester,
      discovery: Discovery([candidate('only', '/games/skyrim')]),
      protonContexts: ProtonDiscovery(),
      chooseDirectory: (_) async => null,
      onSubmit: (value) async {
        submitted = value;
        return null;
      },
    );
    await findInstallations(tester);
    await tester.ensureVisible(find.byKey(const ValueKey('select-proton')));
    await tester.tap(find.byKey(const ValueKey('select-proton')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('proton-data-folder')),
      '/games/compatdata/489830',
    );
    await tester.enterText(
      find.byKey(const ValueKey('proton-runtime-folder')),
      '/games/Proton',
    );
    await tester.pump();
    expect(
      tester
          .widget<McAction>(find.byKey(const ValueKey('submit')).last)
          .onPressed,
      isNotNull,
    );
    await tester.ensureVisible(find.byKey(const ValueKey('submit')).last);
    await tester.tap(find.byKey(const ValueKey('submit')).last);
    await tester.pumpAndSettle();
    expect(find.byType(ProtonDialog), findsNothing);
    await tester.ensureVisible(
      find.byKey(const ValueKey('submit-profile-setup')),
    );
    await tester.tap(find.byKey(const ValueKey('submit-profile-setup')));
    await tester.pumpAndSettle();

    expect(submitted?.proton?.compatData, '/games/compatdata/489830');
    expect(submitted?.proton?.runtimeDirectory, '/games/Proton');
  }, skip: !Platform.isLinux);

  testWidgets(
    'one discovered installation is selected without another decision',
    (tester) async {
      ProfileSetupSelection? submitted;
      var completed = 0;
      final discovery = Discovery([
        candidate('only', '/games/Skyrim Special Edition'),
      ]);
      await mount(
        tester,
        discovery: discovery,
        chooseDirectory: (_) async => null,
        onSubmit: (value) async {
          submitted = value;
          return null;
        },
        onComplete: () => completed++,
      );

      await findInstallations(tester);
      final submit = tester.widget<McAction>(
        find.byKey(const ValueKey('submit-profile-setup')),
      );
      expect(submit.onPressed, isNotNull);
      await tester.tap(find.byKey(const ValueKey('submit-profile-setup')));
      await tester.pumpAndSettle();

      expect(submitted?.installation, '/games/Skyrim Special Edition');
      expect(submitted?.name, 'Northern Roads');
      expect(completed, 1);
    },
  );

  testWidgets('several installations require an explicit selection', (
    tester,
  ) async {
    ProfileSetupSelection? submitted;
    final discovery = Discovery([
      candidate('first', '/games/first'),
      candidate('second', '/games/second'),
    ]);
    await mount(
      tester,
      discovery: discovery,
      chooseDirectory: (_) async => null,
      onSubmit: (value) async {
        submitted = value;
        return null;
      },
    );

    await findInstallations(tester);
    expect(
      tester
          .widget<McAction>(find.byKey(const ValueKey('submit-profile-setup')))
          .onPressed,
      isNull,
    );
    await tester.tap(
      find.byKey(const ValueKey(('Steam folder', '/games/first'))),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('/games/second').last);
    await tester.pumpAndSettle();
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const ValueKey('submit-profile-setup')),
    );
    await tester.tap(find.byKey(const ValueKey('submit-profile-setup')));
    await tester.pumpAndSettle();

    expect(submitted?.installation, '/games/second');
  });

  testWidgets('no discovery result requires a manually selected folder', (
    tester,
  ) async {
    ProfileSetupSelection? submitted;
    final discovery = Discovery(const []);
    await mount(
      tester,
      discovery: discovery,
      chooseDirectory: (_) async => '/manual/skyrim',
      onSubmit: (value) async {
        submitted = value;
        return null;
      },
      size: const Size(480, 820),
    );

    await findInstallations(tester);
    expect(
      tester
          .widget<McAction>(find.byKey(const ValueKey('submit-profile-setup')))
          .onPressed,
      isNull,
    );
    await tester.tap(find.byKey(const ValueKey('choose-installation-folder')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('submit-profile-setup')),
    );
    await tester.tap(find.byKey(const ValueKey('submit-profile-setup')));
    await tester.pumpAndSettle();

    expect(submitted?.installation, '/manual/skyrim');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'cancelling the folder override retains the discovered selection',
    (tester) async {
      ProfileSetupSelection? submitted;
      var initialPath = '';
      final discovery = Discovery([candidate('only', '/games/discovered')]);
      await mount(
        tester,
        discovery: discovery,
        chooseDirectory: (path) async {
          initialPath = path ?? '';
          return null;
        },
        onSubmit: (value) async {
          submitted = value;
          return null;
        },
      );

      await findInstallations(tester);
      final override = tester.widget<McIconAction>(
        find.byKey(const ValueKey('choose-installation-folder')),
      );
      override.focusNode!.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('submit-profile-setup')));
      await tester.pumpAndSettle();

      expect(initialPath, '/games/discovered');
      expect(submitted?.installation, '/games/discovered');
    },
  );

  testWidgets('the folder override can replace several discovered choices', (
    tester,
  ) async {
    ProfileSetupSelection? submitted;
    final discovery = Discovery([
      candidate('first', '/games/first'),
      candidate('second', '/games/second'),
    ]);
    await mount(
      tester,
      discovery: discovery,
      chooseDirectory: (_) async => '/manual/skyrim',
      onSubmit: (value) async {
        submitted = value;
        return null;
      },
    );

    await findInstallations(tester);
    await tester.tap(find.byKey(const ValueKey('choose-installation-folder')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('submit-profile-setup')));
    await tester.pumpAndSettle();

    expect(submitted?.installation, '/manual/skyrim');
  });

  testWidgets('a rejected save retains the draft for retry', (tester) async {
    var submissions = 0;
    var completed = 0;
    final discovery = Discovery([candidate('only', '/games/discovered')]);
    await mount(
      tester,
      discovery: discovery,
      chooseDirectory: (_) async => null,
      onSubmit: (_) async {
        submissions++;
        return submissions == 1 ? 'The selected folder is not valid.' : null;
      },
      onComplete: () => completed++,
    );

    await findInstallations(tester);
    await tester.tap(find.byKey(const ValueKey('submit-profile-setup')));
    await tester.pumpAndSettle();
    expect(completed, 0);
    expect(
      tester
          .widget<TextFormField>(
            find.byKey(const ValueKey('profile-setup-name')),
          )
          .controller!
          .text,
      'Northern Roads',
    );
    await tester.tap(find.byKey(const ValueKey('submit-profile-setup')));
    await tester.pumpAndSettle();

    expect(submissions, 2);
    expect(completed, 1);
  });

  testWidgets('cancel exits before discovery or profile submission', (
    tester,
  ) async {
    var cancelled = 0;
    var submissions = 0;
    final discovery = Discovery(const []);
    await mount(
      tester,
      discovery: discovery,
      chooseDirectory: (_) async => null,
      onSubmit: (_) async {
        submissions++;
        return null;
      },
      onCancel: () => cancelled++,
    );

    await tester.tap(find.widgetWithText(McAction, 'Cancel'));
    await tester.pump();

    expect(cancelled, 1);
    expect(discovery.searches, 0);
    expect(submissions, 0);
  });
}
