import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';
import 'package:mod_conductor/src/app.dart';

import '../../../packages/mc_client/test/support/native_child.dart';
import '../../../packages/mc_game_contexts/test/support/game_registration_fake.dart';

class _SearchClient extends GameRegistrationFake {
  _SearchClient([this.remote]);
  final GameRegistrationClient? remote;
  Completer<ThunderstoreGamesResult> pending = Completer();
  String? query;
  @override
  Future<ThunderstoreGamesResult> searchGames(String value) {
    query = value;
    if (remote != null) {
      remote!
          .searchGames(value)
          .then(pending.complete, onError: pending.completeError);
    }
    return pending.future;
  }
}

Future<void> _openSearch(WidgetTester tester, _SearchClient client) async {
  tester.view.physicalSize = const Size(1440, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ModConductorApp(
      status: const DesktopConnected((
        runtime: (architecture: 'x64', nativeAot: true, sqliteVersion: '3'),
        heartbeats: 1,
      )),
      gameCatalogue: client,
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('nav-games')));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(McAction, 'Add game'));
  await tester.pumpAndSettle();
  final appId = GameRegistrationFake.candidate.origins.first.manifest.appId;
  expect(
    tester
        .widgetList<McPortraitArtwork>(find.byType(McPortraitArtwork))
        .map((image) => image.image?.path),
    contains('/steam/apps/$appId/header.jpg'),
  );
  await tester.tap(find.text('Example Game').first);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Advanced'));
  await tester.pumpAndSettle();
  await tester.ensureVisible(
    find.widgetWithText(McAction, 'Search Thunderstore'),
  );
  await tester.tap(find.widgetWithText(McAction, 'Search Thunderstore'));
  await tester.pump();
}

void main() {
  testWidgets(
    'shell search uses the selected name and reports pending, empty and failed requests',
    (tester) async {
      final client = _SearchClient();
      await _openSearch(tester, client);
      expect(client.query, 'Example Game');
      expect(
        tester.widget<McActionFeedback>(find.byType(McActionFeedback)).kind,
        McActionFeedbackKind.pending,
      );
      client.pending.complete(const ThunderstoreGamesResult([], null));
      await tester.pumpAndSettle();
      expect(
        tester.widget<McStatus>(find.byType(McStatus)).tone,
        isNot(McStatusTone.error),
      );
      client.pending = Completer();
      await tester.enterText(
        find.widgetWithText(TextField, 'Search Thunderstore games'),
        'Unavailable',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      client.pending.complete(
        const ThunderstoreGamesResult([], 'Thunderstore is not available.'),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<McStatus>(find.byType(McStatus)).tone,
        McStatusTone.error,
      );
      expect(tester.takeException(), isNull);
    },
  );
  final engine = Platform.environment['MC_GAME_SEARCH_ENGINE'];
  testWidgets(
    'shell search crosses the authenticated Engine and displays live game artwork',
    (tester) async {
      final root = await tester.runAsync(
        () => Directory.systemTemp.createTemp('mc-search-wire-'),
      );
      final child = await tester.runAsync(
        () => NativeChild.start(engine!, root!),
      );
      try {
        final client = await tester.runAsync(
          () async => _SearchClient(child!.gameCatalogue()),
        );
        await tester.runAsync(() => _openSearch(tester, client!));
        await tester.runAsync(
          () => client!.pending.future.timeout(const Duration(seconds: 30)),
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextField, 'Search Thunderstore games'),
          'Valheim',
        );
        final search = tester.widget<TextField>(
          find.widgetWithText(TextField, 'Search Thunderstore games'),
        );
        final result = await tester.runAsync(() async {
          client!.pending = Completer();
          search.onSubmitted!('Valheim');
          expect(client.query, 'Valheim');
          return client.pending.future.timeout(const Duration(seconds: 30));
        });
        await tester.pumpAndSettle();
        expect(result!.problem, isNull);
        expect(result.games, isNotEmpty);
        expect(result.games.any((game) => game.artworkUrl.isNotEmpty), isTrue);
        final images = tester
            .widgetList<McPortraitArtwork>(find.byType(McPortraitArtwork))
            .map((image) => image.image?.toString());
        expect(images, contains(result.games.first.artworkUrl));
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.runAsync(() async {
          await child!.close();
          await root!.delete(recursive: true);
        });
      }
    },
    skip: engine == null,
  );
}
