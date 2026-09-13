import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_credentials/mc_credentials.dart';
import 'package:mc_artifacts/mc_artifacts.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';
import 'package:mod_conductor/src/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets(
    'account and private download survive navigation without duplicate transfer',
    (tester) async {
      const fixture = String.fromEnvironment('MC_NEXUS_FIXTURE'),
          output = String.fromEnvironment('MC_NEXUS_OUTPUT');
      const narrow = bool.fromEnvironment('MC_NEXUS_NARROW');
      if (!Platform.isLinux || fixture.isEmpty || output.isEmpty) {
        throw StateError('Select the isolated Nexus fixture host.');
      }
      final area = await Directory(output).create(recursive: true);
      final root = await Directory('$output/Weekend workspace with a long path')
          .create(recursive: true);
      final game = '$output/synthetic-game';
      final generated = await Process.run(fixture, ['--game-files', game]);
      expect(generated.exitCode, 0);
      final owner = EngineOwner(
        fixture,
        launch: (path) => Process.start(path, [
          '--nexus-engine',
          '$output/state',
          '$output/provider-origin',
        ]),
      );
      final boundary = GlobalKey();
      final workspace = newOperationId(), profile = newOperationId();
      Finder action(String label) => find.byWidgetPredicate(
        (w) =>
            (w is McAction && w.label == label) ||
            (w is McIconAction && w.label == label),
      );
      Future<void> until(bool Function() condition) async {
        final limit = DateTime.now().add(const Duration(seconds: 40));
        while (!condition() && DateTime.now().isBefore(limit)) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(condition(), isTrue);
        expect(tester.takeException(), isNull);
      }

      Future<void> tap(Finder finder) async {
        await tester.ensureVisible(finder.last);
        await tester.pumpAndSettle();
        await tester.tap(finder.last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      Future<void> capture(String name) async {
        await tester.pumpAndSettle();
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
        expect(tester.takeException(), isNull);
      }

      Future<void> storageReady() => until(
        () =>
            action('Check storage').evaluate().isNotEmpty &&
            tester.widget<McAction>(action('Check storage')).onPressed != null,
      );
      Future<void> mode(String value) async {
        final origin = await File('$output/provider-origin').readAsString();
        final client = HttpClient();
        try {
          final request = await client.getUrl(
            Uri.parse('${origin}fixture/mode?value=$value'),
          );
          final response = await request.close();
          await response.drain<void>();
          expect(response.statusCode, 200);
        } finally {
          client.close(force: true);
        }
      }

      ArtifactController controller() => tester
          .widget<ArtifactBrowser>(
            find.byType(ArtifactBrowser, skipOffstage: false),
          )
          .controller;
      Future<void> closeDetails() async {
        if (narrow) {
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await tester.pumpAndSettle();
        } else {
          await tap(action('Close inspector'));
        }
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
        await owner.workspaces!.create(workspace, 'Weekend', root.path);
        await owner.workspaces!.createProfile(
          workspace,
          0,
          ProfileInfo(profile, 'Everyday'),
        );
        await owner.gameContexts!.save(workspace, 0, game);
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
              credentials: owner.credentials,
              nexus: owner.nexus,
              status: DesktopConnected((owner.state as EngineConnected).report),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tap(find.byKey(const ValueKey('nav-preferences')));
        if (narrow) {
          await tap(find.byKey(const ValueKey('preferences-scale')));
          await tap(find.text('150%'));
          await tap(find.byKey(const ValueKey('apply-preferences')));
        }
        await storageReady();
        await tester.ensureVisible(find.byType(CredentialPreferences));
        await capture('signed-out');
        await tap(action('Sign in'));
        await until(() => action('Disconnect').evaluate().isNotEmpty);
        await storageReady();
        await capture('connected');
        expect((await owner.nexus!.status()).name, 'Rowan');
        await tap(find.byKey(const ValueKey('nav-workspaces')));
        await tap(find.byKey(ValueKey('workspace-$workspace')));
        await until(
          () =>
              find
                  .byType(ArtifactBrowser, skipOffstage: false)
                  .evaluate()
                  .isNotEmpty &&
              controller().loaded,
        );
        await tap(find.text('Archives').first);
        await tap(action('Nexus Mods'));
        await until(
          () => tester.widget<McAction>(action('Find')).onPressed != null,
        );
        await tester.enterText(find.byType(TextField).first, '64012');
        await tap(action('Find'));
        await until(
          () =>
              find.text('Quiet rivers.7z').evaluate().isNotEmpty &&
              tester.widget<McAction>(action('Download').first).onPressed !=
                  null,
        );
        await capture('files');
        await tap(action('Mod details'));
        await capture('details');
        await closeDetails();
        await mode('entitlement');
        await tap(action('Download'));
        await until(() => action('Open mod page').evaluate().isNotEmpty);
        expect(
          tester.widget<McAction>(action('Download').first).onPressed,
          isNull,
        );
        await capture('entitlement');
        await tap(action('Mod details'));
        expect(
          tester.widget<McAction>(action('Download').last).onPressed,
          isNull,
        );
        await capture('entitlement-details');
        await closeDetails();
        await mode('slow');
        await tap(find.byKey(const ValueKey(502)));
        await closeDetails();
        await tap(find.byKey(const ValueKey(501)));
        await closeDetails();
        await tester.tap(action('Download').first);
        await tester.pump();
        await tester.tap(action('Back to Archives'));
        await tester.pumpAndSettle();
        await until(() => controller().model.ids.isNotEmpty);
        final artifact = controller().model[controller().model.ids.first]!;
        await tap(find.byKey(ValueKey(artifact.id)).first);
        await capture('download');
        if (narrow) await closeDetails();
        await tap(find.byKey(const ValueKey('nav-preferences')));
        await storageReady();
        expect((await owner.nexus!.status()).name, 'Rowan');
        await tap(find.byKey(const ValueKey('nav-workspaces')));
        await until(
          () =>
              controller().selected?.download?.phase == DownloadPhase.complete,
        );
        expect(controller().model.ids.length, 1);
        expect(controller().selected!.originalPath, 'Nexus Mods');
        expect(controller().selected!.id, artifact.id);
        await capture('download-complete');
        await tap(find.byKey(const ValueKey('nav-preferences')));
        await storageReady();
        final locked = await Process.run('dbus-send', [
          '--session',
          '--print-reply',
          '--dest=org.freedesktop.secrets',
          '/org/freedesktop/secrets',
          'org.freedesktop.Secret.Service.Lock',
          'array:objpath:/org/freedesktop/secrets/collection/login',
        ]);
        expect(locked.exitCode, 0);
        await tap(action('Disconnect'));
        await capture('disconnect-confirm');
        await tap(action('Disconnect'));
        await storageReady();
        expect((await owner.nexus!.status()).name, isNull);
        expect(
          (await owner.credentials!.status()).saved,
          SavedCredentials.present,
        );
        await capture('disconnect-failed');
        await tap(find.byWidgetPredicate((w) => w is McChoice<CredentialMode>));
        await tap(find.text('This session only'));
        await capture('session-confirm');
        await tap(action('Use this session only'));
        await storageReady();
        await tap(action('Sign in'));
        await until(() => action('Disconnect').evaluate().isNotEmpty);
        await storageReady();
        final memory = await owner.credentials!.status();
        expect(memory.mode, CredentialMode.sessionOnly);
        expect(memory.hasSession, isTrue);
        expect(memory.saved, SavedCredentials.present);
        expect((await owner.nexus!.status()).name, 'Rowan');
        await capture('connected-session');
        await File('$output/verified.txt').writeAsString(
          'Actual compiled shared Preferences and archive widgets, v1 RPC and NativeAOT fixture host using production Engine composition. PKCE uses only an isolated fake HTTP provider/browser. Verified sign-in, navigation, metadata/details, refusal disables both Download controls, explicit retry via new selection, one tracked transfer after Back during its pending handoff and later tab navigation, truthful locked-store disconnect, and explicit fresh session-only sign-in while the saved item remains locked. Synthetic game files are metadata only; no executable is run.\n',
        );
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await owner.close();
        FlutterError.onError = previous;
        await File('${area.path}/closed.txt')
            .writeAsString('Fixture engine stopped.\n');
      }
    },
  );
}
