import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mc_artifacts/mc_artifacts.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';
import 'package:mod_conductor/src/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets(
    'local archives retain provenance through locate cleanup and engine restart',
    (tester) async {
      const engine = String.fromEnvironment('MC_ENGINE_PATH'),
          output = String.fromEnvironment('MC_ARTIFACT_OUTPUT');
      const narrow = bool.fromEnvironment('MC_ARTIFACT_NARROW');
      if (!Platform.isLinux || engine.isEmpty || output.isEmpty) {
        throw StateError(
          'Select a native Linux engine and owned output folder.',
        );
      }
      await Directory(output).create(recursive: true);
      final area = await Directory(output).createTemp('fixture-');
      final workspacePath = '${area.path}/workspace';
      await Directory('$workspacePath/mod').create(recursive: true);
      await File('$workspacePath/mod/content.txt')
          .writeAsString('installed mod fixture');
      final originalPath = '${area.path}/Textures — rivière.zip',
          movedPath = '${area.path}/renamed archive.7z';
      final bytes = List<int>.generate(150000, (i) => i % 251);
      await File(originalPath).writeAsBytes(bytes);
      var chosen = originalPath;
      EngineOwner newOwner() => EngineOwner(
        engine,
        launch: (path) =>
            Process.start(path, ['--state-directory', '${area.path}/state']),
      );
      var owner = newOwner();
      final boundary = GlobalKey();
      ArtifactController controller() => tester
          .widget<ArtifactBrowser>(
            find.byType(ArtifactBrowser, skipOffstage: false),
          )
          .controller;
      Finder action(String label) => find.byWidgetPredicate(
        (w) =>
            (w is McAction && w.label == label) ||
            (w is McIconAction && w.label == label),
      );
      Future<void> until(bool Function() condition) async {
        final end = DateTime.now().add(const Duration(seconds: 30));
        while (!condition() && DateTime.now().isBefore(end)) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(condition(), isTrue);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      Future<void> tap(String label) async {
        if (action(label).evaluate().isEmpty) {
          final inspector = find.byType(McInspector).last;
          final scroll = find
              .descendant(of: inspector, matching: find.byType(Scrollable))
              .first;
          await tester.scrollUntilVisible(
            action(label),
            160,
            scrollable: scroll,
            maxScrolls: 30,
          );
        }
        final found = action(label).last;
        await tester.ensureVisible(found);
        await tester.pumpAndSettle();
        await tester.tap(found);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      Future<void> capture(String name) async {
        await tester.pumpAndSettle();
        final image =
            await (boundary.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage();
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('$output/$name.png')
            .writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      }

      Future<void> inspect(String id) async {
        if (narrow) {
          final drawer = find.byType(Drawer);
          if (drawer.evaluate().isNotEmpty) {
            await tester.sendKeyEvent(LogicalKeyboardKey.escape);
            await tester.pumpAndSettle();
          }
        }
        await tester.tap(find.byKey(ValueKey(id)).first);
        await tester.pumpAndSettle();
      }

      Future<void> linked() async {
        await tap('Link installed mod');
        await capture('link-form-diagnostic');
        await until(
          () =>
              action('Link mod')
                  .evaluate()
                  .any((e) => (e.widget as McAction).onPressed != null),
        );
        await tap('Link mod');
        await until(() => !controller().busy);
        expect(controller().problem, isNull);
      }

      try {
        await owner.connect();
        expect(owner.state, isA<EngineConnected>());
        expect(
          (owner.state as EngineConnected).report.runtime.nativeAot,
          isTrue,
        );
        final workspace = newOperationId(),
            profile = newOperationId(),
            mod = newOperationId(),
            version = newOperationId();
        await owner.workspaces!.create(workspace, 'Weekend', workspacePath);
        await owner.workspaces!.createProfile(
          workspace,
          0,
          ProfileInfo(profile, 'Everyday'),
        );
        final registered = await owner.modLibrary!.register(
          workspace,
          mod,
          const ModMetadata(name: 'River textures', version: '1.0'),
          const DirectoryMod(ModKind.regular, ['mod']),
        );
        await owner.modLibrary!.publish(mod, registered.revision, version);
        final choices = await owner.artifacts!.linkOptions(workspace);
        expect(choices.entries.single.versionId, version);
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
              artifacts: owner.artifacts,
              chooseArchive: () async =>
                  ArchiveFile(chosen, await File(chosen).length()),
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
              controller().loaded,
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
        await tap('Add archive');
        await tap('Choose file');
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(controller().model.ids, isEmpty);
        await tap('Add archive');
        await tap('Choose file');
        await capture('add-reference');
        await tap('Add archive');
        await until(
          () => !controller().busy && controller().model.ids.length == 1,
        );
        expect(controller().problem, isNull);
        final referenceId = controller().selected!.id;
        await inspect(referenceId);
        await linked();
        expect(controller().selected!.links.single.versionId, version);
        await capture('manual-provenance');
        await File(originalPath).rename(movedPath);
        chosen = movedPath;
        await controller().load();
        await tester.pumpAndSettle();
        expect(controller().model[referenceId]!.state, ArtifactState.detached);
        await inspect(referenceId);
        await capture('file-not-found-with-link');
        await tap('Locate archive');
        await tap('Choose file');
        await tap('Use file');
        await until(() => !controller().busy);
        expect(controller().selected!.id, referenceId);
        expect(controller().selected!.path, movedPath);
        expect(controller().selected!.state, ArtifactState.installed);
        if (narrow) {
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await tester.pumpAndSettle();
        }
        await tap('Add archive');
        await tap('Choose file');
        await tester.tap(find.text('Keep in current folder'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Copy to library').last);
        await tester.pumpAndSettle();
        await capture('add-managed-copy');
        await tap('Add archive');
        await until(
          () => !controller().busy && controller().model.ids.length == 2,
        );
        expect(controller().problem, isNull);
        final copiedId = controller().selected!.id;
        await inspect(copiedId);
        await linked();
        if (narrow) {
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await tester.pumpAndSettle();
        } else {
          await tap('Close inspector');
        }
        await capture('archive-list-full-header');
        await inspect(copiedId);
        await tap('Delete copy');
        await capture('delete-copy-confirmation');
        await tap('Delete copy');
        await until(() => !controller().busy);
        expect(controller().selected!.state, ArtifactState.detached);
        expect(controller().selected!.links.single.versionId, version);
        expect(await File(controller().selected!.path).exists(), isFalse);
        expect(await File(movedPath).readAsBytes(), bytes);
        await capture('deleted-copy-retains-provenance');
        await tap('Remove link');
        await until(() => !controller().busy);
        await tap('Remove from list');
        await tap('Remove from list');
        await until(() => !controller().busy);
        expect(controller().model.ids, [referenceId]);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        expect(await owner.close(), isTrue);
        owner = newOwner();
        await owner.connect();
        final restored = await owner.artifacts!.list(workspace);
        expect(restored.entries.single.id, referenceId);
        expect(restored.entries.single.path, movedPath);
        expect(restored.entries.single.originalPath, originalPath);
        expect(restored.entries.single.links.single.versionId, version);
        expect(restored.entries.single.state, ArtifactState.installed);
        expect(await File(movedPath).readAsBytes(), bytes);
        await File('$output/result.txt').writeAsString(
          'Compiled Linux Flutter used the NativeAOT engine. Reference adoption, manual provenance, locate, managed copy, explicit cleanup, and process restart passed. Original bytes remained unchanged.\n',
        );
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await owner.close();
      }
    },
  );
}
