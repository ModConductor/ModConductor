import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_credentials/mc_credentials.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';
import 'package:mod_conductor/src/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets(
    'storage mode survives navigation and failed removal remains truthful',
    (tester) async {
      const engine = String.fromEnvironment('MC_ENGINE_PATH'),
          output = String.fromEnvironment('MC_CREDENTIAL_OUTPUT'),
          fixture = String.fromEnvironment('MC_CREDENTIAL_FIXTURE');
      const narrow = bool.fromEnvironment('MC_CREDENTIAL_NARROW');
      if (engine.isEmpty ||
          output.isEmpty ||
          fixture.isEmpty ||
          !Platform.isLinux) {
        throw StateError('Select isolated native credential fixtures.');
      }
      await Directory(output).create(recursive: true);
      final state = await Directory('$output/state').create();
      final owner = EngineOwner(
        engine,
        launch: (path) =>
            Process.start(path, ['--state-directory', state.path]),
      );
      final boundary = GlobalKey();
      Finder action(String text) =>
          find.byWidgetPredicate((w) => w is McAction && w.label == text);
      Future<void> until(bool Function() ready) async {
        for (var i = 0; i < 200; i++) {
          await tester.pump(const Duration(milliseconds: 100));
          if (ready()) return;
        }
        throw StateError('Credential interaction did not finish.');
      }

      Future<void> tap(Finder finder) async {
        await tester.ensureVisible(finder.last);
        await tester.pumpAndSettle();
        await tester.tap(finder.last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      Future<void> ready() => until(
        () =>
            action('Check storage').evaluate().isNotEmpty &&
            tester.widget<McAction>(action('Check storage')).onPressed != null,
      );
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

      final previous = FlutterError.onError;
      FlutterError.onError = (details) {
        File('$output/framework-errors.log')
            .writeAsStringSync('$details\n', mode: FileMode.append);
        previous?.call(details);
      };
      try {
        await owner.connect();
        expect(owner.state, isA<EngineConnected>());
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundary,
            child: ModConductorApp(
              credentials: owner.credentials,
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
        await ready();
        await tester.ensureVisible(find.byType(CredentialPreferences));
        await capture('saved');
        expect(
          (await owner.credentials!.status()).saved,
          SavedCredentials.present,
        );
        await tap(action('Remove sign-in'));
        await capture('remove-confirm');
        await tap(action('Remove sign-in'));
        await ready();
        expect(
          (await owner.credentials!.status()).saved,
          SavedCredentials.absent,
        );
        await capture('available');
        await tap(find.byWidgetPredicate((w) => w is McChoice<CredentialMode>));
        await tap(find.text('This session only'));
        await capture('session-confirm');
        await tap(action('This session only'));
        await ready();
        expect(
          (await owner.credentials!.status()).mode,
          CredentialMode.sessionOnly,
        );
        await capture('session');
        await tap(find.byKey(const ValueKey('nav-workspaces')));
        await tap(find.byKey(const ValueKey('nav-preferences')));
        await ready();
        expect(
          (await owner.credentials!.status()).mode,
          CredentialMode.sessionOnly,
        );
        await tester.ensureVisible(find.byType(CredentialPreferences));
        await capture('navigation-return');
        final seeded = await Process.run(fixture, [
          '--credential-worker',
          'seed',
        ]);
        expect(seeded.exitCode, 0);
        final locked = await Process.run('dbus-send', [
          '--session',
          '--print-reply',
          '--dest=org.freedesktop.secrets',
          '/org/freedesktop/secrets',
          'org.freedesktop.Secret.Service.Lock',
          'array:objpath:/org/freedesktop/secrets/collection/login',
        ]);
        expect(locked.exitCode, 0);
        await tap(action('Check storage'));
        await ready();
        expect(
          (await owner.credentials!.status()).problem,
          CredentialProblem.locked,
        );
        await capture('locked');
        await tap(action('Remove sign-in'));
        await tap(action('Remove sign-in'));
        await ready();
        final failed = await owner.credentials!.status();
        expect(failed.saved, SavedCredentials.present);
        expect(failed.removalProblem, CredentialProblem.locked);
        await capture('removal-failed');
        await tap(find.byWidgetPredicate(
          (w) => w is McIconAction && w.label == 'Sign-in storage details',
        ));
        await capture('diagnostic');
        await tap(action('Close'));
        await owner.close();
        await owner.connect();
        expect((await owner.credentials!.status()).mode, CredentialMode.secure);
        expect(
          (await owner.credentials!.status()).saved,
          SavedCredentials.present,
        );
        final privatePid = int.parse(
          Platform.environment['MC_PRIVATE_KEYRING_PID']!,
        );
        expect(
          Platform.environment['DBUS_SESSION_BUS_ADDRESS'],
          startsWith('unix:path=${Directory(output).parent.path}/runtime/bus'),
        );
        expect(Process.killPid(privatePid), isTrue);
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundary,
            child: ModConductorApp(
              key: UniqueKey(),
              credentials: owner.credentials,
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
        await ready();
        await tester.ensureVisible(find.byType(CredentialPreferences));
        final unavailable = await owner.credentials!.status();
        expect(unavailable.saved, SavedCredentials.unknown);
        expect(unavailable.problem, CredentialProblem.unavailable);
        await capture('unavailable');
        await tap(find.byWidgetPredicate((w) => w is McChoice<CredentialMode>));
        await tap(find.text('This session only'));
        await capture('fallback-confirm');
        await tap(action('This session only'));
        await ready();
        expect(
          (await owner.credentials!.status()).mode,
          CredentialMode.sessionOnly,
        );
        await capture('unavailable-session');
        await File('$output/result.txt').writeAsString(
          'Actual production Preferences and native engine: saved/available, explicit session choice, navigation preservation, successful removal, private locked-store failed removal and safe diagnostic display. Engine restart resets memory mode and retains OS presence. Stopping only the driver-owned keyring gives explicit unavailable storage and session-only fallback. No sign-in or provider access.\n',
        );
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await owner.close();
        FlutterError.onError = previous;
      }
    },
  );
}
