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
  bool unavailableSettings = false,
  bool settle = true,
  DiagnosticsClient? diagnostics,
  WorkspacesClient? workspaces,
  GameContextsClient? gameContexts,
  SkseClient? skse,
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
      settings: unavailableSettings ? null : settings ?? _SettingsFake(),
      diagnostics: diagnostics,
      workspaces: workspaces,
      gameContexts: gameContexts,
      skse: skse,
    ),
  );
  if (settle) await tester.pumpAndSettle();
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

class _CapabilityGameContexts extends Fake implements GameContextsClient {
  _CapabilityGameContexts({this.skyrim = false});
  final bool skyrim;

  static const definition = GameDefinitionInfo(
    id: 'example-steam-game',
    revision: 1,
    name: 'Example Steam game',
    storefront: 'Steam',
    declaredSteamAppId: 1,
    capabilities: [
      GameCapability(
        id: GameCapabilityId.gameInstallationValidation,
        revision: 1,
        name: 'Game installation validation',
        kind: GameCapabilityKind.coreOutcome,
        contexts: [
          GameCapabilityContext(
            definitionId: 'example-steam-game',
            platforms: [GameContextPlatform.windows],
          ),
        ],
        disposition: GameCapabilityDisposition.available,
      ),
    ],
  );

  @override
  Future<GameContextState> read(String workspaceId, String profileId) async =>
      GameContextState(
        workspaceId: workspaceId,
        profileId: profileId,
        revision: 1,
        definition: skyrim
            ? GameDefinitionInfo(
                id: definition.id,
                revision: definition.revision,
                name: definition.name,
                storefront: definition.storefront,
                declaredSteamAppId: definition.declaredSteamAppId,
                capabilities: [
                  ...definition.capabilities,
                  const GameCapability(
                    id: GameCapabilityId.skyrimSpecialEdition,
                    revision: 1,
                    name: 'Skyrim Special Edition',
                    kind: GameCapabilityKind.gameAdapter,
                    contexts: [
                      GameCapabilityContext(
                        definitionId: 'example-steam-game',
                        platforms: [GameContextPlatform.windows],
                      ),
                    ],
                    disposition: GameCapabilityDisposition.available,
                  ),
                ],
              )
            : definition,
        binding: GameBindingInfo(
          id: 'binding',
          path: '/games/example',
          needsCheck: false,
          evidence: GameInstallationEvidence(
            definitionId: definition.id,
            definitionRevision: definition.revision,
            platform: GameContextPlatform.windows,
            rootPath: '/games/example',
            dataPath: '/games/example/Data',
            executable: const GameExecutableEvidence(
              path: '/games/example/game.exe',
              sha256: 'abc',
              length: 1,
              fileVersion: '1',
              productVersion: '1',
            ),
            launcherPath: null,
            documents: const UnavailableGameLocation('not needed'),
            saves: const UnavailableGameLocation('not needed'),
            localAppData: const UnavailableGameLocation('not needed'),
            problems: const [],
            checkedAt: DateTime.utc(2026),
            fingerprint: 'fixture',
          ),
        ),
      );
}

class _UnboundGameContexts extends Fake implements GameContextsClient {
  @override
  Future<GameContextState> read(String workspaceId, String profileId) async =>
      GameContextState(
        workspaceId: workspaceId,
        profileId: profileId,
        revision: 0,
        definition: null,
        binding: null,
      );
}

class _DelayedSkyrimGameContexts extends _CapabilityGameContexts {
  _DelayedSkyrimGameContexts() : super(skyrim: true);
  final pending = Completer<GameContextState>();
  late String workspaceId, profileId;

  @override
  Future<GameContextState> read(String workspace, String profile) {
    workspaceId = workspace;
    profileId = profile;
    return pending.future;
  }

  Future<void> finish() async =>
      pending.complete(await super.read(workspaceId, profileId));
}

