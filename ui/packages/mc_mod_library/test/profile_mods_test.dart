import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_mod_library/mc_mod_library.dart';

import 'controller_test.dart' show mod, settle, LibraryClient;
import 'organization_fakes.dart';

OrganizedMod row(String id, int priority, {bool enabled = false}) =>
    OrganizedMod(
      ProfileMod(mod(id), ManagedProfileMod(id, priority, enabled)),
      null,
    );

class ProfileClient extends Fake implements ProfileModsClient {
  late Future<ProfileModsDelta> Function(int, List<String>, ProfileModMove)
  onMove;
  @override
  Future<ProfileModsDelta> move(
    String profile,
    int revision,
    Iterable<String> ids,
    ProfileModMove direction,
  ) => onMove(revision, ids.toList(), direction);
}

class AddingLibrary extends LibraryClient {
  String? added;
  int registrations = 0;
  @override
  Future<ModEntry> register(
    String workspace,
    String id,
    ModMetadata metadata,
    ModRegistration registration,
  ) async {
    registrations++;
    added = id;
    return mod(id);
  }
}

void main() {
  test('a completed retry clears a local busy fault', () async {
    final client = ProfileClient();
    final queries = QueryClient()
      ..onQuery = (_, _, _, _) async => queryPage([row('a', 0)]);
    final state = ProfileModsController();
    addTearDown(state.dispose);
    state.attach(client, queries, 'workspace', 'profile');
    await settle();
    state.model.select((modId: 'a'));

    client.onMove = (_, _, _) async => throw const LibraryException(
      LibraryFault.busy,
      'A library change is still in progress.',
    );
    await state.move(ProfileModMove.up);
    expect(state.problem, 'A library change is still in progress.');
    expect(state.stale, isFalse);

    await state.load(refresh: true);
    expect(state.problem, isNull);

    client.onMove = (_, _, _) async =>
        const ProfileModsDelta(1, [ManagedProfileMod('a', 0, false)], 0);
    queries.onQuery = (_, _, _, _) async =>
        queryPage([row('a', 0)], revision: 1);
    await state.move(ProfileModMove.up);
    expect(state.problem, isNull);
    expect(state.stale, isFalse);
  });

  test('one coherent move and query retain hidden selection and reject a superseded page', () async {
    final client = ProfileClient();
    final queries = QueryClient()
      ..onQuery = (_, _, _, _) async => queryPage(
        [row('a', 0), row('b', 1), row('c', 2)],
        revision: 4,
        nextOffset: 3,
        total: 4,
      );
    final state = ProfileModsController();
    addTearDown(state.dispose);
    state.attach(client, queries, 'workspace', 'profile');
    await settle();
    state.model.select((modId: 'b'));
    state.model.select((modId: 'c'), toggle: true);
    queries.onQuery = (_, _, _, _) async =>
        queryPage([row('c', 2)], revision: 4, nextOffset: 1, total: 1);
    state.setQuery(const ModQuery(text: 'Mod c'));
    await settle();
    final pending = Completer<ModQueryPage>();
    queries.onQuery = (_, _, cursor, _) {
      expect(cursor!.selectionRevision, 4);
      return pending.future;
    };
    final oldPage = state.load();
    final revisions = <int?>[];
    state.addListener(() => revisions.add(state.revision));
    client.onMove = (revision, ids, direction) async {
      expect(revision, 4);
      expect(ids, unorderedEquals(['b', 'c']));
      expect(direction, ProfileModMove.up);
      return const ProfileModsDelta(5, [
        ManagedProfileMod('a', 2, false),
        ManagedProfileMod('b', 0, false),
        ManagedProfileMod('c', 1, false),
      ], 0);
    };
    queries.onQuery = (_, query, cursor, inspected) async {
      expect(query.text, 'Mod c');
      expect(cursor, isNull);
      expect(inspected, 'c');
      return queryPage([row('c', 1)], revision: 5, total: 1);
    };
    await state.move(ProfileModMove.up);
    expect(revisions.where((value) => value == 5).length, 1);
    expect(state.model[(modId: 'b')]!.selection.priority, 0);
    expect(state.model.selectedIds, {(modId: 'b'), (modId: 'c')});
    expect(state.model.focusedId, (modId: 'c'));
    expect(state.hiddenSelected, 1);
    pending.complete(queryPage([row('d', 3)], revision: 4));
    await oldPage;
    expect(state.model[(modId: 'd')], isNull);
    expect(state.revision, 5);
    queries.onQuery = (_, _, _, _) async => queryPage([
      row('b', 0),
      row('c', 1),
      row('a', 2),
      row('d', 3),
    ], revision: 5);
    state.setQuery(const ModQuery());
    await settle();
    expect(state.model.visible, [
      (modId: 'b'),
      (modId: 'c'),
      (modId: 'a'),
      (modId: 'd'),
    ]);
    state.sort('Name');
    await settle();
    expect(state.canMove, isFalse);
    expect(state.revision, 5);
    state.showPriority();
    await settle();
    expect(state.canMove, isTrue);
  });

  test('failed joined detail query preserves known revision selection and focus until coherent recovery', () async {
    final client = ProfileClient();
    final queries = QueryClient()
      ..onQuery = (_, _, _, _) async =>
          queryPage([row('a', 0), row('z', 1)], revision: 1);
    final state = ProfileModsController();
    addTearDown(state.dispose);
    state.attach(client, queries, 'workspace', 'profile');
    await settle();
    state.model.select((modId: 'z'));
    client.onMove = (_, _, _) async =>
        throw const LibraryException(LibraryFault.staleRevision, 'stale');
    await state.move(ProfileModMove.up);
    expect(state.stale, isTrue);
    expect(state.revision, 1);
    expect(state.canMove, isFalse);
    queries.onQuery = (_, _, _, inspected) async {
      expect(inspected, 'z');
      throw Exception('joined read lost');
    };
    await state.load(refresh: true);
    expect(state.revision, 1);
    expect(state.model[(modId: 'a')]!.selection.priority, 0);
    expect(state.model.selectedId, (modId: 'z'));
    queries.onQuery = (_, _, _, _) async => queryPage(
      [row('a', 1)],
      revision: 2,
      inspected: row('z', 0),
      nextOffset: 1,
      total: 2,
    );
    await state.load(refresh: true);
    expect(state.revision, 2);
    expect(state.stale, isFalse);
    expect(state.model.selectedIds, {(modId: 'z')});
    expect(state.model.focusedId, (modId: 'z'));
    expect(state.model[(modId: 'a')]!.selection.priority, 1);
    expect(state.model.position((modId: 'z')), isNull);
  });

  test('committed addition outside first page remains recoverable after failed joined reload', () async {
    final library = AddingLibrary(), queries = QueryClient();
    final client = ProfileClient();
    final rows = [for (var i = 0; i < 32; i++) row('existing-$i', i)];
    queries.onQuery = (_, _, _, _) async =>
        queryPage(rows, nextOffset: 32, total: 32);
    final controller = ModLibraryController();
    addTearDown(controller.dispose);
    controller.attach(
      library,
      client,
      organizationClient: queries,
      workspaceId: 'workspace',
      profileId: 'profile',
      editable: true,
    );
    await settle();
    controller.mods.select((modId: 'existing-0'));
    queries.onQuery = (_, _, _, _) async =>
        throw Exception('reload unavailable');
    await controller.addFolder(
      const ModMetadata(name: 'Added'),
      '/workspace/new',
    );
    expect(library.registrations, 1);
    expect(library.added, isNotNull);
    expect(controller.actionProblem, isNotNull);
    expect(controller.mods.selectedId, (modId: 'existing-0'));
    expect(controller.mods.length, 32);
    queries.onQuery = (_, _, _, inspected) async {
      expect(inspected, library.added);
      return queryPage(
        rows,
        revision: 1,
        nextOffset: 32,
        total: 33,
        inspected: row(library.added!, 32),
      );
    };
    await controller.inventory.load(refresh: true);
    expect(library.registrations, 1);
    expect(controller.actionProblem, isNull);
    expect(controller.mods.selectedId, (modId: library.added!));
    expect(controller.mods.selected!.selection.priority, 32);
    expect(controller.inventory.revision, 1);
    expect(controller.mods.length, 33);
    expect(controller.inventory.loaded, 32);
    expect(controller.mods.position((modId: library.added!)), isNull);
  });
  test('late text and sort queries cannot replace the active projection or clear its selected identity', () async {
    final queries = QueryClient()
      ..onQuery = (_, _, _, _) async => queryPage([row('a', 0), row('b', 1)]);
    final state = ProfileModsController();
    addTearDown(state.dispose);
    state.attach(ProfileClient(), queries, 'workspace', 'profile');
    await settle();
    state.model.select((modId: 'b'));
    final old = Completer<ModQueryPage>();
    queries.onQuery = (_, query, _, _) => query.text == 'first'
        ? old.future
        : Future.value(queryPage([row('b', 1)], inspected: row('b', 1)));
    state.setQuery(const ModQuery(text: 'first'));
    state.setQuery(const ModQuery(text: 'second', sort: OrganizationSort.name));
    await settle();
    old.complete(queryPage([row('a', 0)]));
    await settle();
    expect(state.query.text, 'second');
    expect(state.query.sort, OrganizationSort.name);
    expect(state.model.visible, [(modId: 'b')]);
    expect(state.model.selectedId, (modId: 'b'));
    expect(state.canMove, isFalse);
  });
}
