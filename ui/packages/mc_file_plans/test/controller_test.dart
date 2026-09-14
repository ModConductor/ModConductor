import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_file_plans/mc_file_plans.dart';
import 'package:mc_file_plans/src/planned_files_controller.dart';
import 'package:mc_mod_library/mc_mod_library.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

FilePlanState state(String id) => FilePlanState(
  id: id,
  workspaceId: 'workspace',
  profileId: 'profile',
  fingerprint: 'fingerprint-$id',
  loaded: true,
  stale: false,
  plannedFiles: 3,
  absentTargets: 0,
  inspectedFiles: 3,
  problems: const [],
  problemCount: 0,
);
PlannedFileNode node(
  List<String> path, {
  bool folder = false,
  String source = 'Mod',
}) => PlannedFileNode(
  path: path,
  directory: folder,
  disposition: PlannedFileDisposition.planned,
  sourceName: source,
  copies: 1,
);
final copy = ManagedFileCopy('mod', 'version', ['textures', 'stone.dds']);
InspectedFileCopy inspected({bool hidden = false, ManagedFileCopy? id}) =>
    InspectedFileCopy(
      copy: id ?? copy,
      sourcePath: (id ?? copy).path,
      name: 'Textures',
      versionLabel: '1',
      priority: 2,
      enabled: true,
      hidden: hidden,
      winner: !hidden,
      historical: false,
      length: 10,
      sha256: 'a' * 64,
      canHide: !hidden,
      canUnhide: hidden,
      source: ManagedPreviewSource(
        copy: id ?? copy,
        sourcePath: (id ?? copy).path,
        target: copy.path,
        length: 10,
        sha256: 'a' * 64,
        payloadId: 'payload',
        modRevision: 1,
      ),
      standing: hidden
          ? FileSourceStanding.unavailable
          : FileSourceStanding.winner,
    );

class FakePlans implements FilePlansClient {
  FilePlanState current = state('first');
  bool hidden = false, unknownChange = false;
  int changes = 0;
  bool failTextSave = false;
  final textActions = <String>[];
  final textSnapshots = <String>[];
  final abandonedTextActions = <String>[];
  final openedProfiles = <String>[];
  final stream = StreamController<FilePlanLoadEvent>.broadcast();
  Future<FilePlanPage> Function(String, List<String>?, String, FilePlanCursor?)?
  page;
  @override
  Future<ManagedTextDocument> openManagedText(
    String snapshotId,
    ManagedPreviewSource source,
  ) async => ManagedTextDocument(
    source,
    const TextDocument(
      content: 'original\n',
      encoding: TextDocumentEncoding.utf8,
      newline: TextDocumentNewline.lf,
      finalTerminator: true,
      lines: 2,
    ),
  );
  @override
  Future<ManagedTextEdit> saveManagedText(
    String snapshotId,
    String id,
    ManagedPreviewSource source,
    String content,
  ) async {
    textActions.add(id);
    textSnapshots.add(snapshotId);
    if (failTextSave) {
      throw const FilePlanException(
        FilePlanFailure.stale,
        'The source changed.',
      );
    }
    return ManagedTextEdit(id, id, source);
  }

  @override
  Future<void> abandonManagedText(String id) async {
    abandonedTextActions.add(id);
  }

  @override
  Future<FilePlanState> open(String profileId) async {
    openedProfiles.add(profileId);
    return current;
  }

  @override
  Future<FilePlanState> read(String snapshotId) async => current;
  @override
  Stream<FilePlanLoadEvent> acquire(
    String profileId, {
    required bool refresh,
  }) => stream.stream;
  @override
  Future<FilePlanPage> children(
    String snapshotId, {
    List<String>? parent,
    String filter = '',
    FilePlanCursor? cursor,
  }) async => page == null
      ? FilePlanPage(current, const [], null)
      : page!(snapshotId, parent, filter, cursor);
  @override
  Future<FilePlanInspection> inspectCopy(
    String snapshotId,
    ManagedFileCopy value,
  ) async => FilePlanInspection(
    current,
    copy.path,
    [inspected(id: ManagedFileCopy('other', 'version', copy.path))],
    const FilePlanCursor('sources', 1),
    focusedCopy: inspected(hidden: hidden),
  );
  @override
  Future<FilePlanInspection> inspect(
    String snapshotId,
    List<String> target, {
    FilePlanCursor? cursor,
  }) async =>
      FilePlanInspection(current, target, [inspected(hidden: hidden)], null);
  @override
  Future<FileVisibilityChange> change(
    String snapshotId,
    ManagedFileCopy value, {
    required bool hidden,
  }) async {
    changes++;
    this.hidden = hidden;
    current = state('changed');
    if (unknownChange) throw Exception('Reply lost after commit');
    return FileVisibilityChange(
      current,
      node(copy.path, source: 'Game folder'),
    );
  }

