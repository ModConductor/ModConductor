import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_collections/mc_ui_collections.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'archive_facts.dart';

class NexusFileInspector extends StatelessWidget {
  const NexusFileInspector({
    super.key,
    required this.file,
    required this.modName,
    required this.accountName,
    required this.onClose,
    required this.downloadAction,
    required this.pageAction,
  });

  final NexusFile? file;
  final String? modName, accountName;
  final VoidCallback onClose;
  final Widget Function() downloadAction, pageAction;

  @override
  Widget build(BuildContext context) => McInspector(
    title: file?.name ?? 'File details',
    onClose: onClose,
    children: [
      if (file != null) ...[
        Text(modName ?? ''),
        const SizedBox(height: 16),
        Text('${file!.version} · ${archiveSize(file!.bytes)}'),
        const SizedBox(height: 16),
        Text(file!.category),
        const SizedBox(height: 16),
        Text(file!.description),
        const SizedBox(height: 16),
        McStatus(title: 'Nexus Mods', detail: accountName),
      ],
    ],
    footer: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [downloadAction(), pageAction()],
    ),
  );
}

class NexusFileCollection extends StatelessWidget {
  const NexusFileCollection({
    super.key,
    required this.model,
    required this.modName,
    required this.narrow,
    required this.busy,
    required this.downloadAction,
    required this.onDetails,
    required this.onSelect,
  });

  final McCollectionModel<int, NexusFile> model;
  final String? modName;
  final bool narrow, busy;
  final Widget Function() downloadAction;
  final VoidCallback onDetails;
  final ValueChanged<NexusFile> onSelect;

  List<Widget> filterActions(BuildContext context) => narrow
      ? [
          Expanded(
            child: Text(
              modName ?? 'Nexus Mods',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          downloadAction(),
          McIconAction(
            label: 'Mod details',
            icon: const Icon(Icons.info_outline),
            onPressed: model.selected == null ? null : onDetails,
          ),
        ]
      : const [];

  List<McColumn<NexusFile>> columns(BuildContext context) => [
    McColumn(
      'File',
      (file) => narrow
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(
                  '${file.category} · ${file.version} · ${archiveSize(file.bytes)}',
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            )
          : Text(file.name),
      width: narrow ? null : 340,
    ),
    if (!narrow) ...[
      McColumn('Version', (file) => Text(file.version), width: 100),
      McColumn('Size', (file) => Text(archiveSize(file.bytes)), width: 110),
      McColumn('Category', (file) => Text(file.category), width: 160),
    ],
  ];

  @override
  Widget build(BuildContext context) => McCollection<int, NexusFile>(
    model: model,
    title: modName ?? 'Nexus Mods',
    showTitle: !narrow,
    filterActions: filterActions(context),
    columns: columns(context),
    compactFilter: narrow,
    filterLabel: 'Filter files',
    countLabel:
        '${model.ids.length} ${model.ids.length == 1 ? 'file' : 'files'}',
    showTree: false,
    nodeLabel: (file) => file.name,
    nodeIcon: (_) => const Icon(Icons.description_outlined),
    loading: busy,
    onSelect: onSelect,
    footer: narrow
        ? null
        : Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              downloadAction(),
              McAction(
                label: 'Mod details',
                icon: Icons.info_outline,
                onPressed: model.selected == null ? null : onDetails,
              ),
            ],
          ),
  );
}
