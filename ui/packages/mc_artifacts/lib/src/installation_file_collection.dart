import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_collections/mc_ui_collections.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'archive_facts.dart';
import 'installation_controller.dart';
import 'installation_tree.dart';

class InstallationRootChoice extends StatelessWidget {
  const InstallationRootChoice({
    super.key,
    required this.draft,
    required this.narrow,
    required this.enabled,
    required this.onSelected,
  });

  final InstallationDraft draft;
  final bool narrow, enabled;
  final ValueChanged<List<String>> onSelected;

  @override
  Widget build(BuildContext context) => McMenuAction<List<String>>(
    label: narrow
        ? 'Root: ${draft.root.isEmpty ? 'Archive' : draft.root.join(' / ')}'
        : 'Root folder',
    choices: [
      for (var i = 0; i <= draft.root.length; ++i) draft.root.take(i).toList(),
    ],
    describe: (path) => path.isEmpty ? 'Archive root' : path.join(' / '),
    enabled: enabled,
    onSelected: onSelected,
  );
}

class InstallationFileCollection extends StatelessWidget {
  const InstallationFileCollection({
    super.key,
    required this.draft,
    required this.tree,
    required this.controller,
    required this.manual,
    required this.excluded,
    required this.narrow,
    required this.onLayout,
    required this.onExcluded,
    required this.onInspect,
  });

  final InstallationDraft draft;
  final InstallationTree tree;
  final InstallationController controller;
  final bool manual, excluded, narrow;
  final ValueChanged<bool> onLayout, onExcluded;
  final VoidCallback onInspect;

  int get included => draft.files.length;
  int get omitted =>
      draft.manifest.entries.where((entry) => !entry.directory).length -
      included;

  String get countLabel {
    if (manual) return '$included included · $omitted excluded';
    if (excluded) return '$omitted excluded ${omitted == 1 ? 'file' : 'files'}';
    final files =
        '$included ${included == 1 ? 'file' : 'files'} · ${archiveSize(draft.bytes)}';
    return narrow
        ? '$files · Mod starts disabled'
        : '$files · $omitted excluded';
  }

  List<Widget> filterActions(BuildContext context) => [
    if (draft.wizardScripts.isNotEmpty) ...[
      Text(
        'Wizard script not supported',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(width: 8),
    ],
    if (narrow) ...[
      if (manual)
        InstallationRootChoice(
          draft: draft,
          narrow: true,
          enabled: controller.canEdit,
          onSelected: (path) =>
              unawaited(controller.change(InstallationRootChange(path))),
        )
      else ...[
        Flexible(
          child: Text(
            draft.root.isEmpty ? 'Archive root' : draft.root.join(' / '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        McIconAction(
          label: 'Change layout',
          icon: const Icon(Icons.account_tree_outlined),
          onPressed: controller.canEdit ? () => onLayout(true) : null,
        ),
      ],
    ],
    if (!manual) ...[
      const SizedBox(width: 8),
      McMenuAction<bool>(
        label: excluded ? 'Excluded ($omitted)' : 'Included ($included)',
        choices: const [false, true],
        describe: (value) =>
            value ? 'Excluded ($omitted)' : 'Included ($included)',
        onSelected: onExcluded,
      ),
    ],
  ];

  List<McColumn<InstallationRow>> columns() => [
    McColumn(
      manual || excluded ? 'Archive path' : 'Destination',
      (row) => Row(
        children: [
          if (manual)
            Checkbox(
              tristate: true,
              value: row.included,
              onChanged: controller.canEdit
                  ? (_) => unawaited(
                      controller.change(
                        InstallationInclusionChange(
                          row.components,
                          row.included != true,
                        ),
                      ),
                    )
                  : null,
            ),
          Expanded(
            child: McCollectionName(
              row.name,
              icon: row.directory ? Icons.folder_outlined : null,
            ),
          ),
        ],
      ),
      interactive: manual,
    ),
    if (!narrow && manual)
      McColumn(
        'Destination',
        (row) => Text(
          row.included == false
              ? 'Excluded'
              : row.destination == null
              ? ''
              : row.destination!.isEmpty
              ? 'Mod root'
              : row.destination!.join('/'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        width: 270,
      ),
    if (!narrow)
      McColumn(
        'Size',
        (row) => Text(row.directory ? '' : archiveSize(row.size)),
        width: 90,
      ),
  ];

  @override
  Widget build(BuildContext context) => McCollection<String, InstallationRow>(
    model: tree.model,
    title: manual
        ? 'Archive files'
        : excluded
        ? 'Excluded archive files'
        : 'Files in new mod',
    showTitle: !narrow,
    showTree: true,
    filterLabel: 'Filter files',
    filterEnabled: !controller.busy,
    compactFilter: narrow,
    countLabel: countLabel,
    filterActions: filterActions(context),
    onSelect: manual ? (_) => onInspect() : null,
    columns: columns(),
  );
}
