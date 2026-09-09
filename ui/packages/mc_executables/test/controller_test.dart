import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_executables/mc_executables.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

const workspace = WorkspaceInfo(
  id: 'workspace',
  name: 'Workspace',
  path: '/owned',
  revision: 1,
  selectedProfile: ProfileInfo('a', 'Alpha'),
);
ExecutablePreset preset({String name = 'Audit', int revision = 1}) =>
    ExecutablePreset(
      id: 'tool',
      workspaceId: 'workspace',
      revision: revision,
      name: name,
      executable: '/owned/tool',
      workingDirectory: '/owned',
      arguments: ['', 'a b', '"quoted"'],
      environment: [
        const ExecutableEnvironment('EMPTY', ''),
        const ExecutableEnvironment('REMOVE', null),
      ],
    );
ExecutableRun run(
  ExecutableRunRequest request, {
  ExecutableRunPhase phase = ExecutableRunPhase.running,
  int revision = 1,
}) => ExecutableRun(
  request: request,
  revision: revision,
  preset: preset(),
  profileId: 'a',
  profileName: 'Alpha',
  requestedAt: DateTime.utc(2026),
  phase: phase,
  processId: 12,
  scope: 'Linux process group',
  rootExitCode: null,
  observedProcessCount: 1,
  problem: null,
);

class FakeExecutables implements ExecutablesClient {
  ExecutablePreset current = preset();
  ExecutableRun? recorded;
  final requests = <ExecutableRunRequest>[];
  bool loseBegin = false, loseSave = false;
  int stops = 0, subscriptions = 0, cancellations = 0, saves = 0;
  Completer<ExecutablePreset>? saveCompletion;
  Completer<ExecutableRun>? readCompletion;
  final changes = StreamController<ExecutableRun>.broadcast();
  @override
  Future<ExecutablePresetPage> list(
    String workspaceId, {
    String? after,
  }) async => ExecutablePresetPage(
    [current],
    null,
    recorded == null ? [] : [recorded!],
  );
  @override
  Future<ExecutablePreset> readPreset(String workspaceId, String id) async =>
      current;
  @override
  Future<ExecutablePreset> save(ExecutablePreset value) async {
    ++saves;
    if (saveCompletion != null) return saveCompletion!.future;
    current = value;
    if (loseSave) throw StateError('lost after commit');
    return current;
  }

  @override
  Future<void> delete(
    String workspaceId,
    String id,
    int expectedRevision,
  ) async {}
  @override
  Future<ExecutableRun> begin(ExecutableRunRequest value) async {
    requests.add(value);
    recorded ??= run(value);
    if (loseBegin) throw StateError('lost after commit');
    return recorded!;
  }

  @override
  Future<ExecutableRun> read(String workspaceId, String id) async {
    if (readCompletion != null) return readCompletion!.future;
    if (recorded == null) {
      throw const ExecutableException(
        ExecutableFailure.notFound,
        'Not recorded',
      );
    }
    return recorded!;
  }

  @override
  Future<ExecutableRunPage> recent(String workspaceId, {String? after}) async =>
      ExecutableRunPage(recorded == null ? [] : [recorded!], null);
  @override
  Stream<ExecutableRun> observe(String workspaceId, String id) {
    ++subscriptions;
    return Stream.multi((sink) {
      final sub = changes.stream.listen(
        sink.add,
        onError: sink.addError,
        onDone: sink.close,
      );
      sink.onCancel = () {
        ++cancellations;
        return sub.cancel();
      };
    });
  }

  @override
  Future<ExecutableRun> stopWaiting(String workspaceId, String id) async {
    ++stops;
    return recorded = run(
      recorded!.request,
      phase: ExecutableRunPhase.detached,
    );
  }
}

Future<void> settleController() async {
  await Future<void>.delayed(Duration.zero);
}

Finder action(String label) =>
    find.byWidgetPredicate((w) => w is McAction && w.label == label);
