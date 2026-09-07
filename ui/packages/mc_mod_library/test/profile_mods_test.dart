import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_mod_library/mc_mod_library.dart';

import 'controller_test.dart' show mod, settle, LibraryClient;

ProfileMod row(String id, int priority, {bool enabled = false}) =>
    ProfileMod(mod(id), ManagedProfileMod(id, priority, enabled));

class ProfileClient extends Fake implements ProfileModsClient {
  late Future<ProfileModsPage> Function(String?, int?) onRead;
  Future<ProfileModDetail> Function(String, int?)? onFind;
  Future<ProfileModsDelta> Function(int, List<String>, ProfileModMove)? onMove;
  @override
  Future<ProfileModsPage> read(
    String profile, {
    String? afterModId,
    int? expectedRevision,
  }) => onRead(afterModId, expectedRevision);
  @override
  Future<ProfileModDetail> find(
    String profile,
    String modId, {
    int? expectedRevision,
  }) => onFind!(modId, expectedRevision);
  @override
  Future<ProfileModsDelta> move(
    String profile,
    int revision,
    Iterable<String> ids,
    ProfileModMove direction,
  ) => onMove!(revision, ids.toList(), direction);
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
  test('one coherent move delta retains hidden selection and rejects a superseded page', () async {
    final client = ProfileClient()
      ..onRead = (_, _) async => ProfileModsPage(
        4,
        [row('a', 0), row('b', 1), row('c', 2)],
        'c',
        4,
        0,
      );
    final state = ProfileModsController();
    addTearDown(state.dispose);
    state.attach(client, 'workspace', 'profile');
    await settle();
    state.model.select((modId: 'b'));
    state.model.select((modId: 'c'), toggle: true);
    state.model.filter('Mod c');
    final pending = Completer<ProfileModsPage>();
    client.onRead = (cursor, revision) {
      expect(cursor, 'c');
      expect(revision, 4);
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
    await state.move(ProfileModMove.up);
    expect(revisions.where((v) => v == 5).length, 1);
    expect(state.model[(modId: 'a')]!.selection.priority, 2);
    expect(state.model.selectedIds, {(modId: 'b'), (modId: 'c')});
    expect(state.model.focusedId, (modId: 'c'));
    expect(state.hiddenSelected, 1);
    pending.complete(ProfileModsPage(4, [row('d', 3)], null, 4, 0));
    await oldPage;
    expect(state.model[(modId: 'd')], isNull);
    expect(state.revision, 5);
    client.onRead = (cursor, revision) async {
      expect(cursor, 'c');
      expect(revision, 5);
      return ProfileModsPage(5, [row('d', 3)], null, 4, 0);
    };
    await state.load();
    expect(state.complete, isTrue);
    state.model.filter('');
    expect(state.model.visible, [
      (modId: 'b'),
      (modId: 'c'),
      (modId: 'a'),
      (modId: 'd'),
    ]);
    state.model.sort(
      (a, b) => a.mod.metadata.name.compareTo(b.mod.metadata.name),
      label: 'Name',
    );
    expect(state.canMove, isFalse);
    expect(state.revision, 5);
    state.showPriority();
    expect(state.canMove, isTrue);
  });

  test(
    'failed exact-row reload preserves the known revision and selected IDs',
    () async {
      final client = ProfileClient()
        ..onRead = (_, _) async =>
            ProfileModsPage(1, [row('a', 0), row('z', 1)], null, 2, 0);
      final state = ProfileModsController();
      addTearDown(state.dispose);
      state.attach(client, 'workspace', 'profile');
      await settle();
      state.model.select((modId: 'z'));
      client.onMove = (_, _, _) async =>
          throw const LibraryException(LibraryFault.staleRevision, 'stale');
      await state.move(ProfileModMove.up);
      expect(state.stale, isTrue);
      expect(state.revision, 1);
      expect(state.canMove, isFalse);
      client.onRead = (_, _) async =>
          ProfileModsPage(2, [row('a', 1)], 'a', 2, 0);
      client.onFind = (id, revision) async {
        expect(id, 'z');
        expect(revision, 2);
        throw Exception('read lost');
      };
      await state.load(refresh: true);
      expect(state.revision, 1);
      expect(state.model[(modId: 'a')]!.selection.priority, 0);
      expect(state.model.selectedId, (modId: 'z'));
      client.onFind = (id, revision) async => ProfileModDetail(2, row('z', 0));
      await state.load(refresh: true);
      expect(state.revision, 2);
      expect(state.stale, isFalse);
      expect(state.model.selectedIds, {(modId: 'z')});
      expect(state.model.focusedId, (modId: 'z'));
      expect(state.model[(modId: 'a')]!.selection.priority, 1);
    },
  );

  test('committed addition outside the first page stays recoverable after a failed joined reload', () async {
    final library = AddingLibrary();
    final client = ProfileClient();
    final page = [for (var i = 0; i < 32; i++) row('existing-$i', i)];
    client.onRead = (_, _) async => ProfileModsPage(
      library.added == null ? 0 : 1,
      page,
      'existing-31',
      library.added == null ? 32 : 33,
      0,
    );
    final controller = ModLibraryController();
    addTearDown(controller.dispose);
    controller.attach(
      library,
      client,
      workspaceId: 'workspace',
      profileId: 'profile',
      editable: true,
    );
    await settle();
    controller.mods.select((modId: 'existing-0'));
    client.onFind = (_, _) async => throw Exception('reload unavailable');
    await controller.addFolder(
      const ModMetadata(name: 'Added'),
      '/workspace/new',
    );
    expect(library.registrations, 1);
    expect(library.added, isNotNull);
    expect(controller.actionProblem, isNotNull);
    expect(controller.mods.selectedId, (modId: 'existing-0'));
    expect(controller.mods.length, 32);
    client.onFind = (id, revision) async {
      expect(id, library.added);
      expect(revision, 1);
      return ProfileModDetail(1, row(id, 32));
    };
    await controller.inventory.load(refresh: true);
    expect(library.registrations, 1);
    expect(controller.actionProblem, isNull);
    expect(controller.mods.selectedId, (modId: library.added!));
    expect(controller.mods.selected!.selection.priority, 32);
    expect(controller.inventory.revision, 1);
    expect(controller.mods.length, 33);
  });
}
