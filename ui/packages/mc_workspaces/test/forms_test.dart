import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';
import 'package:mc_workspaces/mc_workspaces.dart';

import 'controller_test.dart' show ScriptedClient, page;

void main() {
  testWidgets('an unbound current profile builds only its setup gate', (
    tester,
  ) async {
    final client = ScriptedClient()..onOpen = (_) async => page('one');
    final controller = WorkspaceController()..attach(client);
    addTearDown(controller.dispose);
    await controller.open('/fixture/one');
    var setupBuilds = 0;
    var workbenchBuilds = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: mcTheme(Brightness.light),
        home: Scaffold(
          body: WorkspaceBrowser(
            controller: controller,
            workbenchReady: false,
            profileSetupBuilder: (_, _, _) {
              setupBuilds++;
              return const SizedBox(key: ValueKey('profile-setup-gate'));
            },
            modLibraryBuilder: (_, _) {
              workbenchBuilds++;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(setupBuilds, greaterThan(0));
    expect(workbenchBuilds, 0);
    expect(find.byKey(const ValueKey('profile-setup-gate')), findsOneWidget);
  });

  testWidgets(
    'workspace modal Escape restores keyboard focus without choosing a folder or submitting',
    (tester) async {
      final controller = WorkspaceController()..attach(ScriptedClient());
      addTearDown(controller.dispose);
      var choices = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: mcTheme(Brightness.light),
          home: Scaffold(
            body: WorkspaceBrowser(
              controller: controller,
              chooseDirectory: (_) async {
                choices++;
                return null;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final opener = tester
          .widget<McAction>(find.byKey(const ValueKey('create-workspace')))
          .focusNode!;
      opener.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('name')), 'Discarded');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(opener.hasFocus, isTrue);
      expect(choices, 0);
      expect(controller.workspace, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'name-only creation skips the folder chooser and an override failure keeps the draft',
    (tester) async {
      var choices = 0;
      String? receivedPath;
      String? openedPath;
      final client = ScriptedClient()
        ..onCreate = (id, name, path) async {
          receivedPath = path;
          return WorkspacePage(
            WorkspaceInfo(
              id: id,
              name: name,
              path: '/default/$id',
              revision: 0,
            ),
            const [],
            null,
          );
        };
      final controller = WorkspaceController()..attach(client);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: mcTheme(Brightness.light),
          home: Scaffold(
            body: WorkspaceBrowser(
              controller: controller,
              openFolder: (path) async {
                openedPath = path;
                return false;
              },
              chooseDirectory: (_) async {
                choices++;
                throw Exception('synthetic chooser failure');
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('create-workspace')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('name')), 'Weekend');
      await tester.tap(find.byKey(const ValueKey('choose-folder')));
      await tester.pumpAndSettle();
      expect(choices, 1);
      expect(
        tester
            .widget<TextButton>(find.byKey(const ValueKey('choose-folder')))
            .focusNode!
            .hasFocus,
        isTrue,
      );
      expect(find.byType(McActionFeedback), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('name')))
            .controller!
            .text,
        'Weekend',
      );
      await tester.tap(find.byKey(const ValueKey('submit')));
      await tester.pumpAndSettle();
      expect(receivedPath, isNull);
      expect(choices, 1);
      expect(controller.workspace!.path, startsWith('/default/'));
      await tester.tap(find.byKey(const ValueKey('open-workspace-folder')));
      await tester.pumpAndSettle();
      expect(openedPath, controller.workspace!.path);
      expect(find.byType(McActionFeedback), findsOneWidget);
      expect(
        tester.widget<McActionFeedback>(find.byType(McActionFeedback)).kind,
        McActionFeedbackKind.failure,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
