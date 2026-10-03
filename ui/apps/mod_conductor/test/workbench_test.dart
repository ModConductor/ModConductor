import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_bethesda/mc_bethesda.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_file_plans/mc_file_plans.dart';
import 'package:mc_mod_library/mc_mod_library.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

ModEntry mod(
  String id,
  String name, {
  bool separator = false,
  String category = '',
}) => ModEntry(
  id: id,
  workspaceId: 'workspace',
  kind: separator ? ModKind.separator : ModKind.regular,
  metadata: ModMetadata(
    name: name,
    categories: category.isEmpty
        ? const []
        : [CategoryReference(category, category)],
  ),
  revision: 0,
  status: InventoryStatus.ready,
  actions: const [],
  currentVersionId: separator ? null : 'version-$id',
);

class Organization extends Fake implements ModOrganizationClient {
  int revision = 0;
  List<String> layout = [
    'plugin:skyrim.esm',
    'plugin:update.esm',
    'files:skse',
    'files:address',
    'plugin:skyui_se.esp',
    'files:skyui',
    'files:patch',
    'files:ordinator',
    'files:legacy',
    'files:alternate',
  ];
  List<String>? moved, grouped;
  late final entries = [
    OrganizedMod(
      ProfileMod(
        mod('tools', 'Tools', separator: true),
        const OrderedProfileMod('tools', 0),
      ),
      null,
      position: 0,
      groupSize: const GroupSize(2, 2),
    ),
    OrganizedMod(
      ProfileMod(
        mod('skse', 'SKSE64', category: 'Script extender'),
        const ManagedProfileMod('skse', 1, true),
      ),
      'tools',
      position: 1,
    ),
    OrganizedMod(
      ProfileMod(
        mod(
          'address',
          'Address Library for SKSE Plugins',
          category: 'Framework',
        ),
        const ManagedProfileMod('address', 2, true),
      ),
      'tools',
      position: 2,
    ),
    OrganizedMod(
      ProfileMod(
        mod('interface', 'Interface', separator: true),
        const OrderedProfileMod('interface', 3),
      ),
      null,
      position: 3,
      groupSize: const GroupSize(1, 1),
    ),
    OrganizedMod(
      ProfileMod(
        mod('skyui', 'SkyUI', category: 'Interface'),
        const ManagedProfileMod('skyui', 4, true),
      ),
      'interface',
      position: 4,
    ),
    OrganizedMod(
      ProfileMod(
        mod('gameplay', 'Gameplay', separator: true),
        const OrderedProfileMod('gameplay', 5),
      ),
      null,
      position: 5,
      groupSize: const GroupSize(4, 4),
    ),
    for (final (index, id, name, category) in [
      (6, 'patch', 'Unofficial Skyrim Special Edition Patch', 'Patch'),
      (7, 'ordinator', 'Ordinator - Perks of Skyrim', 'Gameplay'),
      (8, 'legacy', 'Legacy of the Dragonborn', 'Quest / items'),
      (9, 'alternate', 'Alternate Start - Live Another Life', 'New game'),
    ])
      OrganizedMod(
        ProfileMod(
          mod(id, name, category: category),
          ManagedProfileMod(id, index, true),
        ),
        'gameplay',
        position: index,
      ),
  ];
  @override
  Future<ModQueryPage> query(
    String profile,
    ModQuery query, {
    ModQueryCursor? cursor,
    String? inspectedId,
  }) async => ModQueryPage(
    catalogueRevision: 0,
    selectionRevision: revision,
    queryIdentity: 'query',
    entries: [
      for (final row in entries)
        OrganizedMod(
          row.entry,
          query.view == OrganizationView.groups ? row.groupId : null,
          position: row.position,
          groupSize: query.view == OrganizationView.groups
              ? row.groupSize
              : null,
        ),
    ],
    context: const [],
    inspected: null,
    next: null,
    matchingMods: 7,
    matchingSeparators: 3,
    matchingGroups: 3,
    totalMods: 7,
    enabledCount: 7,
  );
  @override
  Future<List<String>> loadOrderLayout(String profile) async => List.of(layout);
  @override
  Future<void> saveLoadOrderLayout(
    String profile,
    List<String> entries,
  ) async => layout = List.of(entries);
  @override
  Future<int> move(
    String profile,
    int expected,
    List<String> ids,
    ProfileModMove direction,
  ) async {
    moved = ids;
    return ++revision;
  }

  @override
  Future<int> group(
    String profile,
    int expected,
    List<String> ids,
    String group,
  ) async {
    grouped = ids;
    return ++revision;
  }
}

class Library extends Fake implements ModLibraryClient {
  Library(this.organization);
  final Organization organization;
  int separators = 0;
  @override
  Future<ModEntry> register(
    String workspace,
    String id,
    ModMetadata metadata,
    ModRegistration registration,
  ) async {
    expect(registration, isA<SeparatorMod>());
    separators++;
    final entry = mod(id, metadata.name, separator: true);
    organization.entries.add(
      OrganizedMod(
        ProfileMod(entry, OrderedProfileMod(id, 10)),
        null,
        position: 10,
        groupSize: const GroupSize(0, 0),
      ),
    );
    organization.revision++;
    return entry;
  }

