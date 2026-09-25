import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_mod_library/mc_mod_library.dart';

import 'controller_test.dart' show settle;
import 'organization_fakes.dart';
import 'profile_mods_test.dart' show row, ProfileClient;

void main() {
  test('setup event catalogue refresh retains content and selection until FNIS arrives', () async {
    final pending = Completer<ModQueryPage>();
    final queries = QueryClient()
      ..onQuery = (_, _, _, _) async =>
          queryPage([row('skse', 0)], catalogue: 1);
    final state = ProfileModsController();
    addTearDown(state.dispose);
    state.attach(ProfileClient(), queries, 'workspace', 'profile');
    await settle();
    state.model.select((modId: 'skse'));
    queries.onQuery = (_, _, _, _) => pending.future;

    final updating = state.refreshCatalogue();
    expect(state.model.visible, [(modId: 'skse')]);
    expect(state.model.selectedId, (modId: 'skse'));
    pending.complete(queryPage([row('skse', 0), row('fnis', 1)], catalogue: 2));
    await updating;
    expect(state.model.visible, [(modId: 'skse'), (modId: 'fnis')]);
    expect(state.model.selectedId, (modId: 'skse'));
  });

  test('flat priority keeps locked rows after saved order while name sort follows the query', () async {
    final regular = row('z', 0);
    final locked = OrganizedMod(
      ProfileMod(
        ModEntry(
          id: 'locked',
          workspaceId: 'workspace',
          kind: ModKind.unmanaged,
          metadata: const ModMetadata(name: 'Alpha'),
          revision: 0,
          status: InventoryStatus.ready,
          actions: const [],
        ),
        const LockedProfileMod('locked', ProfileModRestriction.unmanaged),
      ),
      null,
    );
    final queries = QueryClient()
      ..onQuery = (_, query, _, _) async => queryPage(
        query.sort == OrganizationSort.priority
            ? [regular, locked]
            : [locked, regular],
      );
    final state = ProfileModsController();
    addTearDown(state.dispose);
    state.attach(ProfileClient(), queries, 'workspace', 'profile');
    await settle();
    expect(state.model.visible, [(modId: 'z'), (modId: 'locked')]);
    state.model.select((modId: 'locked'));
    state.sort('Name');
    await settle();
    expect(state.model.visible, [(modId: 'locked'), (modId: 'z')]);
    expect(state.model.selectedId, (modId: 'locked'));
  });

  test('manager close supersedes a delayed pre-edit query without publishing its old projection', () async {
    final queries = QueryClient()
      ..onQuery = (_, _, _, _) async =>
          queryPage([row('a', 0), row('b', 1)], catalogue: 1);
    final state = ProfileModsController();
    addTearDown(state.dispose);
    state.attach(ProfileClient(), queries, 'workspace', 'profile');
    await settle();
    state.model.select((modId: 'b'));
    final old = Completer<ModQueryPage>();
    queries.onQuery = (_, _, _, _) => old.future;
    final reading = state.load(refresh: true);
    queries.onQuery = (_, _, _, _) async =>
        queryPage([row('b', 1)], catalogue: 2);
    await state.refreshCatalogue();
    old.complete(queryPage([row('a', 0)], catalogue: 1));
    await reading;
    expect(state.model.visible, [(modId: 'b')]);
    expect(state.catalogueRevision, 2);
    expect(state.model.selectedId, (modId: 'b'));
    expect(state.loading, isFalse);
    expect(state.stale, isFalse);
  });

  for (final afterCommand in [false, true]) {
    test(
      'manager invalidation ${afterCommand ? 'during accepted selection reload' : 'during selection command'} retains the accepted delta in the fresh snapshot',
      () async {
        final client = ProfileClient();
        final queries = QueryClient()
          ..onQuery = (_, _, _, _) async =>
              queryPage([row('a', 0), row('b', 1)], revision: 4, catalogue: 1);
        final state = ProfileModsController();
        addTearDown(state.dispose);
        state.attach(client, queries, 'workspace', 'profile');
        await settle();
        state.model.select((modId: 'a'));
        state.model.select((modId: 'b'), toggle: true);
        final publishedCatalogues = <int?>[];
        state.addListener(() {
          if (!state.loading && !state.changing && !state.stale) {
            publishedCatalogues.add(state.catalogueRevision);
          }
        });
        final command = Completer<ProfileModsDelta>();
        final oldProjection = Completer<ModQueryPage>();
        client.onMove = (_, _, _) => command.future;
        queries.onQuery = (_, _, _, _) => oldProjection.future;
        final moving = state.move(ProfileModMove.up);
        const delta = ProfileModsDelta(5, [
          ManagedProfileMod('a', 1, true),
          ManagedProfileMod('b', 0, false),
        ], 1);
        if (afterCommand) {
          command.complete(delta);
          await settle();
          expect(state.loading, isTrue);
        }
        await state.refreshCatalogue();
        queries.onQuery = (_, _, cursor, _) async {
          expect(cursor, isNull);
          return queryPage([row('b', 0)], revision: 5, catalogue: 2);
        };
        if (afterCommand) {
          oldProjection.complete(
            queryPage([row('a', 1), row('b', 0)], revision: 5, catalogue: 1),
          );
        } else {
          command.complete(delta);
        }
        await moving;
        expect(publishedCatalogues, isNotEmpty);
        expect(publishedCatalogues.every((revision) => revision == 2), isTrue);
        expect(state.catalogueRevision, 2);
        expect(state.revision, 5);
        expect(state.model.visible, [(modId: 'b')]);
        expect(
          state.model[(modId: 'a')]!.selection,
          isA<ManagedProfileMod>()
              .having((row) => row.enabled, 'accepted enablement', isTrue)
              .having((row) => row.priority, 'accepted precedence', 1),
        );
        expect(state.model.selectedIds, {(modId: 'a'), (modId: 'b')});
        expect(state.hiddenSelected, 1);
        expect(state.changing || state.loading || state.stale, isFalse);
        expect(state.problem, isNull);
      },
    );
  }
}
