import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_desktop/mc_desktop.dart';
import 'package:mc_artifacts/mc_artifacts.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';
import 'package:mod_conductor/src/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets(
    'native second launch preserves current work and reviews one archive',
    (tester) async {
      const fixture = String.fromEnvironment('MC_DESKTOP_FIXTURE'),
          output = String.fromEnvironment('MC_DESKTOP_OUTPUT');
      const narrow = bool.fromEnvironment('MC_DESKTOP_NARROW');
      const noBus = bool.fromEnvironment('MC_DESKTOP_NO_BUS');
      if (!Platform.isLinux || fixture.isEmpty || output.isEmpty) {
        throw StateError('Use the private desktop fixture.');
      }
      await Directory(output).create(recursive: true);
      final root = await Directory(
        '$output/Texture collections/Weekend workspace with a long path',
      ).create(recursive: true);
      final game = '$output/synthetic-game';
      expect((await Process.run(fixture, ['--game-files', game])).exitCode, 0);
      final archive = File('$output/Northern lights — rivière.7z');
      await archive.writeAsString('synthetic archive input without a reader');
      final owner = EngineOwner(
        fixture,
        launch: (path) =>
            Process.start(path, ['--desktop-engine', '$output/state']),
      );
      final requests = DesktopRequests();
      final boundary = GlobalKey();
      final workspace = newOperationId(), profile = newOperationId();
      Finder action(String label) => find.byWidgetPredicate(
        (w) =>
            (w is McAction && w.label == label) ||
            (w is McIconAction && w.label == label),
      );
      Finder requestButton() => find.byKey(const ValueKey('open-requests'));
      Future<void> until(bool Function() ready) async {
        final deadline = DateTime.now().add(const Duration(seconds: 30));
        while (!ready() && DateTime.now().isBefore(deadline)) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(ready(), isTrue);
        expect(tester.takeException(), isNull);
      }

      Future<void> tap(Finder item) async {
        await tester.ensureVisible(item.last);
        await tester.pumpAndSettle();
        await tester.tap(item.last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      Future<void> capture(String name) async {
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.runAsync(() async {
          final image =
              await (boundary.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File('$output/$name.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }

      Future<ProcessResult> launch(
        List<String> args, {
        Map<String, String>? environment,
      }) async {
        final result = await Process.run(
          Platform.resolvedExecutable,
          args,
          environment: environment,
        ).timeout(const Duration(seconds: 15));
        await tester.pumpAndSettle();
        return result;
      }

      final previous = FlutterError.onError;
      FlutterError.onError = (details) {
        File('$output/framework-errors.log')
            .writeAsStringSync('$details\n', mode: FileMode.append);
        previous?.call(details);
      };
      try {
        await owner.connect();
        expect(owner.state, isA<EngineConnected>());
        requests.attach(owner.desktop, nxm: owner.nxm);
        await owner.workspaces!.create(workspace, 'Weekend', root.path);
        await owner.workspaces!.createProfile(
          workspace,
          0,
          ProfileInfo(profile, 'Everyday'),
        );
        await owner.gameContexts!.save(
          workspace,
          profile,
          'skyrim-se-steam',
          0,
          game,
        );
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundary,
            child: ModConductorApp(
              desktopRequests: requests,
              workspaces: owner.workspaces,
              modLibrary: owner.modLibrary,
              profileMods: owner.profileMods,
              modOrganization: owner.modOrganization,
              gameContexts: owner.gameContexts,
              deployments: owner.deployments,
              executables: owner.executables,
              gameLaunching: owner.gameLaunching,
              artifacts: owner.artifacts,
              credentials: owner.credentials,
              nexus: owner.nexus,
              chooseArchive: () async => null,
              status: DesktopConnected((owner.state as EngineConnected).report),
            ),
          ),
        );
        await tester.pumpAndSettle();
        if (narrow) {
          await tap(find.byKey(const ValueKey('nav-preferences')));
          await tap(find.byKey(const ValueKey('preferences-scale')));
          await tap(find.text('150%'));
          await tap(find.byKey(const ValueKey('apply-preferences')));
          await tap(find.byKey(const ValueKey('nav-workspaces')));
        }
        await tap(find.byKey(ValueKey('workspace-$workspace')));
        await tap(find.text('Archives').first);
        ArtifactController controller() => tester
            .widget<ArtifactBrowser>(
              find.byType(ArtifactBrowser, skipOffstage: false),
            )
            .controller;
        await until(() => controller().loaded && !controller().busy);
        await capture('archives');
        if (noBus) {
          await until(() => !requests.available);
          await tap(
            find.widgetWithText(TextButton, 'Cannot open from other apps'),
          );
          await capture('desktop-unavailable');
          await tap(action('Close'));
          await tap(action('Add archive'));
          await tap(action('Choose file'));
          await capture('manual-picker-fallback');
          await tap(action('Cancel'));
          expect((await owner.artifacts!.list(workspace)).entries, isEmpty);
          expect((await launch([])).exitCode, isNot(0));
          await File('$output/observations.txt').writeAsString(
            'first no-bus desktop remains usable; in-app fallback visible; picker cancellation preserved data; second owner refused\n',
          );
          return;
        }
        await tap(action('Add archive'));
        expect((await launch(['--archive', archive.path])).exitCode, 0);
        await until(() => requests.intent != null);
        expect(find.byType(ArchiveFileForm), findsOneWidget);
        expect((await launch(['--archive', archive.path])).exitCode, 0);
        expect(requests.count, 1);
        await capture('pending-with-open-form');
        await tap(action('Choose file'));
        expect((await owner.artifacts!.list(workspace)).entries, isEmpty);
        await tap(action('Cancel'));
        await tap(find.byKey(const ValueKey('nav-preferences')));
        await tap(requestButton());
        await capture('request');
        await tap(action('Close'));
        expect(requests.count, 1);
        await tap(requestButton());
        await tap(action('Review archive'));
        await capture('archive-confirm');
        await tap(action('Add archive'));
        await until(() => requests.count == 0 && !controller().busy);
        final saved = (await owner.artifacts!.list(workspace)).entries;
        expect(saved.length, 1);
        expect(saved.single.originalPath, archive.path);
        expect(
          await archive.readAsString(),
          'synthetic archive input without a reader',
        );
        await capture('archive-added');
        const secret = 'synthetic-private-nxm-value';
        expect(
          (await launch([
            '--uri',
            'nxm://skyrimspecialedition/mods/1/files/2?key=$secret&expires=999',
          ])).exitCode,
          0,
        );
        await until(() => requests.problem != null);
        final channel = await const MethodChannel('dev.modconductor/desktop')
            .invokeMapMethod<String, Object?>('state');
        expect(channel.toString().contains(secret), isFalse);
        await tap(requestButton());
        await capture('unsupported-link');
        await tap(action('Dismiss'));
        expect(
          (await launch(['--uri', 'modconductor://archives/$workspace']))
              .exitCode,
          0,
        );
        await until(() => requests.intent?.kind == DesktopIntentKind.archives);
        await tap(requestButton());
        await capture('workspace-request');
        await tap(action('Open workspace'));
        await until(() => requests.count == 0);
        expect((await owner.artifacts!.list(workspace)).entries.length, 1);
        final refused = await launch(
          [],
          environment: {
            'DBUS_SESSION_BUS_ADDRESS': 'unix:path=$output/no-session-bus',
          },
        );
        expect(refused.exitCode, isNot(0));
        await File('$output/runner-refusal.log')
            .writeAsString('exit=${refused.exitCode}\n${refused.stderr}');
        await capture('after-refused-second-owner');
        await File('$output/observations.txt').writeAsString(
          'actual Linux runner forwarding; one native request for duplicate launch; open form preserved; picker cancellation had no effect; navigation retained request; confirmed one archive; unsupported secret never reached channel; registered workspace route; unavailable-bus duplicate refused\n',
        );
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        requests.dispose();
        await owner.close();
        FlutterError.onError = previous;
      }
    },
  );
}
