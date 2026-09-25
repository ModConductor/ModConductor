import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_executables/mc_executables.dart';

class FakeFnis implements FnisClient {
  FnisStatus current = status(FnisStatusPhase.available);
  int runs = 0;

  @override
  Future<FnisStatus> read(String workspace, String profile) async => current;

  @override
  Future<FnisStatus> run(String workspace, String profile, String id) async {
    runs++;
    return current = status(
      FnisStatusPhase.ready,
      output: FnisOutputStatusPhase.running,
    );
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
  outputStatus: output == FnisOutputStatusPhase.running
      ? 'FNIS is running'
      : 'FNIS output is current',
  canRun: output != FnisOutputStatusPhase.running,
  canCancelRun: output == FnisOutputStatusPhase.running,
);

void main() {
  testWidgets('installed FNIS reruns from Tools and uses its returned state', (
    tester,
  ) async {
    final fnis = FakeFnis();
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
  });
}
