import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_mod_library/mc_mod_library.dart';

import 'controller_test.dart' show mod, file, LibraryClient, settle;
import 'load_order_test.dart' show plugin;
import 'organization_fakes.dart';

class _Organization extends QueryClient {
  final layouts = <String, List<String>>{};
  final saves = <String>[];
  Completer<void>? pendingSave;
  @override
  Future<List<String>> loadOrderLayout(String profile) async =>
      List.of(layouts[profile] ?? const []);
  @override
  Future<void> saveLoadOrderLayout(String profile, List<String> entries) async {
    saves.add(profile);
    await pendingSave?.future;
    layouts[profile] = List.of(entries);
  }
}

class _Selection extends Fake implements ProfileModsClient {
  final calls = <(String, int, List<String>)>[];
  late Future<ProfileModsDelta> Function(List<String>, ProfileModMove) onMove;
  @override
  Future<ProfileModsDelta> move(
    String profile,
    int revision,
    Iterable<String> ids,
    ProfileModMove direction, {
    bool fileSourcesOnly = false,
  }) {
    expect(fileSourcesOnly, isTrue);
    calls.add((profile, revision, ids.toList()));
    return onMove(ids.toList(), direction);
  }
}

ModQueryPage _sources(List<String> ids, {int revision = 4}) => queryPage([
  for (final (index, id) in ids.indexed)
    OrganizedMod(
      ProfileMod(mod(id, version: 'v-$id'), ManagedProfileMod(id, index, true)),
      null,
    ),
], revision: revision);

void _moveDomain(
  List<String> order,
  List<String> selected,
  ProfileModMove direction,
) {
  final up = direction == ProfileModMove.up;
  for (
    var index = up ? 1 : order.length - 2;
    up ? index < order.length : index >= 0;
    index += up ? 1 : -1
  ) {
    final other = up ? index - 1 : index + 1;
    if (selected.contains(order[index]) && !selected.contains(order[other])) {
      final value = order[index];
      order[index] = order[other];
      order[other] = value;
    }
  }
}