  @override
  Future<ModVersionPage> version(String version, {int offset = 0}) async =>
      ModVersionPage(version, version.substring(8), [
        ManifestEntry([
          'scripts',
          'loader.pex',
        ], const ModPayload('payload', 10, 'digest')),
        ManifestEntry(['readme.txt'], const ModPayload('readme', 10, 'digest')),
      ], null);
}

class Selection extends Fake implements ProfileModsClient {}

final headers = PluginSnapshot(
  'headers',
  'workspace',
  'profile',
  DateTime.utc(2026),
  false,
  [
    for (final (name, kind) in [
      ('Skyrim.esm', 'Master · base game'),
      ('Update.esm', 'Master · base game'),
      ('SkyUI_SE.esp', 'Plugin'),
    ])
      PluginEntry(
        name,
        kind,
        'Ready',
        '',
        false,
        null,
        const [],
        null,
        const [],
      ),
  ],
  const [],
);
const reference = ProfileDataRef(
  workspaceId: 'workspace',
  profileId: 'profile',
  contextId: 'context',
  revision: 0,
);

class Bethesda extends Fake implements BethesdaClient {
  @override
  Future<PluginSnapshot> scan(String profile) async => headers;
}

class Orders extends Fake implements PluginOrderClient {
  List<String> names = headers.entries.map((entry) => entry.name).toList();
  ProfilePluginOrder get value => ProfilePluginOrder(
    reference,
    headers,
    [
      for (final name in names)
        PluginSetting(
          name,
          true,
          null,
          name == 'Skyrim.esm' ? PluginRequirement.engine : null,
        ),
    ],
    const [],
    const [],
    3,
    0,
    255,
    true,
    false,
    false,
    false,
    '',
  );
  @override
  Future<ProfilePluginOrder> read(
    String workspace,
    String profile,
    String snapshot,
  ) async => value;
}

class Loot extends Fake implements LootClient {
  Loot([this.orders]);
  final Orders? orders;
  int previews = 0, applies = 0;
  @override
  Future<LootStateView> read() async => LootStateView(
    'skyrim',
    true,
    '',
    LootMetadataView(
      'metadata',
      'master',
      'user',
      'master',
      'user',
      DateTime.utc(2026),
    ),
    null,
  );
  @override
  Future<LootStateView> preview(
    String workspace,
    String profile,
    String snapshot,
  ) async {
    previews++;
    final current = await read();
    return LootStateView(
      current.capabilityId,
      true,
      '',
      current.metadata,
      LootProposalView(
        'proposal',
        reference,
        headers.id,
        DateTime.utc(2026),
        orders!.names,
        const ['Skyrim.esm', 'SkyUI_SE.esp', 'Update.esm'],
        const [],
        const [],
        current.metadata!,
        'engine',
        'loot',
        'source',
      ),
    );
  }

  @override
  Future<ProfilePluginOrder> apply(
    String proposal,
    ProfileDataRef expected,
    String snapshot,
  ) async {
    applies++;
    orders!.names = ['Skyrim.esm', 'SkyUI_SE.esp', 'Update.esm'];
    return orders!.value;
  }
}

