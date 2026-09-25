import 'dart:async';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_skse/mc_skse.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';
import 'package:mc_workspaces/mc_workspaces.dart';
import 'package:mod_conductor/src/app.dart';

DiagnosticFinding finding({
  String id = 'conflict',
  String code = 'priority-tie',
  String title = 'Two copies have the same priority',
}) => DiagnosticFinding(
  id: id,
  code: code,
  severity: DiagnosticSeverity.error,
  workspaceName: 'My workspace',
  profileName: 'Main',
  gameName: 'Skyrim Special Edition',
  title: title,
  summary: 'Mod Conductor cannot select one file copy',
  detail: null,
  area: 'Main mod files',
  evidence: const [
    DiagnosticEvidence('Target', 'meshes/marker.nif'),
    DiagnosticEvidence('First mod', '1.0 · priority 10'),
  ],
  nextAction: 'Preview a change that hides one file copy.',
  fixability: DiagnosticFixability.previewAvailable,
  fixDetail: 'Mod Conductor can fix this',
  correlations: const [
    DiagnosticCorrelation('mod-files', 'file-check-1', null),
  ],
);

class FakeDiagnostics implements DiagnosticsClient {
  FakeDiagnostics({this.checkResult});
  DiagnosticSnapshot? checkResult;
  Object? previewFailure;
  int checks = 0, previews = 0, applies = 0;

  @override
  Future<DiagnosticSnapshot> check({
    required String workspaceId,
    required String profileId,
    String? fileSnapshotId,
    String? pluginSnapshotId,
    String? deploymentId,
    int? deploymentRevision,
  }) async {
    checks++;
    return checkResult ??
        DiagnosticSnapshot(
          'check-1',
          workspaceId,
          profileId,
          DateTime.utc(2026, 9, 14),
          [finding()],
        );
  }

  @override
  Future<DiagnosticPreview> preview(String snapshotId, String problemId) async {
    previews++;
    if (previewFailure case final failure?) throw failure;
    return DiagnosticPreview(
      'preview-1',
      snapshotId,
      problemId,
      DateTime.utc(2026, 9, 14, 0, 5),
      const [
        DiagnosticRemediationItem('Target file', 'meshes/marker.nif'),
        DiagnosticRemediationItem('Saved copy', 'First mod · 1.0'),
        DiagnosticRemediationItem('Profile setting', 'Hide this copy for Main'),
      ],
      const [
        DiagnosticRemediationIdentifier('Mod ID', 'mod-id'),
        DiagnosticRemediationIdentifier('Version ID', 'version-id'),
        DiagnosticRemediationIdentifier('Profile ID', 'profile-id'),
      ],
      'Mod Conductor will hide one file copy.',
    );
  }

  @override
  Future<DiagnosticApplyResult> apply(String previewId) async {
    applies++;
    return DiagnosticApplyResult(
      previewId,
      true,
      'Mod Conductor updated the mod files',
      'Second mod now supplies this file in the saved mod files.',
    );
  }

  @override
  Future<DiagnosticSupportReport> export(String snapshotId) =>
      throw UnimplementedError();
}

class FakeWorkspaces extends Fake implements WorkspacesClient {
  FakeWorkspaces({this.savedWorkspace});

  WorkspaceInfo? savedWorkspace;
  int opens = 0, creates = 0, profileCreates = 0;

  WorkspacePage _page() =>
      WorkspacePage(savedWorkspace!, [?savedWorkspace!.selectedProfile], null);

  @override
  Future<WorkspaceList> recent({String? after}) async =>
      WorkspaceList([?savedWorkspace], null);

  @override
  Future<WorkspacePage> open(String path) async {
    opens++;
    savedWorkspace ??= WorkspaceInfo(
      id: 'opened-workspace',
      name: 'Opened workspace',
      path: path,
      revision: 1,
    );
    return _page();
  }

  @override
  Future<WorkspacePage> create(String id, String name, [String? path]) async {
    creates++;
    savedWorkspace = WorkspaceInfo(
      id: id,
      name: name,
      path: path ?? '/default/$id',
      revision: 1,
    );
    return _page();
  }

