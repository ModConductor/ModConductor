import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_artifacts/mc_artifacts.dart';
import 'package:mc_skse/mc_skse.dart';

class _SkseFixtureClient extends SkseClient {
  _SkseFixtureClient(this.current)
    : super(ClientChannel('127.0.0.1', port: 1), CallOptions());

  SkseStatus current;
  int starts = 0;

  @override
  Future<SkseStatus> read(String workspace, String profile) async => current;

  @override
  Future<SkseStatus> start(String workspace, String profile) async {
    starts++;
    return current;
  }
}

class _EnbFixtureClient extends EnbClient {
  _EnbFixtureClient(this.current)
    : super(ClientChannel('127.0.0.1', port: 1), CallOptions());

  EnbStatus current;
  int opens = 0, selections = 0, cancels = 0;
  int updates = 0, removals = 0, recoveries = 0;
  String? selectedPath;

  @override
  Future<EnbStatus> read(String workspace, String profile) async => current;

  @override
  Future<EnbStatus> openAuthorPage(String workspace, String profile) async {
    opens++;
    return current = _enb(EnbStatusPhase.waiting, select: true, cancel: true);
  }

  @override
  Future<EnbStatus> selectArchive(
    String workspace,
    String profile,
    String operation,
    String path,
  ) async {
    selections++;
    selectedPath = path;
    return current = _enb(EnbStatusPhase.acquiring);
  }

  @override
  Future<EnbStatus> cancel(String workspace, String profile) async {
    cancels++;
    return current = _enb(EnbStatusPhase.available, open: true);
  }

  @override
  Future<EnbStatus> update(String workspace, String profile) async {
    updates++;
    return current;
  }

  @override
  Future<EnbStatus> remove(String workspace, String profile) async {
    removals++;
    return current;
  }

  @override
  Future<EnbStatus> recover(String workspace, String profile) async {
    recoveries++;
    return current;
  }
}

class _FnisFixtureClient extends FnisClient {
  _FnisFixtureClient(this.current, {this.runStaysActive = false})
    : super(ClientChannel('127.0.0.1', port: 1), CallOptions());

  FnisStatus current;
  final bool runStaysActive;
  int installs = 0, cancels = 0, updates = 0, removals = 0, recoveries = 0;
  int runs = 0, runCancellations = 0;

  @override
  Future<FnisStatus> read(String workspace, String profile) async => current;

  @override
  Future<FnisStatus> install(String workspace, String profile) async {
    installs++;
    return current;
  }

  @override
  Future<FnisStatus> cancel(String workspace, String profile) async {
    cancels++;
    return current;
  }

  @override
  Future<FnisStatus> update(String workspace, String profile) async {
    updates++;
    return current;
  }

  @override
  Future<FnisStatus> remove(String workspace, String profile) async {
    removals++;
    return current;
  }

  @override
  Future<FnisStatus> recover(String workspace, String profile) async {
    recoveries++;
    return current;
  }

  @override
  Future<FnisStatus> run(String workspace, String profile, String id) async {
    runs++;
    if (runStaysActive) {
      current = FnisStatus(
        phase: current.phase,
        version: current.version,
        status: current.status,
        detail: current.detail,
        canInstall: current.canInstall,
        canCancel: current.canCancel,
        canUpdate: current.canUpdate,
        canRemove: current.canRemove,
        canRecover: current.canRecover,
        outputPhase: FnisOutputStatusPhase.running,
        outputStatus: 'FNIS is running',
        outputDetail: 'The previous output remains active.',
        canCancelRun: true,
        runId: id,
      );
    }
    return current;
  }

