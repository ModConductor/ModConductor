import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mc_artifacts/mc_artifacts.dart';
import 'package:mc_artifacts/src/fomod_view.dart';
import 'package:mc_artifacts/src/bain_view.dart';
import 'package:mc_artifacts/src/installation_files_review.dart';
import 'package:mc_ui_collections/mc_ui_collections.dart';
import 'package:mc_mod_library/mc_mod_library.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';
import 'package:mod_conductor/src/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets(
    'package choices and file exclusions reach the existing installation owner',
    (tester) async {
      const engine = String.fromEnvironment('MC_ENGINE_PATH'),
          output = String.fromEnvironment('MC_BAIN_OUTPUT'),
          files = String.fromEnvironment('MC_BAIN_INPUT');
      const narrow = bool.fromEnvironment('MC_BAIN_NARROW');
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

      Future<void> selectRow(String label) async {
        final row = find.text(label).last;
        await tester.ensureVisible(row);
        await tester.pumpAndSettle();
        await tester.tap(row);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      Future<void> checkRow(String label) async {
        final matches = find.text(label);
        if (matches.evaluate().isEmpty) {
          await tester.scrollUntilVisible(
            find.text(label),
            120,
            scrollable: find
                .descendant(
                  of: find.byType(BainView),
                  matching: find.byType(Scrollable),
                )
                .last,
          );
        }
        final text = matches.last;
        await tester.ensureVisible(text);
        await tester.pumpAndSettle();
        final row = find
            .ancestor(of: text, matching: find.byType(InkWell))
            .first;
        final check = find.descendant(of: row, matching: find.byType(Checkbox));
        await tester.tap(check);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      Future<void> menu(String label, String item) async {
        final button = find.byWidgetPredicate(
          (w) => w is McIconMenu<String> && w.label == label,
        );
        await tester.tap(button.last);
        await tester.pumpAndSettle();
        await tester.tap(find.text(item).last);
        await tester.pumpAndSettle();
      }

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
          '$files/Rivière textures.zip',
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
              bain: owner.bain,
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
        await until(
          () =>
              find.byType(McCollection<int, BainPackage>).evaluate().isNotEmpty,
        );
        await capture('packages');
        await menu('Folder selection', 'Clear selection');
        expect(
          tester.widget<McAction>(action('Review files')).onPressed,
          isNull,
        );
        await capture('empty');
        await checkRow('00 Core');
        await checkRow('10 Textures');
        await checkRow('2 Alternatives');
        await selectRow('2 Alternatives');
        await capture('folder');
        if (narrow) {
          await tester.drag(
            find
                .descendant(
                  of: find.byType(McInspector),
                  matching: find.byType(ListView),
                )
                .last,
            const Offset(0, -240),
          );
          await tester.pumpAndSettle();
          await capture('folder-scrolled');
          await tester.drag(
            find
                .descendant(
                  of: find.byType(McInspector),
                  matching: find.byType(ListView),
                )
                .last,
            const Offset(0, 240),
          );
          await tester.pumpAndSettle();
        }
        await tap('Close inspector');
        await menu('Installer actions', 'Package notes');
        await capture('notes');
        await tap('Close');
        await tap('Folder order');
        await capture('order');
        await tap('Close');
        await tap('Review files');
        final review = tester.widget<InstallationFilesReview>(
          find.byType(InstallationFilesReview),
        );
        expect(
          review.files
              .singleWhere(
                (f) => f.destination.join('/') == 'textures/water.dds',
              )
              .choice,
          '2 Alternatives',
        );
        await capture('review');
        await tap('All files');
        await tester.tap(
          find.widgetWithText(MenuItemButton, 'Replacements (1)').last,
        );
        await tester.pumpAndSettle();
        await selectRow('textures/water.dds');
        await capture('replacements');
        await tap('Close inspector');
        await checkRow('textures/water.dds');
        expect(
          tester
              .widget<InstallationFilesReview>(
                find.byType(InstallationFilesReview),
              )
              .files
              .singleWhere(
                (f) => f.destination.join('/') == 'textures/water.dds',
              )
              .included,
          isFalse,
        );
        await capture('excluded');
        await tap('Back to package folders');
        await checkRow('2 Alternatives');
        await tap('Review files');
        final changed = tester.widget<InstallationFilesReview>(
          find.byType(InstallationFilesReview),
        );
        expect(
          changed.files
              .singleWhere(
                (f) => f.destination.join('/') == 'textures/water.dds',
              )
              .included,
          isFalse,
        );
        expect(
          changed.files
              .singleWhere(
                (f) => f.destination.join('/') == 'textures/water.dds',
              )
              .choice,
          '10 Textures',
        );
        await checkRow('textures/water.dds');
        expect(await owner.installations!.recent(workspace), isEmpty);
        await menu('Installer actions', 'Use manual layout');
        await capture('manual-confirm');
        await tap('Use manual layout');
        await until(() => find.byType(BainView).evaluate().isEmpty);
        await capture('manual');
        await tap('Back to archives');
        await tester.tap(find.byKey(ValueKey(archive.id)).first);
        await tester.pumpAndSettle();
        await tap('Install');
        await until(
          () =>
              find.byType(McCollection<int, BainPackage>).evaluate().isNotEmpty,
        );
        final packages = tester
            .widget<McCollection<int, BainPackage>>(
              find.byType(McCollection<int, BainPackage>),
            )
            .model;
        expect(
          packages.ids.where((id) => packages[id]!.selected),
          hasLength(1),
        );
        await checkRow('10 Textures');
        await tap('Review files');
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
        expect(version.entries, hasLength(3));
        expect(await File('$files/Rivière textures.zip').exists(), isTrue);
        // Use the same production entry to confirm XML remains the preferred mode.
        final combined = await owner.artifacts!.add(
          workspace,
          newOperationId(),
          '$files/combined.zip',
          ArtifactStorage.copy,
        );
        await tester.tap(find.text('Archives').first);
        await tester.pumpAndSettle();
        await tap('Back to archives');
        await until(() => action('Refresh Archives').evaluate().isNotEmpty);
        await tap('Refresh Archives');
        await until(
          () => find.byKey(ValueKey(combined.id)).evaluate().isNotEmpty,
        );
        await tester.tap(find.byKey(ValueKey(combined.id)).first);
        await tester.pumpAndSettle();
        await tap('Install');
        await until(
          () =>
              find.byType(FomodView).evaluate().isNotEmpty &&
              action('Install').evaluate().isNotEmpty,
        );
        await capture('xml-preferred');
        await menu('Installer actions', 'Use package folders');
        await tap('Use package folders');
        await until(
          () =>
              find.byType(McCollection<int, BainPackage>).evaluate().isNotEmpty,
        );
        await capture('switched-packages');
        await File('$output/result.txt').writeAsString(
          'Compiled production widgets and NativeAOT services: package defaults and clear/select, folder and note details, lexical replacement review, file exclusion retained through Back, explicit manual switch, fresh draft, installation across tab navigation, disabled installed row, and XML-preferred/explicit package mode switch. No game or wizard execution.\n',
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
