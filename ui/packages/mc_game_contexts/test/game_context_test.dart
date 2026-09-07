import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_game_contexts/mc_game_contexts.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

const definition = GameDefinitionInfo(
  id: 'skyrim',
  revision: 1,
  name: 'Skyrim Special Edition',
  storefront: 'Steam',
  declaredSteamAppId: 489830,
  unavailableCapabilities: [],
);
GameContextState snapshot(String workspace, int revision, String? path) =>
    GameContextState(
      workspaceId: workspace,
      revision: revision,
      definition: definition,
      binding: path == null
          ? null
          : GameBindingInfo(
              id: 'binding',
              path: path,
              needsCheck: false,
              evidence: GameInstallationEvidence(
                definitionId: definition.id,
                definitionRevision: definition.revision,
                platform: GameContextPlatform.proton,
                rootPath: path,
                dataPath: '$path/Data',
                executable: GameExecutableEvidence(
                  path: '$path/SkyrimSE.exe',
                  sha256: 'abc',
                  length: 1024,
                  fileVersion: '1.7.104.0',
                  productVersion: '1.7.104.0',
                ),
                launcherPath: null,
                documents: const UnavailableGameLocation('unresolved'),
                saves: const UnavailableGameLocation('unresolved'),
                localAppData: const UnavailableGameLocation('unresolved'),
                problems: const [],
                checkedAt: DateTime.utc(2026),
                fingerprint: 'fingerprint',
              ),
            ),
    );

class Client implements GameContextsClient {
  Future<GameContextState> Function(String) onRead = (id) async =>
      snapshot(id, 1, '/game');
  Future<GameContextState> Function(String, int, String) onSave = (
    id,
    revision,
    path,
  ) async => snapshot(id, revision + 1, path);
  @override
  Future<GameContextState> read(String id) => onRead(id);
  @override
  Future<GameContextState> save(String id, int revision, String path) =>
      onSave(id, revision, path);
  @override
  Future<GameContextState> refresh(String id, int revision) => onRead(id);
}

Future<void> page(WidgetTester tester, GameContextController controller) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: mcTheme(Brightness.light),
      home: Scaffold(
        body: GameContextBrowser(
          controller: controller,
          chooseDirectory: (_) async => '/chosen',
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('a late context read cannot replace another workspace or a newer saved revision', () async {
    final client = Client();
    final first = Completer<GameContextState>();
    client.onRead = (id) =>
        id == 'first' ? first.future : Future.value(snapshot(id, 1, '/second'));
    final controller = GameContextController();
    controller.attach(client, workspaceId: 'first', editable: true);
    controller.attach(client, workspaceId: 'second', editable: true);
    await Future<void>.delayed(Duration.zero);
    controller.accept(snapshot('second', 3, '/new'), client);
    first.complete(snapshot('first', 9, '/old'));
    await Future<void>.delayed(Duration.zero);
    expect(controller.state!.workspaceId, 'second');
    expect(controller.state!.binding!.path, '/new');
    controller.dispose();
  });
  test(
    'a reply from a replaced connection cannot refresh the current binding',
    () async {
      final oldClient = Client();
      final newClient = Client()
        ..onRead = (id) async => snapshot(id, 1, '/current');
      final controller = GameContextController()
        ..attach(oldClient, workspaceId: 'workspace', editable: true);
      await Future<void>.delayed(Duration.zero);
      controller.attach(newClient, workspaceId: 'workspace', editable: true);
      await Future<void>.delayed(Duration.zero);
      controller.accept(snapshot('workspace', 1, '/old'), oldClient);
      expect(controller.state!.binding!.path, '/current');
      controller.dispose();
    },
  );
  testWidgets(
    'an unknown Save result keeps prior evidence but requires a read after dismissal',
    (tester) async {
      final client = Client()
        ..onSave = (_, _, _) async => throw TimeoutException('lost reply');
      final controller = GameContextController()
        ..attach(client, workspaceId: 'workspace', editable: true);
      await page(tester, controller);
      await tester.tap(find.byKey(const ValueKey('change-installation')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('installation-folder')),
        '/accepted',
      );
      await tester.tap(find.byKey(const ValueKey('submit')));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(controller.state!.binding!.path, '/game');
      expect(controller.needsRead, isTrue);
      expect(controller.canChange, isFalse);
      client.onRead = (id) async => snapshot(id, 2, '/accepted');
      await tester.tap(find.byKey(const ValueKey('refresh-installation')));
      await tester.pumpAndSettle();
      expect(controller.state!.binding!.path, '/accepted');
      expect(controller.needsRead, isFalse);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    },
  );
  testWidgets(
    'cancel preserves the binding and restores focus without a save call',
    (tester) async {
      final client = Client();
      var saved = false;
      client.onSave = (id, revision, path) async {
        saved = true;
        return snapshot(id, revision + 1, path);
      };
      final controller = GameContextController()
        ..attach(client, workspaceId: 'workspace', editable: true);
      await page(tester, controller);
      await tester.tap(find.byKey(const ValueKey('change-installation')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('installation-folder')),
        '/draft',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(saved, isFalse);
      expect(controller.state!.binding!.path, '/game');
      final button = tester.widget<McAction>(
        find.byKey(const ValueKey('change-installation')),
      );
      expect(button.focusNode!.hasFocus, isTrue);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    },
  );
  testWidgets(
    'a stale save retains the draft until the current binding is reviewed',
    (tester) async {
      final client = Client();
      var attempts = 0;
      client.onSave = (id, revision, path) async {
        attempts++;
        if (attempts == 1) {
          throw const GameContextException(GameContextFailure.stale, 'changed');
        }
        expect(revision, 2);
        expect(path, '/draft');
        return snapshot(id, revision + 1, path);
      };
      final controller = GameContextController()
        ..attach(client, workspaceId: 'workspace', editable: true);
      await page(tester, controller);
      await tester.tap(find.byKey(const ValueKey('change-installation')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('installation-folder')),
        '/draft',
      );
      await tester.tap(find.byKey(const ValueKey('submit')));
      await tester.pumpAndSettle();
      expect(controller.state!.binding!.path, '/game');
      expect(
        tester.widget<McAction>(find.byKey(const ValueKey('submit'))).onPressed,
        isNull,
      );
      client.onRead = (id) async => snapshot(id, 2, '/other');
      await tester.tap(find.byKey(const ValueKey('reload-installation')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('installation-folder')),
            )
            .controller!
            .text,
        '/draft',
      );
      expect(controller.state!.binding!.path, '/other');
      await tester.ensureVisible(find.byKey(const ValueKey('submit')));
      await tester.tap(find.byKey(const ValueKey('submit')));
      await tester.pumpAndSettle();
      expect(controller.state!.binding!.path, '/draft');
      expect(attempts, 2);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    },
  );
  testWidgets(
    'an in-flight save blocks dismissal and publishes its completed binding',
    (tester) async {
      final client = Client();
      final pending = Completer<GameContextState>();
      client.onSave = (_, _, _) => pending.future;
      final controller = GameContextController()
        ..attach(client, workspaceId: 'workspace', editable: true);
      await page(tester, controller);
      await tester.tap(find.byKey(const ValueKey('change-installation')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('installation-folder')),
        '/accepted',
      );
      await tester.tap(find.byKey(const ValueKey('submit')));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(8, 8));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('installation-folder')), findsOneWidget);
      pending.complete(snapshot('workspace', 2, '/accepted'));
      await tester.pumpAndSettle();
      expect(controller.state!.binding!.path, '/accepted');
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    },
  );
}
