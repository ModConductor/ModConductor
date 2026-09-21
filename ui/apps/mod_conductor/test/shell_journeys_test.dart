import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mod_conductor/src/app.dart';

Finder keyed(String value) => find.byKey(ValueKey(value));

Future<void> mount(
  WidgetTester tester, {
  VoidCallback? onQuit,
  DesktopStatus status = const DesktopDisconnected(),
  SettingsClient? settings,
  WorkspacesClient? workspaces,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1280, 800);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  await tester.pumpWidget(
    ModConductorApp(
      onQuit: onQuit,
      status: status,
      settings: settings,
      workspaces: workspaces,
    ),
  );
  await tester.pumpAndSettle();
}

SettingsSnapshot settingsSnapshot(
  AppearancePreference appearance, {
  bool inherits = false,
}) => SettingsSnapshot(
  presentation: PresentationPreferences(
    appearance: appearance,
    textScale: 1,
    contrast: ContrastPreference.system,
  ),
  inheritsApplication: inherits,
);

WorkspaceInfo workspace(String id) => WorkspaceInfo(
  id: id,
  name: 'Workspace $id',
  path: '/workspace/$id',
  revision: 0,
  selectedProfile: const ProfileInfo('profile', 'Profile'),
);

class _WorkspacesFake extends Fake implements WorkspacesClient {
  final workspaces = [workspace('one'), workspace('two')];

  @override
  Future<WorkspaceList> recent({String? after}) async =>
      WorkspaceList(workspaces, null);

  @override
  Future<WorkspacePage> open(String path) async {
    final selected = workspaces.singleWhere((value) => value.path == path);
    return WorkspacePage(selected, [selected.selectedProfile!], null);
  }
}

class _DelayedSettingsFake extends _SettingsFake {
  final reads = <String, Completer<SettingsSnapshot>>{};
  final values = <String, SettingsSnapshot>{};
  Completer<SettingsSnapshot>? save;
  final savedWorkspaceIds = <String>[];

  @override
  Future<SettingsSnapshot> readWorkspace(String workspaceId) {
    final delayed = reads[workspaceId];
    return delayed?.future ??
        Future.value(
          values[workspaceId] ?? settingsSnapshot(AppearancePreference.system),
        );
  }

  @override
  Future<SettingsSnapshot> saveWorkspace(
    String workspaceId,
    SettingsSnapshot settings,
  ) {
    savedWorkspaceIds.add(workspaceId);
    return save?.future ?? Future.value(settings);
  }
}

class _SettingsFake implements SettingsClient {
  SettingsSnapshot application = const SettingsSnapshot(
    presentation: PresentationPreferences(
      appearance: AppearancePreference.system,
      textScale: 1,
      contrast: ContrastPreference.system,
    ),
    inheritsApplication: false,
  );
  int applicationSaves = 0;

  @override
  Future<SettingsSnapshot> readApplication() async => application;

  @override
  Future<SettingsSnapshot> readWorkspace(String workspaceId) async =>
      SettingsSnapshot(
        presentation: application.presentation,
        inheritsApplication: true,
      );

  @override
  Future<SettingsSnapshot> saveApplication(SettingsSnapshot settings) async {
    applicationSaves++;
    return application = settings;
  }

