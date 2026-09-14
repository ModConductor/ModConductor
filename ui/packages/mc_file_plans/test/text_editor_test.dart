import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_file_plans/mc_file_plans.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

const document = TextDocument(
  content: 'one\ntwo\n',
  encoding: TextDocumentEncoding.utf8Bom,
  newline: TextDocumentNewline.lf,
  finalTerminator: true,
  lines: 3,
);

Widget host(
  GlobalKey<TextEditorToolboxState> key, {
  required Future<bool> Function(String) save,
}) => MaterialApp(
  theme: mcTheme(Brightness.light),
  home: Scaffold(
    body: TextEditorToolbox(
      key: key,
      document: document,
      name: 'settings.ini',
      source: 'Textures / settings.ini',
      onSave: save,
      onClose: () {},
    ),
  ),
);

void main() {
  testWidgets('dirty editor keeps changes when discard is cancelled', (
    tester,
  ) async {
    final key = GlobalKey<TextEditorToolboxState>();
    await tester.pumpWidget(host(key, save: (_) async => true));
    expect(
      find.text('UTF-8 with BOM · LF · Ends with a line break'),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const ValueKey('text-editor')),
      'changed\n',
    );
    await tester.pump();
    expect(find.text('Unsaved changes'), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Discard'));
    await tester.pumpAndSettle();
    expect(find.text('Save changes?'), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Keep editing'));
    await tester.pumpAndSettle();
    expect(find.text('changed\n'), findsOneWidget);
    expect(tester.testTextInput.isVisible, isTrue);
  });

  testWidgets('save shortcut uses the same bounded draft action', (
    tester,
  ) async {
    final key = GlobalKey<TextEditorToolboxState>();
    String? saved;
    await tester.pumpWidget(
      host(
        key,
        save: (value) async {
          saved = value;
          return true;
        },
      ),
    );
    await tester.enterText(
      find.byKey(const ValueKey('text-editor')),
      'saved\n',
    );
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(saved, 'saved\n');
  });

  testWidgets(
    'save from navigation guard awaits failure and keeps draft focus',
    (tester) async {
      final key = GlobalKey<TextEditorToolboxState>();
      var navigated = false;
      await tester.pumpWidget(host(key, save: (_) async => false));
      await tester.enterText(
        find.byKey(const ValueKey('text-editor')),
        'stale\n',
      );
      final pending = key.currentState!.guardNavigation(() => navigated = true);
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(FilledButton, 'Save as new mod version').last,
      );
      await tester.pumpAndSettle();
      expect(await pending, isFalse);
      expect(navigated, isFalse);
      expect(find.text('stale\n'), findsOneWidget);
      expect(tester.testTextInput.isVisible, isTrue);
    },
  );

  testWidgets('discard from navigation guard performs the pending navigation', (
    tester,
  ) async {
    final key = GlobalKey<TextEditorToolboxState>();
    var navigated = false;
    await tester.pumpWidget(host(key, save: (_) async => true));
    await tester.enterText(
      find.byKey(const ValueKey('text-editor')),
      'discarded\n',
    );
    final pending = key.currentState!.guardNavigation(() => navigated = true);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Discard').last);
    await tester.pumpAndSettle();
    expect(await pending, isTrue);
    expect(navigated, isTrue);
  });
}