  @override
  Future<ProfileChange> createProfile(
    String workspace,
    int revision,
    ProfileInfo profile,
  ) async {
    profileCreates++;
    savedWorkspace = WorkspaceInfo(
      id: savedWorkspace!.id,
      name: savedWorkspace!.name,
      path: savedWorkspace!.path,
      revision: revision + 1,
      selectedProfile: profile,
    );
    return ProfileChange(savedWorkspace!, profile, null);
  }
}

class FakeSkyrimSetup extends Fake implements SkyrimSetupClient {
  int reads = 0;
  final _changes = StreamController<SkyrimSetupStatus>.broadcast();

  @override
  Stream<SkyrimSetupStatus> watch(
    String workspace,
    String profile, {
    required SkyrimSetupSelection selection,
  }) async* {
    yield await read(workspace, profile, selection: selection);
    yield* _changes.stream;
  }

  @override
  Future<SkyrimSetupStatus> read(
    String workspace,
    String profile, {
    required SkyrimSetupSelection selection,
  }) async {
    reads++;
    return const SkyrimSetupStatus(
      phase: SkyrimSetupStatusPhase.ready,
      status: 'Skyrim setup is ready',
      detail: '',
      components: [],
      selection: SkyrimSetupSelection(),
      canStart: false,
      canContinue: false,
      active: false,
      ready: true,
      canCancel: false,
    );
  }
}

const skyrimDefinition = GameDefinitionInfo(
  id: 'skyrim-se-steam',
  revision: 1,
  name: 'Skyrim Special Edition',
  storefront: 'Steam',
  declaredSteamAppId: 489830,
  capabilities: [
    GameCapability(
      id: GameCapabilityId.gameInstallationValidation,
      revision: 1,
      name: 'Game installation validation',
      kind: GameCapabilityKind.coreOutcome,
      contexts: [
        GameCapabilityContext(
          definitionId: 'skyrim-se-steam',
          platforms: [GameContextPlatform.windows],
        ),
      ],
      disposition: GameCapabilityDisposition.available,
    ),
    GameCapability(
      id: GameCapabilityId.skyrimSpecialEdition,
      revision: 1,
      name: 'Skyrim Special Edition',
      kind: GameCapabilityKind.gameAdapter,
      contexts: [
        GameCapabilityContext(
          definitionId: 'skyrim-se-steam',
          platforms: [GameContextPlatform.windows],
        ),
      ],
      disposition: GameCapabilityDisposition.available,
    ),
  ],
);

