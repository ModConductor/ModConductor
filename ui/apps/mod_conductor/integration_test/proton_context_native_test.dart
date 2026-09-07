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
    'Proton selection stays a draft until Save and failed Refresh preserves its evidence',
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
      final steamArea = '${area.path}/steam-fixture';
      final data = '$steamArea/Second library/steamapps/compatdata/489830';
      final runtime = '$steamArea/Steam/compatibilitytools.d/Custom Ω Proton';
      final game =
          '$steamArea/Second library/steamapps/common/Skyrim Special Edition';
      final prepared = await Process.run(fixtureTool, [
        '--proton-files',
        steamArea,
      ]);
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
        await tester.pumpAndSettle();
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
              steamDiscovery: owner.steamDiscovery,
              protonContexts: owner.protonContexts,
              chooseGameDirectory: (_) async => null,
              status: DesktopConnected((owner.state as EngineConnected).report),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tap(find.byKey(ValueKey('workspace-$workspace')));
        await tap(find.text('Game'));
        await until(() => controller().state != null && !controller().loading);
        Future<void> choose() async {
          await tap(find.byKey(const ValueKey('select-installation')));
          await tester.enterText(
            find.byKey(const ValueKey('installation-folder')),
            game,
          );
          if (Platform.isLinux) {
            await tap(find.byKey(const ValueKey('select-proton')));
            await tester.enterText(
              find.byKey(const ValueKey('proton-data-folder')),
              data,
            );
            await tester.enterText(
              find.byKey(const ValueKey('proton-runtime-folder')),
              runtime,
            );
            await capture('proton-draft');
            await tap(find.byKey(const ValueKey('submit')).last);
          }
          expect((await owner.gameContexts!.read(workspace)).binding, isNull);
        }

        await choose();
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect((await owner.gameContexts!.read(workspace)).binding, isNull);
        await choose();
        await tap(find.byKey(const ValueKey('submit')).last);
        await until(
          () => find
              .byKey(const ValueKey('installation-folder'))
              .evaluate()
              .isEmpty,
        );
        final saved = await owner.gameContexts!.read(workspace);
        if (Platform.isLinux) {
          expect(saved.binding!.proton!.compatData, data);
          expect(
            saved.binding!.proton!.toolId,
            saved.binding!.evidence.proton!.selection.toolId,
          );
          expect(
            saved.binding!.evidence.proton!.runtimeName,
            'Fixture Proton Ω',
          );
          expect(
            saved.binding!.evidence.proton!.paths.any(
              (p) => p.location is LocatedGameFolder,
            ),
            isTrue,
          );
        } else {
          expect(saved.binding!.proton, isNull);
          expect(saved.binding!.evidence.platform, GameContextPlatform.windows);
        }
        await capture('saved-context');
        await tap(find.byKey(const ValueKey('nav-preferences')));
        await tap(find.byKey(const ValueKey('preferences-scale')));
        await tap(find.text('150%').last);
        await tap(find.byKey(const ValueKey('apply-preferences')));
        await tap(find.byKey(const ValueKey('nav-workspaces')));
        await tap(find.byKey(const ValueKey('quick-theme')));
        await capture('saved-dark150');
        if (Platform.isLinux) {
          await tap(find.byKey(const ValueKey('change-installation')));
          await tap(find.byKey(const ValueKey('select-proton')));
          await capture('proton-dark150');
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await tester.pumpAndSettle();
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await tester.pumpAndSettle();
          await File('$runtime/proton').rename('$runtime/proton.hidden');
          await tap(find.byKey(const ValueKey('refresh-installation')));
          await until(
            () =>
                !controller().loading &&
                controller().state!.revision > saved.revision,
          );
          final failed = await owner.gameContexts!.read(workspace);
          expect(failed.binding!.needsCheck, isTrue);
          expect(
            failed.binding!.proton!.compatData,
            saved.binding!.proton!.compatData,
          );
          expect(
            failed.binding!.evidence.fingerprint,
            saved.binding!.evidence.fingerprint,
          );
          await capture('failed-refresh');
          await File('$runtime/proton.hidden').rename('$runtime/proton');
        }
        final after = (await owner.workspaces!.read(workspace)).workspace;
        expect(after.revision, before.revision);
        expect(after.selectedProfile!.id, before.selectedProfile!.id);
      } finally {
        await tester.pumpWidget(const SizedBox());
        expect(await owner.close(), isTrue);
        await area.delete(recursive: true);
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
