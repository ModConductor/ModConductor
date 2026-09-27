import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_mod_library/mc_mod_library.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

class _Nexus extends Fake implements NexusClient {
  bool unavailable = false;
  int searches = 0;
  final pages = <int>[];
  final feeds = <String>[];

  @override
  Future<List<NexusDiscoveryMod>> discovery(
    String workspace,
    String profile,
    String feed,
  ) async {
    expect((workspace, profile), ('workspace', 'profile'));
    feeds.add(feed);
    if (unavailable) throw const NexusProblem('not_found', 'Feed unavailable');
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
    expect((workspace, profile), ('workspace', 'profile'));
    searches++;
  }

  @override
  Future<void> openPage(String workspace, String profile, int modId) async {
    expect((workspace, profile), ('workspace', 'profile'));
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
    expect(profileId, 'profile');
    expect(cursor, isNull);
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

class _Metadata extends Fake implements NexusMetadataClient {
  @override
  Future<ModNexusDetails> read(
    String workspace,
    String profile,
    String mod,
  ) async {
    expect((workspace, profile, mod), ('workspace', 'profile', 'local'));
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
            true,
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
) async {
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
          metadata: _Metadata(),
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
    await _show(tester, nexus, _Organization(), viewed);

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
    await _show(tester, nexus, organization, viewed);
    expect(find.text('Feed unavailable'), findsOneWidget);

    await tester.tap(find.text('Updates'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View update'));
    await tester.pump();
    expect(viewed, [64012]);
  });
}
