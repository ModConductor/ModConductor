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
    'archive metadata and ordinary error use the production contents view',
    (tester) async {
      const engine = String.fromEnvironment('MC_ENGINE_PATH'),
          fixture = String.fromEnvironment('MC_NATIVE_FIXTURE'),
          output = String.fromEnvironment('MC_INSPECTION_OUTPUT');
      const narrow = bool.fromEnvironment('MC_INSPECTION_NARROW');
      if (!Platform.isLinux ||
          engine.isEmpty ||
          fixture.isEmpty ||
          output.isEmpty) {
        throw StateError(
          'Select native Linux binaries and an owned output folder.',
        );
      }
      await Directory(output).create(recursive: true);
      final area = await Directory(output).createTemp('fixture-');
      final root = await Directory('${area.path}/workspace').create();
      final files = '${area.path}/archives';
      final made = await Process.run(fixture, ['--inspection-files', files]);
      expect(made.exitCode, 0, reason: '${made.stderr}');
      final owner = EngineOwner(
        engine,
        launch: (path) =>
            Process.start(path, ['--state-directory', '${area.path}/state']),
      );
      final boundary = GlobalKey(),
          workspace = newOperationId(),
          profile = newOperationId();
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

      try {
        await owner.connect();
        expect(owner.state, isA<EngineConnected>());
        await owner.workspaces!.create(workspace, 'Weekend', root.path);
        await owner.workspaces!.createProfile(
          workspace,
          0,
          ProfileInfo(profile, 'Everyday'),
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
              artifacts: owner.artifacts,
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
        final good = await owner.artifacts!.add(
          workspace,
          newOperationId(),
          '$files/textures.zip',
          ArtifactStorage.reference,
        );
        final bad = await owner.artifacts!.add(
          workspace,
          newOperationId(),
          '$files/corrupt.7z',
          ArtifactStorage.reference,
        );
        final original = await File('$files/textures.zip').readAsBytes();
        await controller().load();
        await until(() => controller().model.ids.length == 2);
        await tester.tap(find.byKey(ValueKey(good.id)).first);
        await tester.pumpAndSettle();
        await capture('archive-inspector');
        await tap('Read contents');
        await until(() => find.text('water.dds').evaluate().isNotEmpty);
        await capture('contents');
        await tester.tap(find.text('water.dds').last);
        await tester.pumpAndSettle();
        await capture('entry');
        if (narrow) {
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await tester.pumpAndSettle();
        }
        await tap('Back to archives');
        await tester.tap(find.byKey(ValueKey(bad.id)).first);
        await tester.pumpAndSettle();
        await tap('Read contents');
        await until(
          () => find
              .byWidgetPredicate((w) => w is McStatus && w.detail != null)
              .evaluate()
              .isNotEmpty,
        );
        await capture('corrupt');
        await tap('Back to archives');
        await tester.tap(find.byKey(ValueKey(good.id)).first);
        await tester.pumpAndSettle();
        await tap('Read contents');
        await until(() => find.text('water.dds').evaluate().isNotEmpty);
        expect(
          await File('$files/textures.zip').readAsBytes(),
          orderedEquals(original),
        );
        final remaining = await owner.artifacts!.list(workspace);
        expect(remaining.entries.map((e) => e.id).toSet(), {good.id, bad.id});
        await capture('read-after-error');
        await File('$output/result.txt').writeAsString(
          'Compiled production widgets and NativeAOT v1 gRPC read metadata, show the ordinary corrupt-archive error, return to the original archive and read again. Source bytes and artifact identities remain unchanged.\n',
        );
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await owner.close();
      }
    },
  );
}
