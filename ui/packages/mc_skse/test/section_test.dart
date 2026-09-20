import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_artifacts/mc_artifacts.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_skse/mc_skse.dart';

SkyrimSetupStatus setupStatus({
  SkyrimSetupStatusPhase phase = SkyrimSetupStatusPhase.needsConsent,
  bool consent = false,
  bool canStart = true,
  bool canContinue = false,
  bool canSelectArchive = false,
  bool active = false,
  bool ready = false,
  bool includeFnis = false,
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
);

class SetupFixtureClient extends SkyrimSetupClient {
  SetupFixtureClient(this.current);
  SkyrimSetupStatus current;
  int starts = 0, continues = 0, selections = 0;
  bool? startedWithFnis;
  String? selectedPath;

  @override
  Future<SkyrimSetupStatus> read(
    String workspace,
    String profile, {
    required bool includeFnis,
  }) async => current;

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
    return current = setupStatus(
      phase: SkyrimSetupStatusPhase.waitingForEnbArchive,
      consent: true,
      canStart: false,
      canSelectArchive: true,
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
    return current = setupStatus(
      phase: SkyrimSetupStatusPhase.settingUpEnb,
      consent: true,
      canStart: false,
      active: true,
      includeFnis: current.includeFnis,
    );
  }
}

Widget section(SetupFixtureClient client, {ArchiveChooser? chooseArchive}) =>
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 700,
          child: SkyrimSetupSection(
            client: client,
            chooseArchive:
                chooseArchive ??
                () async => const ArchiveFile('/tmp/enb.zip', 10),
            workspaceId: 'workspace',
            profileId: 'profile',
          ),
        ),
      ),
    );

void main() {
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
}
