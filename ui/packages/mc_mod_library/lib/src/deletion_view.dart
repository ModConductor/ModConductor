import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_collections/mc_ui_collections.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'deletion_controller.dart';

String deletionSize(int? bytes) {
  if (bytes == null) return 'Size unavailable';
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}

Widget deletionFact(BuildContext context, String label, String text) => Padding(
  padding: const EdgeInsets.only(bottom: 16),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: 4),
      Text(text),
    ],
  ),
);
String deletionDeploymentLabel(BuildContext context, DeletionDeployment value) {
  final time = value.preparedAt?.toLocal();
  if (time == null) return value.name;
  final locale = MaterialLocalizations.of(context);
  return '${value.name} · ${locale.formatMediumDate(time)}, ${locale.formatTimeOfDay(TimeOfDay.fromDateTime(time))}';
}

String deletionTotal(DeletionPreview value) {
  final files = value.files.where(
    (file) => !file.shared && file.kind != DeletionFileKind.generationLink,
  );
  final bytes = files.any((file) => file.bytes == null)
      ? null
      : files.fold(0, (sum, file) => sum + file.bytes!);
  return '${value.versions} ${value.versions == 1 ? 'version' : 'versions'} · ${value.backups.length} ${value.backups.length == 1 ? 'backup' : 'backups'} · ${deletionSize(bytes)}';
}

class _DeletionRow {
  const _DeletionRow(this.id, this.label, this.action, this.bytes);
  final int id;
  final String label, action;
  final int? bytes;
}

class ModDeletionView extends StatefulWidget {
  const ModDeletionView({
    super.key,
    required this.controller,
    this.onOpenDeployment,
  });
  final DeletionController controller;
  final VoidCallback? onOpenDeployment;
  @override
  State<ModDeletionView> createState() => _ModDeletionViewState();
}

class _ModDeletionViewState extends State<ModDeletionView> {
  final pane = GlobalKey<ScaffoldState>();
  final rows = McCollectionModel<int, _DeletionRow>(
    idOf: (row) => row.id,
    labelOf: (row) => row.label,
  );
  bool keep = false, inspected = false;
  DeletionPreview? rendered;
  DeletionController get controller => widget.controller;
  @override
  void dispose() {
    rows.dispose();
    super.dispose();
  }

  void load(DeletionPreview value) {
    final values = <_DeletionRow>[];
    var index = 0;
    for (final file in value.files) {
      if (file.shared == keep) {
        values.add(
          _DeletionRow(
            index,
            file.label,
            keep
                ? 'Used by another mod'
                : switch (file.kind) {
                    DeletionFileKind.archive => 'Delete copy',
                    DeletionFileKind.generationLink => 'Delete link',
                    DeletionFileKind.payload ||
                    DeletionFileKind.temporary => 'Delete',
                  },
            file.bytes,
          ),
        );
      }
      ++index;
    }
    if (keep) {
      for (final path in value.external) {
        values.add(_DeletionRow(index++, path, 'Original', null));
      }
    }
    rows.apply(upserts: values, evicted: rows.ids.toList());
    rendered = value;
  }

