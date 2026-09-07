import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_game_contexts/mc_game_contexts.dart';
import 'package:mod_conductor/src/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'manual game Save and stale reload preserve workspace data through the actual engine',
    (tester) async {
      tester.testTextInput.register();
      const engine = String.fromEnvironment('MC_ENGINE_PATH');
      const fixtureTool = String.fromEnvironment('MC_NATIVE_FIXTURE');
      const output = String.fromEnvironment('MC_CONTEXT_OUTPUT');
      if (engine.isEmpty || fixtureTool.isEmpty || output.isEmpty) {
        throw StateError('Select native tools and an owned output directory.');
      }
      final area = await Directory.systemTemp.createTemp('mc-game-ui-');
      await Directory(output).create(recursive: true);
      final root = await Directory('${area.path}/root').create();
      final game = '${area.path}/game';
      final prepared = await Process.run(fixtureTool, ['--game-files', game]);
      expect(prepared.exitCode, 0, reason: '${prepared.stderr}');
      final owner = EngineOwner(
        engine,
        launch: (exe) =>
            Process.start(exe, ['--state-directory', '${area.path}/state']),
      );
      final boundary = GlobalKey();
      GameContextController controller() => tester
          .widget<GameContextBrowser>(
            find.byType(GameContextBrowser, skipOffstage: false),
          )
          .controller;
      Future<void> until(bool Function() condition) async {
        final deadline = DateTime.now().add(const Duration(seconds: 30));
        while (!condition() && DateTime.now().isBefore(deadline)) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(condition(), isTrue);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      Future<void> tap(Finder finder) async {
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      Future<void> capture(String name) async {
        final image =
            await (boundary.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('$output/$name.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      }

      try {
        await owner.connect();
        final workspace = newOperationId();
        await owner.workspaces!.create(workspace, 'Weekend', root.path);
        await owner.workspaces!.createProfile(
          workspace,
          0,
          ProfileInfo(newOperationId(), 'Everyday'),
        );
        final before = (await owner.workspaces!.read(workspace)).workspace;
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundary,
            child: ModConductorApp(
              workspaces: owner.workspaces,
              modLibrary: owner.modLibrary,
              profileMods: owner.profileMods,
              modOrganization: owner.modOrganization,
              gameContexts: owner.gameContexts,
              chooseGameDirectory: (_) async => game,
              status: DesktopConnected((owner.state as EngineConnected).report),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tap(find.byKey(ValueKey('workspace-$workspace')));
        await tap(find.text('Game'));
        await until(() => controller().state != null && !controller().loading);
        await tap(find.byKey(const ValueKey('select-installation')));
        await tester.enterText(
          find.byKey(const ValueKey('installation-folder')),
          game,
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect((await owner.gameContexts!.read(workspace)).binding, isNull);
        await tap(find.byKey(const ValueKey('select-installation')));
        await tester.enterText(
          find.byKey(const ValueKey('installation-folder')),
          '$game/missing',
        );
        await tap(find.byKey(const ValueKey('submit')));
        await until(
          () => tester
              .widget<TextFormField>(
                find.byKey(const ValueKey('installation-folder')),
              )
              .enabled,
        );
        expect((await owner.gameContexts!.read(workspace)).binding, isNull);
        await capture('invalid-folder');
        await tap(find.byKey(const ValueKey('browse-installation')));
        await tap(find.byKey(const ValueKey('submit')));
        await until(
          () => find
              .byKey(const ValueKey('installation-folder'))
              .evaluate()
              .isEmpty,
        );
        final saved = await owner.gameContexts!.read(workspace);
        expect(saved.binding!.path, game);
        expect(saved.binding!.evidence.executable!.fileVersion, '1.7.104.0');
        await capture('saved-context');
        await tap(find.byKey(const ValueKey('change-installation')));
        final draft = tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('installation-folder')),
            )
            .controller!
            .text;
        await owner.gameContexts!.refresh(workspace, saved.revision);
        await tap(find.byKey(const ValueKey('submit')));
        await until(
          () => find
              .byKey(const ValueKey('reload-installation'))
              .evaluate()
              .isNotEmpty,
        );
        await capture('stale-draft');
        await tap(find.byKey(const ValueKey('reload-installation')));
        await until(
          () => find
              .byKey(const ValueKey('reload-installation'))
              .evaluate()
              .isEmpty,
        );
        expect(
          tester
              .widget<TextFormField>(
                find.byKey(const ValueKey('installation-folder')),
              )
              .controller!
              .text,
          draft,
        );
        await capture('reloaded-draft');
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        await tap(find.byKey(const ValueKey('nav-preferences')));
        await tap(find.byKey(const ValueKey('preferences-scale')));
        await tap(find.text('150%').last);
        await tap(find.byKey(const ValueKey('apply-preferences')));
        await tap(find.byKey(const ValueKey('nav-workspaces')));
        await tap(find.byKey(const ValueKey('quick-theme')));
        await capture('saved-dark150');
        await tap(find.byKey(const ValueKey('change-installation')));
        await capture('folder-dark150');
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        final after = (await owner.workspaces!.read(workspace)).workspace;
        expect(after.revision, before.revision);
        expect(after.selectedProfile!.id, before.selectedProfile!.id);
        expect(
          (await owner.gameContexts!.read(workspace)).revision,
          saved.revision + 1,
        );
      } finally {
        await tester.pumpWidget(const SizedBox());
        expect(await owner.close(), isTrue);
        await area.delete(recursive: true);
      }
    },
  );
}
