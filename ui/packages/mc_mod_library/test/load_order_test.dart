import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_mod_library/mc_mod_library.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'controller_test.dart' show mod, file, LibraryClient, settle;
import 'organization_fakes.dart';

class LayoutOrganization extends QueryClient {
  List<String> saved = [];
  @override
  Future<List<String>> loadOrderLayout(String profile) async => saved;
  @override
  Future<void> saveLoadOrderLayout(
    String profile,
    List<String> entries,
  ) async => saved = List.of(entries);
}

class FileSelection extends Fake implements ProfileModsClient {
  int moves = 0;
  Future<ProfileModsDelta> Function(List<String>, ProfileModMove)? onMove;
  @override
  Future<ProfileModsDelta> move(
    String profile,
    int revision,
    Iterable<String> ids,
    ProfileModMove direction, {
    bool fileSourcesOnly = false,
  }) async {
    expect(fileSourcesOnly, isTrue);
    moves++;
    return onMove!(ids.toList(), direction);
  }
}

PluginEntry plugin(String name, {String? source}) => PluginEntry(
  name,
  'Plugin',
  'Ready',
  '',
  false,
  source == null
      ? null
      : PluginSource('Source', '', name, source, 'v-$source', false),
  const [],
  null,
  const [],
);

void main() {
  test('manual mixed moves change only the relevant plugin sequence', () async {
    final organization = LayoutOrganization()
      ..saved = ['files:a', 'plugin:a.esp', 'files:b', 'plugin:b.esp'];
    organization.onQuery = (_, _, _, _) async => queryPage([
      for (final (index, id) in ['a', 'b'].indexed)
        OrganizedMod(
          ProfileMod(
            mod(id, version: 'v-$id'),
            ManagedProfileMod(id, index, true),
          ),
          null,
        ),
    ]);
    final selection = FileSelection();
    final controller = LoadOrderController()
      ..attach(LibraryClient(), organization, selection, 'profile');
    addTearDown(controller.dispose);
    await settle();
    controller.syncPlugins(
      [plugin('A.esp'), plugin('B.esp')],
      ['A.esp', 'B.esp'],
    );
    await settle();
    controller.rows.select('plugin:b.esp');
    var pluginMoves = 0;
    Future<bool> movePlugins(
      List<String> names,
      ProfileModMove direction,
    ) async {
      expect(names, ['B.esp']);
      expect(direction, ProfileModMove.up);
      pluginMoves++;
      controller.syncPlugins(
        [plugin('A.esp'), plugin('B.esp')],
        ['B.esp', 'A.esp'],
      );
      return true;
    }

    await controller.move(ProfileModMove.up, movePlugins: movePlugins);
    expect(pluginMoves, 0); // Crossing a file slot changes presentation only.
    expect(controller.layout, [
      'files:a',
      'plugin:a.esp',
      'plugin:b.esp',
      'files:b',
    ]);
    await controller.move(ProfileModMove.up, movePlugins: movePlugins);
    expect(pluginMoves, 1);
    expect(selection.moves, 0);
    expect(controller.layout, [
      'files:a',
      'plugin:b.esp',
      'plugin:a.esp',
      'files:b',
    ]);
    expect(organization.saved, controller.layout);
    expect(controller.sources.map((row) => row.selection.priority), [0, 1]);
  });

  test('a late source read retains remembered file slots while plugin events arrive', () async {
    final organization = LayoutOrganization()
      ..saved = ['files:a', 'plugin:a.esp', 'files:b', 'plugin:b.esp'];
    final pending = Completer<ModQueryPage>();
    organization.onQuery = (_, _, _, _) => pending.future;
    final controller = LoadOrderController()
      ..attach(LibraryClient(), organization, FileSelection(), 'profile');
    addTearDown(controller.dispose);
    await settle();
    controller.syncPlugins(
      [plugin('A.esp'), plugin('B.esp')],
      ['B.esp', 'A.esp'],
    );
    expect(controller.layout, [
      'files:a',
      'plugin:b.esp',
      'files:b',
      'plugin:a.esp',
    ]);
    pending.complete(
      queryPage([
        for (final (index, id) in ['a', 'b'].indexed)
          OrganizedMod(
            ProfileMod(
              mod(id, version: 'v-$id'),
              ManagedProfileMod(id, index, true),
            ),
            null,
          ),
      ]),
    );
    await settle();
    expect(organization.saved, controller.layout);
    expect(controller.layout, [
      'files:a',
      'plugin:b.esp',
      'files:b',
      'plugin:a.esp',
    ]);
  });

  test('plugin replacement retains file slots precedence expanded files and remembered layout', () async {
    final organization = LayoutOrganization()
      ..saved = ['plugin:a.esp', 'files:a', 'plugin:b.esp', 'files:b'];
    final sources = [
      for (final (index, id) in ['a', 'b'].indexed)
        OrganizedMod(
          ProfileMod(
            mod(id, version: 'v-$id'),
            ManagedProfileMod(id, index, true),
          ),
          null,
          position: index,
        ),
    ];
    organization.onQuery = (_, _, _, _) async =>
        queryPage(sources, revision: 4);
    final library = LibraryClient()
      ..onVersion = (version, _) async => ModVersionPage(
        version,
        version.substring(2),
        [file('shared.txt'), if (version == 'v-a') file('A.esp')],
        null,
      );
    final selection = FileSelection();
    final controller = LoadOrderController()
      ..attach(library, organization, selection, 'profile');
    addTearDown(controller.dispose);
    await settle();
    controller.syncPlugins(
      [plugin('A.esp', source: 'a'), plugin('B.esp')],
      ['A.esp', 'B.esp'],
    );
    controller.rows.toggle('files:a');
    await settle();
    final copyIds = controller.rows.ids
        .where((id) => id.startsWith('copy:'))
        .toList();
    expect(copyIds, hasLength(1));
    controller.rows.select(copyIds.single);
    controller.syncPlugins(
      [plugin('A.esp', source: 'a'), plugin('B.esp')],
      ['B.esp', 'A.esp'],
    );
    await settle();
    expect(controller.layout, [
      'plugin:b.esp',
      'files:a',
      'plugin:a.esp',
      'files:b',
    ]);
    expect(organization.saved, controller.layout);
    expect(controller.sources.map((source) => source.selection.priority), [
      0,
      1,
    ]);
    expect(controller.rows.expanded('files:a'), isTrue);
    expect(controller.rows.selectedId, copyIds.single);
    expect(selection.moves, 0);
    controller.rows.filter('shared');
    controller.rows.sort((a, b) => b.name.compareTo(a.name), label: 'Entry');
    controller.invalidate();
    await settle();
    expect(controller.layout, organization.saved);
    expect(controller.rows.sortLabel, 'Entry');
    expect(controller.rows.query, 'shared');
    final reopened = LoadOrderController()
      ..attach(library, organization, selection, 'profile');
    addTearDown(reopened.dispose);
    await settle();
    reopened.syncPlugins(
      [plugin('A.esp', source: 'a'), plugin('B.esp')],
      ['B.esp', 'A.esp'],
    );
    expect(reopened.layout, controller.layout);
  });

  testWidgets(
    'manual source movement edits files only and display sort cannot move saved precedence',
    (tester) async {
      var reversed = false;
      final organization = LayoutOrganization();
      organization.onQuery = (_, _, _, _) async => queryPage([
        for (final id in ['a', 'b'])
          OrganizedMod(
            ProfileMod(
              mod(id, version: 'v-$id'),
              ManagedProfileMod(id, (id == 'a') == reversed ? 1 : 0, true),
            ),
            null,
          ),
      ], revision: reversed ? 5 : 4);
      final selection = FileSelection()
        ..onMove = (ids, direction) async {
          expect(ids, ['b']);
          expect(direction, ProfileModMove.up);
          reversed = true;
          return const ProfileModsDelta(5, [], 2);
        };
      final controller = LoadOrderController()
        ..attach(LibraryClient(), organization, selection, 'profile');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: mcTheme(Brightness.dark),
          home: Scaffold(
            body: LoadOrderPane(controller: controller, narrow: false),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('files:b')));
      await tester.pump(const Duration(milliseconds: 350));
      expect(controller.rows.selectedIds, {'files:b'});
      expect(controller.canMove, isTrue);
      await tester.tap(
        find.byWidgetPredicate(
          (widget) =>
              widget is McIconAction &&
              (widget.icon as Icon).icon == Icons.arrow_upward,
        ),
      );
      await tester.pumpAndSettle();
      expect(controller.layout, ['files:b', 'files:a']);
      expect(selection.moves, 1);
      controller.rows.sort(
        (a, b) =>
            controller.position(a.id).compareTo(controller.position(b.id)),
        label: 'Order',
        descending: true,
      );
      controller.invalidate();
      await tester.pumpAndSettle();
      expect(controller.rows.descending, isTrue);
      expect(controller.canMove, isFalse);
      expect(controller.layout, ['files:b', 'files:a']);
      controller.rows.sort((a, b) => a.name.compareTo(b.name), label: 'Entry');
      await controller.move(ProfileModMove.down);
      expect(selection.moves, 1);
      controller.rows.filter('a');
      expect(controller.canMove, isFalse);
    },
  );
}