  @override
  Future<FnisStatus> cancelRun(String workspace, String profile) async {
    runCancellations++;
    current = FnisStatus(
      phase: current.phase,
      version: current.version,
      status: current.status,
      detail: current.detail,
      canInstall: current.canInstall,
      canCancel: current.canCancel,
      canUpdate: current.canUpdate,
      canRemove: current.canRemove,
      canRecover: current.canRecover,
      outputPhase: FnisOutputStatusPhase.cancelled,
      outputStatus: 'FNIS run was cancelled',
      outputDetail: 'The previous output remains active.',
      canRun: true,
      standardError: 'synthetic stderr',
      runLog: 'captured generator log',
    );
    return current;
  }
}

FnisStatus _fnis(
  FnisStatusPhase phase, {
  bool install = false,
  bool cancel = false,
  bool update = false,
  bool remove = false,
  bool recover = false,
}) => FnisStatus(
  phase: phase,
  version: '7.6',
  status: 'FNIS status',
  detail: '',
  canInstall: install,
  canCancel: cancel,
  canUpdate: update,
  canRemove: remove,
  canRecover: recover,
);

_FnisFixtureClient _idleFnis() =>
    _FnisFixtureClient(_fnis(FnisStatusPhase.available));

EnbStatus _enb(
  EnbStatusPhase phase, {
  bool open = false,
  bool select = false,
  bool cancel = false,
  bool update = false,
  bool remove = false,
  bool recover = false,
}) => EnbStatus(
  phase: phase,
  status: 'ENB status',
  detail: '',
  runtimeVersion: '0.505',
  presetVersion: '1.0.0',
  canOpenAuthorPage: open,
  canSelectArchive: select,
  canCancel: cancel,
  canUpdate: update,
  canRemove: remove,
  canRecover: recover,
);

Widget _section(_SkseFixtureClient client) => MaterialApp(
  home: Scaffold(
    body: SkseSection(
      client: client,
      workspaceId: 'workspace',
      profileId: 'profile',
    ),
  ),
);

