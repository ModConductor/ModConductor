import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';
import 'package:mc_workspaces/mc_workspaces.dart';

import 'controller_test.dart' show ScriptedClient;

void main() {
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
}
