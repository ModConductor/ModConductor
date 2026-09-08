import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mc_generated_outputs/src/location_dialog.dart';
import 'package:mc_generated_outputs/src/unfinished_review.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_generated_outputs/src/output_controller.dart';
import 'package:mc_generated_outputs/src/output_pane.dart';
import 'package:mc_generated_outputs/src/output_tree.dart';

OutputScope scope(String workspace) => OutputScope(
  OutputScopeRef(workspace, 'context-$workspace', 1, 1),
  '/game',
  const [],
  const [],
  const [],
);
OutputSnapshot snapshot(String id, {String workspace = 'one'}) =>
    OutputSnapshot(id, scope(workspace), DateTime.utc(2026), 1, 1, 1);
OutputFile file(String name) => OutputFile(
  'location',
  [name],
  OutputFileStatus.newFile,
  1,
  'a' * 64,
  DateTime.utc(2026),
  null,
);

class Outputs implements GeneratedOutputsClient {
  Future<OutputScope> Function(String)? reading;
  Future<OutputPage> Function(String, String, String?)? paging;
  final observations = <StreamController<OutputLoadEvent>>[];
  int reads = 0, applications = 0, resumes = 0;
  Completer<OutputLocation>? adding;
  @override
  Future<OutputLocation> add(
    String id,
    OutputScopeRef expected,
    String name,
    OutputLocationKind kind, {
    List<String>? target,
  }) => adding!.future;
  String? actionId;
  bool loseReply = false, incomplete = false;
  @override
  Future<OutputScope> read(String workspaceId, {String? contextId}) {
    reads++;
    return reading?.call(workspaceId) ?? Future.value(scope(workspaceId));
  }

  @override
  Stream<OutputLoadEvent> observe(OutputScopeRef expected) {
    final events = StreamController<OutputLoadEvent>();
    observations.add(events);
    return events.stream;
  }

  @override
  Future<OutputPage> page(
    String snapshotId, {
    required OutputLocationKind kind,
    String? cursor,
    String filter = '',
  }) async => paging == null
      ? OutputPage(snapshot(snapshotId), [file(snapshotId)], 1, null, 1, 1)
      : paging!(snapshotId, filter, cursor);
  @override
  Future<OutputActionResult> apply(
    String id,
    String snapshotId,
    List<OutputSelection> files,
    OutputAction action,
  ) async {
    applications++;
    actionId = id;
    if (loseReply) throw const FormatException('Disconnected after commit');
    return result(id);
  }

