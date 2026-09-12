import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_collections/mc_ui_collections.dart';

class InstallationRow {
  const InstallationRow(
    this.path,
    this.parent,
    this.name,
    this.directory,
    this.size,
    this.included,
    this.destination,
  );
  final String path, name;
  final String? parent;
  final bool directory;
  final bool? included;
  final int? size;
  final List<String>? destination;
  List<String> get components => path.split('/');
}

class InstallationTree {
  final model = McCollectionModel<String, InstallationRow>(
    idOf: (r) => r.path,
    labelOf: (r) => r.name,
    parentOf: (r) => r.parent,
    isBranch: (r) => r.directory,
  );
  void apply(
    InstallationDraft draft, {
    required bool manual,
    required bool excluded,
  }) {
    final selected = {for (final f in draft.files) f.index: f};
    final targets = <String, Set<String>>{};
    final rows = <String, InstallationRow>{}, counts = <String, (int, int)>{};
    for (final entry in draft.manifest.entries.where((e) => !e.directory)) {
      final included = selected.containsKey(entry.index);
      if (!manual && included == excluded) continue;
      final parts = manual || excluded
          ? entry.components
          : selected[entry.index]!.destination;
      for (var count = 1; count <= parts.length; ++count) {
        final path = parts.take(count).join('/'), full = count == parts.length;
        final previous = counts[path] ?? (0, 0);
        counts[path] = (previous.$1 + (included ? 1 : 0), previous.$2 + 1);
        List<String>? target;
        if (manual && included) {
          final destination = selected[entry.index]!.destination;
          final suffix = parts.length - count;
          if (destination.length >= suffix)
            target = destination.take(destination.length - suffix).toList();
        }
        if (target != null)
          (targets[path] ??= <String>{}).add(target.join('/'));
        rows[path] = InstallationRow(
          path,
          count == 1 ? null : parts.take(count - 1).join('/'),
          parts[count - 1],
          !full,
          full ? entry.size : null,
          included,
          target,
        );
      }
    }
    model.apply(
      upserts: rows.values.map((r) {
        final count = counts[r.path]!;
        return InstallationRow(
          r.path,
          r.parent,
          r.name,
          r.directory,
          r.size,
          count.$1 == 0
              ? false
              : count.$1 == count.$2
              ? true
              : null,
          targets[r.path]?.length == 1
              ? (targets[r.path]!.single.isEmpty
                    ? <String>[]
                    : targets[r.path]!.single.split('/'))
              : null,
        );
      }),
      evicted: model.ids.where((id) => !rows.containsKey(id)).toList(),
    );
    for (final r in rows.values) {
      if (r.directory && !model.expanded(r.path)) model.toggle(r.path);
    }
  }

  void dispose() => model.dispose();
}