class _DelayedSettingsFake extends _SettingsFake {
  final reads = <String, Completer<SettingsSnapshot>>{};
  final values = <String, SettingsSnapshot>{};
  Completer<SettingsSnapshot>? save;
  bool failWorkspaceRead = false;
  final savedWorkspaceIds = <String>[];

  @override
  Future<SettingsSnapshot> readWorkspace(String workspaceId) {
    if (failWorkspaceRead) {
      return Future.error(
        const SettingsException(
          SettingsFault.unavailable,
          'Workspace read failed',
        ),
      );
    }
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

class _DelayedApplicationSettingsFake extends _SettingsFake {
  final firstRead = Completer<SettingsSnapshot>();
  int applicationReads = 0;

  @override
  Future<SettingsSnapshot> readApplication() {
    applicationReads++;
    return applicationReads == 1 ? firstRead.future : super.readApplication();
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

class _FailingSettingsFake extends _SettingsFake {
  _FailingSettingsFake(this.readFault);

  final SettingsFault readFault;
  bool failRead = true;
  bool failSave = false;

  @override
  Future<SettingsSnapshot> readApplication() async {
    if (failRead) {
      throw SettingsException(readFault, 'Settings boundary detail');
    }
    return super.readApplication();
  }

  @override
  Future<SettingsSnapshot> saveApplication(SettingsSnapshot settings) async {
    if (failSave) {
      throw const SettingsException(SettingsFault.unavailable, 'Write failed');
    }
    return super.saveApplication(settings);
  }
}

class _NoDiagnostics extends Fake implements DiagnosticsClient {}

class _DelayedSkse extends Fake implements SkseClient {
  final result = Completer<SkseStatus>();
  int checks = 0;

  @override
  Future<SkseStatus> checkUpdate(String workspace, String profile) {
    checks++;
    return result.future;
  }
}

class _ProfileSkse extends Fake implements SkseClient {
  final checked = <String>[];

  @override
  Future<SkseStatus> checkUpdate(String workspace, String profile) async {
    checked.add(workspace);
    return SkseStatus(
      workspace == 'one' ? SkseStatusPhase.available : SkseStatusPhase.ready,
      '1.6.1170.0',
      workspace == 'one' ? '' : '2.2.0',
      workspace == 'one' ? 'SKSE is not installed' : 'SKSE is installed',
      '',
    );
  }
}

class _TemporaryUnavailableSkse extends Fake implements SkseClient {
  int checks = 0;

  @override
  Future<SkseStatus> checkUpdate(String workspace, String profile) async {
    checks++;
    return SkseStatus(
      checks == 1 ? SkseStatusPhase.unavailable : SkseStatusPhase.ready,
      '1.6.1170.0',
      checks == 1 ? '' : '2.2.0',
      checks == 1 ? 'SKSE is unavailable' : 'SKSE is installed',
      '',
    );
  }
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
  testWidgets('launch check waits for a profile and does not hold navigation', (
    tester,
  ) async {
    final skse = _DelayedSkse();
    await mount(
      tester,
      status: const DesktopConnected((
        runtime: (architecture: 'x64', nativeAot: true, sqliteVersion: '3'),
        heartbeats: 1,
      )),
      workspaces: _WorkspacesFake(),
      gameContexts: _CapabilityGameContexts(skyrim: true),
      skse: skse,
    );
    expect(skse.checks, 0);

    await openWorkspace(tester, 'one');
    expect(skse.checks, 1);
    await tester.tap(keyed('close-workspace'));
    await tester.pumpAndSettle();
    await openWorkspace(tester, 'two');
    expect(skse.checks, 1);

    skse.result.complete(
      const SkseStatus(
        SkseStatusPhase.ready,
        '1.6.1170.0',
        '2.2.0',
        'SKSE is installed',
        '',
      ),
    );
    await tester.pump();
  });

  testWidgets('launch check skips absent SKSE and checks the next profile', (
    tester,
  ) async {
    final skse = _ProfileSkse();
    await mount(
      tester,
      status: const DesktopConnected((
        runtime: (architecture: 'x64', nativeAot: true, sqliteVersion: '3'),
        heartbeats: 1,
      )),
      workspaces: _WorkspacesFake(),
      gameContexts: _CapabilityGameContexts(skyrim: true),
      skse: skse,
    );
    await openWorkspace(tester, 'one');
    expect(skse.checked, ['one']);
    await tester.tap(keyed('close-workspace'));
    await tester.pumpAndSettle();
    await openWorkspace(tester, 'one');
    expect(skse.checked, ['one']);
    await tester.tap(keyed('close-workspace'));
    await tester.pumpAndSettle();
    await openWorkspace(tester, 'two');
    expect(skse.checked, ['one', 'two']);
  });

  testWidgets('launch check waits for the selected game context', (
    tester,
  ) async {
    final contexts = _DelayedSkyrimGameContexts();
    final skse = _ProfileSkse();
    await mount(
      tester,
      status: const DesktopConnected((
        runtime: (architecture: 'x64', nativeAot: true, sqliteVersion: '3'),
        heartbeats: 1,
      )),
      workspaces: _WorkspacesFake(),
      gameContexts: contexts,
      skse: skse,
    );
    await tester.tap(keyed('workspace-one'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(skse.checked, isEmpty);
    await contexts.finish();
    await tester.pumpAndSettle();
    expect(skse.checked, ['one']);
  });

  testWidgets('temporary SKSE unavailability allows a later profile check', (
    tester,
  ) async {
    final skse = _TemporaryUnavailableSkse();
    await mount(
      tester,
      status: const DesktopConnected((
        runtime: (architecture: 'x64', nativeAot: true, sqliteVersion: '3'),
        heartbeats: 1,
      )),
      workspaces: _WorkspacesFake(),
      gameContexts: _CapabilityGameContexts(skyrim: true),
      skse: skse,
    );
    await openWorkspace(tester, 'one');
    expect(skse.checks, 1);
    await tester.tap(keyed('close-workspace'));
    await tester.pumpAndSettle();
    await openWorkspace(tester, 'one');
    expect(skse.checks, 2);
  });

  testWidgets('unavailable check follows a profile change made while pending', (
    tester,
  ) async {
    final skse = _DelayedSkse();
    await mount(
      tester,
      status: const DesktopConnected((
        runtime: (architecture: 'x64', nativeAot: true, sqliteVersion: '3'),
        heartbeats: 1,
      )),
      workspaces: _WorkspacesFake(),
      gameContexts: _CapabilityGameContexts(skyrim: true),
      skse: skse,
    );
    await openWorkspace(tester, 'one');
    await tester.tap(keyed('close-workspace'));
    await tester.pumpAndSettle();
    await openWorkspace(tester, 'two');
    expect(skse.checks, 1);
    skse.result.complete(
      const SkseStatus(SkseStatusPhase.unavailable, '', '', '', ''),
    );
    await tester.pumpAndSettle();
    expect(skse.checks, 2);
  });

  testWidgets('an unbound profile shows setup without the workbench', (
    tester,
  ) async {
    await mount(
      tester,
      workspaces: _WorkspacesFake(),
      gameContexts: _UnboundGameContexts(),
    );

    await openWorkspace(tester, 'one');

    expect(keyed('profile-setup-name'), findsOneWidget);
    expect(keyed('workspace-profiles-tab'), findsNothing);
    expect(keyed('workspace-game-tab'), findsNothing);
    expect(keyed('workspace-mods-tab'), findsNothing);
  });

  testWidgets('a bound profile exposes only its supported workbench', (
    tester,
  ) async {
    await mount(
      tester,
      workspaces: _WorkspacesFake(),
      gameContexts: _CapabilityGameContexts(),
    );

    await openWorkspace(tester, 'one');

    expect(keyed('workspace-profiles-tab'), findsOneWidget);
    expect(keyed('workspace-game-tab'), findsOneWidget);
    expect(keyed('workspace-mods-tab'), findsNothing);
    expect(keyed('workspace-tools-tab'), findsNothing);
    expect(keyed('workspace-archives-tab'), findsNothing);
    expect(keyed('workspace-help-tab'), findsNothing);
    expect(keyed('profile-setup-name'), findsNothing);
  });

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
    await choose(tester, 'preferences-interface-scale', '90%');
    await choose(tester, 'preferences-contrast', 'High contrast');
    await activate(tester, 'apply-preferences');
    expect(settings.applicationSaves, 1);
    expect(
      tester.widget<McActionFeedback>(keyed('preferences-feedback')).kind,
      McActionFeedbackKind.success,
    );
    expect(
      settings.application.presentation.appearance,
      AppearancePreference.dark,
    );
    expect(settings.application.presentation.contrast, ContrastPreference.high);
    expect(settings.application.presentation.interfaceScale, 0.9);
    expect(MediaQuery.highContrastOf(tester.element(keyed('quit'))), isTrue);
    expect(
      MediaQuery.sizeOf(tester.element(keyed('quit'))).width,
      closeTo(1280 / 0.9, 0.01),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await mount(tester, settings: settings);
    expect(brightness(tester), Brightness.dark);
    expect(
      MediaQuery.sizeOf(tester.element(keyed('quit'))).width,
      closeTo(1280 / 0.9, 0.01),
    );
    expect(MediaQuery.highContrastOf(tester.element(keyed('quit'))), isTrue);
  });

  for (final fault in [
    SettingsFault.invalidDocument,
    SettingsFault.unavailable,
  ]) {
    testWidgets(
      'failed application read hides values and retry recovers: $fault',
      (tester) async {
        final settings = _FailingSettingsFake(fault)
          ..application = settingsSnapshot(AppearancePreference.dark);
        await mount(tester, settings: settings);
        await activate(tester, 'nav-preferences');
        expect(keyed('preferences-theme'), findsNothing);
        expect(
          tester.widget<McActionFeedback>(keyed('preferences-feedback')).kind,
          McActionFeedbackKind.failure,
        );
        expect(
          tester.widget<McAction>(keyed('apply-preferences')).onPressed,
          isNull,
        );
        expect(keyed('retry-preferences'), findsOneWidget);

        settings.failRead = false;
        await activate(tester, 'retry-preferences');
        expect(keyed('preferences-theme'), findsOneWidget);
        expect(
          tester
              .widget<McChoice<AppearancePreference>>(
                keyed('preferences-theme'),
              )
              .value,
          AppearancePreference.dark,
        );
        expect(
          tester.widget<McAction>(keyed('apply-preferences')).onPressed,
          isNull,
        );
      },
    );
  }

  testWidgets('failed write keeps draft and confirmed settings until Cancel', (
    tester,
  ) async {
    final settings = _FailingSettingsFake(SettingsFault.unavailable)
      ..failRead = false
      ..failSave = true
      ..application = settingsSnapshot(AppearancePreference.light);
    await mount(tester, settings: settings);
    await activate(tester, 'nav-preferences');
    await choose(tester, 'preferences-theme', 'Dark');
    await activate(tester, 'apply-preferences');
    expect(brightness(tester), Brightness.light);
    expect(
      tester.widget<McActionFeedback>(keyed('preferences-feedback')).kind,
      McActionFeedbackKind.failure,
    );
    expect(
      tester
          .widget<McChoice<AppearancePreference>>(keyed('preferences-theme'))
          .value,
      AppearancePreference.dark,
    );
    await activate(tester, 'cancel-preferences');
    expect(
      tester
          .widget<McChoice<AppearancePreference>>(keyed('preferences-theme'))
          .value,
      AppearancePreference.light,
    );
    expect(settings.applicationSaves, 0);
  });

  testWidgets(
    'quick theme saves application while workspace scope inherits it',
    (tester) async {
      ignoreKnownWorkspaceListTileWarning();
      final settings = _SettingsFake();
      await mount(tester, settings: settings, workspaces: _WorkspacesFake());
      await openWorkspace(tester, 'one');
      await activate(tester, 'nav-preferences');
      await choose(tester, 'preferences-scope', 'Current workspace');
      await activate(tester, 'quick-theme');
      expect(settings.applicationSaves, 1);
      expect(
        settings.application.presentation.appearance,
        AppearancePreference.dark,
      );
      expect(brightness(tester), Brightness.dark);
    },
  );

  testWidgets('connection loss hides unconfirmed form and reconnect loads it', (
    tester,
  ) async {
    await mount(tester, unavailableSettings: true);
    await activate(tester, 'nav-preferences');
    expect(keyed('preferences-theme'), findsNothing);
    expect(tester.widget<McIconAction>(keyed('quick-theme')).onPressed, isNull);
    final settings = _SettingsFake()
      ..application = settingsSnapshot(AppearancePreference.dark);
    await mount(tester, settings: settings);
    expect(
      tester
          .widget<McChoice<AppearancePreference>>(keyed('preferences-theme'))
          .value,
      AppearancePreference.dark,
    );
    expect(
      tester.widget<McIconAction>(keyed('quick-theme')).onPressed,
      isNotNull,
    );
  });

  testWidgets('failed reload keeps the last confirmed workspace appearance', (
    tester,
  ) async {
    ignoreKnownWorkspaceListTileWarning();
    final workspaces = _WorkspacesFake();
    final initial = _DelayedSettingsFake()
      ..values['one'] = settingsSnapshot(AppearancePreference.dark);
    await mount(tester, settings: initial, workspaces: workspaces);
    await openWorkspace(tester, 'one');
    expect(brightness(tester), Brightness.dark);

    final disconnected = _DelayedSettingsFake()..failWorkspaceRead = true;
    await mount(tester, settings: disconnected, workspaces: workspaces);
    expect(brightness(tester), Brightness.dark);
    await activate(tester, 'nav-preferences');
    await choose(tester, 'preferences-scope', 'Current workspace');
    expect(keyed('preferences-theme'), findsNothing);
    expect(keyed('retry-preferences'), findsOneWidget);
  });

  testWidgets('settings failure keeps technical detail in Help diagnostics', (
    tester,
  ) async {
    final settings = _FailingSettingsFake(SettingsFault.invalidDocument);
    await mount(tester, settings: settings, diagnostics: _NoDiagnostics());
    await activate(tester, 'open-entry-help');
    await tester.tap(find.text('Technical details').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Settings boundary detail'), findsOneWidget);
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

  testWidgets('interface size leaves platform and chosen text size separate', (
    tester,
  ) async {
    var quits = 0;
    tester.platformDispatcher.textScaleFactorTestValue = 1.25;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await mount(tester, settings: _SettingsFake(), onQuit: () => quits++);
    await activate(tester, 'nav-preferences');
    await choose(tester, 'preferences-interface-scale', '90%');
    await activate(tester, 'apply-preferences');
    expect(
      MediaQuery.textScalerOf(tester.element(keyed('quit'))).scale(1),
      1.25,
    );
    await choose(tester, 'preferences-scale', '150%');
    await activate(tester, 'apply-preferences');
    expect(
      MediaQuery.textScalerOf(tester.element(keyed('quit'))).scale(1),
      1.875,
    );

    tester.view.physicalSize = const Size(900, 650);
    await tester.pumpAndSettle();
    await activate(tester, 'session-details');
    final corner = tester.getBottomRight(find.byType(AlertDialog));
    expect(corner.dx, lessThanOrEqualTo(900));
    expect(corner.dy, lessThanOrEqualTo(650));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await activate(tester, 'quit');
    expect(quits, 1);
    expect(tester.takeException(), isNull);
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
    expect(
      tester.widget<McActionFeedback>(keyed('preferences-feedback')).kind,
      McActionFeedbackKind.pending,
    );

    await tester.tap(keyed('nav-workspaces'));
    await tester.pump();
    await tester.tap(keyed('close-workspace'));
    await tester.pump();
    await tester.tap(keyed('workspace-two'));
    await tester.pump();
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

  testWidgets('a workspace change rejects an older settings read', (
    tester,
  ) async {
    ignoreKnownWorkspaceListTileWarning();
    final pendingRead = Completer<SettingsSnapshot>();
    final settings = _DelayedSettingsFake()
      ..reads['one'] = pendingRead
      ..values['two'] = settingsSnapshot(AppearancePreference.dark);
    await mount(tester, settings: settings, workspaces: _WorkspacesFake());
    await tester.tap(keyed('workspace-one'));
    await tester.pump();
    await tester.tap(keyed('close-workspace'));
    await tester.pump();
    await tester.tap(keyed('workspace-two'));
    await tester.pump();

    pendingRead.complete(settingsSnapshot(AppearancePreference.light));
    await tester.pumpAndSettle();
    await activate(tester, 'nav-preferences');
    await choose(tester, 'preferences-scope', 'Current workspace');
    expect(
      tester
          .widget<McChoice<AppearancePreference>>(keyed('preferences-theme'))
          .value,
      AppearancePreference.dark,
    );
  });

  testWidgets('a scope change rejects an older workspace read generation', (
    tester,
  ) async {
    ignoreKnownWorkspaceListTileWarning();
    final pendingRead = Completer<SettingsSnapshot>();
    final settings = _DelayedSettingsFake()..reads['one'] = pendingRead;
    await mount(tester, settings: settings, workspaces: _WorkspacesFake());
    await openWorkspace(tester, 'one');
    await activate(tester, 'nav-preferences');
    await tester.tap(keyed('preferences-scope'));
    await tester.pump();
    await tester.tap(find.text('Current workspace').last);
    await tester.pump();
    expect(keyed('preferences-theme'), findsNothing);

    await tester.tap(keyed('preferences-scope'));
    await tester.pump();
    await tester.tap(find.text('Application').last);
    await tester.pumpAndSettle();
    settings.reads.remove('one');
    settings.values['one'] = settingsSnapshot(AppearancePreference.dark);
    pendingRead.complete(settingsSnapshot(AppearancePreference.light));
    await tester.pumpAndSettle();

    await choose(tester, 'preferences-scope', 'Current workspace');
    expect(
      tester
          .widget<McChoice<AppearancePreference>>(keyed('preferences-theme'))
          .value,
      AppearancePreference.dark,
    );
  });

  testWidgets(
    'workspace inheritance restarts an invalidated application read',
    (tester) async {
      ignoreKnownWorkspaceListTileWarning();
      final settings = _DelayedApplicationSettingsFake()
        ..application = settingsSnapshot(AppearancePreference.dark);
      await mount(
        tester,
        settings: settings,
        workspaces: _WorkspacesFake(),
        settle: false,
      );
      await tester.pump();
      await tester.tap(keyed('workspace-one'));
      await tester.pump();
      await tester.tap(keyed('nav-preferences'));
      await tester.pump();
      await tester.tap(keyed('preferences-scope'));
      await tester.pump();
      await tester.tap(find.text('Current workspace').last);
      await tester.pumpAndSettle();

      expect(settings.applicationReads, 2);
      expect(
        tester
            .widget<McChoice<AppearancePreference>>(keyed('preferences-theme'))
            .value,
        AppearancePreference.dark,
      );
      expect(keyed('retry-preferences'), findsNothing);

      settings.firstRead.complete(settingsSnapshot(AppearancePreference.light));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<McChoice<AppearancePreference>>(keyed('preferences-theme'))
            .value,
        AppearancePreference.dark,
      );
    },
  );

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