void main() {
  for (final compact in [false, true]) {
    for (final additional in [false, true]) {
      testWidgets(
        '${compact ? 'compact' : 'desktop'} combined plugin inspection opens and closes ${additional ? 'with another inspector' : 'alone'}',
        (tester) async {
          tester.view.physicalSize = Size(compact ? 1100 : 1440, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final organization = Organization();
          final mods = ModLibraryController()
            ..attach(
              Library(organization),
              Selection(),
              organizationClient: organization,
              workspaceId: 'workspace',
              profileId: 'profile',
              editable: true,
            );
          final plugins = PluginsController()
            ..attach(Bethesda(), 'profile', orders: Orders());
          final plans = FilePlansController();
          for (final controller in [mods, plugins, plans]) {
            addTearDown(controller.dispose);
          }
          await plugins.scan();
          await tester.pumpWidget(
            MaterialApp(
              theme: mcTheme(Brightness.dark),
              home: Scaffold(
                body: FilePlanningWorkbench(
                  mods: mods,
                  plans: plans,
                  plugins: plugins,
                  workspacePath: '/workspace',
                  chooseDirectory: (_) async => null,
                  additionalInspector: additional
                      ? (_) => const SizedBox()
                      : null,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('plugin:skyrim.esm')));
          await tester.pump(const Duration(milliseconds: 350));
          await tester.tap(
            find
                .byWidgetPredicate(
                  (widget) =>
                      widget is McIconAction &&
                      (widget.icon as Icon).icon == Icons.info_outline,
                )
                .hitTestable(),
          );
          await tester.pumpAndSettle();
          expect(plugins.rows.selectedId, 'Skyrim.esm');
          expect(plugins.inspecting, isTrue);
          final inspector = find.byType(PluginInspector).hitTestable();
          expect(inspector, findsOneWidget);
          await tester.tap(
            find.descendant(
              of: inspector,
              matching: find.byWidgetPredicate(
                (widget) =>
                    widget is McIconAction &&
                    (widget.icon as Icon).icon == Icons.close,
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(plugins.inspecting, isFalse);
          expect(find.byType(PluginInspector).hitTestable(), findsNothing);
          expect(mods.loadOrder.rows.selectedId, 'plugin:skyrim.esm');
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'one click LOOT saves plugins while retaining mixed file slots and selected copies',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final organization = Organization(), orders = Orders();
      final mods = ModLibraryController()
        ..attach(
          Library(organization),
          Selection(),
          organizationClient: organization,
          workspaceId: 'workspace',
          profileId: 'profile',
          editable: true,
        );
      final plugins = PluginsController()
        ..attach(Bethesda(), 'profile', orders: orders);
      await plugins.scan();
      final loot = Loot(orders), plans = FilePlansController();
      final sort = SortOrderController()..attach(loot, plugins, 'profile');
      for (final controller in [mods, plugins, plans, sort]) {
        addTearDown(controller.dispose);
      }
      await tester.pumpWidget(
        MaterialApp(
          theme: mcTheme(Brightness.dark),
          home: Scaffold(
            body: FilePlanningWorkbench(
              mods: mods,
              plans: plans,
              plugins: plugins,
              sortOrder: sort,
              workspacePath: '/workspace',
              chooseDirectory: (_) async => null,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      mods.loadOrder.rows.toggle('files:skyui');
      await tester.pumpAndSettle();
      final copy = mods.loadOrder.rows.ids.firstWhere(
        (id) => id.startsWith('copy:skyui:'),
      );
      mods.loadOrder.rows.select(copy);
      final before = List.of(mods.loadOrder.layout);
      final sources = mods.loadOrder.sources
          .map((row) => row.selection)
          .toList();
      await tester.pump();
      await tester.tap(find.text('Optimise'));
      await tester.pumpAndSettle();
      expect(loot.previews, 1);
      expect(loot.applies, 1);
      expect(mods.loadOrder.layout.where((id) => id.startsWith('plugin:')), [
        'plugin:skyrim.esm',
        'plugin:skyui_se.esp',
        'plugin:update.esm',
      ]);
      for (var index = 0; index < before.length; index++) {
        if (before[index].startsWith('files:')) {
          expect(mods.loadOrder.layout[index], before[index]);
        }
      }
      expect(mods.loadOrder.sources.map((row) => row.selection), sources);
      expect(mods.loadOrder.rows.selectedId, copy);
      expect(mods.loadOrder.rows.expanded('files:skyui'), isTrue);
      expect(organization.layout, mods.loadOrder.layout);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'production drawers route selection grouping collapsed movement and preserve an explicit pane',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final organization = Organization();
      final library = Library(organization);
      final mods = ModLibraryController()
        ..attach(
          library,
          Selection(),
          organizationClient: organization,
          workspaceId: 'workspace',
          profileId: 'profile',
          editable: true,
        );
      final view = ModWorkbenchView();
      addTearDown(mods.dispose);
      addTearDown(view.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: mcTheme(Brightness.dark),
          home: Scaffold(
            body: ModLibraryBrowser(
              controller: mods,
              workspacePath: '/workspace',
              view: view,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey((modId: 'skse'))));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.tap(find.byKey(const ValueKey((modId: 'address'))));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
      expect(mods.mods.selectedIds, {(modId: 'skse'), (modId: 'address')});
      await tester.tap(
        find.byKey(const ValueKey((modId: 'address'))),
        buttons: kSecondaryMouseButton,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Group selected'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'Selected tools');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      // This fixture does not emulate grouping; persistence behavior has a real engine/planner test.
      expect(library.separators, 1);
      expect(organization.grouped, ['skse', 'address']);
      // Use the shared collection's collapsed state, then select the header and request a move.
      mods.mods.toggle((modId: 'tools'));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey((modId: 'tools'))));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(
        find.byKey(const ValueKey((modId: 'tools'))),
        buttons: kSecondaryMouseButton,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Move selected down'));
      await tester.pumpAndSettle();
      expect(organization.moved, ['tools']);
      expect(mods.mods.expanded((modId: 'tools')), isFalse);
      view.select('saved');
      organization.revision++;
      await mods.inventory.refreshCatalogue();
      await tester.pump();
      expect(view.pane, 'saved');
      organization.entries.clear();
      organization.revision++;
      await mods.inventory.refreshCatalogue();
      await tester.pumpAndSettle();
      await tester.tap(
        find.text('No installed mods.'),
        buttons: kSecondaryMouseButton,
      );
      await tester.pumpAndSettle();
      expect(find.text('Add separator'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
