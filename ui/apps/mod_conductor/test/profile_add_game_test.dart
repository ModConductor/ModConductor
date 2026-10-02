import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_game_contexts/mc_game_contexts.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';
import 'package:mod_conductor/src/app.dart';

import '../../../packages/mc_game_contexts/test/support/game_registration_fake.dart';
import 'profile_context_test.dart' as fixture;

class _Workspaces extends Fake implements WorkspacesClient {
  _Workspaces(this.creating);
  final bool creating;
  WorkspaceInfo get workspace => WorkspaceInfo(
    id: 'workspace',
    name: 'Workspace',
    path: '/workspace',
    revision: 1,
    selectedProfile: creating ? fixture.profiles.first : fixture.profiles.last,
  );
  @override
  Future<WorkspaceList> recent({String? after}) async =>
      WorkspaceList([workspace], null);
  @override
  Future<WorkspacePage> open(String path) async =>
      WorkspacePage(workspace, fixture.profiles, null);
  @override
  Future<WorkspacePage> read(String id, {String? after}) async =>
      WorkspacePage(workspace, fixture.profiles, null);
}

void main() {
  for (final create in [true, false]) {
    testWidgets(
      '${create ? 'new' : 'unbound'} profile setup opens registration, preserves cancellation and selects the published identity',
      (tester) async {
        tester.view.physicalSize = Size(create ? 1440 : 640, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final registration = GameRegistrationFake();
        await tester.pumpWidget(
          ModConductorApp(
            status: const DesktopConnected((
              runtime: (
                architecture: 'x64',
                nativeAot: true,
                sqliteVersion: '3',
              ),
              heartbeats: 1,
            )),
            workspaces: _Workspaces(create),
            gameContexts: fixture.Contexts(),
            gameCatalogue: registration,
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('workspace-workspace')));
        await tester.pumpAndSettle();
        if (create) {
          await tester.tap(find.byKey(const ValueKey('create-profile')));
          await tester.pumpAndSettle();
          await tester.enterText(
            find.byKey(const ValueKey('profile-setup-name')),
            'My profile',
          );
        }
        final name = tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('profile-setup-name')),
            )
            .controller!;
        final initialName = name.text;
        final fields = tester.widget<InstallationSetupFields>(
          find.byType(InstallationSetupFields),
        );
        await tester.enterText(
          find.byKey(const ValueKey('installation-folder')),
          '/draft-installation',
        );
        final initialGame = fields.gameName;
        Future<void> open() async {
          await tester.ensureVisible(find.widgetWithText(McAction, 'Add game'));
          await tester.tap(find.widgetWithText(McAction, 'Add game'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.byType(GameEditor), findsOneWidget);
        }

        await open();
        await tester.ensureVisible(
          find.widgetWithText(McAction, 'Cancel').last,
        );
        await tester.tap(find.widgetWithText(McAction, 'Cancel').last);
        await tester.pumpAndSettle();
        expect(name.text, initialName);
        expect(fields.folder.text, '/draft-installation');
        expect(
          tester
              .widget<InstallationSetupFields>(
                find.byType(InstallationSetupFields),
              )
              .gameName,
          initialGame,
        );
        expect(registration.saved, isEmpty);
        await open();
        await tester.tap(find.text('Example Game').first);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const ValueKey('register-game')));
        await tester.tap(find.byKey(const ValueKey('register-game')));
        await tester.pumpAndSettle();
        final selected = tester.widget<InstallationSetupFields>(
          find.byType(InstallationSetupFields),
        );
        expect(selected.gameName, registration.games.last.id);
        expect(selected.gameChoices, contains(registration.games.last.id));
        expect(selected.folder.text, GameRegistrationFake.path);
        expect(name.text, initialName);
        expect(registration.saved, hasLength(1));
        expect(registration.searches, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
