import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_executables/mc_executables.dart';

import 'controller_test.dart' as native;

ExecutableRun gameRun(
  GameRunRequest request, {
  int revision = 1,
  ExecutableRunPhase phase = ExecutableRunPhase.starting,
}) => ExecutableRun(
  request: null,
  preset: null,
  revision: revision,
  profileId: request.profileId,
  profileName: 'Alpha',
  requestedAt: DateTime.utc(2026),
  phase: phase,
  processId: phase == ExecutableRunPhase.starting ? null : 12,
  scope: 'Linux process group',
  rootExitCode: phase == ExecutableRunPhase.finished ? 0 : null,
  observedProcessCount: null,
  problem: null,
  game: GameRunInfo(
    request: request,
    contextId: 'context',
    name: 'Skyrim',
    gameDirectory: '/owned/game',
    runtime: 'Selected Proton',
    executable: '/owned/runtime',
    arguments: const [],
    workingDirectory: '/owned/game',
    environment: const [],
    preparation: GamePreparationPhase.preparing,
    completed: 0,
    total: 0,
    files: null,
  ),
);

class Games implements GameLaunchingClient {
  Games(this.runs);
  final native.FakeExecutables runs;
  int starts = 0, cancels = 0;
  bool staleFnis = false, runningFnis = false, continuedStaleFnis = false;
  bool loseResponse = false;
  Completer<GameLaunchState>? nextRead;
  GameLaunchState state(String profile) => GameLaunchState(
    workspaceId: 'workspace',
    profileId: profile,
    contextRevision: 1,
    sourceToken: 'sources',
    name: 'Skyrim',
    runtime: 'Selected Proton',
    problem: null,
    latest: runs.recorded,
    fnisStale: staleFnis || runningFnis,
    fnisStatus: runningFnis
        ? 'FNIS is running'
        : staleFnis
        ? 'FNIS output is stale'
        : '',
    canRunFnis: staleFnis && !runningFnis,
  );
  @override
  Future<GameLaunchState> read(String workspaceId, String profileId) =>
      nextRead?.future ?? Future.value(state(profileId));
  @override
  Future<ExecutableRun> play(
    GameRunRequest request, {
    bool continueStaleFnis = false,
  }) async {
    ++starts;
    continuedStaleFnis = continueStaleFnis;
    runs.recorded = gameRun(request);
    if (loseResponse) throw StateError('response lost after admission');
    return runs.recorded!;
  }

  @override
  Future<ExecutableRun> cancel(String workspaceId, String id) async {
    ++cancels;
    return runs.recorded = gameRun(
      runs.recorded!.game!.request,
      revision: 2,
      phase: ExecutableRunPhase.failed,
    );
  }
}