void main() {
  testWidgets('an available update keeps the working version until accepted', (
    tester,
  ) async {
    final client = _SkseFixtureClient(
      const SkseStatus(
        SkseStatusPhase.updateAvailable,
        '1.7.104.0',
        '2.3.0',
        'SKSE update available',
        'The installed version remains selected.',
      ),
    );

    await tester.pumpWidget(_section(client));
    await tester.pumpAndSettle();
    expect(client.starts, 0);

    await tester.tap(find.byIcon(Icons.download));
    await tester.pumpAndSettle();
    expect(client.starts, 1);
  });

  testWidgets(
    'an incompatible installation cannot start replacement implicitly',
    (tester) async {
      final client = _SkseFixtureClient(
        const SkseStatus(
          SkseStatusPhase.incompatible,
          '1.8.0.0',
          '2.2.0',
          'Installed SKSE is incompatible',
          'No compatible author release is available.',
        ),
      );

      await tester.pumpWidget(_section(client));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.download), findsNothing);
      expect(client.starts, 0);
    },
  );

  testWidgets(
    'the author page action waits for the selected archive before acquisition',
    (tester) async {
      final skse = _SkseFixtureClient(
        const SkseStatus(
          SkseStatusPhase.ready,
          '1.7.104.0',
          '2.3.1',
          'SKSE is current',
          '',
        ),
      );
      final enb = _EnbFixtureClient(_enb(EnbStatusPhase.available, open: true));
      var choices = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkyrimSetupSection(
              skse: skse,
              enb: enb,
              fnis: _idleFnis(),
              workspaceId: 'workspace',
              profileId: 'profile',
              chooseArchive: () async {
                choices++;
                return const ArchiveFile('/downloads/enb.zip', 42);
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.folder_open), findsNothing);
      await tester.tap(find.byIcon(Icons.open_in_browser));
      await tester.pumpAndSettle();
      expect(enb.opens, 1);
      expect(find.byIcon(Icons.folder_open), findsOneWidget);

      await tester.tap(find.byIcon(Icons.folder_open));
      await tester.pumpAndSettle();
      expect(choices, 1);
      expect(enb.selections, 1);
      expect(enb.selectedPath, '/downloads/enb.zip');
    },
  );

  testWidgets('cancel keeps archive selection available for a later restart', (
    tester,
  ) async {
    final skse = _SkseFixtureClient(
      const SkseStatus(SkseStatusPhase.ready, '', '', 'SKSE is current', ''),
    );
    final enb = _EnbFixtureClient(
      _enb(EnbStatusPhase.waiting, select: true, cancel: true),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SkyrimSetupSection(
            skse: skse,
            enb: enb,
            fnis: _idleFnis(),
            workspaceId: 'workspace',
            profileId: 'profile',
            chooseArchive: () async => null,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(enb.cancels, 1);
    expect(enb.selections, 0);
    expect(find.byIcon(Icons.open_in_browser), findsOneWidget);
  });

  testWidgets('ready setup exposes explicit update and removal actions', (
    tester,
  ) async {
    final skse = _SkseFixtureClient(
      const SkseStatus(SkseStatusPhase.ready, '', '', 'SKSE is current', ''),
    );
    final enb = _EnbFixtureClient(
      _enb(EnbStatusPhase.ready, update: true, remove: true),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SkyrimSetupSection(
            skse: skse,
            enb: enb,
            fnis: _idleFnis(),
            workspaceId: 'workspace',
            profileId: 'profile',
            chooseArchive: () async => null,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Update Lean ENB'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove ENB setup'));
    await tester.pumpAndSettle();
    expect(enb.updates, 1);
    expect(enb.removals, 1);
  });

  testWidgets('failed setup exposes deployment recovery', (tester) async {
    final skse = _SkseFixtureClient(
      const SkseStatus(SkseStatusPhase.ready, '', '', 'SKSE is current', ''),
    );
    final enb = _EnbFixtureClient(_enb(EnbStatusPhase.failed, recover: true));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SkyrimSetupSection(
            skse: skse,
            enb: enb,
            fnis: _idleFnis(),
            workspaceId: 'workspace',
            profileId: 'profile',
            chooseArchive: () async => null,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Recover previous setup'));
    await tester.pumpAndSettle();
    expect(enb.recoveries, 1);
  });

  testWidgets('stale FNIS output runs only from its explicit action', (
    tester,
  ) async {
    final skse = _SkseFixtureClient(
      const SkseStatus(SkseStatusPhase.ready, '', '', 'SKSE is current', ''),
    );
    final enb = _EnbFixtureClient(_enb(EnbStatusPhase.ready));
    final fnis = _FnisFixtureClient(
      FnisStatus(
        phase: FnisStatusPhase.ready,
        version: '7.6',
        status: 'FNIS is ready',
        detail: '',
        canInstall: false,
        canCancel: false,
        canUpdate: true,
        canRemove: true,
        canRecover: false,
        outputPhase: FnisOutputStatusPhase.stale,
        outputStatus: 'FNIS output is stale',
        outputDetail: 'Animation inputs changed.',
        canRun: true,
      ),
      runStaysActive: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SkyrimSetupSection(
            skse: skse,
            enb: enb,
            fnis: fnis,
            workspaceId: 'workspace',
            profileId: 'profile',
            chooseArchive: () async => null,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Windows generator'), findsOneWidget);
    expect(fnis.runs, 0);
    expect(find.text('Run FNIS'), findsOneWidget);
    await tester.ensureVisible(find.text('Run FNIS'));
    await tester.tap(find.text('Run FNIS'));
    await tester.pumpAndSettle();
    expect(fnis.runs, 1);
    expect(find.text('Cancel FNIS run'), findsOneWidget);
    await tester.ensureVisible(find.text('Cancel FNIS run'));
    await tester.tap(find.text('Cancel FNIS run'));
    await tester.pumpAndSettle();
    expect(fnis.runCancellations, 1);
    expect(find.textContaining('synthetic stderr'), findsOneWidget);
    expect(find.textContaining('captured generator log'), findsOneWidget);
  });
}
