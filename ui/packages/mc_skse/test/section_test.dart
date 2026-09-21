import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_artifacts/mc_artifacts.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_skse/mc_skse.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

SkyrimSetupStatus setupStatus({
  SkyrimSetupStatusPhase phase = SkyrimSetupStatusPhase.needsConsent,
  bool consent = false,
  bool canStart = true,
  bool canContinue = false,
  bool canSelectArchive = false,
  bool active = false,
  bool ready = false,
  bool includeFnis = false,
  bool canCancel = false,
}) => SkyrimSetupStatus(
  phase: phase,
  status: 'Setup status',
  detail: 'Setup detail',
  planToken: 'current-plan',
  changes: const [
    SkyrimSetupChange('Set up SKSE', 'Install the matching version.'),
  ],
  components: const [
    SkyrimSetupComponent(
      name: 'SKSE',
      status: 'Matching SKSE found',
      detail: '',
      ready: false,
      active: false,
      blocked: false,
    ),
  ],
  includeFnis: includeFnis,
  consentRecorded: consent,
  canStart: canStart,
  canContinue: canContinue,
  canSelectEnbArchive: canSelectArchive,
  active: active,
  ready: ready,
  canCancel: canCancel,
);

class SetupFixtureClient extends SkyrimSetupClient {
  SetupFixtureClient(this.current);
  SkyrimSetupStatus current;
  int starts = 0, continues = 0, selections = 0;
  int cancellations = 0;
  bool? startedWithFnis;
  String? selectedPath;
  Completer<SkyrimSetupStatus>? blockedSelection;
  Completer<SkyrimSetupStatus>? blockedRead;
  SkyrimSetupStatus? nextContinue;

  @override
  Future<SkyrimSetupStatus> read(
    String workspace,
    String profile, {
    required bool includeFnis,
  }) async {
    final blocked = blockedRead;
    if (blocked != null) return blocked.future;
    return current;
  }

  @override
  Future<SkyrimSetupStatus> start(
    String workspace,
    String profile, {
    required bool includeFnis,
    required String planToken,
  }) async {
    starts++;
    startedWithFnis = includeFnis;
    return current = setupStatus(
      phase: SkyrimSetupStatusPhase.waitingForEnbArchive,
      consent: true,
      canStart: false,
      canSelectArchive: true,
      includeFnis: includeFnis,
    );
  }

  @override
  Future<SkyrimSetupStatus> continueSetup(
    String workspace,
    String profile,
  ) async {
    continues++;
    final resumed = nextContinue;
    if (resumed != null) {
      nextContinue = null;
      return current = resumed;
    }
    return current = setupStatus(
      phase: SkyrimSetupStatusPhase.waitingForEnbArchive,
      consent: true,
      canStart: false,
      canSelectArchive: true,
      includeFnis: current.includeFnis,
    );
  }

  @override
  Future<SkyrimSetupStatus> cancel(String workspace, String profile) async {
    cancellations++;
    return current = setupStatus(
      phase: SkyrimSetupStatusPhase.cancelled,
      canStart: true,
      includeFnis: current.includeFnis,
    );
  }

  @override
  Future<SkyrimSetupStatus> selectEnbArchive(
    String workspace,
    String profile,
    String operationId,
    String path,
  ) async {
    selections++;
    selectedPath = path;
    final blocked = blockedSelection;
    if (blocked != null) return blocked.future;
    return current = setupStatus(
      phase: SkyrimSetupStatusPhase.settingUpEnb,
      consent: true,
      canStart: false,
      active: true,
      includeFnis: current.includeFnis,
    );
  }
}

Widget section(
  SetupFixtureClient client, {
  ArchiveChooser? chooseArchive,
  double? height = 700,
  ThemeData? theme,
}) {
  final setup = SkyrimSetupSection(
    client: client,
    chooseArchive:
        chooseArchive ?? () async => const ArchiveFile('/tmp/enb.zip', 10),
    workspaceId: 'workspace',
    profileId: 'profile',
  );
  return MaterialApp(
    theme: theme,
    home: Scaffold(
      body: height == null
          ? SingleChildScrollView(child: setup)
          : SizedBox(height: height, child: setup),
    ),
  );
}

