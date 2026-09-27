import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_mod_library/mc_mod_library.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

class _Nexus extends Fake implements NexusClient {
  bool unavailable = false;
  bool tracked = true;
  int searches = 0;
  final pages = <int>[];
  final feeds = <String>[];

  @override
  Future<List<NexusDiscoveryMod>> discovery(
    String workspace,
    String profile,
    String feed,
  ) async {
    expectSync((workspace, profile), ('workspace', 'profile'));
    feeds.add(feed);
    if (unavailable) throw const NexusProblem('not_found', 'Feed unavailable');
    if (feed == 'tracked' && !tracked) return [];
    return [
      NexusDiscoveryMod(
        64012,
        'Quiet Rivers',
        'River textures',
        'Rowan',
        'Visuals',
        null,
      ),
    ];
  }

  @override
  Future<void> openSearch(String workspace, String profile) async {
    expectSync((workspace, profile), ('workspace', 'profile'));
    searches++;
  }

  @override
  Future<void> openPage(String workspace, String profile, int modId) async {
    expectSync((workspace, profile), ('workspace', 'profile'));
    pages.add(modId);
  }

  @override
  Future<NexusMod> mod(String workspace, String profile, int id) async =>
      const NexusMod(
        64012,
        'Quiet Rivers',
        'River textures',
        [],
        author: 'Rowan',
        category: 'Visuals',
      );
}

class _Organization extends Fake implements ModOrganizationClient {
  bool installed = false;

  @override
  Future<ModQueryPage> query(
    String profileId,
    ModQuery query, {
    ModQueryCursor? cursor,
    String? inspectedId,
  }) async {
    expectSync(profileId, 'profile');
    expectSync(cursor, isNull);
    final mod = ModEntry(
      id: 'local',
      workspaceId: 'workspace',
      kind: ModKind.regular,
      metadata: const ModMetadata(name: 'Quiet Rivers'),
      revision: 1,
      status: InventoryStatus.ready,
      actions: const [],
    );
    return ModQueryPage(
      catalogueRevision: 1,
      selectionRevision: 1,
      queryIdentity: 'local',
      entries: installed
          ? [
              OrganizedMod(
                ProfileMod(mod, const ManagedProfileMod('local', 0, true)),
                null,
              ),
            ]
          : [],
      context: const [],
      inspected: null,
      next: null,
      matchingMods: installed ? 1 : 0,
      matchingSeparators: 0,
      totalMods: installed ? 1 : 0,
      enabledCount: installed ? 1 : 0,
    );
  }
}

class _Inventory extends ProfileModsController {
  void changed() {
    catalogueRevision = (catalogueRevision ?? 0) + 1;
    notifyListeners();
  }
}

class _Metadata extends Fake implements NexusMetadataClient {
  bool cachedUpdate = true;
  bool remoteUpdate = true;
  bool refreshFails = false;
  int refreshes = 0;

  @override
  Future<ModNexusDetails> read(
    String workspace,
    String profile,
    String mod,
  ) async {
    expectSync((workspace, profile, mod), ('workspace', 'profile', 'local'));
    return _details(cachedUpdate);
  }

  @override
  Future<ModNexusDetails> refresh(ModNexusReference reference) async {
    expectSync((reference.workspace, reference.mod), ('workspace', 'local'));
    refreshes++;
    if (refreshFails) throw const NexusProblem('offline', 'Nexus is offline');
    cachedUpdate = remoteUpdate;
    return _details(cachedUpdate);
  }

  ModNexusDetails _details(bool update) {
    return ModNexusDetails(
      const ModNexusReference('workspace', 'local', 1, 'version', 64012, 1),
      'Quiet Rivers',
      501,
      '1.0',
      false,
      NexusPublicMetadata(
        'Quiet Rivers',
        'River textures',
        '1.1',
        'Rowan',
        'Rowan',
        29,
        'Visuals',
        null,
        true,
        true,
        [
          NexusMetadataFile(
            const NexusFile(502, 'Update.7z', '1.1', 'Main files', '', null),
            1,
            null,
            update,
          ),
        ],
      ),
      'current',
      null,
      '',
      null,
      '',
    );
  }
}

