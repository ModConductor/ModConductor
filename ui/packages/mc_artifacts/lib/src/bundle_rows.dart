import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_collections/mc_ui_collections.dart';

import 'bundle_collection.dart';

class BundleRows {
  BundleRows() {
    model.sort((left, right) => left.order.compareTo(right.order));
  }

  final model = McCollectionModel<String, BundleRow>(
    idOf: (row) => row.id,
    labelOf: (row) => row.name,
  );
  final chosen = <int>{};
  List<BundleRow> displayed = [];
  BundleRow? current;
  BundleDiscovery? _lastDiscovery;

  void reconcile(BundleDiscovery? discovery, BundlePlan? bundle) {
    if (!identical(discovery, _lastDiscovery)) {
      chosen.clear();
      _lastDiscovery = discovery;
    }
    displayed = discovery == null
        ? _installedRows(bundle?.items ?? <BundleItem>[])
        : _archiveRows(discovery.archives);
    _applyRows();
    _restoreSelection();
  }

  List<BundleRow> _archiveRows(List<BundleArchive> archives) => [
    for (var index = 0; index < archives.length; index++)
      BundleRow(
        'archive:${archives[index].index}',
        index,
        archives[index].path.last,
        archives[index].path.join('/'),
        archives[index].bytes,
        archive: archives[index],
      ),
  ];

  List<BundleRow> _installedRows(List<BundleItem> items) => [
    for (var index = 0; index < items.length; index++)
      BundleRow(
        items[index].id,
        index,
        items[index].name,
        bundlePath(items[index]),
        items[index].bytes,
        item: items[index],
      ),
  ];

  void _applyRows() {
    model.apply(
      removed: model.ids
          .where((id) => !displayed.any((row) => row.id == id))
          .toList(),
      upserts: displayed,
    );
  }

  void _restoreSelection() {
    final selectedId = current?.id;
    current = null;
    for (final row in displayed) {
      if (row.id == selectedId) current = row;
    }
    current ??= displayed.isEmpty ? null : displayed.first;
    if (current != null) model.select(current!.id);
  }

  void selectAll(bool selected) {
    chosen.clear();
    if (selected) {
      chosen.addAll(displayed.map((row) => row.archive!.index));
    }
  }

  void selectArchive(BundleRow row, bool selected) {
    if (selected) {
      chosen.add(row.archive!.index);
    } else {
      chosen.remove(row.archive!.index);
    }
  }

  List<int> get selectedArchives => [
    for (final row in displayed)
      if (chosen.contains(row.archive!.index)) row.archive!.index,
  ];

  void dispose() => model.dispose();
}
