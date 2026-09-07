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
  entries: entries,
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
  @override
  Future<ModQueryPage> query(
    String profileId,
    ModQuery query, {
    ModQueryCursor? cursor,
    String? inspectedId,
  }) => onQuery(profileId, query, cursor, inspectedId);
}

class SelectionClient extends Fake implements ProfileModsClient {}
