import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_mod_library/mc_mod_library.dart';

import 'organization_fakes.dart';
export 'organization_fakes.dart';

ModEntry mod(
  String id, {
  int revision = 0,
  String workspace = 'workspace',
  String? version,
}) => ModEntry(
  id: id,
  workspaceId: workspace,
  kind: ModKind.regular,
  metadata: ModMetadata(name: 'Mod $id'),
  revision: revision,
  status: InventoryStatus.ready,
  actions: [ModAction.editMetadata, ModAction.publish],
  currentVersionId: version,
);
ManifestEntry file(String name) =>
    ManifestEntry([name], ModPayload(name, 5, 'hash'));

class LibraryClient extends Fake implements ModLibraryClient {
  Future<ModQueryPage> Function(String, ModQueryCursor?)? onQuery;
  Future<ModVersionPage> Function(String, int)? onVersion;
  Future<ModEntry> Function(String, int, ModMetadata)? onEdit;
  @override
  Future<ModVersionPage> version(String id, {int offset = 0}) =>
      onVersion!(id, offset);
  @override
  Future<ModEntry> edit(String id, int revision, ModMetadata metadata) =>
      onEdit!(id, revision, metadata);
}

QueryClient organization(LibraryClient library) =>
    QueryClient()
      ..onQuery = (profile, query, cursor, inspected) =>
          library.onQuery!(profile, cursor);
ModQueryPage inventoryPage(List<ModEntry> values, int? next) => queryPage([
  for (final (index, value) in values.indexed)
    OrganizedMod(
      ProfileMod(value, ManagedProfileMod(value.id, index, false)),
      null,
    ),
], nextOffset: next);

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  test('cancelled and old-scope pages cannot replace current rows or resume a cancelled continuation', () async {
    final delayed = Completer<ModQueryPage>();
    final client = LibraryClient()..onQuery = (_, _) => delayed.future;
    final controller = ModLibraryController();
    addTearDown(controller.dispose);
    controller.attach(
      client,
      SelectionClient(),
      organizationClient: organization(client),
      workspaceId: 'workspace',
      profileId: 'one',
      editable: true,
    );
    controller.inventory.cancel();
    client.onQuery = (_, _) async => inventoryPage([mod('new')], null);
    await controller.inventory.load();
    delayed.complete(inventoryPage([mod('stale')], 1));
    await settle();
    expect(controller.mods.ids, [(modId: 'new')]);
    expect(controller.inventory.complete, isTrue);
    final previous = Completer<ModQueryPage>();
    client.onQuery = (_, _) => previous.future;
    final request = controller.inventory.load(refresh: true);
    client.onQuery = (_, _) async =>
        inventoryPage([mod('other', workspace: 'other')], null);
    controller.attach(
      client,
      SelectionClient(),
      organizationClient: organization(client),
      workspaceId: 'other',
      profileId: 'two',
      editable: true,
    );
    await settle();
    previous.complete(inventoryPage([mod('late')], null));
    await request;
    expect(controller.mods.ids, [(modId: 'other')]);
  });

  test('later inventory failure retains partial rows and stale per-mod revisions cannot overwrite a completed edit', () async {
    final client = LibraryClient()
      ..onQuery = (_, _) async => inventoryPage([mod('a')], 1);
    final controller = ModLibraryController();
    addTearDown(controller.dispose);
    controller.attach(
      client,
      SelectionClient(),
      organizationClient: organization(client),
      workspaceId: 'workspace',
      profileId: 'one',
      editable: true,
    );
    await settle();
    controller.select(controller.mods[(modId: 'a')]!.entry);
    client.onEdit = (_, _, _) async => mod('a', revision: 2);
    await controller.edit(
      controller.selected!,
      const ModMetadata(name: 'Updated'),
    );
    client.onQuery = (_, _) async => throw Exception('transport');
    await controller.inventory.load();
    expect(controller.inventory.problem, isNotNull);
    expect(controller.inventory.complete, isFalse);
    expect(controller.selected!.revision, 2);
    client.onQuery = (_, cursor) async {
      expect(cursor, isNull);
      return inventoryPage([mod('a', revision: 1), mod('b')], null);
    };
    await controller.inventory.load();
    expect(controller.selected!.revision, 2);
    expect(controller.inventory.stale, isTrue);
    client.onQuery = (_, _) async =>
        inventoryPage([mod('a', revision: 2), mod('b')], null);
    await controller.inventory.load(refresh: true);
    expect(controller.mods.length, 2);
    expect(controller.inventory.complete, isTrue);
  });

  test('saved-file pages remain pinned through inventory updates and cancelled replies cannot cross mod selection', () async {
    final client = LibraryClient()
      ..onQuery = (_, _) async => inventoryPage([
        mod('a', version: 'version-a'),
        mod('b', version: 'version-b'),
      ], null);
    final pending = Completer<ModVersionPage>();
    client.onVersion = (_, _) => pending.future;
    final controller = ModLibraryController();
    addTearDown(controller.dispose);
    controller.attach(
      client,
      SelectionClient(),
      organizationClient: organization(client),
      workspaceId: 'workspace',
      profileId: 'one',
      editable: true,
    );
    await settle();
    controller.mods.select((modId: 'a'));
    controller.select(controller.mods.selected!.entry);
    controller.cancelFiles();
    client.onVersion = (id, offset) async =>
        ModVersionPage(id, 'a', [file('first')], 1);
    await controller.loadFiles();
    pending.complete(
      ModVersionPage('version-a', 'a', [file('cancelled')], null),
    );
    await settle();
    expect(controller.fileCount, 1);
    expect(controller.filesComplete, isFalse);
    final oldVersion = Completer<ModVersionPage>();
    client.onVersion = (_, _) => oldVersion.future;
    final loading = controller.loadFiles();
    client.onQuery = (_, _) async => inventoryPage([
      mod('a', revision: 1, version: 'new-version'),
      mod('b', version: 'version-b'),
    ], null);
    await controller.inventory.load(refresh: true);
    expect(controller.selectedVersionId, 'version-a');
    client.onVersion = (id, _) async =>
        ModVersionPage(id, 'b', [file('other')], null);
    controller.mods.select((modId: 'b'));
    controller.select(controller.mods.selected!.entry);
    await settle();
    oldVersion.complete(ModVersionPage('version-a', 'a', [file('late')], null));
    await loading;
    expect(controller.selectedVersionId, 'version-b');
    expect(controller.fileCount, 1);
    expect(controller.filesComplete, isTrue);
    expect(
      controller.files.ids.every((id) => id.versionId == 'version-b'),
      isTrue,
    );
  });
}