  Future<void> confirm() async {
    final value = controller.preview!;
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => McFormDialog(
        title: 'Delete ${value.name}?',
        action: 'Delete',
        onSubmit: () => Navigator.pop(context, true),
        children: [
          deletionFact(context, 'Delete', deletionTotal(value)),
          if (value.profiles.isNotEmpty)
            deletionFact(
              context,
              'Remove from profiles',
              value.profiles.map((profile) => profile.name).join(' · '),
            ),
          if (value.deployments.isNotEmpty)
            deletionFact(
              context,
              'Saved deployments that become unavailable',
              value.deployments
                  .map((entry) => deletionDeploymentLabel(context, entry))
                  .join('\n'),
            ),
          const Text(
            'Original archives, source folders and files used by other mods stay unchanged.',
          ),
        ],
      ),
    );
    if (yes == true && mounted) await controller.run();
  }

  Widget inspector(BuildContext context, VoidCallback close) {
    final row = rows.selected;
    return McInspector(
      title: row?.label ?? 'File',
      onClose: close,
      children: row == null
          ? []
          : [
              deletionFact(context, row.action, row.label),
              if (row.bytes != null)
                deletionFact(context, 'Size', deletionSize(row.bytes)),
            ],
    );
  }

  Widget outcome(BuildContext context) {
    final status = controller.status, value = controller.preview;
    final title = status == null
        ? 'Deletion unavailable'
        : switch (status.phase) {
            DeletionPhase.running => 'Deleting ${status.name}',
            DeletionPhase.incomplete => 'Deletion incomplete',
            DeletionPhase.complete => '${status.name} deleted',
          };
    return Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 670),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 20, 4, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                McActionFeedback(
                  kind: status == null
                      ? McActionFeedbackKind.refusal
                      : switch (status.phase) {
                          DeletionPhase.running => McActionFeedbackKind.pending,
                          DeletionPhase.incomplete =>
                            McActionFeedbackKind.failure,
                          DeletionPhase.complete =>
                            McActionFeedbackKind.success,
                        },
                  message: title,
                  detail: status?.problem ?? value?.blocked,
                ),
                const SizedBox(height: 24),
                if (status != null && status.phase != DeletionPhase.complete)
                  deletionFact(
                    context,
                    'Files left to delete',
                    '${status.remaining}',
                  ),
                if (status?.phase == DeletionPhase.complete) ...[
                  if (value?.deployments.isNotEmpty == true)
                    deletionFact(
                      context,
                      'Saved deployments',
                      '${value!.deployments.length} are now unavailable',
                    ),
                  McAction(
                    label: 'Open Mods',
                    icon: Icons.layers_outlined,
                    onPressed: controller.back,
                  ),
                ],
                if (status == null && value != null) ...[
                  if (value.deployments.any((entry) => entry.active)) ...[
                    deletionFact(
                      context,
                      'Active deployment',
                      value.deployments
                          .where((entry) => entry.active)
                          .map((entry) => entry.name)
                          .join('\n'),
                    ),
                    if (widget.onOpenDeployment != null)
                      McAction(
                        label: 'Open deployment',
                        icon: Icons.swap_horiz,
                        onPressed: widget.onOpenDeployment,
                      ),
                  ],
                  const SizedBox(height: 16),
                  McAction(
                    label: 'Back to mod',
                    icon: Icons.arrow_back,
                    onPressed: controller.back,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final value = controller.preview, status = controller.status;
      final narrow =
          box.maxWidth < 1100 * MediaQuery.textScalerOf(context).scale(1);
      final result = status != null || value?.blocked != null;
      if (value != null && !identical(rendered, value)) load(value);
      return Scaffold(
        key: pane,
        backgroundColor: Colors.transparent,
        endDrawer: Drawer(
          width: 440,
          child: inspector(context, () => pane.currentState?.closeEndDrawer()),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                McIconAction(
                  label: 'Back to Mods',
                  icon: const Icon(Icons.arrow_back),
                  onPressed: controller.back,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result
                        ? status?.name ?? value?.name ?? 'Mod deletion'
                        : 'Delete ${value?.name ?? 'mod'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (status?.phase == DeletionPhase.incomplete)
                  McAction(
                    label: 'Continue deletion',
                    icon: Icons.delete_outline,
                    emphasis: McActionEmphasis.primary,
                    onPressed: controller.busy
                        ? null
                        : () => unawaited(controller.run()),
                  ),
                if (!result && value != null)
                  McAction(
                    label: 'Delete…',
                    icon: Icons.delete_outline,
                    emphasis: McActionEmphasis.primary,
                    onPressed: controller.busy ? null : confirm,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (!narrow && !result && value != null) ...[
              Text(
                '${value.name} · all saved versions and backups',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
            ],
            if (controller.problem != null)
              Row(
                children: [
                  Expanded(
                    child: McActionFeedback(
                      kind: McActionFeedbackKind.failure,
                      message: controller.problem!,
                    ),
                  ),
                  if (status?.phase == DeletionPhase.running)
                    McAction(
                      label: 'Check progress',
                      onPressed: controller.observe,
                    ),
                ],
              ),
            if (controller.busy && status == null)
              McActionFeedback(
                kind: McActionFeedbackKind.pending,
                message: value == null
                    ? 'Checking mod files'
                    : 'Deleting ${value.name}',
              ),
            Expanded(
              child: result
                  ? outcome(context)
                  : value == null
                  ? const SizedBox.shrink()
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: McCollection<int, _DeletionRow>(
                            model: rows,
                            title: keep ? 'Files to keep' : 'Files to delete',
                            showTitle: !narrow,
                            showTree: false,
                            compactFilter: narrow,
                            filterLabel: 'Filter files',
                            countLabel: deletionTotal(value),
                            filterActions: [
                              McMenuAction<bool>(
                                label: keep ? 'Keep' : 'Delete',
                                choices: const [false, true],
                                describe: (keep) => keep ? 'Keep' : 'Delete',
                                onSelected: (value) => setState(() {
                                  keep = value;
                                  load(controller.preview!);
                                }),
                              ),
                            ],
                            onSelect: (_) {
                              setState(() => inspected = true);
                              if (narrow) pane.currentState?.openEndDrawer();
                            },
                            columns: [
                              McColumn(
                                'File',
                                (row) => McCollectionName(row.label),
                              ),
                              McColumn(
                                'Action',
                                (row) => Text(row.action, maxLines: 2),
                                width: narrow ? 115 : 220,
                              ),
                              if (!narrow)
                                McColumn(
                                  'Size',
                                  (row) => Text(
                                    row.bytes == null
                                        ? ''
                                        : deletionSize(row.bytes),
                                  ),
                                  width: 90,
                                ),
                            ],
                          ),
                        ),
                        if (inspected && !narrow) ...[
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 360,
                            child: inspector(
                              context,
                              () => setState(() => inspected = false),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      );
    },
  );
}