  @override
  FilePreviewRead preview(
    String snapshotId,
    FilePreviewSource source,
    FilePreviewRepresentation representation,
  ) => FilePreviewRead(
    Future.value(
      FilePreviewResult(
        source: source,
        standing: FileSourceStanding.winner,
        target: source.target,
        status: FilePreviewStatus.ready,
        content: const FilePreviewText('preview', 'UTF-8', 1),
      ),
    ),
    () async {},
  );

  @override
  Future<FileVisibilityHistory> history(
    String snapshotId,
    ManagedFileCopy copy, {
    int? beforeId,
  }) async => const FileVisibilityHistory([], null);
  @override
  Future<FilePlanProblems> problems(
    String snapshotId, {
    FilePlanCursor? cursor,
  }) async => const FilePlanProblems([], null);
}

void main() {
  previewSupersessionTests();
  test('cancelling acquisition completes its waiter and retains the previous snapshot', () async {
    final client = FakePlans();
    final controller = FilePlansController()..attach(client, 'profile');
    await Future<void>.delayed(Duration.zero);
    final original = controller.state;
    var completed = false;
    final load = controller
        .acquire(refresh: true)
        .then((_) => completed = true);
    await Future<void>.delayed(Duration.zero);
    expect(controller.loading, isTrue);
    await controller.cancel();
    await Future<void>.delayed(Duration.zero);
    await load.timeout(const Duration(seconds: 5));
    expect(completed, isTrue);
    expect(controller.loading, isFalse);
    expect(controller.state, same(original));
    controller.dispose();
    await client.stream.close();
  });

  test('workspace readiness starts one initial read and preserves a loaded view during pending actions', () async {
    final client = FakePlans();
    final controller = FilePlansController()
      ..attach(client, 'profile', available: false);
    await Future<void>.delayed(Duration.zero);
    expect(client.openedProfiles, isEmpty);
    controller.attach(client, 'profile', available: true);
    await Future<void>.delayed(Duration.zero);
    final loaded = controller.state;
    controller.attach(client, 'profile', available: false);
    expect(controller.connected, isFalse);
    expect(controller.state, same(loaded));
    controller.attach(client, 'profile', available: true);
    await Future<void>.delayed(Duration.zero);
    expect(controller.state, same(loaded));
    expect(client.openedProfiles, ['profile']);
    controller.dispose();
    await client.stream.close();
  });

  testWidgets(
    'unknown action result reconciles the exact saved copy without a second mutation',
    (tester) async {
      final client = FakePlans()..unknownChange = true;
      final controller = FilePlansController()..attach(client, 'profile');
      await tester.pump();
      await controller.inspector.showCopy(copy);
      expect(
        controller.inspector.copies.any((row) => row.copy == copy),
        isFalse,
      );
      expect(controller.inspector.selected!.copy, copy);
      await tester.pumpWidget(
        MaterialApp(
          theme: mcTheme(Brightness.light),
          home: Scaffold(
            body: ListenableBuilder(
              listenable: controller,
              builder: (context, _) =>
                  FileSourcesInspector(controller: controller, onClose: () {}),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(McAction));
      await tester.pumpAndSettle();
      expect(client.changes, 1);
      expect(controller.needsRead, isTrue);
      expect(controller.inspector.selected!.copy, copy);
      await controller.read();
      await tester.pumpAndSettle();
      expect(controller.needsRead, isFalse);
      expect(controller.inspector.selected!.hidden, isTrue);
      expect(client.changes, 1);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      await client.stream.close();
    },
  );

  test('managed save retries retain the exact publication action', () async {
    final client = FakePlans();
    final controller = FileInspectorController()
      ..attach(client, state('first'));
    await controller.showTarget(copy.path);
    await controller.openTextEditor();
    client.failTextSave = true;
    expect(await controller.saveText('changed\n'), isFalse);
    client.failTextSave = false;
    expect(await controller.saveText('changed\n'), isTrue);
    expect(client.textActions, hasLength(2));
    expect(client.textActions.first, client.textActions.last);
    expect(client.textSnapshots, ['first', 'first']);
    controller.dispose();
    await client.stream.close();
  });

  testWidgets(
    'profile and client switch waits for Save Discard or Keep editing',
    (tester) async {
      final first = FakePlans(),
          second = FakePlans()..current = state('second');
      final plans = FilePlansController()..attach(first, 'first-profile');
      await tester.pump();
      await plans.inspector.showTarget(copy.path);
      await plans.inspector.openTextEditor();
      await tester.pumpWidget(
        MaterialApp(
          theme: mcTheme(Brightness.light),
          home: Scaffold(
            body: FileSourcesInspector(controller: plans, onClose: () {}),
          ),
        ),
      );
      await tester.enterText(
        find.byKey(const ValueKey('text-editor')),
        'stay here\n',
      );

      plans.attach(second, 'second-profile');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Keep editing'));
      await tester.pumpAndSettle();
      expect(find.text('stay here\n'), findsOneWidget);
      expect(second.openedProfiles, isEmpty);
      expect(tester.testTextInput.isVisible, isTrue);

      plans.attach(second, 'second-profile');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Discard').last);
      await tester.pumpAndSettle();
      expect(second.openedProfiles, ['second-profile']);
      expect(plans.inspector.textDocument, isNull);
      await tester.pumpWidget(const SizedBox());
      plans.dispose();
      await first.stream.close();
      await second.stream.close();
    },
  );

  testWidgets('compact drawer dismissal uses the editor navigation guard', (
    tester,
  ) async {
    final client = FakePlans();
    final plans = FilePlansController()..attach(client, 'profile');
    final mods = ModLibraryController();
    await tester.pump();
    await plans.inspector.showTarget(copy.path);
    await plans.inspector.openTextEditor();
    await tester.pumpWidget(
      MaterialApp(
        theme: mcTheme(Brightness.light),
        home: SizedBox(
          width: 800,
          height: 700,
          child: FilePlanningWorkbench(
            mods: mods,
            plans: plans,
            workspacePath: '/workspace',
            chooseDirectory: (_) async => null,
          ),
        ),
      ),
    );
    final scaffold = tester.state<ScaffoldState>(
      find
          .descendant(
            of: find.byType(FilePlanningWorkbench),
            matching: find.byType(Scaffold),
          )
          .first,
    );
    scaffold.openEndDrawer();
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('text-editor')),
      'drawer draft\n',
    );

    scaffold.closeEndDrawer();
    await tester.pumpAndSettle();
    expect(find.text('Save changes?'), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Keep editing'));
    await tester.pumpAndSettle();
    expect(scaffold.isEndDrawerOpen, isTrue);
    expect(find.text('drawer draft\n'), findsOneWidget);
    expect(tester.testTextInput.isVisible, isTrue);

    scaffold.closeEndDrawer();
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Discard').last);
    await tester.pumpAndSettle();
    expect(scaffold.isEndDrawerOpen, isFalse);
    expect(plans.inspector.textDocument, isNull);
    await tester.pumpWidget(const SizedBox());
    plans.dispose();
    mods.dispose();
    await client.stream.close();
  });

  testWidgets('a stale save blocks a dirty inspected-target switch', (
    tester,
  ) async {
    final client = FakePlans()..failTextSave = true;
    final plans = FilePlansController()..attach(client, 'profile');
    await tester.pump();
    final controller = plans.inspector;
    await controller.showTarget(copy.path);
    await controller.openTextEditor();
    await tester.pumpWidget(
      MaterialApp(
        theme: mcTheme(Brightness.light),
        home: Scaffold(
          body: FileSourcesInspector(controller: plans, onClose: () {}),
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const ValueKey('text-editor')),
      'changed\n',
    );
    final switchTarget = controller.showTarget(['other.ini']);
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(FilledButton, 'Save as new mod version').last,
    );
    await tester.pumpAndSettle();
    await switchTarget;
    expect(controller.target, copy.path);
    expect(find.text('changed\n'), findsOneWidget);
    expect(tester.testTextInput.isVisible, isTrue);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Discard'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Discard').last);
    await tester.pumpAndSettle();
    expect(client.abandonedTextActions, [client.textActions.single]);
    await tester.pumpWidget(const SizedBox());
    plans.dispose();
    await client.stream.close();
  });

  testWidgets('late filter pages cannot replace a newer query projection', (
    tester,
  ) async {
    final client = FakePlans();
    final delayed = Completer<FilePlanPage>();
    client.page = (id, parent, filter, cursor) async => filter.isEmpty
        ? delayed.future
        : FilePlanPage(client.current, [
            node(['new.txt']),
          ], null);
    final tree = PlannedFilesController()..attach(client, client.current);
    tree.search('new');
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump();
    delayed.complete(
      FilePlanPage(client.current, [
        node(['old.txt']),
      ], null),
    );
    await tester.pump();
    expect(tree.model.visible.map((id) => tree.model[id]!.path.last), [
      'new.txt',
    ]);
    expect(tree.filter, 'new');
    tree.dispose();
    await client.stream.close();
  });

  testWidgets(
    'a replacement snapshot keeps its completed filtered page after the previous debounce deadline',
    (tester) async {
      final client = FakePlans();
      final queries = <(String, String)>[];
      client.page = (id, parent, filter, cursor) async {
        queries.add((id, filter));
        return FilePlanPage(state(id), [
          node(['$id.txt']),
        ], null);
      };
      final tree = PlannedFilesController()..attach(client, state('first'));
      await tester.pump();
      tree.search('second');
      await tester.pump(const Duration(milliseconds: 50));
      tree.attach(client, state('second'));
      await tester.pump();
      tree.model.select(filePathId(['second.txt']));
      await tester.pump(const Duration(milliseconds: 250));
      expect(tree.model.visible.map((id) => tree.model[id]!.path.last), [
        'second.txt',
      ]);
      expect(tree.model.selectedId, filePathId(['second.txt']));
      expect(tree.model.focusedId, filePathId(['second.txt']));
      expect(tree.filter, 'second');
      expect(queries.where((query) => query.$1 == 'second'), [
        ('second', 'second'),
      ]);
      tree.dispose();
      await client.stream.close();
    },
  );

  testWidgets(
    'visibility delta preserves expanded branch selection and its next page cursor',
    (tester) async {
      final client = FakePlans();
      final requests = <(String, FilePlanCursor?)>[];
      client.page = (id, parent, filter, cursor) async {
        if (parent == null) {
          return FilePlanPage(client.current, [
            node(['textures'], folder: true),
          ], null);
        }
        requests.add((id, cursor));
        return cursor == null
            ? FilePlanPage(client.current, [
                node(['textures', 'first.txt']),
              ], const FilePlanCursor('branch-lineage', 1))
            : FilePlanPage(client.current, [
                node(['textures', 'second.txt']),
              ], null);
      };
      final tree = PlannedFilesController()..attach(client, client.current);
      await tester.pump();
      tree.model.toggle(filePathId(['textures']));
      await tester.pump();
      tree.model.select(filePathId(['textures', 'first.txt']));
      final selected = tree.model.selectedId;
      client.current = state('changed');
      tree.attach(
        client,
        client.current,
        preserve: true,
        changed: node(['textures', 'first.txt'], source: 'Game folder'),
      );
      await tree.loadMore();
      expect(requests.last.$1, 'changed');
      expect(requests.last.$2!.identity, 'branch-lineage');
      expect(tree.model.selectedId, selected);
      expect(tree.model.focusedId, selected);
      expect(tree.model.expanded(filePathId(['textures'])), isTrue);
      expect(tree.model.visible.map((id) => tree.model[id]!.path.last), [
        'textures',
        'first.txt',
        'second.txt',
      ]);
      tree.dispose();
      await client.stream.close();
    },
  );
}

