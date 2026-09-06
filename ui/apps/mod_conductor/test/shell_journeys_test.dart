import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';
import 'package:mod_conductor/src/app.dart';

Finder keyed(String value) => find.byKey(ValueKey(value));

Future<void> mount(
  WidgetTester tester, {
  VoidCallback? onQuit,
  DesktopStatus status = const DesktopDisconnected(),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1280, 800);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  await tester.pumpWidget(ModConductorApp(onQuit: onQuit, status: status));
  await tester.pumpAndSettle();
}

Future<void> choose(WidgetTester tester, String field, String option) async {
  await tester.ensureVisible(keyed(field));
  await tester.tap(keyed(field));
  await tester.pumpAndSettle();
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}

Future<void> activate(WidgetTester tester, String key) async {
  await tester.ensureVisible(keyed(key));
  await tester.tap(keyed(key));
  await tester.pumpAndSettle();
}

Brightness brightness(WidgetTester tester) =>
    Theme.of(tester.element(keyed('quit'))).brightness;

void main() {
  testWidgets('keyboard navigation opens preferences and reaches its form', (
    tester,
  ) async {
    await mount(tester);
    final welcome = tester
        .widget<TextButton>(keyed('nav-workspaces'))
        .focusNode!;
    welcome.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    final preferences = tester
        .widget<TextButton>(keyed('nav-preferences'))
        .focusNode!;
    expect(preferences.hasFocus, true);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(
      tester.widget<McChoice<ThemeMode>>(keyed('preferences-theme')).value,
      ThemeMode.light,
    );
  });

  testWidgets(
    'drafts survive navigation and resize, apply shares theme, discard restores applied values',
    (tester) async {
      await mount(tester);
      await activate(tester, 'nav-preferences');
      await choose(tester, 'preferences-theme', 'Dark');
      expect(brightness(tester), Brightness.light);
      await activate(tester, 'nav-workspaces');
      await activate(tester, 'nav-preferences');
      tester.view.physicalSize = const Size(680, 600);
      await tester.pumpAndSettle();
      expect(
        tester.widget<McChoice<ThemeMode>>(keyed('preferences-theme')).value,
        ThemeMode.dark,
      );
      await activate(tester, 'apply-preferences');
      expect(brightness(tester), Brightness.dark);
      await activate(tester, 'nav-workspaces');
      expect(
        Theme.of(tester.element(keyed('create-workspace'))).brightness,
        Brightness.dark,
      );
      await activate(tester, 'nav-preferences');
      await choose(tester, 'preferences-theme', 'Light');
      await activate(tester, 'cancel-preferences');
      expect(
        tester.widget<McChoice<ThemeMode>>(keyed('preferences-theme')).value,
        ThemeMode.dark,
      );
      expect(brightness(tester), Brightness.dark);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'active comparison preserves draft and restores focus on Escape',
    (tester) async {
      await mount(tester);
      await activate(tester, 'nav-preferences');
      await choose(tester, 'preferences-theme', 'Dark');
      final focus = tester
          .widget<McAction>(keyed('session-details'))
          .focusNode!;
      focus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(focus.hasFocus, false);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Use system appearance'),
        ),
        findsOneWidget,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(focus.hasFocus, true);
      expect(
        tester.widget<McChoice<ThemeMode>>(keyed('preferences-theme')).value,
        ThemeMode.dark,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
    },
  );

  testWidgets(
    'enlarged text keeps navigation, modal dismissal and Quit operable',
    (tester) async {
      var quits = 0;
      await mount(tester, onQuit: () => quits++);
      await activate(tester, 'nav-preferences');
      await choose(tester, 'preferences-scale', '150%');
      await activate(tester, 'apply-preferences');
      tester.view.physicalSize = const Size(640, 600);
      await tester.pumpAndSettle();
      expect(
        MediaQuery.textScalerOf(tester.element(keyed('quit'))).scale(1),
        1.5,
      );
      await choose(tester, 'preferences-theme', 'Dark');
      await activate(tester, 'session-details');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      await activate(tester, 'nav-workspaces');
      await activate(tester, 'quit');
      expect(quits, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'injected display failure retains preferences, focus return and Quit',
    (tester) async {
      var quits = 0;
      await mount(
        tester,
        status: const DesktopFailure('No workspace is available.'),
        onQuit: () => quits++,
      );
      await tester.tap(find.widgetWithText(McAction, 'Preferences'));
      await tester.pumpAndSettle();
      await choose(tester, 'preferences-theme', 'Dark');
      await activate(tester, 'apply-preferences');
      await choose(tester, 'preferences-theme', 'Light');
      final focus = tester
          .widget<McAction>(keyed('session-details'))
          .focusNode!;
      focus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(focus.hasFocus, true);
      await activate(tester, 'nav-workspaces');
      expect(brightness(tester), Brightness.dark);
      await activate(tester, 'quit');
      expect(quits, 1);
    },
  );

  testWidgets(
    'system appearance follows the platform until explicitly overridden',
    (tester) async {
      await mount(tester);
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      await tester.pumpAndSettle();
      expect(brightness(tester), Brightness.dark);
      await activate(tester, 'quick-theme');
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      await tester.pumpAndSettle();
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      await tester.pumpAndSettle();
      expect(brightness(tester), Brightness.light);
    },
  );

  testWidgets('Quit shortcut remains available from the preferences form', (
    tester,
  ) async {
    var quits = 0;
    await mount(tester, onQuit: () => quits++);
    await activate(tester, 'nav-preferences');
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyQ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(quits, 1);
  });
}