void main() {
  for (final plugins in [true, false]) {
    for (final direction in [ProfileModMove.up, ProfileModMove.down]) {
      for (final (description, before, selected, after) in [
        (
          'opposite-only crossing',
          ['a', 'b', 'c', 'other', 'd'],
          ['b', 'd'],
          ['b', 'a', 'c', 'd', 'other'],
        ),
        (
          'selected run and opposite crossing',
          ['a', 'b', 'c', 'other', 'd', 'e'],
          ['b', 'c', 'd'],
          ['b', 'c', 'a', 'd', 'other', 'e'],
        ),
        (
          'discontiguous selected runs',
          ['a', 'b', 'other', 'c', 'd', 'e'],
          ['b', 'd', 'e'],
          ['b', 'a', 'other', 'd', 'e', 'c'],
        ),
      ]) {
        test(
          '${plugins ? 'plugin' : 'file'} batch $direction preserves $description precedence',
          () async {
            String rowId(String id) => (id == 'other') != plugins
                ? LoadOrderRow.pluginId('$id.esp')
                : LoadOrderRow.sourceId(id);
            final down = direction == ProfileModMove.down;
            final initial = (down ? before.reversed : before)
                .map(rowId)
                .toList();
            final expected = (down ? after.reversed : after)
                .map(rowId)
                .toList();
            final organization = _Organization()..layouts['profile'] = initial;
            final files = initial
                .where((id) => id.startsWith('files:'))
                .map((id) => id.substring(6))
                .toList();
            final names = initial
                .where((id) => id.startsWith('plugin:'))
                .map((id) => id.substring(7))
                .toList();
            final entries = names.map(plugin).toList();
            organization.onQuery = (_, _, _, _) async => _sources(files);
            final selection = _Selection()
              ..onMove = (ids, direction) async {
                _moveDomain(files, ids, direction);
                return const ProfileModsDelta(5, [], 0);
              };
            final controller = LoadOrderController()
              ..attach(LibraryClient(), organization, selection, 'profile');
            addTearDown(controller.dispose);
            await settle();
            controller.syncPlugins(entries, names);
            await settle();
            for (final id in selected) {
              controller.rows.select(rowId(id), toggle: true);
            }
            await controller.move(
              direction,
              movePlugins: (selected, direction) async {
                _moveDomain(names, selected, direction);
                controller.syncPlugins(entries, names);
                return true;
              },
            );
            await settle();
            expect(
              names.map(LoadOrderRow.pluginId),
              expected.where((id) => id.startsWith('plugin:')),
            );
            expect(
              files.map(LoadOrderRow.sourceId),
              expected.where((id) => id.startsWith('files:')),
            );
            expect(controller.layout, expected);
            expect(organization.layouts['profile'], expected);
          },
        );
      }
    }
  }

  for (final newReadPending in [false, true]) {
    for (final boundary in ['plugin', 'files', 'layout', 'changed']) {
      test(
        'old mixed move stops after $boundary await with new read ${newReadPending ? 'pending' : 'complete'}',
        () async {
          final organization = _Organization()
            ..layouts['old'] = [
              'plugin:a.esp',
              'plugin:b.esp',
              'files:x',
              'files:y',
            ]
            ..layouts['new'] = ['files:new'];
          final newRead = Completer<ModQueryPage>();
          final queries = <String>[];
          organization.onQuery = (profile, _, _, _) async {
            queries.add(profile);
            return profile == 'old'
                ? _sources(['x', 'y'])
                : newReadPending
                ? newRead.future
                : _sources(['new'], revision: 30);
          };
          final pluginMove = Completer<bool>();
          final fileMove = Completer<ProfileModsDelta>();
          final layoutSave = Completer<void>();
          final changed = Completer<void>();
          final selection = _Selection()
            ..onMove = (_, _) => boundary == 'files'
                ? fileMove.future
                : Future.value(const ProfileModsDelta(5, [], 2));
          final library = LibraryClient();
          final controller = LoadOrderController()
            ..attach(library, organization, selection, 'old');
          addTearDown(controller.dispose);
          await settle();
          controller.syncPlugins(
            [plugin('A.esp'), plugin('B.esp')],
            ['A.esp', 'B.esp'],
          );
          await settle();
          organization.saves.clear();
          if (boundary == 'layout') organization.pendingSave = layoutSave;
          var callbacks = 0;
          controller.onChanged = () {
            callbacks++;
            return changed.future;
          };
          controller.rows.select('plugin:b.esp');
          controller.rows.select('files:y', toggle: true);
          final moving = controller.move(
            ProfileModMove.up,
            movePlugins: (_, _) =>
                boundary == 'plugin' ? pluginMove.future : Future.value(true),
          );
          await settle();
          controller.attach(library, organization, selection, 'new');
          await settle();
          expect(controller.revision, newReadPending ? isNull : 30);
          switch (boundary) {
            case 'plugin':
              pluginMove.complete(true);
            case 'files':
              fileMove.complete(const ProfileModsDelta(5, [], 2));
            case 'layout':
              layoutSave.complete();
            case 'changed':
              changed.complete();
          }
          await moving;
          expect(controller.revision, newReadPending ? isNull : 30);
          expect(controller.problem, isNull);
          if (boundary == 'plugin') {
            expect(selection.calls, isEmpty);
          } else {
            final (profile, revision, ids) = selection.calls.single;
            expect(profile, 'old');
            expect(revision, 4);
            expect(ids, ['y']);
          }
          expect(
            organization.saves,
            boundary == 'plugin' || boundary == 'files' ? isEmpty : ['old'],
          );
          expect(callbacks, boundary == 'changed' ? 1 : 0);
          if (newReadPending) {
            expect(controller.reading, isTrue);
            newRead.complete(_sources(['new'], revision: 30));
            await settle();
          }
          expect(controller.layout, ['files:new']);
          expect(controller.sources.map((source) => source.mod.id), ['new']);
          expect(queries, ['old', 'new']);
          expect(controller.revision, 30);
          expect(controller.writing, isFalse);
        },
      );
    }
  }

  for (final pluginSequenceChanges in [false, true]) {
    test(
      'source events during ${pluginSequenceChanges ? 'plugin' : 'presentation'} move drain after save and retain view state',
      () async {
        final organization = _Organization()
          ..layouts['profile'] = pluginSequenceChanges
              ? ['files:a', 'plugin:a.esp', 'plugin:b.esp', 'files:b']
              : ['files:a', 'plugin:a.esp', 'files:b', 'plugin:b.esp'];
        var sources = ['a', 'b', 'removed'];
        var queries = 0;
        organization.onQuery = (_, _, _, _) async {
          queries++;
          return _sources(sources);
        };
        final library = LibraryClient()
          ..onVersion = (version, _) async =>
              ModVersionPage(version, 'a', [file('shared.txt')], null);
        final selection = _Selection();
        final controller = LoadOrderController()
          ..attach(library, organization, selection, 'profile');
        addTearDown(controller.dispose);
        await settle();
        final entries = [plugin('A.esp'), plugin('B.esp')];
        controller.syncPlugins(entries, ['A.esp', 'B.esp']);
        controller.rows.toggle('files:a');
        await settle();
        controller.rows.select('plugin:b.esp');
        final before = queries;
        organization.pendingSave = Completer<void>();
        final moving = controller.move(
          ProfileModMove.up,
          movePlugins: (_, _) async {
            controller.syncPlugins(entries, ['B.esp', 'A.esp']);
            return true;
          },
        );
        await settle();
        sources = ['a', 'b', 'added'];
        controller.invalidate();
        expect(queries, before);
        organization.pendingSave!.complete();
        await moving;
        await settle();
        expect(controller.sources.map((source) => source.mod.id), sources);
        expect(controller.layout, [
          'files:a',
          if (pluginSequenceChanges) ...[
            'plugin:b.esp',
            'plugin:a.esp',
          ] else ...[
            'plugin:a.esp',
            'plugin:b.esp',
          ],
          'files:b',
          'files:added',
        ]);
        expect(controller.rows.selectedIds, {'plugin:b.esp'});
        expect(controller.rows.expanded('files:a'), isTrue);
        expect(
          controller.rows.ids.where((id) => id.startsWith('copy:a:')),
          isNotEmpty,
        );
        expect(selection.calls, isEmpty);
        expect(queries, before + 1);
        expect(organization.layouts['profile'], controller.layout);
      },
    );
  }
}