void main() {
  test(
    'late reconnect read cannot replace a newer observed completion',
    () async {
      final api = FakeExecutables(), c = ExecutablesController();
      c.attach(api, workspace, available: true);
      await settleController();
      await c.run();
      await settleController();
      api.readCompletion = Completer();
      final pending = c.readRun();
      api.changes.add(
        run(
          api.recorded!.request,
          phase: ExecutableRunPhase.finished,
          revision: 2,
        ),
      );
      await settleController();
      api.readCompletion!.complete(api.recorded!);
      await pending;
      expect(c.selectedRun!.phase, ExecutableRunPhase.finished);
      expect(c.selectedRun!.revision, 2);
      expect(api.stops, 0);
      c.dispose();
      await settleController();
      await api.changes.close();
    },
  );
  testWidgets(
    'removing a setting restores inheritance while an empty Set remains explicit',
    (tester) async {
      final api = FakeExecutables(), c = ExecutablesController();
      c.attach(api, workspace, available: true);
      await tester.pump();
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: McAction(
                label: 'Edit',
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => ExecutableEditor(
                    controller: c,
                    initial: api.current,
                    chooseExecutable: (_) async => null,
                    chooseDirectory: (_) async => null,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(action('Edit'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Environment'));
      await tester.tap(find.text('Environment'));
      await tester.pumpAndSettle();
      final remove = find.byWidgetPredicate(
        (w) => w is McIconAction && w.label == 'Remove environment setting',
      );
      await tester.ensureVisible(remove.first);
      await tester.tap(remove.first);
      await tester.pumpAndSettle();
      final choice = find.byType(McChoice<bool>);
      await tester.ensureVisible(choice);
      await tester.tap(choice);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Set value').last);
      await tester.pumpAndSettle();
      await tester.tap(action('Save'));
      await tester.pumpAndSettle();
      expect(api.current.environment.map((v) => v.name), ['REMOVE']);
      expect(api.current.environment.single.value, '');
      c.dispose();
      await api.changes.close();
    },
  );
  test('lost launch response retains request identity across profile changes and reconnect read', () async {
    final api = FakeExecutables()..loseBegin = true,
        c = ExecutablesController();
    c.attach(api, workspace, available: true);
    await settleController();
    await c.run();
    final request = c.pendingLaunch!;
    expect(c.needsRead, isTrue);
    c.attach(
      api,
      const WorkspaceInfo(
        id: 'workspace',
        name: 'Workspace',
        path: '/owned',
        revision: 2,
        selectedProfile: ProfileInfo('b', 'Beta'),
      ),
      available: true,
    );
    await c.continueLaunch();
    expect(api.requests.map((r) => r.id).toSet(), {request.id});
    await c.readRun();
    expect(c.pendingLaunch, isNull);
    expect(c.selectedRun!.profileName, 'Alpha');
    expect(c.workspace!.selectedProfile!.name, 'Beta');
    c.dispose();
    await settleController();
    expect(api.stops, 0);
    await api.changes.close();
  });
  test('disconnecting observation does not detach and explicit stop waiting changes the run', () async {
    final api = FakeExecutables(), c = ExecutablesController();
    c.attach(api, workspace, available: true);
    await settleController();
    await c.run();
    await settleController();
    api.changes.addError(StateError('disconnected'));
    await settleController();
    expect(c.needsRead, isTrue);
    expect(api.stops, 0);
    await c.readRun();
    await settleController();
    expect(api.subscriptions, 2);
    expect(api.cancellations, 1);
    expect(c.selectedRun!.phase, ExecutableRunPhase.running);
    await c.stopWaiting();
    expect(api.stops, 1);
    expect(c.selectedRun!.phase, ExecutableRunPhase.detached);
    c.dispose();
    await settleController();
    await api.changes.close();
  });
  testWidgets(
    'pending Save refuses Escape and lost committed Save reconciles without another save',
    (tester) async {
      final api = FakeExecutables()..saveCompletion = Completer(),
          c = ExecutablesController();
      c.attach(api, workspace, available: true);
      await tester.pump();
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: McAction(
                label: 'Edit',
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => ExecutableEditor(
                    controller: c,
                    initial: api.current,
                    chooseExecutable: (_) async => null,
                    chooseDirectory: (_) async => null,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(action('Edit'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Name'),
        'Changed',
      );
      await tester.tap(action('Save'));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(find.byType(ExecutableEditor), findsOneWidget);
      api.current = preset(name: 'Changed', revision: 2);
      api.saveCompletion!.completeError(StateError('lost after commit'));
      await tester.pumpAndSettle();
      await tester.tap(action('Read saved'));
      await tester.pumpAndSettle();
      expect(find.byType(ExecutableEditor), findsNothing);
      expect(api.saves, 1);
      expect(c.selected!.name, 'Changed');
      c.dispose();
      await api.changes.close();
    },
  );
  testWidgets(
    'cancelled preset drafts preserve saved arguments and environment',
    (tester) async {
      final api = FakeExecutables(), c = ExecutablesController();
      c.attach(api, workspace, available: true);
      await tester.pump();
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: McAction(
                label: 'Edit',
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => ExecutableEditor(
                    controller: c,
                    initial: api.current,
                    chooseExecutable: (_) async => null,
                    chooseDirectory: (_) async => null,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(action('Edit'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Name'),
        'Draft',
      );
      await tester.tap(action('Cancel'));
      await tester.pumpAndSettle();
      expect(api.saves, 0);
      expect(c.selected!.name, 'Audit');
      expect(c.selected!.arguments, ['', 'a b', '"quoted"']);
      expect(c.selected!.environment.last.value, isNull);
      c.dispose();
      await api.changes.close();
    },
  );
}