void main() {
  testWidgets('Play options open details without starting the game', (
    tester,
  ) async {
    final runs = native.FakeExecutables(), controller = GamePlayController();
    final games = Games(runs);
    controller.attach(games, runs, native.workspace, available: true);
    addTearDown(controller.dispose);
    addTearDown(runs.changes.close);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: GamePlayActions(controller: controller)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Play options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Run details'));
    await tester.pumpAndSettle();
    expect(find.byType(GamePlayDialog), findsOneWidget);
    expect(games.starts, 0);
  });

  testWidgets(
    'split Play launches the selected profile and reads a lost reply',
    (tester) async {
      final runs = native.FakeExecutables(), controller = GamePlayController();
      final games = Games(runs)..loseResponse = true;
      controller.attach(games, runs, native.workspace, available: true);
      addTearDown(controller.dispose);
      addTearDown(runs.changes.close);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: GamePlayActions(controller: controller)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Play · Alpha'));
      await tester.pumpAndSettle();
      expect(games.starts, 1);
      expect(controller.pending!.profileId, 'a');
      expect(controller.uncertain, isTrue);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Play options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Read result'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(controller.pending, isNull);
      expect(controller.uncertain, isFalse);
      expect(controller.run!.profileId, 'a');
      expect(games.starts, 1);
    },
  );

  testWidgets(
    'menu remains keyboard reachable when primary Play is unavailable',
    (tester) async {
      final controller = GamePlayController();
      addTearDown(controller.dispose);
      var switches = 0;
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 240);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GamePlayActions(
              controller: controller,
              additionalMenuItems: [
                PopupMenuItem(
                  value: () => switches++,
                  child: const Text('Switch deployment'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(switches, 1);
      expect(tester.takeException(), isNull);
    },
  );

  test('stale FNIS requires an explicit continue before Play', () async {
    final runs = native.FakeExecutables(), controller = GamePlayController();
    final games = Games(runs)..staleFnis = true;
    controller.attach(games, runs, native.workspace, available: true);
    await native.settleController();
    await controller.play();
    expect(games.starts, 0);
    expect(controller.problem, contains('Run FNIS'));
    await controller.play(continueStaleFnis: true);
    expect(games.starts, 1);
    expect(games.continuedStaleFnis, isTrue);
    controller.dispose();
    await runs.changes.close();
  });

  test('running FNIS also requires an explicit continue before Play', () async {
    final runs = native.FakeExecutables(), controller = GamePlayController();
    final games = Games(runs)..runningFnis = true;
    controller.attach(games, runs, native.workspace, available: true);
    await native.settleController();
    await controller.play();
    expect(games.starts, 0);
    expect(controller.problem, contains('FNIS is running'));
    await controller.play(continueStaleFnis: true);
    expect(games.starts, 1);
    controller.dispose();
    await runs.changes.close();
  });

  test(
    'lost Play reply is reconciled by run identity without launching again',
    () async {
      final runs = native.FakeExecutables(), controller = GamePlayController();
      final games = Games(runs)..loseResponse = true;
      controller.attach(games, runs, native.workspace, available: true);
      await native.settleController();
      await controller.play();
      final id = controller.pending!.id;
      expect(controller.uncertain, isTrue);
      await controller.play();
      expect(games.starts, 1);
      await controller.readResult();
      expect(controller.run!.id, id);
      expect(controller.pending, isNull);
      expect(controller.uncertain, isFalse);
      await controller.stop();
      expect(games.cancels, 1);
      expect(runs.stops, 0);
      controller.dispose();
      await runs.changes.close();
    },
  );

  test(
    'selection changed during launch-state read is not applied or launched',
    () async {
      final runs = native.FakeExecutables(), controller = GamePlayController();
      final games = Games(runs);
      controller.attach(games, runs, native.workspace, available: true);
      await native.settleController();
      games.nextRead = Completer();
      final pending = controller.play();
      controller.attach(
        games,
        runs,
        const WorkspaceInfo(
          id: 'workspace',
          name: 'Workspace',
          path: '/owned',
          revision: 2,
          selectedProfile: ProfileInfo('b', 'Beta'),
        ),
        available: true,
      );
      games.nextRead!.complete(games.state('a'));
      await pending;
      expect(games.starts, 0);
      expect(controller.pending, isNull);
      expect(controller.problem, isNotNull);
      controller.dispose();
      await runs.changes.close();
    },
  );

  test('newer game completion survives late result read and selected-profile changes', () async {
    final runs = native.FakeExecutables(), controller = GamePlayController();
    final games = Games(runs);
    controller.attach(games, runs, native.workspace, available: true);
    await native.settleController();
    await controller.play();
    final initial = controller.run!;
    runs.readCompletion = Completer();
    final read = controller.readResult();
    runs.changes.add(
      gameRun(
        initial.game!.request,
        revision: 3,
        phase: ExecutableRunPhase.finished,
      ),
    );
    await native.settleController();
    runs.readCompletion!.complete(initial);
    await read;
    controller.attach(
      games,
      runs,
      const WorkspaceInfo(
        id: 'workspace',
        name: 'Workspace',
        path: '/owned',
        revision: 2,
        selectedProfile: ProfileInfo('b', 'Beta'),
      ),
      available: true,
    );
    await native.settleController();
    expect(controller.run!.phase, ExecutableRunPhase.finished);
    expect(controller.run!.profileId, 'a');
    expect(controller.workspace!.selectedProfile!.id, 'b');
    controller.dispose();
    await runs.changes.close();
  });
}
