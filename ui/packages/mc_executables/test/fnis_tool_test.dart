import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_executables/mc_executables.dart';

class FakeFnis implements FnisClient {
  FnisStatus current = status(FnisStatusPhase.available, installed: false);
  int runs = 0;
  int reads = 0;
  bool failRead = false;
  int cancelledListeners = 0;
  int observations = 0;
  String? observedRun;
  Completer<FnisStatus>? pendingRead;
  late final StreamController<FnisStatus> events =
      StreamController<FnisStatus>.broadcast(
        onCancel: () => cancelledListeners++,
      );

  @override
  Future<FnisStatus> read(String workspace, String profile) async {
    reads++;
    if (failRead) throw StateError('read failed');
    final pending = pendingRead;
    pendingRead = null;
    if (pending != null) return pending.future;
    return current;
  }

  @override
  Future<FnisStatus> run(String workspace, String profile, String id) async {
    runs++;
    return current = status(
      FnisStatusPhase.ready,
      output: FnisOutputStatusPhase.running,
      runId: id,
    );
  }

  @override
  Stream<FnisStatus> observeRun(String workspace, String profile, String id) {
    observations++;
    observedRun = id;
    return events.stream;
  }

  @override
  Future<FnisStatus> cancelRun(String workspace, String profile) async =>
      current = status(
        FnisStatusPhase.ready,
        output: FnisOutputStatusPhase.cancelled,
      );

  @override
  Future<FnisStatus> install(String workspace, String profile) =>
      throw UnimplementedError();
  @override
  Future<FnisStatus> update(String workspace, String profile) =>
      throw UnimplementedError();
  @override
  Future<FnisStatus> cancel(String workspace, String profile) =>
      throw UnimplementedError();
  @override
  Future<FnisStatus> remove(String workspace, String profile) =>
      throw UnimplementedError();
  @override
  Future<FnisStatus> recover(String workspace, String profile) =>
      throw UnimplementedError();
}

FnisStatus status(
  FnisStatusPhase phase, {
  FnisOutputStatusPhase output = FnisOutputStatusPhase.current,
  String? runId,
  int? exitCode,
  String? outputStatus,
  String runLog = '',
  String outputDetail = '',
  String standardOutput = '',
  String standardError = '',
  bool installed = true,
}) => FnisStatus(
  phase: phase,
  version: '',
  status: '',
  detail: '',
  canInstall: false,
  canCancel: false,
  canUpdate: false,
  canRemove: false,
  canRecover: false,
  outputPhase: installed ? output : FnisOutputStatusPhase.unavailable,
  outputStatus:
      outputStatus ??
      (installed
          ? (output == FnisOutputStatusPhase.running
                ? 'FNIS is running'
                : 'FNIS output is current')
          : ''),
  outputDetail: outputDetail,
  standardOutput: standardOutput,
  standardError: standardError,
  canRun:
      installed &&
      output != FnisOutputStatusPhase.running &&
      output != FnisOutputStatusPhase.unavailable,
  canCancelRun: installed && output == FnisOutputStatusPhase.running,
  runId: runId,
  exitCode: exitCode,
  runLog: runLog,
);