class _DelayedPreviewPlans extends FakePlans {
  final requests = <Completer<FilePreviewResult>>[];
  final cancelled = <int>[];

  @override
  FilePreviewRead preview(
    String snapshotId,
    FilePreviewSource source,
    FilePreviewRepresentation representation,
  ) {
    final index = requests.length;
    final request = Completer<FilePreviewResult>();
    requests.add(request);
    return FilePreviewRead(request.future, () async => cancelled.add(index));
  }
}

void previewSupersessionTests() {
  test('a superseded preview is cancelled and cannot overwrite the current source representation', () async {
    final client = _DelayedPreviewPlans();
    final controller = FileInspectorController();
    controller.attach(client, state('first'));
    await controller.showTarget(copy.path);
    await Future<void>.delayed(Duration.zero);
    expect(client.requests, hasLength(1));

    controller.setPreviewRepresentation(FilePreviewRepresentation.text);
    await Future<void>.delayed(Duration.zero);
    expect(client.cancelled, [0]);
    expect(client.requests, hasLength(2));

    final source = controller.selected!.source;
    client.requests[1].complete(
      FilePreviewResult(
        source: source,
        standing: FileSourceStanding.winner,
        target: source.target,
        status: FilePreviewStatus.ready,
        content: const FilePreviewText('new', 'UTF-8', 1),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    client.requests[0].complete(
      FilePreviewResult(
        source: source,
        standing: FileSourceStanding.winner,
        target: source.target,
        status: FilePreviewStatus.ready,
        content: FilePreviewHex(Uint8List.fromList([1, 2]), 2, false),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect((controller.preview!.content as FilePreviewText).content, 'new');
    controller.dispose();
  });
}
