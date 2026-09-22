import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_file_plans/mc_file_plans.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';
import 'package:mod_conductor/src/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets(
    'planned and saved file inspection preserves exact shared hide rules and stale inputs',
    (tester) async {
      tester.testTextInput.register();
      const engine = String.fromEnvironment('MC_ENGINE_PATH');
      const fixture = String.fromEnvironment('MC_NATIVE_FIXTURE');
      const output = String.fromEnvironment('MC_FILES_OUTPUT');
      const narrow = bool.fromEnvironment('MC_FILES_NARROW');
      if (engine.isEmpty || fixture.isEmpty || output.isEmpty) {
        throw StateError('Select native tools and an owned output directory.');
      }
      final area = await Directory.systemTemp.createTemp('mc-files-ui-');
      await Directory(output).create(recursive: true);
      final root = await Directory('${area.path}/workspace').create();
      final inputs = '${area.path}/inputs';
      final prepared = await Process.run(fixture, ['--proton-files', inputs]);
      expect(prepared.exitCode, 0, reason: '${prepared.stderr}');
      final game =
          '$inputs/Second library/steamapps/common/Skyrim Special Edition';
      await File('$game/Data/shared.txt').writeAsString('Game folder');
      final owner = EngineOwner(
        engine,
        launch: (path) =>
            Process.start(path, ['--state-directory', '${area.path}/state']),
      );
      final boundary = GlobalKey();
      FilePlansController controller() => tester
          .widget<FilePlanningWorkbench>(
            find.byType(FilePlanningWorkbench, skipOffstage: false),
          )
          .plans;
      Future<void> until(bool Function() condition) async {
        final deadline = DateTime.now().add(const Duration(seconds: 30));
        while (!condition() && DateTime.now().isBefore(deadline)) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        if (!condition()) {
          final current = controller();
          await File('$output/failure.json').writeAsString(
            jsonEncode({
              'connected': current.connected,
              'reading': current.reading,
              'loading': current.loading,
              'problem': current.problem,
              'snapshot': current.state?.id,
              'needsRead': current.needsRead,
              'treeProblem': current.tree.problem,
              'inspectorProblem': current.inspector.problem,
            }),
          );
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
        expect(tester.takeException(), isNull);
      }

      Finder action(String label) => find.byWidgetPredicate(
        (widget) => widget is McAction && widget.label == label,
      );
      Finder icon(String label) => find.byWidgetPredicate(
        (widget) => widget is McIconAction && widget.label == label,
      );
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
        final workspace = newOperationId(),
            profile = newOperationId(),
            mod = newOperationId(),
            version = newOperationId();
        await owner.workspaces!.create(
          workspace,
          'File check workspace',
          root.path,
        );
        await owner.workspaces!.createProfile(
          workspace,
          0,
          ProfileInfo(profile, 'Everyday'),
        );
        final source = await Directory('${root.path}/Textures').create();
        await File('${source.path}/shared.txt').writeAsString('Mod shared');
        await File('${source.path}/only.txt').writeAsString('Mod only');
        final registered = await owner.modLibrary!.register(
          workspace,
          mod,
          const ModMetadata(name: 'Textures', version: '1.0'),
          const DirectoryMod(ModKind.regular, ['Textures']),
        );
        await owner.modLibrary!.publish(mod, registered.revision, version);
        final inventory = await owner.modOrganization!.query(
          profile,
          const ModQuery(),
        );
        final enabled = await owner.profileMods!.enable(
          profile,
          inventory.selectionRevision,
          [mod],
          true,
        );
        await owner.gameContexts!.save(
          workspace,
          profile,
          'skyrim-se-steam',
          0,
          game,
          proton: Platform.isLinux
              ? ProtonSelection(
                  appId: 489830,
                  association: SteamProtonAssociation(
                    '$inputs/Steam',
                    '$inputs/Second library',
                  ),
                  compatData:
                      '$inputs/Second library/steamapps/compatdata/489830',
                  runtimeDirectory:
                      '$inputs/Steam/compatibilitytools.d/Custom Ω Proton',
                  toolId: 'fixture_tool',
                )
              : null,
        );
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundary,
            child: ModConductorApp(
              workspaces: owner.workspaces,
              modLibrary: owner.modLibrary,
              profileMods: owner.profileMods,
              modOrganization: owner.modOrganization,
              gameContexts: owner.gameContexts,
              filePlans: owner.filePlans,
              steamDiscovery: owner.steamDiscovery,
              protonContexts: owner.protonContexts,
              status: DesktopConnected((owner.state as EngineConnected).report),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tap(find.byKey(ValueKey('workspace-$workspace')));
        await tap(find.text('Mods'));
        await capture('opened-mods');
        await until(() => controller().state != null && !controller().reading);
        if (narrow) {
          await tap(find.byKey(const ValueKey('nav-preferences')));
          await tap(find.byKey(const ValueKey('preferences-scale')));
          await tap(find.text('150%').last);
          await tap(find.byKey(const ValueKey('apply-preferences')));
          await tap(find.byKey(const ValueKey('nav-workspaces')));
        }
        await tap(find.text('Skyrim Data'));
        await capture('cold-light');
        await until(
          () =>
              controller().state?.loaded == true &&
              !controller().loading &&
              !controller().tree.loading,
        );
        expect(controller().state!.problems, isEmpty);
        await tester.enterText(
          find.widgetWithText(TextField, 'Filter files'),
          'shared',
        );
        await until(
          () => controller().tree.model.visible.any(
            (id) => controller().tree.model[id]!.path.last == 'shared.txt',
          ),
        );
        await tap(find.text('shared.txt'));
        await tap(icon('Inspect file'));
        await until(
          () =>
              !controller().inspector.loading &&
              controller().inspector.copies.length == 2,
        );
        await capture('conflict-light');
        await tap(icon('Close inspector'));

        await tester.enterText(
          find.widgetWithText(TextField, 'Filter files'),
          'only',
        );
        await until(
          () => controller().tree.model.visible.any(
            (id) => controller().tree.model[id]!.path.last == 'only.txt',
          ),
        );
        await tap(find.text('only.txt'));
        await tap(icon('Inspect file'));
        await until(
          () =>
              !controller().inspector.loading &&
              controller().inspector.selected != null,
        );
        expect(
          controller().inspector.selected!.copy,
          ManagedFileCopy(mod, version, ['only.txt']),
        );
        await capture('copy-light');
        await tap(action('Hide this copy'));
        await until(
          () =>
              !controller().changing &&
              controller().inspector.selected?.hidden == true,
        );
        expect(controller().state!.absentTargets, 1);
        final pinned = controller().inspector.selected!.copy!;
        expect(
          (await owner.filePlans!.history(
            controller().state!.id,
            pinned,
          )).changes.single.hidden,
          isTrue,
        );
        await capture('hidden-light');
        await tap(action('Unhide this copy'));
        await until(
          () =>
              !controller().changing &&
              controller().inspector.selected?.hidden == false,
        );
        expect(controller().state!.absentTargets, 0);
        await tap(icon('Close inspector'));
        await tap(find.byKey(const ValueKey('quick-theme')));
        await tap(icon('Inspect file'));
        await until(
          () =>
              !controller().inspector.loading &&
              controller().inspector.selected != null,
        );
        await capture('copy-dark');
        await File('$game/Data/shared.txt')
            .writeAsString('Changed external fixture data');
        await tap(action('Hide this copy'));
        await until(
          () =>
              !controller().changing &&
              (controller().loading ||
                  (!controller().needsRead &&
                      controller().state?.stale == false)),
        );
        expect(
          (await owner.filePlans!.history(
            controller().state!.id,
            pinned,
          )).changes.length,
          2,
        );
        await capture('stale-dark');
        await tap(icon('Close inspector'));
        await until(
          () =>
              !controller().loading &&
              !controller().tree.loading &&
              controller().state?.stale == false &&
              !controller().needsRead,
        );
        await capture('refreshed-dark');
        if (narrow) await tap(find.text('Installed mods').first);
        await tap(
          find
              .descendant(
                of: find.byKey(const ValueKey('installed-mods')),
                matching: find.text('Textures'),
              )
              .first,
        );
        await tap(find.text(narrow ? 'Saved files' : 'Saved mod files'));
        await until(
          () => tester
              .widget<FilePlanningWorkbench>(find.byType(FilePlanningWorkbench))
              .mods
              .filesComplete,
        );
        await tap(find.text('only.txt'));
        await tap(icon('Inspect file'));
        await until(
          () =>
              !controller().inspector.loading &&
              controller().inspector.selected?.copy == pinned,
        );
        final history = find.text('Saved version and history');
        final inspectorScroll = find
            .descendant(
              of: find.descendant(
                of: find.byType(McInspector),
                matching: find.byType(ListView),
              ),
              matching: find.byType(Scrollable),
            )
            .first;
        await tester.scrollUntilVisible(
          history,
          160,
          scrollable: inspectorScroll,
          maxScrolls: 12,
        );
        await tap(history);
        await until(() => controller().inspector.historyLoaded);
        expect(controller().inspector.history.length, 2);
        await capture('saved-history-dark');
        await tester.scrollUntilVisible(
          icon('Close inspector'),
          -160,
          scrollable: inspectorScroll,
          maxScrolls: 12,
        );
        await tap(icon('Close inspector'));

        expect(
          (await owner.modOrganization!.query(
            profile,
            const ModQuery(),
          )).selectionRevision,
          enabled.revision,
        );
        expect(
          await File('${source.path}/only.txt').readAsString(),
          'Mod only',
        );
        expect(
          (await owner.modLibrary!.version(version)).entries
              .any((entry) => entry.path.join('/') == 'only.txt'),
          isTrue,
        );
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        expect(await owner.close(), isTrue);
        await area.delete(recursive: true);
      }
    },
  );
}
