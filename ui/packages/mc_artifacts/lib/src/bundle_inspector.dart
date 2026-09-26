import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'archive_facts.dart';
import 'bundle_collection.dart';

class BundleInspector extends StatelessWidget {
  const BundleInspector({
    super.key,
    required this.row,
    required this.archiveName,
    required this.count,
    required this.busy,
    required this.onClose,
    required this.onPrimary,
    required this.onRename,
  });

  final BundleRow? row;
  final String archiveName;
  final int count;
  final bool busy;
  final VoidCallback onClose;
  final ValueChanged<BundleItem> onPrimary, onRename;

  String primaryLabel(BundleItem item) => switch (item.state) {
    BundleItemState.installed => 'Open Mods',
    BundleItemState.failed => 'Retry',
    BundleItemState.installing => 'View installation',
    BundleItemState.needsReview => 'Configure',
  };

  @override
  Widget build(BuildContext context) {
    final item = row?.item;
    return McInspector(
      title: row?.name ?? 'Archive',
      onClose: onClose,
      children: [
        if (row != null) ...[
          if (item?.problem != null) ...[
            McStatus(title: item!.problem!, tone: McStatusTone.error),
            const SizedBox(height: 16),
          ],
          archiveFact(context, 'Archive', row!.path),
          if (item != null)
            archiveFact(context, 'Destination', 'New mod: ${item.name}'),
          archiveFact(context, 'Archive size', archiveSize(row!.bytes)),
          if (item != null) ...[
            archiveFact(context, 'Status', bundleState(item.state)),
            McAction(
              label: primaryLabel(item),
              onPressed: busy ? null : () => onPrimary(item),
            ),
            const SizedBox(height: 16),
            if (item.state == BundleItemState.needsReview) ...[
              McAction(
                label: 'Change destination',
                onPressed: busy ? null : () => onRename(item),
              ),
              const SizedBox(height: 16),
            ],
            archiveFact(context, 'Source', archiveName),
            archiveFact(
              context,
              'Installation order',
              '${row!.order + 1} of $count',
            ),
          ],
        ] else
          const Text('No archives selected.'),
      ],
    );
  }
}