GameContextState boundGame(String workspace, String profile) =>
    GameContextState(
      workspaceId: workspace,
      profileId: profile,
      revision: 1,
      definition: skyrimDefinition,
      binding: GameBindingInfo(
        id: 'binding-$profile',
        path: '/games/skyrim',
        needsCheck: false,
        evidence: GameInstallationEvidence(
          definitionId: skyrimDefinition.id,
          definitionRevision: skyrimDefinition.revision,
          platform: GameContextPlatform.windows,
          rootPath: '/games/skyrim',
          dataPath: '/games/skyrim/Data',
          executable: const GameExecutableEvidence(
            path: '/games/skyrim/SkyrimSE.exe',
            sha256: 'abc',
            length: 1,
            fileVersion: '1.6.1170',
            productVersion: '1.6.1170',
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

class FakeGameContexts extends Fake implements GameContextsClient {
  @override
  Future<GameContextState> read(String workspaceId, String profileId) async =>
      boundGame(workspaceId, profileId);

  @override
  Future<GameContextState> save(
    String workspaceId,
    String profileId,
    String gameId,
    int revision,
    String path, {
    ProtonSelection? proton,
  }) async => boundGame(workspaceId, profileId);
}

GameContextState unboundGame(String workspace, String profile) =>
    GameContextState(
      workspaceId: workspace,
      profileId: profile,
      revision: 0,
      definition: null,
      binding: null,
    );

class RetryWorkspaces extends FakeWorkspaces {
  RetryWorkspaces({this.loseFirstCreateResponse = false})
    : profiles = [const ProfileInfo('original-profile', 'Original')],
      super(
        savedWorkspace: const WorkspaceInfo(
          id: 'workspace-1',
          name: 'My workspace',
          path: '/games/my-workspace',
          revision: 1,
          selectedProfile: ProfileInfo('original-profile', 'Original'),
        ),
      );

  final List<ProfileInfo> profiles;
  final bool loseFirstCreateResponse;
  int failedSelections = 0;
  int selectionAttempts = 0;

  ProfileInfo get createdProfile => profiles.last;

  WorkspacePage get page => WorkspacePage(savedWorkspace!, profiles, null);

  @override
  Future<WorkspacePage> open(String path) async => page;

  @override
  Future<WorkspacePage> read(String id, {String? after}) async => page;

  @override
  Future<ProfileChange> createProfile(
    String workspace,
    int revision,
    ProfileInfo profile,
  ) async {
    profileCreates++;
    profiles.add(profile);
    savedWorkspace = WorkspaceInfo(
      id: savedWorkspace!.id,
      name: savedWorkspace!.name,
      path: savedWorkspace!.path,
      revision: revision + 1,
      selectedProfile: savedWorkspace!.selectedProfile,
    );
    if (loseFirstCreateResponse && profileCreates == 1) {
      throw Exception('The profile creation response was lost.');
    }
    return ProfileChange(savedWorkspace!, profile, null);
  }

  @override
  Future<ProfileChange> selectProfile(
    String workspace,
    int revision,
    String profile,
  ) async {
    selectionAttempts++;
    if (failedSelections > 0) {
      failedSelections--;
      throw const WorkspaceException(
        WorkspaceFault.unresolved,
        'The profile selection did not return a result.',
      );
    }
    final selected = profiles.singleWhere((item) => item.id == profile);
    savedWorkspace = WorkspaceInfo(
      id: savedWorkspace!.id,
      name: savedWorkspace!.name,
      path: savedWorkspace!.path,
      revision: revision + 1,
      selectedProfile: selected,
    );
    return ProfileChange(savedWorkspace!, selected, null);
  }
}

class RetryGameContexts extends Fake implements GameContextsClient {
  RetryGameContexts({this.loseFirstSaveResponse = false});

  final bool loseFirstSaveResponse;
  final states = <String, GameContextState>{
    'original-profile': boundGame('workspace-1', 'original-profile'),
  };
  int saves = 0;

  @override
  Future<GameContextState> read(String workspaceId, String profileId) async =>
      states[profileId] ?? unboundGame(workspaceId, profileId);

  @override
  Future<GameContextState> save(
    String workspaceId,
    String profileId,
    String gameId,
    int revision,
    String path, {
    ProtonSelection? proton,
  }) async {
    final current = states[profileId] ?? unboundGame(workspaceId, profileId);
    if (revision != current.revision) {
      throw const GameContextException(
        GameContextFailure.stale,
        'The game context revision is stale.',
      );
    }
    saves++;
    final saved = boundGame(workspaceId, profileId);
    states[profileId] = saved;
    if (loseFirstSaveResponse && saves == 1) {
      throw Exception('The saved response was lost.');
    }
    return saved;
  }
}

class FakeSteamDiscovery implements SteamDiscoveryClient {
  @override
  SteamSearch search(String definitionId, List<String> additionalRoots) =>
      SteamSearch(
        Future.value(
          const SteamSearchResult(
            appId: 489830,
            roots: [],
            candidates: [
              SteamInstallationCandidate(
                'candidate',
                SteamDirectory('/games/skyrim', '/games/skyrim', 'fixture'),
                [],
              ),
            ],
            diagnostics: [],
            limited: false,
          ),
        ),
        () async {},
      );
}

Future<void> mountApp(
  WidgetTester tester, {
  required FakeWorkspaces workspaces,
  required FakeDiagnostics diagnostics,
  FakeSkyrimSetup? skyrimSetup,
  GameContextsClient? gameContexts,
  SteamDiscoveryClient? steamDiscovery,
  DirectoryChooser? chooseDirectory,
  SettingsClient? settings,
  Size size = const Size(1280, 800),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  await tester.pumpWidget(
    ModConductorApp(
      workspaces: workspaces,
      settings: settings,
      diagnostics: diagnostics,
      skyrimSetup: skyrimSetup,
      gameContexts: gameContexts,
      steamDiscovery: steamDiscovery,
      chooseDirectory: chooseDirectory ?? (_) async => null,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> prepareNewProfile(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('workspace-workspace-1')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('create-profile')));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const ValueKey('profile-setup-name')),
    'Retry profile',
  );
  await tester.tap(find.byKey(const ValueKey('find-profile-installation')));
  await tester.pumpAndSettle();
}

Future<void> openGuide(WidgetTester tester, String id) async {
  await tester.tap(find.byKey(const ValueKey('help-guides-section')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(ValueKey(id)));
  await tester.pump();
  await tester.sendKeyEvent(LogicalKeyboardKey.enter);
  await tester.pumpAndSettle();
}

Future<void> activateAction(WidgetTester tester, String key) async {
  final action = tester.widget<McAction>(find.byKey(ValueKey(key)));
  action.focusNode!.requestFocus();
  await tester.pump();
  await tester.sendKeyEvent(LogicalKeyboardKey.enter);
  await tester.pumpAndSettle();
}

bool isSelected(WidgetTester tester, String id) =>
    tester
        .getSemantics(find.byKey(ValueKey(id)))
        .getSemanticsData()
        .flagsCollection
        .isSelected ==
    Tristate.isTrue;

Future<DiagnosticsController> mount(
  WidgetTester tester,
  FakeDiagnostics client, {
  Size size = const Size(1280, 800),
  ThemeData? theme,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  final controller = DiagnosticsController();
  addTearDown(controller.dispose);
  controller.attach(client, 'workspace-1', 'profile-1');
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(body: HelpBrowser(controller: controller)),
    ),
  );
  await tester.pumpAndSettle();
  return controller;
}

class _DisplaySettings implements SettingsClient {
  _DisplaySettings(this.interfaceScale);

  final double interfaceScale;

  @override
  Future<SettingsSnapshot> readApplication() async => SettingsSnapshot(
    presentation: PresentationPreferences(
      appearance: AppearancePreference.light,
      textScale: 1,
      interfaceScale: interfaceScale,
      contrast: ContrastPreference.system,
    ),
    inheritsApplication: false,
  );

  @override
  Future<SettingsSnapshot> readWorkspace(String workspaceId) async =>
      SettingsSnapshot(
        presentation: (await readApplication()).presentation,
        inheritsApplication: true,
      );

  @override
  Future<SettingsSnapshot> saveApplication(SettingsSnapshot settings) async =>
      settings;

  @override
  Future<SettingsSnapshot> saveWorkspace(
    String workspaceId,
    SettingsSnapshot settings,
  ) async => settings;
}

void main() {
  testWidgets('a lost create response recovers one usable profile', (
    tester,
  ) async {
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final workspaces = RetryWorkspaces(loseFirstCreateResponse: true);
    final contexts = RetryGameContexts();
    await mountApp(
      tester,
      workspaces: workspaces,
      diagnostics: FakeDiagnostics(),
      gameContexts: contexts,
      steamDiscovery: FakeSteamDiscovery(),
    );
    await prepareNewProfile(tester);

    await tester.tap(find.byKey(const ValueKey('submit-profile-setup')));
    await tester.pumpAndSettle();

    expect(workspaces.profileCreates, 1);
    expect(workspaces.profiles, hasLength(2));
    expect(contexts.saves, 1);
    expect(workspaces.selectionAttempts, 1);
    expect(
      workspaces.savedWorkspace!.selectedProfile!.id,
      workspaces.createdProfile.id,
    );
    expect(
      contexts.states[workspaces.createdProfile.id]!.binding!.needsCheck,
      isFalse,
    );
    expect(find.byKey(const ValueKey('submit-profile-setup')), findsNothing);
    expect(find.byKey(const ValueKey('workspace-mods-tab')), findsOneWidget);
  });

  testWidgets(
    'a selection failure retries without saving the game context twice',
    (tester) async {
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final workspaces = RetryWorkspaces()..failedSelections = 1;
      final contexts = RetryGameContexts();
      await mountApp(
        tester,
        workspaces: workspaces,
        diagnostics: FakeDiagnostics(),
        gameContexts: contexts,
        steamDiscovery: FakeSteamDiscovery(),
      );
      await prepareNewProfile(tester);

      await tester.tap(find.byKey(const ValueKey('submit-profile-setup')));
      await tester.pumpAndSettle();
      expect(workspaces.profileCreates, 1);
      expect(workspaces.profiles, hasLength(2));
      expect(contexts.saves, 1);
      expect(workspaces.selectionAttempts, 1);

      await tester.tap(find.byKey(const ValueKey('submit-profile-setup')));
      await tester.pumpAndSettle();
      expect(workspaces.profileCreates, 1);
      expect(workspaces.profiles, hasLength(2));
      expect(contexts.saves, 1);
      expect(workspaces.selectionAttempts, 2);
      expect(
        workspaces.savedWorkspace!.selectedProfile!.id,
        workspaces.createdProfile.id,
      );
      expect(
        contexts.states[workspaces.createdProfile.id]!.binding!.needsCheck,
        isFalse,
      );
      expect(find.byKey(const ValueKey('submit-profile-setup')), findsNothing);
      expect(find.byKey(const ValueKey('workspace-mods-tab')), findsOneWidget);
    },
  );

  testWidgets(
    'a lost save response reloads the committed context before retry',
    (tester) async {
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final workspaces = RetryWorkspaces();
      final contexts = RetryGameContexts(loseFirstSaveResponse: true);
      await mountApp(
        tester,
        workspaces: workspaces,
        diagnostics: FakeDiagnostics(),
        gameContexts: contexts,
        steamDiscovery: FakeSteamDiscovery(),
      );
      await prepareNewProfile(tester);

      await tester.tap(find.byKey(const ValueKey('submit-profile-setup')));
      await tester.pumpAndSettle();
      expect(workspaces.profileCreates, 1);
      expect(workspaces.profiles, hasLength(2));
      expect(contexts.saves, 1);
      expect(workspaces.selectionAttempts, 0);

      await tester.tap(find.byKey(const ValueKey('submit-profile-setup')));
      await tester.pumpAndSettle();
      expect(workspaces.profileCreates, 1);
      expect(workspaces.profiles, hasLength(2));
      expect(contexts.saves, 1);
      expect(workspaces.selectionAttempts, 1);
      expect(
        workspaces.savedWorkspace!.selectedProfile!.id,
        workspaces.createdProfile.id,
      );
      expect(contexts.states[workspaces.createdProfile.id]!.revision, 1);
      expect(find.byKey(const ValueKey('submit-profile-setup')), findsNothing);
      expect(find.byKey(const ValueKey('workspace-mods-tab')), findsOneWidget);
    },
  );

  testWidgets('cancelling profile setup does not create a profile', (
    tester,
  ) async {
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final workspaces = FakeWorkspaces(
      savedWorkspace: const WorkspaceInfo(
        id: 'workspace-1',
        name: 'My workspace',
        path: '/games/my-workspace',
        revision: 1,
        selectedProfile: ProfileInfo('profile-1', 'Main'),
      ),
    );
    await mountApp(
      tester,
      workspaces: workspaces,
      diagnostics: FakeDiagnostics(),
      gameContexts: FakeGameContexts(),
      steamDiscovery: FakeSteamDiscovery(),
    );
    await tester.tap(find.byKey(const ValueKey('workspace-workspace-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create-profile')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('profile-setup-name')),
      'Discarded',
    );
    await tester.tap(find.byKey(const ValueKey('find-profile-installation')));
    await tester.pumpAndSettle();

    expect(workspaces.profileCreates, 0);
    await tester.tap(find.byKey(const ValueKey('cancel-profile-setup')));
    await tester.pumpAndSettle();

    expect(workspaces.profileCreates, 0);
    expect(find.byKey(const ValueKey('profile-setup-name')), findsNothing);
  });

  testWidgets(
    'first workspace Help uses the existing setup actions at 150% text',
    (tester) async {
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final workspaces = FakeWorkspaces(
        savedWorkspace: const WorkspaceInfo(
          id: 'workspace-1',
          name: 'My workspace',
          path: '/games/my-workspace',
          revision: 1,
          selectedProfile: ProfileInfo('profile-1', 'Main'),
        ),
      );
      final setup = FakeSkyrimSetup();
      final chosen = ['/opened', '/created'];
      await mountApp(
        tester,
        workspaces: workspaces,
        diagnostics: FakeDiagnostics(),
        skyrimSetup: setup,
        gameContexts: FakeGameContexts(),
        steamDiscovery: FakeSteamDiscovery(),
        chooseDirectory: (_) async => chosen.removeAt(0),
        size: const Size(900, 900),
      );

      await activateAction(tester, 'open-entry-help');
      await openGuide(tester, 'first-skyrim-workspace');
      final semantics = tester.ensureSemantics();
      expect(
        tester
            .getSemantics(find.byKey(const ValueKey('guide-create-workspace')))
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
      );
      expect(
        tester
            .getSemantics(find.byKey(const ValueKey('guide-open-workspace')))
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
      );
      semantics.dispose();

      await activateAction(tester, 'guide-open-workspace');
      await tester.tap(find.byKey(const ValueKey('choose-folder')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('submit')));
      await tester.pumpAndSettle();
      expect(workspaces.opens, 1);

      await tester.tap(find.byKey(const ValueKey('close-workspace')));
      await tester.pumpAndSettle();
      await activateAction(tester, 'open-entry-help');
      await openGuide(tester, 'first-skyrim-workspace');
      await activateAction(tester, 'guide-create-workspace');
      await tester.enterText(
        find.byKey(const ValueKey('name')),
        'New workspace',
      );
      await tester.tap(find.byKey(const ValueKey('choose-folder')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('submit')));
      await tester.pumpAndSettle();
      expect(workspaces.creates, 1);

      await tester.tap(find.byKey(const ValueKey('create-profile')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('profile-setup-name')),
        'Main',
      );
      await tester.tap(find.byKey(const ValueKey('find-profile-installation')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('submit-profile-setup')));
      await tester.pumpAndSettle();
      expect(workspaces.profileCreates, 1);

      await tester.tap(find.byKey(const ValueKey('workspace-help-tab')));
      await tester.pumpAndSettle();
      await openGuide(tester, 'first-skyrim-workspace');
      await activateAction(tester, 'open-skyrim-setup');
      await tester.pumpAndSettle();
      expect(find.byType(SkyrimSetupSection), findsOneWidget);
      expect(setup.reads, greaterThan(0));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Help preserves a chosen guide and rehydrates recovery after app restart',
    (tester) async {
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final deployment = finding(
        id: 'deployment',
        code: 'deployment-incomplete',
        title: 'Deployment did not finish',
      );
      final client = FakeDiagnostics(
        checkResult: DiagnosticSnapshot(
          'check-1',
          'workspace-1',
          'profile-1',
          DateTime.utc(2026, 9, 20),
          [deployment, finding()],
        ),
      );
      final workspaces = FakeWorkspaces(
        savedWorkspace: const WorkspaceInfo(
          id: 'workspace-1',
          name: 'My workspace',
          path: '/games/my-workspace',
          revision: 1,
          selectedProfile: ProfileInfo('profile-1', 'Main'),
        ),
      );
      await mountApp(
        tester,
        workspaces: workspaces,
        diagnostics: client,
        gameContexts: FakeGameContexts(),
      );
      await tester.tap(find.byKey(const ValueKey('workspace-workspace-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('workspace-help-tab')));
      await tester.pumpAndSettle();
      await openGuide(tester, 'conflict');
      expect(isSelected(tester, 'conflict'), isTrue);
      await tester.tap(find.byKey(const ValueKey('workspace-game-tab')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('workspace-help-tab')));
      await tester.pumpAndSettle();
      expect(isSelected(tester, 'conflict'), isTrue);
      expect(
        find.byKey(const ValueKey('open-conflict-diagnostics')),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await mountApp(
        tester,
        workspaces: workspaces,
        diagnostics: client,
        gameContexts: FakeGameContexts(),
      );
      await tester.tap(find.byKey(const ValueKey('workspace-workspace-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('workspace-help-tab')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('help-guides-section')));
      await tester.pumpAndSettle();
      expect(isSelected(tester, 'first-skyrim-workspace'), isTrue);
      expect(isSelected(tester, 'conflict'), isFalse);

      await openGuide(tester, 'recover');
      await activateAction(tester, 'open-deployment-recovery');
      final preview = find.byKey(const ValueKey('preview-diagnostic-change'));
      expect(
        tester
            .getSemantics(preview)
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
      );
      await activateAction(tester, 'preview-diagnostic-change');
      await tester.tap(find.byKey(const ValueKey('apply-diagnostic-change')));
      await tester.pumpAndSettle();
      expect(client.checks, greaterThanOrEqualTo(2));
      expect(client.previews, 1);
      expect(client.applies, 1);
    },
  );

  testWidgets('Help navigation remains aligned at supported widths', (
    tester,
  ) async {
    for (final visualCase in [
      (name: 'wide', size: const Size(1280, 800)),
      (name: 'narrow', size: const Size(680, 800)),
    ]) {
      await mount(
        tester,
        FakeDiagnostics(),
        size: visualCase.size,
        theme: mcTheme(Brightness.dark),
      );
      await expectLater(
        find.byType(HelpBrowser),
        matchesGoldenFile(
          'goldens/help_navigation_${visualCase.name}_dark.png',
        ),
      );
    }
  });

  testWidgets('Help stays readable at a 900 pixel window at both sizes', (
    tester,
  ) async {
    await (FontLoader('packages/mc_ui_foundation/Roboto')..addFont(
          rootBundle.load(
            'packages/mc_ui_foundation/assets/fonts/Roboto-Regular.ttf',
          ),
        ))
        .load();
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final interfaceScale in [1.0, 0.9]) {
      await tester.pumpWidget(const SizedBox.shrink());
      await mountApp(
        tester,
        workspaces: FakeWorkspaces(
          savedWorkspace: WorkspaceInfo(
            id: 'workspace-1',
            name: 'My workspace',
            path: '/games/my-workspace',
            revision: 1,
            selectedProfile: const ProfileInfo('profile-1', 'Main'),
          ),
        ),
        diagnostics: FakeDiagnostics(
          checkResult: DiagnosticSnapshot(
            'visual-check',
            'workspace-1',
            'profile-1',
            DateTime.utc(2026, 9, 25),
            const [],
          ),
        ),
        gameContexts: FakeGameContexts(),
        settings: _DisplaySettings(interfaceScale),
        size: const Size(900, 650),
      );
      await tester.tap(find.byKey(const ValueKey('workspace-workspace-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('workspace-help-tab')));
      await tester.pumpAndSettle();

      final filter = find.byType(TextField).first;
      final filterStart = tester.getTopLeft(filter);
      final filterEnd = tester.getBottomRight(filter);
      final guides = tester.getCenter(
        find.byKey(const ValueKey('help-guides-section')),
      );
      expect(guides.dy, lessThan(filterStart.dy));
      expect(filterEnd.dx - filterStart.dx, greaterThan(500));
      expect(filterEnd.dx, lessThanOrEqualTo(900));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
    'wide Help reuses one sidebar, list, inspector and explicit preview',
    (tester) async {
      final client = FakeDiagnostics();
      await mount(tester, client);

      expect(
        find.byWidgetPredicate((widget) => widget is McNavigationList),
        findsOneWidget,
      );
      expect(find.text('Diagnostics'), findsWidgets);
      expect(find.text('FAQ'), findsOneWidget);
      expect(find.text('Guides'), findsOneWidget);
      expect(find.text('Two copies have the same priority'), findsWidgets);
      final faqAction = find.ancestor(
        of: find.text('FAQ'),
        matching: find.byType(TextButton),
      );
      final faqIcon = find.descendant(
        of: faqAction,
        matching: find.byIcon(Icons.help_outline),
      );
      expect(faqAction, findsOneWidget);
      expect(faqIcon, findsOneWidget);
      expect(
        tester.getCenter(faqIcon).dy,
        closeTo(tester.getCenter(find.text('FAQ')).dy, 1),
      );

      final previewAction = find.byKey(
        const ValueKey('preview-diagnostic-change'),
      );
      final opener = tester.widget<McAction>(previewAction).focusNode!;
      opener.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Hide this file copy?'), findsOneWidget);
      expect(find.text('meshes/marker.nif'), findsWidgets);
      expect(find.text('First mod · 1.0'), findsOneWidget);
      expect(find.text('Hide this copy for Main'), findsOneWidget);
      expect(find.text('mod-id'), findsNothing);
      await tester.tap(find.text('Technical details').last);
      await tester.pumpAndSettle();
      expect(find.text('mod-id'), findsOneWidget);
      expect(client.applies, 0);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(opener.hasFocus, true);
      expect(client.applies, 0);

      await tester.tap(find.byKey(const ValueKey('preview-diagnostic-change')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(McAction, 'Hide this copy'));
      await tester.pumpAndSettle();
      expect(client.previews, 2);
      expect(client.applies, 1);
      expect(
        find.textContaining('Mod Conductor updated the mod files'),
        findsOneWidget,
      );
      expect(
        find.text('Second mod now supplies this file in the saved mod files.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'narrow Help uses tabs and reports stale refusal without applying',
    (tester) async {
      final client = FakeDiagnostics()
        ..previewFailure = const DiagnosticsException(DiagnosticFault.stale);
      await mount(tester, client, size: const Size(680, 800));

      expect(
        find.byWidgetPredicate((widget) => widget is SegmentedButton),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate((widget) => widget is McNavigationList),
        findsNothing,
      );
      final faqIcon = find.byIcon(Icons.help_outline);
      expect(faqIcon, findsOneWidget);
      expect(
        tester.getCenter(faqIcon).dy,
        closeTo(tester.getCenter(find.text('FAQ').first).dy, 1),
      );
      await tester.tap(find.text('FAQ').first);
      await tester.pumpAndSettle();
      expect(find.text('What happens when I select Play?'), findsOneWidget);
      await tester.tap(find.text('Diagnostics').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.open_in_new));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('preview-diagnostic-change')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining(
          'The selected information changed. Run Diagnostics again.',
        ),
        findsOneWidget,
      );
      expect(client.applies, 0);
    },
  );

  test('new attachment supersedes an older in-flight check', () async {
    final first = Completer<DiagnosticSnapshot>();
    final second = Completer<DiagnosticSnapshot>();
    final client = _SequencedDiagnostics([first, second]);
    final controller = DiagnosticsController();
    addTearDown(controller.dispose);

    controller.attach(client, 'workspace-1', 'profile-1');
    controller.attach(client, 'workspace-2', 'profile-2');
    second.complete(
      DiagnosticSnapshot(
        'new',
        'workspace-2',
        'profile-2',
        DateTime.utc(2026, 9, 14),
        [finding(id: 'new')],
      ),
    );
    await Future<void>.delayed(Duration.zero);
    first.complete(
      DiagnosticSnapshot(
        'old',
        'workspace-1',
        'profile-1',
        DateTime.utc(2026, 9, 14),
        [finding(id: 'old')],
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(controller.snapshot?.id, 'new');
  });
}

class _SequencedDiagnostics extends FakeDiagnostics {
  _SequencedDiagnostics(this.values);
  final List<Completer<DiagnosticSnapshot>> values;
  int next = 0;

  @override
  Future<DiagnosticSnapshot> check({
    required String workspaceId,
    required String profileId,
    String? fileSnapshotId,
    String? pluginSnapshotId,
    String? deploymentId,
    int? deploymentRevision,
  }) => values[next++].future;
}