  OutputActionResult result(String id) =>
      OutputActionResult(id, 'published-version', true, [
        OutputActionEntry(
          file('output').selection,
          incomplete ? OutputDisposition.pending : OutputDisposition.moved,
        ),
      ], !incomplete);
  @override
  Future<OutputActionResult> action(String id) async => result(id);
  @override
  Future<OutputActionResult> resume(String id) async {
    resumes++;
    incomplete = false;
    actionId = id;
    return result(id);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
    'a short output pane keeps unknown-result recovery and its error reachable',
    (tester) async {
      await tester.runAsync(() async {
        final font = FontLoader('packages/mc_ui_foundation/Roboto');
        for (final weight in ['Regular', 'Medium', 'Bold']) {
          font.addFont(
            rootBundle.load(
              'packages/mc_ui_foundation/assets/fonts/Roboto-$weight.ttf',
            ),
          );
        }
        await font.load();
      });
      final api = Outputs()
        ..loseReply = true
        ..incomplete = true;
      final loadedScope = OutputScope(
        scope('one').reference,
        '/game',
        const [
          OutputLocation(
            id: 'location',
            workspaceId: 'one',
            contextId: 'context-one',
            name: 'Tool files',
            kind: OutputLocationKind.toolFolder,
            revision: 1,
            status: OutputLocationStatus.ready,
            physicalPath: '/outputs',
          ),
        ],
        const [],
        const [],
      );
      final loaded = OutputSnapshot(
        'checked',
        loadedScope,
        DateTime.utc(2026),
        1,
        1,
        1,
      );
      api.reading = (_) async => loadedScope;
      api.paging = (_, _, _) async =>
          OutputPage(loaded, [file('output')], 1, null, 1, 1);
      final controller = OutputController();
      addTearDown(controller.dispose);
      controller.attach(api, 'one', available: true);
      await tester.pump();
      controller.snapshot = loaded;
      controller.tools.attach(api, loaded);
      await tester.pumpWidget(
        MaterialApp(
          theme: mcTheme(Brightness.light),
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 680,
                  height: 317.25,
                  child: OutputPane(
                    controller: controller,
                    kind: OutputLocationKind.toolFolder,
                    narrow: true,
                    onInspect: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await controller.apply([
        file('output').selection,
      ], const MoveOutputToMod(NewOutputMod('new-mod', 'Output', '1')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(controller.problem, isNotNull);
      final read = find.byWidgetPredicate(
        (w) => w is McAction && w.label == 'Read action result',
      );
      await tester.ensureVisible(read);
      await tester.tap(read);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(controller.result?.complete, isFalse);
      final resume = find.byWidgetPredicate(
        (w) => w is McAction && w.label == 'Continue review',
      );
      await tester.ensureVisible(resume);
      await tester.tap(resume);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(api.applications, 1);
      expect(api.resumes, 1);
      expect(controller.result?.complete, isTrue);
      expect(controller.pendingAction, isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );

  testWidgets(
    'a restarted review is read by its durable ID before the user continues it',
    (tester) async {
      final api = Outputs()..incomplete = true;
      api.reading = (_) async => OutputScope(
        scope('one').reference,
        '/game',
        const [],
        const [],
        const ['durable-action'],
      );
      final controller = OutputController();
      addTearDown(controller.dispose);
      controller.attach(api, 'one', available: true);
      await tester.pump();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: UnfinishedOutputReview(controller: controller)),
        ),
      );
      await tester.pumpAndSettle();
      expect(controller.result?.id, 'durable-action');
      expect(controller.result?.published, isTrue);
      expect(controller.result?.complete, isFalse);
      expect(api.applications, 0);
      expect(api.resumes, 0);
      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is McAction && w.label == 'Continue review',
        ),
      );
      await tester.pumpAndSettle();
      expect(api.actionId, 'durable-action');
      expect(api.applications, 0);
      expect(api.resumes, 1);
      expect(controller.result?.complete, isTrue);
      expect(controller.pendingAction, isNull);
    },
  );

  testWidgets(
    'a submitting location form cannot imply cancellation and retains its draft after an unknown response',
    (tester) async {
      final api = Outputs()..adding = Completer<OutputLocation>();
      final controller = OutputController();
      addTearDown(controller.dispose);
      controller.attach(api, 'one', available: true);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => AddOutputLocationDialog(
                    controller: controller,
                    kind: OutputLocationKind.toolFolder,
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Kept draft');
      await tester.tap(find.byKey(const ValueKey('submit')));
      await tester.pump();
      expect(controller.changing, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(find.byType(AddOutputLocationDialog), findsOneWidget);
      expect(
        tester.widget<McFormDialog>(find.byType(McFormDialog)).canCancel,
        isFalse,
      );
      api.adding!.completeError(const FormatException('Unknown response'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField))
            .controller!
            .text,
        'Kept draft',
      );
      expect(
        tester.widget<McFormDialog>(find.byType(McFormDialog)).canCancel,
        isTrue,
      );
      expect(
        tester.widget<McAction>(find.byKey(const ValueKey('submit'))).onPressed,
        isNull,
      );
      final reload = find.byWidgetPredicate(
        (w) => w is McAction && w.label == 'Reload',
      );
      await tester.tap(reload);
      await tester.pumpAndSettle();
      expect(controller.needsRead, isFalse);
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField))
            .controller!
            .text,
        'Kept draft',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(AddOutputLocationDialog), findsNothing);
    },
  );

