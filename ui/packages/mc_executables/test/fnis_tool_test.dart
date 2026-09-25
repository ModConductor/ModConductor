import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_executables/mc_executables.dart';

class FakeFnis implements FnisClient {
  FnisStatus current = status(FnisStatusPhase.available);
  int runs = 0;
  int cancelledListeners = 0;
  String? observedRun;
  late final StreamController<FnisStatus> events =
      StreamController<FnisStatus>.broadcast(
        onCancel: () => cancelledListeners++,
      );

  @override
  Future<FnisStatus> read(String workspace, String profile) async => current;

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
  outputPhase: output,
  outputStatus:
      outputStatus ??
      (output == FnisOutputStatusPhase.running
          ? 'FNIS is running'
          : 'FNIS output is current'),
  canRun: output != FnisOutputStatusPhase.running,
  canCancelRun: output == FnisOutputStatusPhase.running,
  runId: runId,
  exitCode: exitCode,
  runLog: runLog,
);

void main() {
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

    fnis.current = status(FnisStatusPhase.ready);
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
}
