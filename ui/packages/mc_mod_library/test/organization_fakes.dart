import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';

ModQueryPage queryPage(
  List<OrganizedMod> entries, {
  int revision = 0,
  int catalogue = 0,
  int? nextOffset,
  List<OrganizedMod> context = const [],
  OrganizedMod? inspected,
  int? total,
}) => ModQueryPage(
  catalogueRevision: catalogue,
  selectionRevision: revision,
  queryIdentity: 'query',
  entries: [
    for (final row in entries)
      OrganizedMod(
        row.entry,
        row.groupId,
        groupSize: row.groupSize,
        position: row.position ?? row.selection.priority,
      ),
  ],
  context: context,
  inspected: inspected,
  next: nextOffset == null
      ? null
      : ModQueryCursor(catalogue, revision, 'query', nextOffset),
  matchingMods: total ?? entries.length,
  matchingSeparators: 0,
  totalMods: total ?? entries.length,
  enabledCount: 0,
);

class QueryClient extends Fake implements ModOrganizationClient {
  late Future<ModQueryPage> Function(String, ModQuery, ModQueryCursor?, String?)
  onQuery;
  Future<int> Function(int, List<String>, ProfileModMove)? onMove;
  @override
  Future<int> move(
    String profile,
    int revision,
    List<String> ids,
    ProfileModMove direction,
  ) async =>
      onMove == null ? revision + 1 : await onMove!(revision, ids, direction);
  @override
  Future<List<String>> loadOrderLayout(String profile) async => const [];
  @override
  Future<void> saveLoadOrderLayout(
    String profile,
    List<String> entries,
  ) async {}
  @override
  Future<ModQueryPage> query(
    String profileId,
    ModQuery query, {
    ModQueryCursor? cursor,
    String? inspectedId,
  }) => onQuery(profileId, query, cursor, inspectedId);
}

class SelectionClient extends Fake implements ProfileModsClient {}
