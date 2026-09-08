import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_file_plans/mc_file_plans.dart';
import 'package:mc_file_plans/src/inspector.dart';
import 'package:mc_file_plans/src/planned_files_controller.dart';
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
    );

class FakePlans implements FilePlansClient {
  FilePlanState current = state('first');
  bool hidden = false, unknownChange = false;
  int changes = 0;
  final openedProfiles = <String>[];
  final stream = StreamController<FilePlanLoadEvent>.broadcast();
  Future<FilePlanPage> Function(String, List<String>?, String, FilePlanCursor?)?
  page;
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