  test('initial refresh waits for the shared scope read and cancels without replacing the last complete observation', () async {
    final api = Outputs(), read = Completer<OutputScope>();
    api.reading = (_) => read.future;
    final controller = OutputController();
    addTearDown(controller.dispose);
    controller.attach(api, 'one', available: true);
    final refresh = controller.refresh();
    expect(api.reads, 1);
    read.complete(scope('one'));
    await Future<void>.delayed(const Duration(milliseconds: 1));
    expect(api.observations, hasLength(1));
    api.observations.single.add(OutputsObserved(snapshot('complete')));
    unawaited(api.observations.single.close());
    await Future<void>.delayed(const Duration(milliseconds: 1));
    await refresh;
    expect(controller.snapshot?.id, 'complete');
    final second = controller.refresh();
    await Future<void>.delayed(const Duration(milliseconds: 1));
    api.observations.last.add(const OutputLoadProgress(0, 32));
    await Future<void>.delayed(const Duration(milliseconds: 1));
    await controller.cancel();
    await second;
    expect(controller.snapshot?.id, 'complete');
    expect(controller.loading, isFalse);
    expect(controller.progress, isNull);
    unawaited(api.observations.last.close());
  });

  test('a late scope read cannot repopulate another workspace or clear an invalidation', () async {
    final api = Outputs(), delayed = Completer<OutputScope>();
    api.reading = (workspace) =>
        workspace == 'one' ? delayed.future : Future.value(scope(workspace));
    final controller = OutputController();
    addTearDown(controller.dispose);
    controller.attach(api, 'one', available: true);
    controller.attach(api, 'two', available: true);
    await Future<void>.delayed(const Duration(milliseconds: 1));
    delayed.complete(scope('one'));
    await Future<void>.delayed(const Duration(milliseconds: 1));
    expect(controller.scope?.reference.workspaceId, 'two');
    final stale = Completer<OutputScope>();
    api.reading = (_) => stale.future;
    final read = controller.read();
    controller.invalidate();
    stale.complete(scope('two'));
    await read;
    expect(controller.needsRead, isTrue);
  });

  test('unknown publication is reconciled by its action identity without applying another promotion', () async {
    final api = Outputs()..loseReply = true;
    final controller = OutputController();
    addTearDown(controller.dispose);
    controller.attach(api, 'one', available: true);
    await Future<void>.delayed(const Duration(milliseconds: 1));
    controller.snapshot = snapshot('checked');
    expect(
      await controller.apply([
        file('output').selection,
      ], const MoveOutputToMod(NewOutputMod('new-mod', 'Output', '1'))),
      isFalse,
    );
    expect(controller.pendingAction, api.actionId);
    expect(controller.needsRead, isTrue);
    expect(controller.canAct, isFalse);
    await controller.checkResult();
    expect(api.applications, 1);
    expect(api.resumes, 0);
    expect(controller.result?.versionId, 'published-version');
    expect(controller.pendingAction, isNull);
  });

  test(
    'superseded debounce and late pages cannot clear or mix a new snapshot',
    () async {
      final api = Outputs(), delayed = Completer<OutputPage>();
      api.paging = (id, filter, cursor) => id == 'old'
          ? delayed.future
          : Future.value(OutputPage(snapshot(id), [file(id)], 1, null, 1, 1));
      final tree = OutputTree(OutputLocationKind.toolFolder);
      addTearDown(tree.dispose);
      tree.attach(api, snapshot('old'));
      tree.search('match');
      tree.attach(api, snapshot('new'));
      await Future<void>.delayed(const Duration(milliseconds: 1));
      delayed.complete(
        OutputPage(snapshot('old'), [file('stale')], 1, null, 1, 1),
      );
      await Future<void>.delayed(const Duration(milliseconds: 250));
      expect(tree.model.ids.map((id) => tree.model[id]!.file!.path.single), [
        'new',
      ]);
      expect(tree.canLoad, isFalse);
    },
  );
}
