import 'dart:convert';
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
    'download survives workspace navigation and paused engine restart',
    (tester) async {
      const engine = String.fromEnvironment('MC_ENGINE_PATH'),
          fixture = String.fromEnvironment('MC_NATIVE_FIXTURE'),
          output = String.fromEnvironment('MC_DOWNLOAD_OUTPUT');
      const narrow = bool.fromEnvironment('MC_DOWNLOAD_NARROW');
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
      final server = await Process.start(fixture, ['--download-server']);
      final serverErrors = server.stderr.transform(utf8.decoder).join();
      final serverInfo =
          (await server.stdout
                  .transform(utf8.decoder)
                  .transform(const LineSplitter())
                  .first
                  .timeout(const Duration(seconds: 15)))
              .split(' ');
      final source = serverInfo[0],
          checksum = serverInfo[1],
          length = int.parse(serverInfo[2]);
      EngineOwner newOwner() => EngineOwner(
        engine,
        launch: (path) =>
            Process.start(path, ['--state-directory', '${area.path}/state']),
      );
      var owner = newOwner();
      final boundary = GlobalKey();
      final workspace = newOperationId(), profile = newOperationId();
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
      Future<void> until(bool Function() done) async {
        final limit = DateTime.now().add(const Duration(seconds: 30));
        while (!done() && DateTime.now().isBefore(limit)) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(done(), isTrue);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      Future<void> tap(String label) async {
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

      Future<int> requests() async {
        final client = HttpClient();
        try {
          final request = await client.getUrl(Uri.parse('$source/stats'));
          return int.parse(
            await (await request.close()).transform(utf8.decoder).join(),
          );
        } finally {
          client.close(force: true);
        }
      }

      Future<void> openWorkspace() async {
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
      }

      Future<void> showApp() async {
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
        await openWorkspace();
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
      }

      Future<void> inspect(String id) async {
        await tester.tap(find.byKey(ValueKey(id)).first);
        await tester.pumpAndSettle();
      }

      Future<void> closeInspector() async {
        if (narrow) {
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await tester.pumpAndSettle();
        } else {
          await tap('Close inspector');
        }
      }

      Finder field(String label) => find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == label,
      );
      try {
        await owner.connect();
        expect(owner.state, isA<EngineConnected>());
        expect(
          (owner.state as EngineConnected).report.runtime.nativeAot,
          isTrue,
        );
        await owner.workspaces!.create(workspace, 'Weekend', root.path);
        await owner.workspaces!.createProfile(
          workspace,
          0,
          ProfileInfo(profile, 'Everyday'),
        );
        await showApp();
        await tap(narrow ? 'Download archive' : 'Download');
        await tester.enterText(field('URL'), '$source/slow');
        await tester.enterText(field('Name'), 'Textures — rivière.zip');
        await tester.tap(find.text('Download options'));
        await tester.pumpAndSettle();
        await tester.enterText(
          field('Expected size in bytes (optional)'),
          '$length',
        );
        await tester.enterText(field('Expected SHA-256 (optional)'), checksum);
        await capture('download-form');
        await tap('Download');
        await until(
          () =>
              !controller().busy &&
              controller().model.ids.length == 1 &&
              controller().selected!.download!.bytes > 0,
        );
        final id = controller().selected!.id;
        expect(controller().problem, isNull);
        await inspect(id);
        await capture('downloading');
        await closeInspector();
        await tap('Close workspace');
        await openWorkspace();
        await until(
          () =>
              controller().model[id]?.download?.bytes != null &&
              controller().model[id]!.download!.bytes > 0,
        );
        expect(controller().model.ids, [id]);
        expect(await requests(), 1);
        await capture('list-after-navigation');
        await inspect(id);
        await tap('Pause');
        await until(
          () =>
              !controller().busy &&
              controller().selected!.download!.phase == DownloadPhase.paused &&
              controller().selected!.canDeleteCopy,
        );
        expect(controller().selected!.download!.bytes, greaterThan(0));
        await capture('paused');
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        expect(await owner.close(), isTrue);
        owner = newOwner();
        await owner.connect();
        final saved = await owner.artifacts!.read(workspace, id);
        expect(saved.download!.phase, DownloadPhase.paused);
        expect(saved.originalName, 'Textures — rivière.zip');
        expect(await requests(), 1);
        await showApp();
        await inspect(id);
        await capture('restart-paused');
        await tap('Resume');
        await until(
          () =>
              !controller().busy &&
              controller().selected!.state == ArtifactState.ready,
        );
        final ready = controller().selected!;
        expect(ready.id, id);
        expect(ready.download!.checksumMatched, isTrue);
        expect(ready.sha256, checksum);
        expect(await File(ready.path).length(), length);
        expect(await requests(), 2);
        if (narrow) {
          final scroll = find
              .descendant(
                of: find.byType(McInspector).last,
                matching: find.byType(Scrollable),
              )
              .first;
          await tester.scrollUntilVisible(
            find.text('Matched supplied SHA-256'),
            120,
            scrollable: scroll,
          );
          await tester.pumpAndSettle();
        }
        await capture('checksum-match');
        await closeInspector();
        await capture('finished-list');
        await File('$output/result.txt').writeAsString(
          'Compiled production Flutter used the NativeAOT engine and deterministic local HTTP server. Navigation kept one artifact and one active request. Pause and engine restart kept the prefix without network. Resume used one further request and completed with the supplied SHA-256.\n',
        );
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await owner.close();
        server.stdin.writeln();
        await server.stdin.flush();
        final exit = await server.exitCode.timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            server.kill();
            return -1;
          },
        );
        expect(exit, 0, reason: await serverErrors);
      }
    },
  );
}
