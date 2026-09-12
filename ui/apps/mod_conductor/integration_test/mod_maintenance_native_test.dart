import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mc_artifacts/mc_artifacts.dart';
import 'package:mc_artifacts/src/update_view.dart';
import 'package:mc_mod_library/mc_mod_library.dart';
import 'package:mc_mod_library/src/deletion_view.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';
import 'package:mod_conductor/src/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets('update and owned deletion use production controls', (
    tester,
  ) async {
    const engine = String.fromEnvironment('MC_ENGINE_PATH'),
        output = String.fromEnvironment('MC_MAINTENANCE_OUTPUT'),
        files = String.fromEnvironment('MC_MAINTENANCE_INPUT');
    const narrow = bool.fromEnvironment('MC_MAINTENANCE_NARROW');
    if (!Platform.isLinux ||
        engine.isEmpty ||
        output.isEmpty ||
        files.isEmpty) {
      throw StateError('Select the native engine and owned fixture paths.');
    }
    await Directory(output).create(recursive: true);
    final area = await Directory(output).createTemp('fixture-');
    final root = await Directory(
      '${area.path}/Mod collections/Skyrim Special Edition/Weekend workspace with a long path',
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
      await File('$output/$name.png').writeAsBytes(data!.buffer.asUint8List());
      image.dispose();
    }

    final previousError = FlutterError.onError;
    FlutterError.onError = (details) {
      File('$output/primary-ui-errors.log')
          .writeAsStringSync('${details.toString()}\n', mode: FileMode.append);
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
      final original = await owner.artifacts!.add(
        workspace,
        newOperationId(),
        '$files/Rivière-1.2.zip',
        ArtifactStorage.copy,
      );
      var draft = await owner.installations!.prepare(original).result;
      draft = await owner.installations!.change(
        draft,
        const InstallationMetadataChange('Rivière textures', '1.2'),
      );
      var installed = await owner.installations!.start(draft, newOperationId());
      await for (final value in owner.installations!.watch(installed)) {
        installed = value;
      }
      expect(installed.phase, InstallationPhase.complete);
      final newer = await owner.artifacts!.add(
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
      await tester.tap(find.byKey(ValueKey(newer.id)).first);
      await tester.pumpAndSettle();
      await tap('Install');
      await until(() => action('Update installed mod').evaluate().isNotEmpty);
      await tap('Update installed mod');
      await until(() => action('Review update').evaluate().isNotEmpty);
      await tester.enterText(find.byType(TextField).last, '1.3');
      await tester.pumpAndSettle();
      await capture('target');
      await tap('Review update');
      await until(() => find.byType(ModUpdateView).evaluate().isNotEmpty);
      await capture('merge');
      await tap('Merge');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(MenuItemButton, 'Replace').last);
      await tester.pumpAndSettle();
      await capture('replace');
      await tap('Replace');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(MenuItemButton, 'Merge').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('textures/water.dds').first);
      await tester.pumpAndSettle();
      await Scrollable.ensureVisible(
        tester.element(find.byType(McChoice<bool>).last),
        alignment: 1,
      );
      await tester.pumpAndSettle();
      await capture('conflict');
      await tester.tap(find.text('Use archive').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keep current').last);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ModUpdateView>(find.byType(ModUpdateView))
            .controller
            .updatePreview!
            .keep,
        contains(equals(['textures', 'water.dds'])),
      );
      await tester.tap(find.text('Keep current').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Use archive').last);
      await tester.pumpAndSettle();
      if (narrow) {
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
      }
      await tester.tap(action('Update').last);
      await tester.pump();
      await tester.tap(find.text('Mods').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Archives').first);
      await tester.pumpAndSettle();
      await until(() => action('Open Mods').evaluate().isNotEmpty);
      await capture('updated');
      await tap('Open Mods');
      await until(() => mods().inventory.loaded > 0);
      await tester.tap(find.byKey(ValueKey((modId: installed.modId!))).first);
      await tester.pumpAndSettle();
      await capture('mods');
      await tap('Delete mod');
      await until(
        () =>
            find.byType(ModDeletionView).evaluate().isNotEmpty &&
            action('Delete…').evaluate().isNotEmpty,
      );
      await capture('delete-review');
      await tap('Delete…');
      await capture('delete-confirm');
      await tap('Delete');
      await until(() => action('Open Mods').evaluate().isNotEmpty);
      await capture('deleted');
      expect((await owner.maintenance!.recentDeletions(workspace)), isEmpty);
      expect(
        (await owner.modLibrary!.scan(
          workspace,
          candidateLimit: 100,
        )).entries.where((entry) => entry.id == installed.modId),
        isEmpty,
      );
      expect(await File('$files/Rivière-1.2.zip').exists(), isTrue);
      expect(await File('$files/Rivière-1.3.zip').exists(), isTrue);
      await File('$output/result.txt').writeAsString(
        'Compiled production app and NativeAOT v1 services: target selection, merge/replace preview, conflict inspector, stable-mod update, owned deletion confirmation and result. External fixture originals remain.\n',
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
  });
}
