import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_collections/mc_ui_collections.dart';

typedef ModRowId = ({String modId});

class ModQueryCache {
  OrganizationView _view = OrganizationView.flat;
  late final model = McCollectionModel<ModRowId, OrganizedMod>(
    idOf: (row) => (modId: row.mod.id),
    labelOf: (row) => row.mod.metadata.name,
    parentOf: (row) => row.groupId == null ? null : (modId: row.groupId!),
    isBranch: (row) =>
        _view == OrganizationView.groups && row.mod.kind == ModKind.separator,
  );
  final Map<ModRowId, int> _displayOrder = {};
  final Set<ModRowId> _matches = {}, _context = {}, _seenGroups = {};
  int get loaded => _matches.length;
  void clear() {
    _matches.clear();
    _context.clear();
    _displayOrder.clear();
    _seenGroups.clear();
    model.clear();
  }

  int comparePriority(OrganizedMod a, OrganizedMod b) {
    final left = a.selection.priority, right = b.selection.priority;
    if (left == null && right != null) return -1;
    if (right == null && left != null) return 1;
    return left == null ? a.mod.id.compareTo(b.mod.id) : left.compareTo(right!);
  }

  void accept(
    ModQueryPage page,
    ModQuery requested, {
    required bool refresh,
    required int offset,
    List<ProfileModSelection> delta = const [],
  }) {
    _view = requested.view;
    if (refresh) _displayOrder.clear();
    for (var index = 0; index < page.entries.length; index++) {
      _displayOrder[(modId: page.entries[index].mod.id)] = offset + index;
    }
    final values = [
      for (final selection in delta)
        if (model[(modId: selection.modId)] case final old?)
          OrganizedMod(
            ProfileMod(old.mod, selection),
            old.groupId,
            groupSize: old.groupSize,
          ),
      ...page.entries,
      ...page.context,
      if (page.inspected != null) page.inspected!,
    ];
    final present = values.map((row) => (modId: row.mod.id)).toSet();
    final retained = {...present, ...model.selectedIds};
    final evicted = refresh
        ? model.ids.where((id) => !retained.contains(id)).toList()
        : <ModRowId>[];
    if (refresh) {
      _matches.clear();
      _context.clear();
    }
    _matches.addAll(page.entries.map((row) => (modId: row.mod.id)));
    _context.addAll(page.context.map((row) => (modId: row.mod.id)));
    model.apply(
      upserts: values,
      evicted: evicted,
      visibleIds: {..._matches, ..._context},
    );
    model.sort(
      (a, b) {
        if (requested.sort == OrganizationSort.priority ||
            (requested.view == OrganizationView.groups &&
                (a.mod.kind == ModKind.separator ||
                    b.mod.kind == ModKind.separator))) {
          return comparePriority(a, b);
        }
        return (_displayOrder[(modId: a.mod.id)] ?? 0).compareTo(
          _displayOrder[(modId: b.mod.id)] ?? 0,
        );
      },
      label: requested.sort == OrganizationSort.priority ? 'Priority' : 'Name',
    );
    for (final row in values) {
      final id = (modId: row.mod.id);
      if (requested.view == OrganizationView.groups &&
          row.mod.kind == ModKind.separator &&
          _seenGroups.add(id) &&
          !model.expanded(id)) {
        model.toggle(id);
      }
    }
  }
}
