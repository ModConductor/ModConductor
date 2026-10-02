import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_game_contexts/mc_game_contexts.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'support/game_registration_fake.dart';

void main() {
  testWidgets(
    'matched Steam selection and folder override register immediately without a search step',
    (tester) async {
      final client = GameRegistrationFake();
      final catalogue = GameCatalogueController();
      final controller = GameEditorController(client, catalogue);
      addTearDown(controller.dispose);
      addTearDown(catalogue.dispose);
      RegisteredGame? saved;
      await tester.pumpWidget(
        MaterialApp(
          theme: mcTheme(Brightness.light),
          home: Scaffold(
            body: McPage(
              title: 'Add game',
              children: [
                GameEditor(
                  controller: controller,
                  chooseDirectory: (_) async => '/override',
                  onSaved: (value) => saved = value,
                  onCancel: () {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Example Game'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('choose-game-folder')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('register-game')));
      await tester.tap(find.byKey(const ValueKey('register-game')));
      await tester.pumpAndSettle();
      expect(client.searches, 0);
      expect(client.detected, [GameRegistrationFake.path, '/override']);
      expect(saved!.path, '/override');
      expect(catalogue.games.single.id, saved!.game.id);
      expect(client.saved.single.steamAppId, 990001);
    },
  );
  testWidgets(
    'manual loader fallback remains usable at compact width without a network entry',
    (tester) async {
      tester.view.physicalSize = const Size(640, 960);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final client = GameRegistrationFake()..manual = true;
      final catalogue = GameCatalogueController();
      final controller = GameEditorController(client, catalogue);
      addTearDown(controller.dispose);
      addTearDown(catalogue.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: mcTheme(Brightness.dark),
          home: Scaffold(
            body: McPage(
              title: 'Add game',
              children: [
                GameEditor(
                  controller: controller,
                  chooseDirectory: (_) async => GameRegistrationFake.path,
                  onSaved: (_) {},
                  onCancel: () {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      controller.changeSource(GameRegistrationSource.folder);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('choose-game-folder')));
      await tester.pumpAndSettle();
      expect(controller.canSave, isFalse);
      final choice = find.byType(McChoice<String>).first;
      await tester.tap(choice);
      await tester.pumpAndSettle();
      await tester.tap(find.text('BepInEx').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('register-game')));
      await tester.tap(find.byKey(const ValueKey('register-game')));
      await tester.pumpAndSettle();
      expect(client.saved.single.mechanism, 'unity-il2cpp');
      expect(client.searches, 0);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('same-named game edits address the selected stable identity', (
    tester,
  ) async {
    final client = GameRegistrationFake();
    final catalogue = GameCatalogueController()..attach(client);
    addTearDown(catalogue.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GamesPage(
            catalogue: catalogue,
            client: client,
            chooseDirectory: (_) async => null,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final selected = client.games.last.id;
    await tester.tap(
      find.descendant(
        of: find.byKey(ValueKey(selected)),
        matching: find.byType(McIconAction),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('register-game')));
    await tester.tap(find.byKey(const ValueKey('register-game')));
    await tester.pumpAndSettle();
    expect(client.reads, [selected]);
    expect(client.saved.single.id, selected);
    expect(
      catalogue.games.map((row) => row.id).toSet(),
      client.games.map((row) => row.id).toSet(),
    );
  });
}
