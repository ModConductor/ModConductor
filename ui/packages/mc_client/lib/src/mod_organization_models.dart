import 'mod_library_models.dart';
import 'profile_mod_models.dart';

class ModCategory {
  const ModCategory(
    this.id,
    this.workspaceId,
    this.parentId,
    this.label,
    this.missing,
    this.assignedCount,
    this.hasChildren,
  );
  final String id, workspaceId, label;
  final String? parentId;
  final bool missing, hasChildren;
  final int assignedCount;
  CategoryReference get reference =>
      CategoryReference(id, label, missing: missing);
}

class CategoriesPage {
  const CategoriesPage(
    this.revision,
    this.entries,
    this.ancestors,
    this.nextId,
  );
  final int revision;
  final List<ModCategory> entries, ancestors;
  final String? nextId;
}

enum FilterMode { all, any }

enum OrganizationView { flat, groups }

enum OrganizationSort { priority, name }

sealed class ModFilter {
  const ModFilter();
}

class CategoryFilter extends ModFilter {
  const CategoryFilter(this.category, {this.descendants = false});
  final CategoryReference category;
  final bool descendants;
}

class KindFilter extends ModFilter {
  const KindFilter(this.kind);
  final ModKind kind;
}

class StatusFilter extends ModFilter {
  const StatusFilter(this.status);
  final InventoryStatus status;
}

class EnabledFilter extends ModFilter {
  const EnabledFilter(this.enabled);
  final bool? enabled;
}

class UncategorizedFilter extends ModFilter {
  const UncategorizedFilter();
}

class MissingCategoryFilter extends ModFilter {
  const MissingCategoryFilter();
}

class ModQuery {
  const ModQuery({
    this.text = '',
    this.mode = FilterMode.all,
    this.filters = const [],
    this.view = OrganizationView.flat,
    this.sort = OrganizationSort.priority,
  });
  final String text;
  final FilterMode mode;
  final List<ModFilter> filters;
  final OrganizationView view;
  final OrganizationSort sort;
  ModQuery copyWith({
    String? text,
    FilterMode? mode,
    List<ModFilter>? filters,
    OrganizationView? view,
    OrganizationSort? sort,
  }) => ModQuery(
    text: text ?? this.text,
    mode: mode ?? this.mode,
    filters: filters ?? this.filters,
    view: view ?? this.view,
    sort: sort ?? this.sort,
  );
}

class ModQueryCursor {
  const ModQueryCursor(
    this.catalogueRevision,
    this.selectionRevision,
    this.queryIdentity,
    this.offset,
  );
  final int catalogueRevision, selectionRevision, offset;
  final String queryIdentity;
}

class GroupSize {
  const GroupSize(this.matching, this.total);
  final int matching, total;
}

class OrganizedMod {
  const OrganizedMod(this.entry, this.groupId, {this.groupSize});
  final ProfileMod entry;
  ModEntry get mod => entry.mod;
  ProfileModSelection get selection => entry.selection;
  final String? groupId;
  final GroupSize? groupSize;
}

class ModQueryPage {
  const ModQueryPage({
    required this.catalogueRevision,
    required this.selectionRevision,
    required this.queryIdentity,
    required this.entries,
    required this.context,
    required this.inspected,
    required this.next,
    required this.matchingMods,
    required this.matchingSeparators,
    this.matchingGroups = 0,
    required this.totalMods,
    required this.enabledCount,
  });
  final int catalogueRevision, selectionRevision;
  final String queryIdentity;
  final List<OrganizedMod> entries, context;
  final OrganizedMod? inspected;
  final ModQueryCursor? next;
  final int matchingMods,
      matchingSeparators,
      matchingGroups,
      totalMods,
      enabledCount;
}
