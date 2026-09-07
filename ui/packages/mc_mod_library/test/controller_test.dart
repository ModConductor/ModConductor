import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_mod_library/mc_mod_library.dart';

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
  Future<InventoryPage> Function(String, String?)? onInventory;
  Future<ModVersionPage> Function(String, int)? onVersion;
  Future<ModEntry> Function(String, int, ModMetadata)? onEdit;
  @override
  Future<InventoryPage> inventory(String profile, {String? afterModId}) =>
      onInventory!(profile, afterModId);
  @override
  Future<ModVersionPage> version(String id, {int offset = 0}) =>
      onVersion!(id, offset);
  @override
  Future<ModEntry> edit(String id, int revision, ModMetadata metadata) =>
      onEdit!(id, revision, metadata);
}

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  test('cancelled and old-scope pages cannot replace current rows or resume a cancelled continuation', () async {
    final delayed = Completer<InventoryPage>();
    final client = LibraryClient()..onInventory = (_, _) => delayed.future;
    final controller = ModLibraryController();
    addTearDown(controller.dispose);
    controller.attach(
      client,
      workspaceId: 'workspace',
      profileId: 'one',
      editable: true,
    );
    controller.cancelMods();
    client.onInventory = (_, _) async => InventoryPage([mod('new')], null);
    await controller.loadMods();
    delayed.complete(InventoryPage([mod('stale')], 'cursor'));
    await settle();
    expect(controller.mods.ids, [(modId: 'new')]);
    expect(controller.modsComplete, isTrue);
    final previous = Completer<InventoryPage>();
    client.onInventory = (_, _) => previous.future;
    final request = controller.loadMods(refresh: true);
    client.onInventory = (_, _) async =>
        InventoryPage([mod('other', workspace: 'other')], null);
    controller.attach(
      client,
      workspaceId: 'other',
      profileId: 'two',
      editable: true,
    );
    await settle();
    previous.complete(InventoryPage([mod('late')], null));
    await request;
    expect(controller.mods.ids, [(modId: 'other')]);
  });

  test('later inventory failure retains partial rows and stale per-mod revisions cannot overwrite a completed edit', () async {
    final client = LibraryClient()
      ..onInventory = (_, _) async => InventoryPage([mod('a')], 'a');
    final controller = ModLibraryController();
    addTearDown(controller.dispose);
    controller.attach(
      client,
      workspaceId: 'workspace',
      profileId: 'one',
      editable: true,
    );
    await settle();
    controller.select(controller.mods[(modId: 'a')]!);
    client.onEdit = (_, _, _) async => mod('a', revision: 2);
    await controller.edit(
      controller.mods.selected!,
      const ModMetadata(name: 'Updated'),
    );
    client.onInventory = (_, _) async => throw Exception('transport');
    await controller.loadMods();
    expect(controller.modProblem, isNotNull);
    expect(controller.modsComplete, isFalse);
    expect(controller.mods.selected!.revision, 2);
    client.onInventory = (_, cursor) async {
      expect(cursor, 'a');
      return InventoryPage([mod('a', revision: 1), mod('b')], null);
    };
    await controller.loadMods();
    expect(controller.mods.selected!.revision, 2);
    expect(controller.mods.length, 2);
    expect(controller.modsComplete, isTrue);
  });

  test('saved-file pages remain pinned through inventory updates and cancelled replies cannot cross mod selection', () async {
    final client = LibraryClient()
      ..onInventory = (_, _) async => InventoryPage([
        mod('a', version: 'version-a'),
        mod('b', version: 'version-b'),
      ], null);
    final pending = Completer<ModVersionPage>();
    client.onVersion = (_, _) => pending.future;
    final controller = ModLibraryController();
    addTearDown(controller.dispose);
    controller.attach(
      client,
      workspaceId: 'workspace',
      profileId: 'one',
      editable: true,
    );
    await settle();
    controller.mods.select((modId: 'a'));
    controller.select(controller.mods.selected!);
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
    client.onInventory = (_, _) async =>
        InventoryPage([mod('a', revision: 1, version: 'new-version')], null);
    await controller.loadMods(refresh: true);
    expect(controller.selectedVersionId, 'version-a');
    client.onVersion = (id, _) async =>
        ModVersionPage(id, 'b', [file('other')], null);
    controller.mods.select((modId: 'b'));
    controller.select(controller.mods.selected!);
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
