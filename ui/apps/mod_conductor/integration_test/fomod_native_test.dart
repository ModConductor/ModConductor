import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mc_artifacts/mc_artifacts.dart';
import 'package:mc_artifacts/src/fomod_view.dart';
import 'package:mc_artifacts/src/fomod_options.dart';
import 'package:mc_mod_library/mc_mod_library.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';
import 'package:mod_conductor/src/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets(
    'installer choices backtrack into the confirmed production installation',
    (tester) async {
      const engine = String.fromEnvironment('MC_ENGINE_PATH'),
          output = String.fromEnvironment('MC_FOMOD_OUTPUT'),
          files = String.fromEnvironment('MC_FOMOD_INPUT');
      const narrow = bool.fromEnvironment('MC_FOMOD_NARROW');
      if (!Platform.isLinux ||
          engine.isEmpty ||
          output.isEmpty ||
          files.isEmpty) {
        throw StateError('Select the native engine and owned fixture paths.');
      }
      await Directory(output).create(recursive: true);
      final area = await Directory(output).createTemp('fixture-');
      final root = await Directory(
        '${area.path}/Weekend workspace with a long path',
      ).create(recursive: true);
      final owner = EngineOwner(
        engine,
        launch: (path) =>
            Process.start(path, ['--state-directory', '${area.path}/state']),
      );
      final boundary = GlobalKey(),
          workspace = newOperationId(),
          profile = newOperationId();
      ArtifactController artifacts() => tester
          .widget<ArtifactBrowser>(
            find.byType(ArtifactBrowser, skipOffstage: false),
          )
          .controller;
      ModLibraryController mods() => tester
          .widget<ModLibraryBrowser>(
            find.byType(ModLibraryBrowser, skipOffstage: false),
          )
          .controller;
      Finder action(String label) => find.byWidgetPredicate(
        (widget) =>
            (widget is McAction && widget.label == label) ||
            (widget is McIconAction && widget.label == label),
      );
      Future<void> tap(String label) async {
        final found = action(label).last;
        await tester.ensureVisible(found);
        await tester.pumpAndSettle();
        await tester.tap(found);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      Future<void> until(bool Function() done) async {
        final end = DateTime.now().add(const Duration(seconds: 30));
        while (!done() && DateTime.now().isBefore(end)) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(done(), isTrue);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      Future<void> capture(String name) async {
        final image =
            await (boundary.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage();
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('$output/$name.png')
            .writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      }

      Future<void> advance() async {
        await tap(
          action('Next').evaluate().isNotEmpty ? 'Next' : 'Review files',
        );
      }

      Future<void> choose(String name) async {
        final found = find.text(name).last;
        await tester.ensureVisible(found);
        await tester.pumpAndSettle();
        await tester.tap(found);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      List<FomodOption> options() => tester
          .widget<FomodOptionGroups>(find.byType(FomodOptionGroups))
          .groups
          .expand((g) => g.options)
          .toList();
      final previousError = FlutterError.onError;
      FlutterError.onError = (details) {
        File(
          '$output/primary-ui-errors.log',
        ).writeAsStringSync('${details.toString()}\n', mode: FileMode.append);
        previousError?.call(details);
      };
      try {
        await owner.connect();
        expect(owner.state, isA<EngineConnected>());
        await owner.workspaces!.create(workspace, 'Weekend', root.path);
        await owner.workspaces!.createProfile(
          workspace,
          0,
          ProfileInfo(profile, 'Everyday'),
        );
        final archive = await owner.artifacts!.add(
          workspace,
          newOperationId(),
          '$files/Rivière-1.3.zip',
          ArtifactStorage.copy,
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
              deployments: owner.deployments,
              executables: owner.executables,
              gameLaunching: owner.gameLaunching,
              filePlans: owner.filePlans,
              outputs: owner.outputs,
              artifacts: owner.artifacts,
              installations: owner.installations,
              maintenance: owner.maintenance,
              fomod: owner.fomod,
              status: DesktopConnected((owner.state as EngineConnected).report),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(ValueKey('workspace-$workspace')));
        await until(
          () =>
              find
                  .byType(ArtifactBrowser, skipOffstage: false)
                  .evaluate()
                  .isNotEmpty &&
              artifacts().loaded,
        );
        await tester.tap(find.text('Archives').first);
        await tester.pumpAndSettle();
        if (narrow) {
          await tester.tap(find.byKey(const ValueKey('nav-preferences')));
          await tester.pumpAndSettle();
          await tester.tap(find.text('100%'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('150%').last);
          await tester.pumpAndSettle();
          await tap('Apply');
          await tester.tap(find.byKey(const ValueKey('nav-workspaces')));
          await tester.pumpAndSettle();
        }
        await tester.tap(find.byKey(ValueKey(archive.id)).first);
        await tester.pumpAndSettle();
        await tap('Install');
        await until(() => find.byType(FomodOptionGroups).evaluate().isNotEmpty);
        await capture('quality');
        await advance();
        expect(options().every((o) => !o.selected), isTrue);
        expect(await owner.installations!.recent(workspace), isEmpty);
        await capture('validation');
        await choose('2K textures');
        await advance();
        await choose('Waterfalls');
        await capture('patches');
        await advance();
        await choose('Clear water');
        await capture('foam');
        await advance();
        var selected = tester.widget<FomodView>(find.byType(FomodView)).initial;
        expect(
          selected.files.map((f) => f.destination.join('/')),
          contains('textures/foam.dds'),
        );
        await tap('Previous step');
        expect(
          options().singleWhere((o) => o.name == 'Clear water').selected,
          isTrue,
        );
        await tap('Previous step');
        await choose('Waterfalls');
        await choose('Riverbanks');
        await capture('backtracked');
        await advance();
        selected = tester.widget<FomodView>(find.byType(FomodView)).initial;
        expect(
          selected.files.map((f) => f.destination.join('/')),
          isNot(contains('textures/foam.dds')),
        );
        expect(
          selected.files.map((f) => f.destination.join('/')),
          contains('Riviere/patch.ini'),
        );
        expect(
          selected.files.where(
            (f) =>
                f.index ==
                selected.files
                    .singleWhere(
                      (f) => f.destination.join('/') == 'textures/water.dds',
                    )
                    .index,
          ),
          hasLength(2),
        );
        await capture('review');
        await tap('All files');
        await tester.tap(
          find.widgetWithText(MenuItemButton, 'Replacements (1)').last,
        );
        await tester.pumpAndSettle();
        await capture('replacements');
        await tester.tap(find.byType(McIconMenu<String>).last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Use manual layout').last);
        await tester.pumpAndSettle();
        await capture('manual-confirm');
        await tap('Use manual layout');
        await until(() => find.byType(FomodView).evaluate().isEmpty);
        await capture('manual');
        await tap('Back to archives');
        await tester.tap(find.byKey(ValueKey(archive.id)).first);
        await tester.pumpAndSettle();
        await tap('Install');
        await until(() => find.byType(FomodOptionGroups).evaluate().isNotEmpty);
        expect(options().every((o) => !o.selected), isTrue);
        await choose('2K textures');
        await advance();
        await choose('Riverbanks');
        await advance();
        await tap('Install');
        await tester.pump();
        await tester.tap(find.text('Mods').first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Archives').first);
        await tester.pumpAndSettle();
        await until(() => action('Open Mods').evaluate().isNotEmpty);
        await capture('installed');
        final installed = (await owner.installations!.recent(workspace)).single;
        expect(installed.phase, InstallationPhase.complete);
        await tap('Open Mods');
        await until(() => mods().inventory.loaded > 0);
        await tester.tap(find.byKey(ValueKey((modId: installed.modId!))).first);
        await tester.pumpAndSettle();
        await capture('mods');
        final version = await owner.modLibrary!.version(installed.versionId!);
        expect(
          version.entries.map((e) => e.path.join('/')),
          isNot(contains('textures/foam.dds')),
        );
        expect(await File('$files/Rivière-1.3.zip').exists(), isTrue);
        await File('$output/result.txt').writeAsString(
          'Compiled production widgets + NativeAOT v1: cardinality validation, choices, Back and dependent choice removal, exact review/replacements, explicit manual fallback, fresh choices, install across tab navigation and Open Mods. No game context used by UI fixture; native owner fixture owns game/file facts and deletion.\n',
        );
      } catch (error, stack) {
        File('$output/primary-ui-error.log').writeAsStringSync(
          '${error is ArtifactProblem ? error.detail : error}\n$stack\n',
        );
        rethrow;
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await owner.close();
        FlutterError.onError = previousError;
      }
    },
  );
}
