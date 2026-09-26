import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_collections/mc_ui_collections.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'archive_facts.dart';
import 'controller.dart';
import 'download_view.dart';

class ArtifactCollection extends StatelessWidget {
  const ArtifactCollection({
    super.key,
    required this.controller,
    required this.narrow,
    required this.hasNexus,
    required this.focus,
    required this.addFocus,
    required this.scroll,
    required this.onAdd,
    required this.onDownload,
    required this.onNexus,
    required this.onSelect,
  });

  final ArtifactController controller;
  final bool narrow, hasNexus;
  final FocusNode focus, addFocus;
  final ScrollController scroll;
  final VoidCallback onAdd, onDownload, onNexus, onSelect;

  List<Widget> filterActions() => [
    if (narrow) ...[
      McIconAction(
        label: 'Add archive',
        icon: const Icon(Icons.add),
        focusNode: addFocus,
        onPressed: controller.canEdit ? onAdd : null,
      ),
      McIconAction(
        label: 'Download archive',
        icon: const Icon(Icons.download),
        onPressed: controller.canEdit ? onDownload : null,
      ),
    ],
    if (narrow && hasNexus) McAction(label: 'Nexus Mods', onPressed: onNexus),
  ];

  List<Widget> actions() => [
    if (!narrow && hasNexus) McAction(label: 'Nexus Mods', onPressed: onNexus),
    if (!narrow)
      McAction(
        label: 'Add archive',
        icon: Icons.add,
        focusNode: addFocus,
        onPressed: controller.canEdit ? onAdd : null,
      ),
    if (!narrow) ...[
      const SizedBox(width: 8),
      McAction(
        label: 'Download',
        icon: Icons.download,
        emphasis: McActionEmphasis.primary,
        onPressed: controller.canEdit ? onDownload : null,
      ),
    ],
  ];

  List<McColumn<Artifact>> columns() => [
    McColumn(
      'Name',
      (artifact) => McCollectionName(
        artifact.originalName,
        icon: Icons.inventory_2_outlined,
      ),
    ),
    McColumn(
      'Status',
      (artifact) => Text(
        artifact.download != null &&
                artifact.download!.phase != DownloadPhase.complete
            ? downloadLabel(artifact.download!)
            : archiveState(artifact.state),
      ),
      width: 160,
    ),
    if (!narrow)
      McColumn(
        'Size',
        (artifact) => Text(
          artifact.download != null &&
                  artifact.download!.phase != DownloadPhase.complete
              ? downloadSize(artifact.download!)
              : archiveSize(artifact.length),
        ),
        width: 150,
      ),
  ];

  @override
  Widget build(BuildContext context) => McCollection<String, Artifact>(
    model: controller.model,
    title: 'Archives',
    showTitle: !narrow,
    showTree: false,
    focusNode: focus,
    scrollController: scroll,
    filterLabel: controller.next == null
        ? 'Filter archives'
        : 'Filter loaded archives',
    countLabel:
        '${controller.model.ids.length} ${controller.model.ids.length == 1 ? 'archive' : 'archives'}${controller.next == null ? '' : ' loaded'}',
    empty: 'No archives.',
    loading: controller.busy,
    problem: controller.problem ?? controller.progressProblem,
    filterActions: filterActions(),
    actions: actions(),
    onRefresh: controller.busy || controller.client == null
        ? null
        : controller.load,
    onLoad: controller.next != null && !controller.busy
        ? () => controller.load(more: true)
        : null,
    onSelect: (_) => onSelect(),
    columns: columns(),
  );
}
