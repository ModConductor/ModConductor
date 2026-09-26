import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_collections/mc_ui_collections.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'archive_facts.dart';

String bundleState(BundleItemState state) => switch (state) {
  BundleItemState.needsReview => 'Needs review',
  BundleItemState.installed => 'Installed',
  BundleItemState.failed => 'Failed',
  BundleItemState.installing => 'Installing',
};

String bundlePath(BundleItem item) =>
    item.archives.map((path) => path.join('/')).join(' / ');

class BundleRow {
  const BundleRow(
    this.id,
    this.order,
    this.name,
    this.path,
    this.bytes, {
    this.item,
    this.archive,
  });

  final String id, name, path;
  final int order, bytes;
  final BundleItem? item;
  final BundleArchive? archive;
}

class BundleCollection extends StatelessWidget {
  const BundleCollection({
    super.key,
    required this.model,
    required this.displayed,
    required this.current,
    required this.chosen,
    required this.installed,
    required this.picking,
    required this.narrow,
    required this.busy,
    required this.onAction,
    required this.onSelect,
    required this.onArchiveSelected,
  });

  final McCollectionModel<String, BundleRow> model;
  final List<BundleRow> displayed;
  final BundleRow? current;
  final Set<int> chosen;
  final int installed;
  final bool picking, narrow, busy;
  final ValueChanged<String> onAction;
  final ValueChanged<BundleRow> onSelect;
  final void Function(BundleRow, bool) onArchiveSelected;

  List<PopupMenuEntry<String>> menuItems(BuildContext context) => picking
      ? const [
          PopupMenuItem(value: 'all', child: Text('Select all')),
          PopupMenuItem(value: 'none', child: Text('Clear selection')),
        ]
      : [
          PopupMenuItem(
            value: 'configure',
            enabled: !busy && current?.item != null,
            child: const Text('Configure'),
          ),
          PopupMenuItem(
            value: 'destination',
            enabled:
                !busy && current?.item?.state == BundleItemState.needsReview,
            child: const Text('Change destination'),
          ),
          PopupMenuItem(
            value: 'up',
            enabled:
                !busy && current?.item?.state == BundleItemState.needsReview,
            child: const Text('Move earlier'),
          ),
          PopupMenuItem(
            value: 'down',
            enabled:
                !busy && current?.item?.state == BundleItemState.needsReview,
            child: const Text('Move later'),
          ),
          PopupMenuItem(
            value: 'nested',
            enabled:
                !busy && current?.item?.state == BundleItemState.needsReview,
            child: const Text('Open contained archives'),
          ),
        ];

  List<McColumn<BundleRow>> columns(BuildContext context) => [
    if (picking)
      McColumn(
        '',
        (row) => Checkbox(
          value: chosen.contains(row.archive!.index),
          onChanged: busy
              ? null
              : (value) => onArchiveSelected(row, value == true),
        ),
        width: 48,
        interactive: true,
      ),
    if (!narrow)
      McColumn('Order', (row) => Text('${row.order + 1}'), width: 60),
    McColumn(
      picking ? 'Archive' : 'Mod name',
      (row) => narrow
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  picking ? row.name : '${row.order + 1}. ${row.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  picking
                      ? archiveSize(row.bytes)
                      : bundleState(row.item!.state),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            )
          : McCollectionName(row.name),
    ),
    if (!narrow && !picking)
      McColumn(
        'Archive',
        (row) => Text(row.path, maxLines: 1, overflow: TextOverflow.ellipsis),
        width: 340,
      ),
    if (!narrow)
      McColumn(
        picking ? 'Size' : 'Status',
        (row) => Text(
          picking ? archiveSize(row.bytes) : bundleState(row.item!.state),
        ),
        width: 150,
      ),
  ];

  @override
  Widget build(BuildContext context) => McCollection<String, BundleRow>(
    model: model,
    title: picking ? 'Archives in bundle' : 'Mods in bundle',
    showTitle: !narrow,
    showTree: false,
    compactFilter: narrow,
    filterLabel: picking ? 'Filter archives' : 'Filter mods',
    countLabel: picking
        ? '${chosen.length} selected'
        : '$installed of ${displayed.length} installed',
    filterActions: [
      McIconMenu<String>(
        label: picking ? 'Archive selection' : 'Mod actions',
        itemBuilder: menuItems,
        onSelected: onAction,
      ),
    ],
    onSelect: onSelect,
    columns: columns(context),
  );
}
