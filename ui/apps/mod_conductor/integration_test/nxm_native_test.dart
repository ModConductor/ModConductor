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
    'native Nexus handoff retains one request and reuses the partial transfer',
    (tester) async {
      const fixture = String.fromEnvironment('MC_DESKTOP_FIXTURE'),
          output = String.fromEnvironment('MC_DESKTOP_OUTPUT');
      const narrow = bool.fromEnvironment('MC_DESKTOP_NARROW');
      if (!Platform.isLinux || fixture.isEmpty || output.isEmpty) {
        throw StateError('Use the private desktop fixture.');
      }
      await Directory(output).create(recursive: true);
      final root = await Directory(
        '$output/Texture collections/Weekend workspace with a long path',
      ).create(recursive: true);
      final game = '$output/synthetic-game';
      expect((await Process.run(fixture, ['--game-files', game])).exitCode, 0);
      final info = '$output/provider.txt';
      final owner = EngineOwner(
        fixture,
        launch: (path) =>
            Process.start(path, ['--nexus-engine', '$output/state', info]),
      );
      final requests = DesktopRequests();
      final boundary = GlobalKey();
      final workspace = newOperationId(), profile = newOperationId();
      Finder action(String label) => find.byWidgetPredicate(
        (w) =>
            (w is McAction && w.label == label) ||
            (w is McIconAction && w.label == label),
      );
      Finder requestButton() => find.widgetWithText(
        TextButton,
        'Open requests${requests.count == 0 ? '' : ' (${requests.count})'}',
      );
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

      final config = Platform.environment['XDG_CONFIG_HOME']!,
          data = Platform.environment['XDG_DATA_HOME']!;
      expect(config.startsWith(Directory(output).parent.path), isTrue);
      expect(data.startsWith(Directory(output).parent.path), isTrue);
      await Directory('$data/applications').create(recursive: true);
      await File('$data/applications/previous.desktop').writeAsString(
        '[Desktop Entry]\nType=Application\nName=Previous fixture app\nExec=/bin/false %u\nMimeType=x-scheme-handler/nxm;\n',
      );
      const before =
          '[Default Applications]\nx-scheme-handler/nxm=previous.desktop;\nx-scheme-handler/mailto=mail.desktop;\n';
      final mime = File('$config/mcfixture-mimeapps.list');
      await mime.writeAsString(before);
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
        await owner.credentials!.setMode(CredentialMode.sessionOnly);
        await owner.nexus!.signIn();
        for (
          var count = 0;
          count < 60 && (await owner.nexus!.status()).name == null;
          count++
        ) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
        expect((await owner.nexus!.status()).name, isNotNull);
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
              linkSetup: owner.linkSetup,
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
        final provider = Uri.parse(await File(info).readAsString());
        expect(provider.host, '127.0.0.1');
        final http = HttpClient();
        final response = await (await http.getUrl(
          provider.resolve('fixture/mode?value=slow'),
        )).close();
        await response.drain<void>();
        http.close();
        final archiveId = newOperationId();
        final started = await owner.nexus!.download(
          workspace,
          profile,
          archiveId,
          64012,
          501,
        );
        controller().acceptDownload(started, select: true);
        await until(
          () => controller().selected?.download?.phase == DownloadPhase.running,
        );
        await tester.pump(const Duration(milliseconds: 500));
        final paused = await owner.artifacts!.controlDownload(
          controller().selected!,
          DownloadAction.pause,
        );
        controller().acceptDownload(paused, select: true);
        final keptBytes = paused.download!.bytes;
        expect(paused.download!.phase, DownloadPhase.paused);
        expect(keptBytes, greaterThan(0));
        await capture('archives');
        await tap(action('Add archive'));
        final expiry =
            DateTime.now()
                .add(const Duration(minutes: 5))
                .millisecondsSinceEpoch ~/
            1000;
        const secret = 'synthetic-nxm-private-grant';
        final link =
            'nxm://skyrimspecialedition/mods/64012/files/501?key=$secret&expires=$expiry&user_id=42';
        expect((await launch(['--uri', link])).exitCode, 0);
        await until(() => requests.nexusReference != null);
        expect(find.byType(ArchiveFileForm), findsOneWidget);
        expect((await launch(['--uri', link])).exitCode, 0);
        expect(requests.count, 1);
        final channel = await const MethodChannel('dev.modconductor/desktop')
            .invokeMapMethod<String, Object?>('state');
        expect(channel.toString().contains(secret), isFalse);
        expect(channel.toString().contains('nxm://'), isFalse);
        await File('$output/native-safe-state.txt')
            .writeAsString(channel.toString());
        await capture('pending-with-open-form');
        await tap(action('Cancel'));
        await tap(requestButton());
        await until(
          () => requests.nexusLink?.artifact != null && !requests.resolving,
        );
        await capture('partial-request');
        await tap(action('Close'));
        expect(requests.count, 1);
        await tap(find.byKey(const ValueKey('nav-preferences')));
        await tap(requestButton());
        await until(
          () => requests.nexusLink?.artifact != null && !requests.resolving,
        );
        await capture('request-after-navigation');
        await tap(action('Open Downloads'));
        await until(
          () => requests.count == 0 && controller().selected?.id == archiveId,
        );
        expect((await owner.artifacts!.list(workspace)).entries.length, 1);
        expect(controller().selected!.download!.bytes, keptBytes);
        await capture('downloads');
        await tap(find.text(paused.originalName).first);
        await capture('download-details');
        await tap(action('Resume'));
        await until(
          () =>
              controller().selected?.download?.phase == DownloadPhase.complete,
        );
        await capture('download-complete');
        if (action('Close inspector').evaluate().isNotEmpty) {
          await tap(action('Close inspector'));
        }
        await tap(find.byKey(const ValueKey('nav-preferences')));
        await tester.ensureVisible(find.text('Nexus download links'));
        await tester.pumpAndSettle();
        await capture('link-setup-off');
        await tap(action('Use Mod Conductor'));
        for (
          var n = 0;
          n < 40 && (await owner.linkSetup!.read()).available != true;
          n++
        ) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(
          (await owner.linkSetup!.read()).defaultApp,
          NexusLinkDefault.modConductor,
        );
        await capture('link-setup-on');
        final wrong = link.replaceFirst('user_id=42', 'user_id=77');
        final launchResult = await Process.run('gio', [
          'open',
          wrong,
        ]).timeout(const Duration(seconds: 15));
        expect(launchResult.exitCode, 0);
        await until(() => requests.nexusLink?.problem != null);
        await tap(requestButton());
        await until(() => !requests.resolving && requests.problem != null);
        await capture('system-open-wrong-account');
        expect((await owner.artifacts!.list(workspace)).entries.length, 1);
        await tap(action('Dismiss'));
        await tap(action('Remove link setup'));
        await capture('link-setup-remove');
        await tap(action('Remove link setup'));
        for (
          var n = 0;
          n < 40 && (await owner.linkSetup!.read()).available != false;
          n++
        ) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(await mime.readAsString(), before);
        expect(
          (await owner.linkSetup!.read()).defaultApp,
          NexusLinkDefault.anotherApp,
        );
        await capture('link-setup-restored');
        await File('$output/observations.txt').writeAsString(
          'Actual Linux native queue/private ingress: duplicate after acknowledgement coalesced; raw NXM/key absent from method channel; open form and navigation retained pending work; keyed request reused ordinary paused artifact without losing bytes; Resume completed through existing owner; private gio URI launch reached the same instance and refused mismatched account without new artifact; opt-in/opt-out restored prior private association. No install action or host account/default/browser access.\n',
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
