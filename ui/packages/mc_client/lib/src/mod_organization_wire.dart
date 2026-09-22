import 'package:fixnum/fixnum.dart';

import 'generated/modconductor/v1/mod_organization.pb.dart' as wire;
import 'generated/modconductor/v1/mod_library.pb.dart' as mods;
import 'mod_library_models.dart';
import 'mod_library_wire.dart' as mapping;
import 'profile_mod_wire.dart' as profile;
import 'mod_organization_models.dart';

ModCategory category(wire.ModCategory value) => ModCategory(
  value.categoryId,
  value.workspaceId,
  value.hasParentId() ? value.parentId : null,
  value.label,
  value.missing,
  value.assignedCount,
  value.hasChildren,
);
OrganizedMod row(wire.OrganizedModView value) => OrganizedMod(
  profile.entry(value.entry),
  value.hasGroupId() ? value.groupId : null,
  groupSize: value.hasGroupSize()
      ? GroupSize(value.groupSize.matching, value.groupSize.total)
      : null,
);
ModQueryCursor cursor(wire.ModQueryCursor value) => ModQueryCursor(
  value.catalogueRevision.toInt(),
  value.selectionRevision.toInt(),
  value.queryIdentity,
  value.offset,
);
wire.ModQueryCursor encodeCursor(ModQueryCursor value) => wire.ModQueryCursor(
  catalogueRevision: Int64(value.catalogueRevision),
  selectionRevision: Int64(value.selectionRevision),
  queryIdentity: value.queryIdentity,
  offset: value.offset,
);
wire.ModFilterPredicate predicate(ModFilter value) => switch (value) {
  CategoryFilter() => wire.ModFilterPredicate(
    category: wire.ModCategoryFilter(
      category: mapping.encodeCategory(value.category),
      descendants: value.descendants,
    ),
  ),
  KindFilter() => wire.ModFilterPredicate(
    kind: mapping.encodeModKind(value.kind),
  ),
  StatusFilter() => wire.ModFilterPredicate(
    status: switch (value.status) {
      InventoryStatus.ready =>
        mods.ModInventoryStatus.MOD_INVENTORY_STATUS_READY,
      InventoryStatus.detached =>
        mods.ModInventoryStatus.MOD_INVENTORY_STATUS_DETACHED,
      InventoryStatus.changed =>
        mods.ModInventoryStatus.MOD_INVENTORY_STATUS_CHANGED,
      InventoryStatus.unproved =>
        mods.ModInventoryStatus.MOD_INVENTORY_STATUS_UNPROVED,
      InventoryStatus.publishing =>
        mods.ModInventoryStatus.MOD_INVENTORY_STATUS_PUBLISHING,
    },
  ),
  EnabledFilter() => wire.ModFilterPredicate(
    enabled: switch (value.enabled) {
      true => wire.ModEnabledFilter.MOD_ENABLED_FILTER_YES,
      false => wire.ModEnabledFilter.MOD_ENABLED_FILTER_NO,
      null => wire.ModEnabledFilter.MOD_ENABLED_FILTER_NOT_APPLICABLE,
    },
  ),
  UncategorizedFilter() => wire.ModFilterPredicate(uncategorized: true),
  MissingCategoryFilter() => wire.ModFilterPredicate(missingCategory: true),
};
wire.ModQueryDefinition query(ModQuery value) => wire.ModQueryDefinition(
  text: value.text,
  mode: switch (value.mode) {
    FilterMode.all => wire.ModFilterMode.MOD_FILTER_MODE_ALL,
    FilterMode.any => wire.ModFilterMode.MOD_FILTER_MODE_ANY,
  },
  filters: value.filters.map(predicate),
  view: switch (value.view) {
    OrganizationView.flat => wire.ModQueryView.MOD_QUERY_VIEW_FLAT,
    OrganizationView.groups => wire.ModQueryView.MOD_QUERY_VIEW_GROUPS,
  },
  sort: switch (value.sort) {
    OrganizationSort.priority => wire.ModQuerySort.MOD_QUERY_SORT_PRIORITY,
    OrganizationSort.name => wire.ModQuerySort.MOD_QUERY_SORT_NAME,
  },
);
ModQueryPage page(wire.ModQueryPage value) => ModQueryPage(
  catalogueRevision: value.catalogueRevision.toInt(),
  selectionRevision: value.selectionRevision.toInt(),
  queryIdentity: value.queryIdentity,
  entries: List.unmodifiable(value.entries.map(row)),
  context: List.unmodifiable(value.context.map(row)),
  inspected: value.hasInspected() ? row(value.inspected) : null,
  next: value.hasNext() ? cursor(value.next) : null,
  matchingMods: value.matchingMods,
  matchingSeparators: value.matchingSeparators,
  matchingGroups: value.matchingGroups,
  totalMods: value.totalMods,
  enabledCount: value.enabledCount,
);