  @override
  Future<SettingsSnapshot> saveWorkspace(
    String workspaceId,
    SettingsSnapshot settings,
  ) async => settings;
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

Future<void> openWorkspace(WidgetTester tester, String id) async {
  await tester.tap(keyed('workspace-$id'));
  await tester.pumpAndSettle();
}

void ignoreKnownWorkspaceListTileWarning() {
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().startsWith(
      'ListTile background color or ink splashes may be invisible.',
    )) {
      return;
    }
    previous?.call(details);
  };
  addTearDown(() => FlutterError.onError = previous);
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
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<McChoice<AppearancePreference>>(keyed('preferences-theme'))
          .value,
      AppearancePreference.light,
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
        tester
            .widget<McChoice<AppearancePreference>>(keyed('preferences-theme'))
            .value,
        AppearancePreference.dark,
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
        tester
            .widget<McChoice<AppearancePreference>>(keyed('preferences-theme'))
            .value,
        AppearancePreference.dark,
      );
      expect(brightness(tester), Brightness.dark);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('apply persists display settings and cancel does not write', (
    tester,
  ) async {
    final settings = _SettingsFake();
    await mount(tester, settings: settings);
    await activate(tester, 'nav-preferences');
    await choose(tester, 'preferences-theme', 'Dark');
    await activate(tester, 'cancel-preferences');
    expect(settings.applicationSaves, 0);
    await choose(tester, 'preferences-theme', 'Dark');
    await choose(tester, 'preferences-contrast', 'High contrast');
    await activate(tester, 'apply-preferences');
    expect(settings.applicationSaves, 1);
    expect(
      settings.application.presentation.appearance,
      AppearancePreference.dark,
    );
    expect(settings.application.presentation.contrast, ContrastPreference.high);
    expect(MediaQuery.highContrastOf(tester.element(keyed('quit'))), isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    await mount(tester, settings: settings);
    expect(brightness(tester), Brightness.dark);
    expect(MediaQuery.highContrastOf(tester.element(keyed('quit'))), isTrue);
  });

  testWidgets('standard contrast overrides platform high contrast', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(highContrast: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await mount(tester, settings: _SettingsFake());
    final systemOutline = Theme.of(tester.element(keyed('quit')))
        .colorScheme
        .outlineVariant;
    expect(MediaQuery.highContrastOf(tester.element(keyed('quit'))), isTrue);

    await activate(tester, 'nav-preferences');
    await choose(tester, 'preferences-contrast', 'Standard');
    await activate(tester, 'apply-preferences');

    expect(MediaQuery.highContrastOf(tester.element(keyed('quit'))), isFalse);
    expect(
      Theme.of(tester.element(keyed('quit'))).colorScheme.outlineVariant,
      isNot(systemOutline),
    );
  });

  testWidgets('application text size multiplies the platform text size', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.25;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await mount(tester, settings: _SettingsFake());
    expect(
      MediaQuery.textScalerOf(tester.element(keyed('quit'))).scale(1),
      1.25,
    );

    await activate(tester, 'nav-preferences');
    await choose(tester, 'preferences-scale', '150%');
    await activate(tester, 'apply-preferences');

    expect(
      MediaQuery.textScalerOf(tester.element(keyed('quit'))).scale(1),
      1.875,
    );
  });

  testWidgets('a workspace change rejects a pending settings save', (
    tester,
  ) async {
    ignoreKnownWorkspaceListTileWarning();
    final settings = _DelayedSettingsFake()
      ..values['one'] = settingsSnapshot(AppearancePreference.light)
      ..values['two'] = settingsSnapshot(AppearancePreference.light)
      ..save = Completer<SettingsSnapshot>();
    await mount(tester, settings: settings, workspaces: _WorkspacesFake());
    await openWorkspace(tester, 'one');
    await activate(tester, 'nav-preferences');
    await choose(tester, 'preferences-scope', 'Current workspace');
    await choose(tester, 'preferences-theme', 'Dark');
    await tester.tap(keyed('apply-preferences'));
    await tester.pump();

    await activate(tester, 'nav-workspaces');
    await activate(tester, 'close-workspace');
    await openWorkspace(tester, 'two');
    settings.save!.complete(settingsSnapshot(AppearancePreference.dark));
    await tester.pumpAndSettle();

    await activate(tester, 'nav-preferences');
    await choose(tester, 'preferences-scope', 'Current workspace');
    expect(
      tester
          .widget<McChoice<AppearancePreference>>(keyed('preferences-theme'))
          .value,
      AppearancePreference.light,
    );
    expect(settings.savedWorkspaceIds, ['one']);
  });

  testWidgets('a settings save rejects an older workspace read', (
    tester,
  ) async {
    ignoreKnownWorkspaceListTileWarning();
    final pendingRead = Completer<SettingsSnapshot>();
    final settings = _DelayedSettingsFake()..reads['one'] = pendingRead;
    await mount(tester, settings: settings, workspaces: _WorkspacesFake());
    await tester.tap(keyed('workspace-one'));
    await tester.pump();
    await activate(tester, 'nav-preferences');
    await choose(tester, 'preferences-scope', 'Current workspace');
    await tester.tap(find.byType(SwitchListTile));
    await tester.pump();
    await choose(tester, 'preferences-theme', 'Dark');
    await activate(tester, 'apply-preferences');

    pendingRead.complete(settingsSnapshot(AppearancePreference.light));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<McChoice<AppearancePreference>>(keyed('preferences-theme'))
          .value,
      AppearancePreference.dark,
    );
  });

  testWidgets('unsupported and regional platform locales select English', (
    tester,
  ) async {
    tester.platformDispatcher.localesTestValue = const [Locale('ar')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await mount(tester);

    for (final platformLocales in <List<Locale>>[
      const [Locale('ar')],
      const [Locale('C')],
      const [],
      const [Locale('en', 'GB')],
    ]) {
      tester.platformDispatcher.localesTestValue = platformLocales;
      await tester.pumpAndSettle();
      final context = tester.element(keyed('quit'));
      expect(Localizations.localeOf(context), const Locale('en'));
      expect(Directionality.of(context), TextDirection.ltr);
    }
  });

  testWidgets('large text, high contrast and status semantics stay operable', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await mount(tester, settings: _SettingsFake());
    await activate(tester, 'nav-preferences');

    tester.widget<McChoice<double>>(keyed('preferences-scale')).onChanged(1.5);
    await tester.pump();
    tester
        .widget<McChoice<ContrastPreference>>(keyed('preferences-contrast'))
        .onChanged(ContrastPreference.high);
    await tester.pump();
    await activate(tester, 'apply-preferences');
    tester.view.physicalSize = const Size(640, 700);
    await tester.pumpAndSettle();

    expect(
      MediaQuery.textScalerOf(tester.element(keyed('quit'))).scale(1),
      1.5,
    );
    expect(MediaQuery.highContrastOf(tester.element(keyed('quit'))), isTrue);
    final status = tester.getSemantics(find.byType(McStatus).first);
    expect(status.getSemanticsData().label, isNotEmpty);
    expect(keyed('quit'), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

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
        tester
            .widget<McChoice<AppearancePreference>>(keyed('preferences-theme'))
            .value,
        AppearancePreference.dark,
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
