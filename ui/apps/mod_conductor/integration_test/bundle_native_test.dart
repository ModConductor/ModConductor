import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mc_artifacts/mc_artifacts.dart';
import 'package:mc_artifacts/src/fomod_view.dart';
import 'package:mc_artifacts/src/bundle_view.dart';
import 'package:mc_artifacts/src/installation_files_review.dart';
import 'package:mc_mod_library/mc_mod_library.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';
import 'package:mod_conductor/src/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets(
    'explicit bundle checklist reuses review and publication across navigation',
    (tester) async {
      const engine = String.fromEnvironment('MC_ENGINE_PATH'),
          output = String.fromEnvironment('MC_BUNDLE_OUTPUT'),
          files = String.fromEnvironment('MC_BUNDLE_INPUT');
      const narrow = bool.fromEnvironment('MC_BUNDLE_NARROW');
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
        if (find.text(label).evaluate().isEmpty) {
          await tester.scrollUntilVisible(
            find.text(label),
            100,
            scrollable: find
                .descendant(
                  of: find.byType(ModBundleView),
                  matching: find.byType(Scrollable),
                )
                .last,
          );
        }
        final row = find.text(label).last;
        await tester.ensureVisible(row);
        await tester.pumpAndSettle();
        await tester.tap(row);
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
          '$files/Weekend collection.zip',
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
              bundles: owner.bundles,
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
        await tap('Open bundle');
        await until(
          () =>
              action('Continue').evaluate().isNotEmpty &&
              tester.widget<McAction>(action('Continue')).onPressed == null,
        );
        await capture('select-empty');
        await menu('Archive selection', 'Select all');
        await capture('select');
        await tap('Continue');
        await until(() => action('Configure next').evaluate().isNotEmpty);
        await selectRow(narrow ? '2. First' : 'First');
        await tap('Close inspector');
        await menu('Mod actions', 'Move earlier');
        await until(
          () => find.text(narrow ? '1. First' : 'First').evaluate().isNotEmpty,
        );
        await capture('overview');
        await menu('Bundle actions', 'Installation order');
        await capture('order');
        await tap('Close');
        await tap('Configure next');
        await until(() => action('Install').evaluate().isNotEmpty);
        await capture('review');
        await tap('Install');
        await tester.tap(find.text('Mods').first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Archives').first);
        await tester.pumpAndSettle();
        await until(() => action('Open Mods').evaluate().isNotEmpty);
        await capture('installed');
        await tap('Back to bundle');
        await until(() => action('Configure next').evaluate().isNotEmpty);
        var saved = (await owner.bundles!.find(workspace, archive.id))!;
        expect(saved.items.first.state, BundleItemState.installed);
        expect(saved.items[1].state, BundleItemState.needsReview);
        final first = (await owner.installations!.recent(workspace)).single;
        await tap('Back to archives');
        await tester.tap(find.byKey(ValueKey(archive.id)).first);
        await tester.pumpAndSettle();
        await tap('Open bundle');
        await until(() => action('Configure next').evaluate().isNotEmpty);
        await capture('resumed');
        await tap('Configure next');
        await until(() => action('Continue').evaluate().isNotEmpty);
        await menu('Archive selection', 'Select all');
        await capture('nested');
        await tap('Continue');
        await until(() => action('Configure next').evaluate().isNotEmpty);
        await tap('Configure next');
        await until(
          () =>
              find.byType(FomodView).evaluate().isNotEmpty &&
              action('Install').evaluate().isNotEmpty,
        );
        expect(
          tester
              .widget<InstallationFilesReview>(
                find.byType(InstallationFilesReview),
              )
              .files
              .single
              .destination,
          ['textures', 'road.dds'],
        );
        await capture('xml-review');
        await tap('Back to bundle');
        await until(() => action('Configure next').evaluate().isNotEmpty);
        await tap('Configure next');
        await until(() => action('Install').evaluate().isNotEmpty);
        await tap('Install');
        await until(() => action('Open Mods').evaluate().isNotEmpty);
        await tap('Back to bundle');
        await until(() => action('Configure next').evaluate().isNotEmpty);
        await tap('Configure next');
        await until(() => action('Retry').evaluate().isNotEmpty);
        await capture('failed');
        saved = (await owner.bundles!.find(workspace, archive.id))!;
        expect(
          saved.items.where((m) => m.state == BundleItemState.installed),
          hasLength(2),
        );
        expect(saved.items.last.state, BundleItemState.failed);
        await selectRow(narrow ? '3. Unreadable' : 'Unreadable');
        await capture('failure-details');
        await tap('Close inspector');
        await capture('failed-row');
        await tap('Retry');
        await until(
          () =>
              tester.widget<McAction>(action('Retry').first).onPressed != null,
        );
        await capture('retry');
        await menu('Bundle actions', 'Delete temporary files');
        await capture('cleanup');
        await tap('Delete temporary files');
        await until(() => action('Refresh Archives').evaluate().isNotEmpty);
        expect(await owner.bundles!.find(workspace, archive.id), isNull);
        expect(await owner.installations!.recent(workspace), hasLength(2));
        await tester.tap(find.text('Mods').first);
        await tester.pumpAndSettle();
        await until(() => mods().inventory.loaded == 2);
        await tester.tap(find.byKey(ValueKey((modId: first.modId!))).first);
        await tester.pumpAndSettle();
        await capture('mods');
        if (narrow) {
          await tester.tap(find.text('Installed mods').last);
          await tester.pumpAndSettle();
          await tester.tap(find.text('Saved mod files').last);
          await tester.pumpAndSettle();
        }
        await tap('Archive source');
        await capture('provenance');
        await tap('Close');
        final version = await owner.modLibrary!.version(first.versionId!);
        expect(version.origin.bundle!.archives.single.path, ['First.zip']);
        expect(await File('$files/Weekend collection.zip').exists(), isTrue);
        await File('$output/result.txt').writeAsString(
          'Actual compiled production checklist: explicit selection/order, existing manual/XML review and Back, tab navigation during install, saved-checklist resume, two committed disabled mods, ordinary unreadable third archive with no false success, retry/cleanup dialogs, exact individual provenance and explicit temporary cleanup. No game/script execution.\n',
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
