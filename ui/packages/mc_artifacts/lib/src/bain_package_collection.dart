import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_collections/mc_ui_collections.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'archive_facts.dart';

class BainPackageCollection extends StatelessWidget {
  const BainPackageCollection({
    super.key,
    required this.model,
    required this.value,
    required this.narrow,
    required this.available,
    required this.hasWizardScripts,
    required this.onOrder,
    required this.onMenuAction,
    required this.onSelect,
    required this.onChoose,
  });

  final McCollectionModel<int, BainPackage> model;
  final BainChoices? value;
  final bool narrow, available, hasWizardScripts;
  final VoidCallback onOrder;
  final ValueChanged<String> onMenuAction;
  final ValueChanged<BainPackage> onSelect;
  final void Function(BainPackage, bool) onChoose;

  List<McColumn<BainPackage>> columns() => [
    McColumn(
      '',
      (package) => Checkbox(
        value: package.selected,
        onChanged: available
            ? (selected) => onChoose(package, selected!)
            : null,
      ),
      width: 48,
      interactive: true,
    ),
    if (!narrow)
      McColumn(
        'Order',
        (package) => Text(
          '${(value?.packages.indexWhere((row) => row.index == package.index) ?? 0) + 1}',
        ),
        width: 65,
      ),
    McColumn('Package folder', (package) => McCollectionName(package.name)),
    if (!narrow)
      McColumn('Files', (package) => Text('${package.files}'), width: 80),
    if (!narrow)
      McColumn(
        'Size',
        (package) => Text(archiveSize(package.bytes)),
        width: 100,
      ),
  ];

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (!narrow)
        Text('Package folders', style: Theme.of(context).textTheme.titleMedium),
      Row(
        children: [
          Expanded(
            child: Text(
              'Later folders replace earlier files.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          McIconAction(
            label: 'Folder order',
            icon: const Icon(Icons.info_outline),
            onPressed: onOrder,
          ),
        ],
      ),
      const SizedBox(height: 8),
      Expanded(
        child: McCollection<int, BainPackage>(
          model: model,
          title: 'Package folders',
          showTitle: false,
          showTree: false,
          compactFilter: narrow,
          filterLabel: 'Filter folders',
          countLabel:
              '${value?.packages.where((package) => package.selected).length ?? 0} of ${value?.packages.length ?? 0} folders selected',
          filterActions: [
            if (hasWizardScripts) ...[
              Text(
                'Wizard script not supported',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(width: 8),
            ],
            McIconMenu<String>(
              label: 'Folder selection',
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'all',
                  enabled: available,
                  child: const Text('Select all'),
                ),
                PopupMenuItem(
                  value: 'none',
                  enabled: available,
                  child: const Text('Clear selection'),
                ),
                if (value?.hasNotes == true)
                  PopupMenuItem(
                    value: 'notes',
                    enabled: available,
                    child: const Text('Package notes'),
                  ),
              ],
              onSelected: onMenuAction,
            ),
          ],
          onSelect: onSelect,
          columns: columns(),
        ),
      ),
    ],
  );
}