void main() {
  for (final failed in [false, true]) {
    testWidgets(
      'external FNIS run observes ${failed ? 'failure' : 'success'} once and releases its listener',
      (tester) async {
        final fnis = FakeFnis()
          ..current = status(
            FnisStatusPhase.ready,
            output: FnisOutputStatusPhase.running,
            runId: 'setup-run',
          );
        final changes = ValueNotifier(0);
        addTearDown(changes.dispose);
        addTearDown(fnis.events.close);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FnisTool(
                client: fnis,
                workspaceId: 'w',
                profileId: 'p',
                changes: changes,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(fnis.observedRun, 'setup-run');
        expect(fnis.runs, 0);
        changes.value++;
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.refresh));
        await tester.pumpAndSettle();
        expect(fnis.observations, 1);

        final pending = Completer<FnisStatus>();
        fnis.pendingRead = pending;
        changes.value++;
        await tester.pump();
        final terminal = status(
          FnisStatusPhase.ready,
          output: failed
              ? FnisOutputStatusPhase.failed
              : FnisOutputStatusPhase.current,
          runId: 'setup-run',
          exitCode: failed ? 9 : 0,
          outputStatus: failed ? 'FNIS failed' : 'FNIS finished',
          outputDetail: 'Authoritative terminal detail',
          standardOutput: 'Captured stdout',
          standardError: 'Captured stderr',
          runLog: 'Captured log',
        );
        fnis.events.add(terminal);
        await tester.pumpAndSettle();
        pending.complete(fnis.current);
        await tester.pumpAndSettle();
        expect(
          find.text(failed ? 'FNIS failed' : 'FNIS finished'),
          findsOneWidget,
        );
        expect(find.text('Authoritative terminal detail'), findsOneWidget);
        expect(find.text('Exit code ${failed ? 9 : 0}'), findsOneWidget);
        expect(find.text('Cancel'), findsNothing);
        expect(fnis.cancelledListeners, 1);
        expect(fnis.observations, 1);
        expect(fnis.runs, 0);
        await tester.tap(find.text('Last run'));
        await tester.pumpAndSettle();
        expect(find.text('Captured stdout'), findsOneWidget);
        expect(find.text('Captured stderr'), findsOneWidget);
        expect(find.text('Captured log'), findsOneWidget);
        fnis.events.add(fnis.current);
        await tester.pumpAndSettle();
        expect(find.text('FNIS is running'), findsNothing);
      },
    );
  }

  testWidgets(
    'external run replacement and client context changes discard old reads and events',
    (tester) async {
      final first = FakeFnis()
        ..current = status(
          FnisStatusPhase.ready,
          output: FnisOutputStatusPhase.running,
          runId: 'old',
        );
      final second = FakeFnis()
        ..current = status(
          FnisStatusPhase.ready,
          output: FnisOutputStatusPhase.running,
          runId: 'new-profile',
        );
      addTearDown(first.events.close);
      addTearDown(second.events.close);
      final changes = ValueNotifier(0);
      addTearDown(changes.dispose);
      Widget view(FakeFnis client, String workspace, String profile) =>
          MaterialApp(
            home: Scaffold(
              body: FnisTool(
                client: client,
                workspaceId: workspace,
                profileId: profile,
                changes: changes,
              ),
            ),
          );
      await tester.pumpWidget(view(first, 'w', 'p'));
      await tester.pumpAndSettle();
      first.current = status(
        FnisStatusPhase.ready,
        output: FnisOutputStatusPhase.running,
        runId: 'replacement',
      );
      changes.value++;
      await tester.pumpAndSettle();
      expect(first.observations, 2);
      expect(first.cancelledListeners, 1);
      first.events.add(
        status(
          FnisStatusPhase.ready,
          runId: 'old',
          outputStatus: 'Late old run',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Late old run'), findsNothing);
      final pending = Completer<FnisStatus>();
      first.pendingRead = pending;
      first.events.addError(StateError('old stream failed'));
      await tester.pump();
      await tester.pumpWidget(view(second, 'other-workspace', 'other-profile'));
      await tester.pumpAndSettle();
      pending.complete(
        status(
          FnisStatusPhase.ready,
          runId: 'replacement',
          outputStatus: 'Late recovery',
        ),
      );
      first.events.add(
        status(
          FnisStatusPhase.ready,
          runId: 'replacement',
          outputStatus: 'Late old profile',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Late recovery'), findsNothing);
      expect(find.text('Late old profile'), findsNothing);
      expect(second.observedRun, 'new-profile');
      expect(first.runs + second.runs, 0);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      expect(second.cancelledListeners, 1);
      second.events.add(status(FnisStatusPhase.ready, runId: 'new-profile'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'setup changes received during a read show installed FNIS without manual refresh',
    (tester) async {
      final fnis = FakeFnis();
      final initial = fnis.current;
      final pending = Completer<FnisStatus>();
      fnis.pendingRead = pending;
      final changes = ValueNotifier(0);
      addTearDown(changes.dispose);
      addTearDown(fnis.events.close);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FnisTool(
              client: fnis,
              workspaceId: 'w',
              profileId: 'p',
              changes: changes,
            ),
          ),
        ),
      );
      fnis.current = status(
        FnisStatusPhase.failed,
        output: FnisOutputStatusPhase.missing,
      );
      changes.value++;
      pending.complete(initial);
      await tester.pumpAndSettle();
      expect(fnis.reads, 2);
      await tester.tap(find.text('Run FNIS'));
      await tester.pumpAndSettle();
      expect(fnis.runs, 1);
    },
  );

  testWidgets(
    'deleting output refreshes FNIS and allows Run on the retained view',
    (tester) async {
      final fnis = FakeFnis()..current = status(FnisStatusPhase.ready);
      final changes = ValueNotifier(0);
      addTearDown(changes.dispose);
      addTearDown(fnis.events.close);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FnisTool(
              client: fnis,
              workspaceId: 'w',
              profileId: 'p',
              changes: changes,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      fnis.current = status(
        FnisStatusPhase.available,
        output: FnisOutputStatusPhase.missing,
      );
      changes.value++;
      await tester.pumpAndSettle();
      await tester.tap(find.text('Run FNIS'));
      await tester.pumpAndSettle();
      expect(fnis.runs, 1);
    },
  );

  testWidgets('installed FNIS reruns from Tools and uses its returned state', (
    tester,
  ) async {
    final fnis = FakeFnis();
    addTearDown(fnis.events.close);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FnisTool(client: fnis, workspaceId: 'w', profileId: 'p'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Run FNIS'), findsNothing);

    fnis.current = status(
      FnisStatusPhase.failed,
      output: FnisOutputStatusPhase.missing,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FnisTool(
            key: UniqueKey(),
            client: fnis,
            workspaceId: 'w',
            profileId: 'p',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Run FNIS'));
    await tester.pumpAndSettle();
    expect(fnis.runs, 1);
    expect(find.text('FNIS is running'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(fnis.observedRun, isNotNull);

    fnis.events.add(
      status(
        FnisStatusPhase.ready,
        runId: fnis.observedRun,
        exitCode: 7,
        outputStatus: 'FNIS files updated with warnings',
        runLog: 'Generator warning details',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('FNIS files updated with warnings'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.text('Exit code 7'), findsOneWidget);
    await tester.tap(find.text('Last run'));
    await tester.pumpAndSettle();
    expect(find.text('Generator warning details'), findsOneWidget);
    expect(find.text('Run FNIS'), findsOneWidget);
  });

  testWidgets('changing profiles cancels the FNIS run listener', (
    tester,
  ) async {
    final fnis = FakeFnis()..current = status(FnisStatusPhase.ready);
    addTearDown(fnis.events.close);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FnisTool(client: fnis, workspaceId: 'w', profileId: 'first'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Run FNIS'));
    await tester.pumpAndSettle();
    final oldRun = fnis.observedRun;

    fnis.current = status(FnisStatusPhase.ready);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FnisTool(client: fnis, workspaceId: 'w', profileId: 'second'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(fnis.cancelledListeners, 1);
    fnis.events.add(
      status(
        FnisStatusPhase.ready,
        runId: oldRun,
        outputStatus: 'Old profile result',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Old profile result'), findsNothing);
  });

  testWidgets(
    'stream recovery observes a different authoritative running run without admission',
    (tester) async {
      final fnis = FakeFnis()
        ..current = status(
          FnisStatusPhase.ready,
          output: FnisOutputStatusPhase.running,
          runId: 'setup-first',
        );
      addTearDown(fnis.events.close);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FnisTool(client: fnis, workspaceId: 'w', profileId: 'p'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      fnis.current = status(
        FnisStatusPhase.ready,
        output: FnisOutputStatusPhase.running,
        runId: 'setup-next',
      );
      fnis.events.addError(StateError('first stream ended'));
      await tester.pumpAndSettle();
      expect(fnis.observedRun, 'setup-next');
      expect(fnis.observations, 2);
      expect(fnis.runs, 0);
      fnis.events.add(
        status(
          FnisStatusPhase.ready,
          runId: 'setup-first',
          outputStatus: 'Late first result',
        ),
      );
      fnis.events.add(
        status(
          FnisStatusPhase.ready,
          runId: 'setup-next',
          outputStatus: 'Next run completed',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Late first result'), findsNothing);
      expect(find.text('Next run completed'), findsOneWidget);
      expect(fnis.cancelledListeners, 2);
    },
  );

  testWidgets('stream failure reads the finished FNIS run once', (
    tester,
  ) async {
    final fnis = FakeFnis()..current = status(FnisStatusPhase.ready);
    addTearDown(fnis.events.close);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FnisTool(client: fnis, workspaceId: 'w', profileId: 'p'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Run FNIS'));
    await tester.pumpAndSettle();

    fnis.current = status(
      FnisStatusPhase.ready,
      runId: fnis.observedRun,
      exitCode: 7,
      outputStatus: 'FNIS finished with warnings',
      runLog: 'Generator warning details',
    );
    fnis.events.addError(StateError('stream lost'));
    await tester.pumpAndSettle();

    expect(fnis.reads, 2);
    expect(find.text('FNIS finished with warnings'), findsOneWidget);
    expect(find.text('FNIS is running'), findsNothing);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    await tester.tap(find.text('Last run'));
    await tester.pumpAndSettle();
    expect(find.text('Generator warning details'), findsOneWidget);
  });

  testWidgets('failed stream and read show unavailable instead of running', (
    tester,
  ) async {
    final fnis = FakeFnis()..current = status(FnisStatusPhase.ready);
    addTearDown(fnis.events.close);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FnisTool(client: fnis, workspaceId: 'w', profileId: 'p'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Run FNIS'));
    await tester.pumpAndSettle();

    fnis.failRead = true;
    fnis.events.addError(StateError('stream lost'));
    await tester.pumpAndSettle();

    expect(fnis.reads, 2);
    expect(find.text('FNIS run status is unavailable.'), findsOneWidget);
    expect(find.text('FNIS is running'), findsNothing);
  });
}