void main() {
  testWidgets('setup layout should support parent and bounded scrolling', (
    tester,
  ) async {
    final client = SetupFixtureClient(setupStatus());

    await tester.pumpWidget(section(client, height: null));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(section(client, height: 180));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'refresh and FNIS changes keep valid setup content in a stable slot',
    (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final client = SetupFixtureClient(setupStatus());
      await tester.pumpWidget(section(client, height: null));
      await tester.pumpAndSettle();

      final sectionFinder = find.byType(McSection);
      final includeFnis = find.byKey(const ValueKey('include-fnis'));
      final refreshAction = find.byKey(const ValueKey('refresh-skyrim-setup'));
      final reviewAction = find.byKey(const ValueKey('review-skyrim-setup'));
      final originalHeight = tester.getSize(sectionFinder).height;
      final originalFnis = tester.getRect(includeFnis);
      final originalRefresh = tester.getRect(refreshAction);
      final originalReview = tester.getRect(reviewAction);
      expect(find.textContaining('Matching SKSE found'), findsOneWidget);

      final refresh = Completer<SkyrimSetupStatus>();
      client.blockedRead = refresh;
      await tester.tap(find.text('Refresh'));
      await tester.pump();

      expect(find.textContaining('Matching SKSE found'), findsOneWidget);
      expect(tester.getSize(sectionFinder).height, originalHeight);
      expect(tester.getRect(includeFnis), originalFnis);
      expect(tester.getRect(refreshAction), originalRefresh);
      expect(tester.getRect(reviewAction), originalReview);
      expect(tester.widget<SwitchListTile>(includeFnis).onChanged, isNotNull);
      expect(
        tester
            .widget<OutlinedButton>(
              find.descendant(
                of: refreshAction,
                matching: find.byType(OutlinedButton),
              ),
            )
            .onPressed,
        isNotNull,
      );
      expect(
        tester
            .widget<FilledButton>(
              find.descendant(
                of: reviewAction,
                matching: find.byType(FilledButton),
              ),
            )
            .onPressed,
        isNotNull,
      );
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(
        tester.widget<McAsyncStatusSlot>(find.byType(McAsyncStatusSlot)).active,
        isTrue,
      );

      refresh.completeError(Exception('refresh failed'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Matching SKSE found'), findsOneWidget);
      expect(tester.getSize(sectionFinder).height, originalHeight);
      expect(tester.getRect(includeFnis), originalFnis);
      expect(tester.getRect(refreshAction), originalRefresh);
      expect(tester.getRect(reviewAction), originalReview);
      expect(
        tester
            .widget<McAsyncStatusSlot>(find.byType(McAsyncStatusSlot))
            .problem,
        isNotNull,
      );

      final fnis = Completer<SkyrimSetupStatus>();
      client.blockedRead = fnis;
      await tester.tap(find.text('Include FNIS'));
      await tester.pump();

      expect(find.textContaining('Matching SKSE found'), findsOneWidget);
      expect(tester.getSize(sectionFinder).height, originalHeight);
      expect(tester.getRect(includeFnis), originalFnis);
      expect(tester.getRect(refreshAction), originalRefresh);
      expect(tester.getRect(reviewAction), originalReview);
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isTrue,
      );

      client.blockedRead = null;
      fnis.complete(client.current);
      await tester.pumpAndSettle();
      expect(find.textContaining('Matching SKSE found'), findsOneWidget);
      expect(tester.getSize(sectionFinder).height, originalHeight);
    },
  );

  testWidgets('setup status slots retain valid content at 150% text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(760, 900);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final client = SetupFixtureClient(setupStatus());
    await tester.pumpWidget(section(client, theme: mcTheme(Brightness.dark)));
    await tester.pumpAndSettle();

    final statusRows = find.descendant(
      of: find.byType(SkyrimSetupSection),
      matching: find.byType(McStatus),
    );
    final retainedStatusRects = [
      for (var index = 0; index < statusRows.evaluate().length; index++)
        tester.getRect(statusRows.at(index)),
    ];
    final includeFnis = find.byKey(const ValueKey('include-fnis'));
    final refreshAction = find.byKey(const ValueKey('refresh-skyrim-setup'));
    final reviewAction = find.byKey(const ValueKey('review-skyrim-setup'));
    final retainedFnisRect = tester.getRect(includeFnis);
    final retainedRefreshRect = tester.getRect(refreshAction);
    final retainedReviewRect = tester.getRect(reviewAction);

    await expectLater(
      find.byType(SkyrimSetupSection),
      matchesGoldenFile('goldens/skyrim_setup_idle_dark_150.png'),
    );

    final refresh = Completer<SkyrimSetupStatus>();
    client.blockedRead = refresh;
    await tester.tap(find.text('Refresh'));
    await tester.pump();
    await expectLater(
      find.byType(SkyrimSetupSection),
      matchesGoldenFile('goldens/skyrim_setup_pending_dark_150.png'),
    );

    refresh.completeError(Exception('refresh failed'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(SkyrimSetupSection),
      matchesGoldenFile('goldens/skyrim_setup_failure_dark_150.png'),
    );

    final fnis = Completer<SkyrimSetupStatus>();
    client.blockedRead = fnis;
    await tester.tap(find.text('Include FNIS'));
    await tester.pump();
    expect(statusRows, findsNWidgets(retainedStatusRects.length));
    expect([
      for (var index = 0; index < retainedStatusRects.length; index++)
        tester.getRect(statusRows.at(index)),
    ], retainedStatusRects);
    expect(tester.getRect(includeFnis), retainedFnisRect);
    expect(tester.getRect(refreshAction), retainedRefreshRect);
    expect(tester.getRect(reviewAction), retainedReviewRect);
    expect(
      tester.widget<McAsyncStatusSlot>(find.byType(McAsyncStatusSlot)).active,
      isTrue,
    );
    expect(tester.widget<SwitchListTile>(includeFnis).value, isTrue);
    await expectLater(
      find.byType(SkyrimSetupSection),
      matchesGoldenFile('goldens/skyrim_setup_fnis_pending_dark_150.png'),
    );
    client.blockedRead = null;
    fnis.complete(client.current);
    await tester.pumpAndSettle();
  });

  testWidgets(
    'setup should require one confirmed plan before starting writes',
    (tester) async {
      final client = SetupFixtureClient(setupStatus());
      await tester.pumpWidget(section(client));
      await tester.pumpAndSettle();

      expect(client.starts, 0);
      await tester.tap(find.text('Include FNIS'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Review and apply setup'));
      await tester.pumpAndSettle();

      expect(client.starts, 0);
      await tester.tap(find.text('Apply changes'));
      await tester.pumpAndSettle();

      expect(client.starts, 1);
      expect(client.startedWithFnis, isTrue);
      expect(find.text('Choose downloaded ENBSeries archive'), findsOneWidget);
    },
  );

  testWidgets(
    'waiting ENB setup should route the selected archive through the workflow',
    (tester) async {
      final client = SetupFixtureClient(
        setupStatus(
          phase: SkyrimSetupStatusPhase.waitingForEnbArchive,
          consent: true,
          canStart: false,
          canSelectArchive: true,
        ),
      );
      await tester.pumpWidget(
        section(
          client,
          chooseArchive: () async =>
              const ArchiveFile('/downloads/enbseries.zip', 42),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Choose downloaded ENBSeries archive'));
      await tester.pump();

      expect(client.selections, 1);
      expect(client.selectedPath, '/downloads/enbseries.zip');
    },
  );

  testWidgets('recorded consent should resume the next durable child step', (
    tester,
  ) async {
    final client = SetupFixtureClient(
      setupStatus(
        phase: SkyrimSetupStatusPhase.waitingForSkse,
        consent: true,
        canStart: false,
        canContinue: true,
      ),
    );
    await tester.pumpWidget(section(client));
    await tester.pumpAndSettle();

    expect(client.continues, 1);
    expect(client.starts, 0);
  });

  testWidgets(
    'cancel should stop the combined workflow and retain its durable choice',
    (tester) async {
      final client = SetupFixtureClient(
        setupStatus(
          phase: SkyrimSetupStatusPhase.waitingForEnbArchive,
          consent: true,
          canStart: false,
          canSelectArchive: true,
          canCancel: true,
          includeFnis: true,
        ),
      );
      await tester.pumpWidget(section(client));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel setup'));
      await tester.pumpAndSettle();

      expect(client.cancellations, 1);
      expect(client.current.phase, SkyrimSetupStatusPhase.cancelled);
      expect(client.current.includeFnis, isTrue);
    },
  );

  testWidgets('completed setup restores the retained FNIS choice', (
    tester,
  ) async {
    final client = SetupFixtureClient(
      setupStatus(
        phase: SkyrimSetupStatusPhase.ready,
        canStart: false,
        ready: true,
        includeFnis: true,
      ),
    );
    await tester.pumpWidget(section(client));
    await tester.pumpAndSettle();

    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isTrue,
    );
  });

  testWidgets('completed stale setup restores the retained FNIS choice', (
    tester,
  ) async {
    final client = SetupFixtureClient(
      setupStatus(
        phase: SkyrimSetupStatusPhase.needsConsent,
        canStart: true,
        includeFnis: true,
      ),
    );
    await tester.pumpWidget(section(client));
    await tester.pumpAndSettle();

    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isTrue,
    );
  });

  testWidgets('active ENB selection keeps combined Cancel available', (
    tester,
  ) async {
    final client = SetupFixtureClient(
      setupStatus(
        phase: SkyrimSetupStatusPhase.waitingForEnbArchive,
        consent: true,
        canStart: false,
        canSelectArchive: true,
        canCancel: true,
      ),
    );
    final selection = Completer<SkyrimSetupStatus>();
    client.blockedSelection = selection;
    await tester.pumpWidget(section(client));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Choose downloaded ENBSeries archive'));
    await tester.pump();
    await tester.tap(find.text('Cancel setup'));
    await tester.pump();
    await tester.pump();

    expect(client.selections, 1);
    expect(client.cancellations, 1);
    expect(client.current.phase, SkyrimSetupStatusPhase.cancelled);

    selection.complete(client.current);
    await tester.pumpAndSettle();
  });

  testWidgets(
    'recreated shared setup resumes a recorded pending cancellation',
    (tester) async {
      final client = SetupFixtureClient(
        setupStatus(
          phase: SkyrimSetupStatusPhase.recoveryRequired,
          consent: true,
          canStart: false,
          canContinue: true,
          includeFnis: true,
        ),
      );
      client.nextContinue = setupStatus(
        phase: SkyrimSetupStatusPhase.cancelled,
        canStart: true,
        includeFnis: true,
      );

      await tester.pumpWidget(section(client));
      await tester.pumpAndSettle();

      expect(client.continues, 1);
      expect(client.current.phase, SkyrimSetupStatusPhase.cancelled);
      expect(client.current.includeFnis, isTrue);
    },
  );
}