Future<void> _show(
  WidgetTester tester,
  _Nexus nexus,
  _Organization organization,
  List<int> viewed,
  _Metadata metadata,
  _Inventory inventory,
  ValueNotifier<int> trackedChanges, {
  bool active = true,
  Listenable? localChanges,
}) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: mcTheme(Brightness.dark),
      home: Scaffold(
        body: NexusDiscoveryBrowser(
          workspace: 'workspace',
          profile: 'profile',
          nexus: nexus,
          organization: organization,
          metadata: metadata,
          inventory: inventory,
          trackedChanges: trackedChanges,
          localChanges: localChanges ?? trackedChanges,
          active: active,
          onViewFiles: viewed.add,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('feed cards use the file route and browser handoffs', (
    tester,
  ) async {
    final nexus = _Nexus();
    final viewed = <int>[];
    final inventory = _Inventory();
    final trackedChanges = ValueNotifier(0);
    addTearDown(inventory.dispose);
    addTearDown(trackedChanges.dispose);
    await _show(
      tester,
      nexus,
      _Organization(),
      viewed,
      _Metadata(),
      inventory,
      trackedChanges,
    );

    await tester.tap(find.text('Search Nexus in browser'));
    await tester.pump();
    expect(nexus.searches, 1);

    await tester.tap(find.text('View files'));
    await tester.pump();
    expect(viewed, [64012]);

    await tester.tap(find.text('Open mod page'));
    await tester.pump();
    expect(nexus.pages, [64012]);

    await tester.tap(find.text('Latest added'));
    await tester.pumpAndSettle();
    expect(nexus.feeds, containsAll(['trending', 'latest_added']));
  });

  testWidgets('unavailable feed does not block installed update actions', (
    tester,
  ) async {
    final nexus = _Nexus()..unavailable = true;
    final organization = _Organization()..installed = true;
    final viewed = <int>[];
    final inventory = _Inventory();
    final trackedChanges = ValueNotifier(0);
    addTearDown(inventory.dispose);
    addTearDown(trackedChanges.dispose);
    await _show(
      tester,
      nexus,
      organization,
      viewed,
      _Metadata(),
      inventory,
      trackedChanges,
    );
    expect(find.text('Feed unavailable'), findsOneWidget);

    await tester.tap(find.text('Updates'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View update'));
    await tester.pump();
    expect(viewed, [64012]);
  });

  testWidgets(
    'revisit refreshes remote updates and inventory removal clears cards',
    (tester) async {
      final nexus = _Nexus();
      final organization = _Organization();
      final metadata = _Metadata()
        ..cachedUpdate = false
        ..remoteUpdate = false;
      final inventory = _Inventory();
      final trackedChanges = ValueNotifier(0);
      addTearDown(inventory.dispose);
      addTearDown(trackedChanges.dispose);
      final viewed = <int>[];
      await _show(
        tester,
        nexus,
        organization,
        viewed,
        metadata,
        inventory,
        trackedChanges,
      );
      expect(metadata.refreshes, 0);

      organization.installed = true;
      inventory.changed();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Installed').first);
      await tester.pumpAndSettle();
      expect(find.text('View files'), findsOneWidget);

      await tester.tap(find.text('Updates'));
      await tester.pumpAndSettle();
      expect(metadata.refreshes, 1);
      expect(find.text('View update'), findsNothing);

      metadata.remoteUpdate = true;
      await _show(
        tester,
        nexus,
        organization,
        viewed,
        metadata,
        inventory,
        trackedChanges,
        active: false,
      );
      await _show(
        tester,
        nexus,
        organization,
        viewed,
        metadata,
        inventory,
        trackedChanges,
      );
      expect(metadata.refreshes, 2);
      expect(find.text('View update'), findsOneWidget);

      organization.installed = false;
      inventory.changed();
      await tester.pumpAndSettle();
      expect(find.text('View update'), findsNothing);
      expect(find.text('No mods in this collection.'), findsOneWidget);
    },
  );

  testWidgets('tracked changes replace the mounted collection', (tester) async {
    final nexus = _Nexus()..tracked = false;
    final inventory = _Inventory();
    final trackedChanges = ValueNotifier(0);
    addTearDown(inventory.dispose);
    addTearDown(trackedChanges.dispose);
    await _show(
      tester,
      nexus,
      _Organization(),
      [],
      _Metadata(),
      inventory,
      trackedChanges,
    );
    await tester.tap(find.text('Tracked'));
    await tester.pumpAndSettle();
    expect(find.text('View files'), findsNothing);

    nexus.tracked = true;
    trackedChanges.value++;
    await tester.pumpAndSettle();
    expect(find.text('View files'), findsOneWidget);

    nexus.tracked = false;
    trackedChanges.value++;
    await tester.pumpAndSettle();
    expect(find.text('View files'), findsNothing);
  });

  testWidgets('failed update refresh keeps installed cards available', (
    tester,
  ) async {
    final inventory = _Inventory();
    final trackedChanges = ValueNotifier(0);
    addTearDown(inventory.dispose);
    addTearDown(trackedChanges.dispose);
    final metadata = _Metadata()..refreshFails = true;
    await _show(
      tester,
      _Nexus(),
      _Organization()..installed = true,
      [],
      metadata,
      inventory,
      trackedChanges,
    );
    await tester.tap(find.text('Updates'));
    await tester.pumpAndSettle();
    expect(find.text('View update'), findsNothing);
    expect(find.text('Nexus is offline'), findsOneWidget);

    await tester.tap(find.text('Installed').first);
    await tester.pumpAndSettle();
    expect(find.text('View files'), findsOneWidget);
  });

  testWidgets('explicit Nexus link change invalidates local cards', (
    tester,
  ) async {
    final inventory = _Inventory();
    final trackedChanges = ValueNotifier(0);
    final localChanges = ValueNotifier(0);
    addTearDown(inventory.dispose);
    addTearDown(trackedChanges.dispose);
    addTearDown(localChanges.dispose);
    final organization = _Organization();
    await _show(
      tester,
      _Nexus(),
      organization,
      [],
      _Metadata()..cachedUpdate = false,
      inventory,
      trackedChanges,
      localChanges: localChanges,
    );
    organization.installed = true;
    localChanges.value++;
    await tester.pumpAndSettle();
    await tester.tap(find.text('Installed').first);
    await tester.pumpAndSettle();
    expect(find.text('View files'), findsOneWidget);
  });
}
