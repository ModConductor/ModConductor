import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_collections/mc_ui_collections.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'archive_facts.dart';
import 'installation_controller.dart';

String updateChange(UpdateChange value) => switch (value) {
  UpdateChange.add => 'Add',
  UpdateChange.replace => 'Replace',
  UpdateChange.remove => 'Remove',
  UpdateChange.keep => 'Keep',
};

class ModUpdateView extends StatefulWidget {
  const ModUpdateView({
    super.key,
    required this.controller,
    required this.client,
    required this.edit,
    required this.onBack,
  });
  final InstallationController controller;
  final MaintenanceClient client;
  final VoidCallback edit, onBack;
  @override
  State<ModUpdateView> createState() => _ModUpdateViewState();
}

class _ModUpdateViewState extends State<ModUpdateView> {
  final pane = GlobalKey<ScaffoldState>();
  final rows = McCollectionModel<String, UpdateFile>(
    idOf: (row) => jsonEncode(row.path),
    labelOf: (row) => row.path.join('/'),
  );
  UpdatePreview? rendered;
  bool inspected = false;
  InstallationController get controller => widget.controller;
  @override
  void dispose() {
    rows.dispose();
    super.dispose();
  }

  void change({UpdateMode? mode, UpdateFile? file, bool? keep}) {
    final value = controller.updatePreview!;
    final kept = [...value.keep];
    if (file != null) {
      final current = file.existingPaths.map(jsonEncode).toSet();
      final related = value.files
          .where(
            (candidate) =>
                candidate.hasIncoming &&
                (jsonEncode(candidate.path) == jsonEncode(file.path) ||
                    candidate.existingPaths.any(
                      (path) => current.contains(jsonEncode(path)),
                    )),
          )
          .toList();
      final destinations = related
          .map((entry) => jsonEncode(entry.path))
          .toSet();
      kept.removeWhere((path) => destinations.contains(jsonEncode(path)));
      if (keep == true) kept.addAll(related.map((entry) => entry.path));
    }
    unawaited(
      controller.prepareUpdate(
        widget.client,
        controller.updateTarget!,
        value.nextVersion,
        mode: mode ?? value.mode,
        keep: kept,
      ),
    );
  }

  Widget inspector(BuildContext context, VoidCallback close) {
    final row = rows.selected;
    return McInspector(
      title: row?.path.last ?? 'File',
      onClose: close,
      children: row == null
          ? []
          : [
              archiveFact(context, 'Destination', row.path.join('/')),
              archiveFact(context, 'Current', archiveSize(row.existingBytes)),
              if (row.hasIncoming)
                archiveFact(context, 'Archive', archiveSize(row.incomingBytes)),
              if (row.existingPaths.length > 1)
                archiveFact(
                  context,
                  'Current files',
                  row.existingPaths.map((path) => path.join('/')).join('\n'),
                ),
              if (row.hasIncoming && row.existingBytes != null)
                McChoice<bool>(
                  label: 'Use',
                  enabled: controller.canEdit,
                  value: controller.updatePreview!.keep.any(
                    (path) => jsonEncode(path) == jsonEncode(row.path),
                  ),
                  choices: const [false, true],
                  describe: (keep) => keep ? 'Keep current' : 'Use archive',
                  onChanged: (keep) => change(file: row, keep: keep),
                ),
            ],
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final value = controller.updatePreview!;
      if (!identical(rendered, value)) {
        rows.apply(upserts: value.files, evicted: rows.ids.toList());
        rendered = value;
      }
      final narrow =
          box.maxWidth < 1100 * MediaQuery.textScalerOf(context).scale(1);
      final counts = <String>[];
      for (final type in [
        UpdateChange.replace,
        UpdateChange.add,
        UpdateChange.remove,
      ]) {
        final count = value.files.where((row) => row.change == type).length;
        if (count > 0)
          counts.add(
            '$count ${switch (type) {
              UpdateChange.replace => 'replaced',
              UpdateChange.add => 'added',
              UpdateChange.remove => 'removed',
              UpdateChange.keep => 'kept',
            }}',
          );
      }
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
                  label: controller.startId == null
                      ? 'Back to archive layout'
                      : 'Back to archives',
                  icon: const Icon(Icons.arrow_back),
                  onPressed: controller.startId != null
                      ? widget.onBack
                      : controller.canEdit
                      ? controller.closeUpdate
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Update ${value.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                McIconAction(
                  label: 'Edit update details',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: controller.canEdit ? widget.edit : null,
                ),
                const SizedBox(width: 8),
                McAction(
                  label: 'Update',
                  icon: Icons.system_update_alt,
                  emphasis: McActionEmphasis.primary,
                  onPressed: controller.busy
                      ? null
                      : () => unawaited(controller.update(widget.client)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (!narrow) ...[
              Text(
                '${controller.draft!.archiveName} · Version ${value.currentVersion} to ${value.nextVersion}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
            ],
            if (controller.problem != null)
              McStatus(title: controller.problem!, tone: McStatusTone.error),
            if (controller.busy) const LinearProgressIndicator(),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: McCollection<String, UpdateFile>(
                      model: rows,
                      title: 'Update changes',
                      showTitle: !narrow,
                      showTree: false,
                      compactFilter: narrow,
                      filterLabel: 'Filter files',
                      countLabel: [
                        ...counts,
                        'up to ${archiveSize(value.requiredBytes)} extra',
                      ].join(' · '),
                      filterActions: [
                        if (narrow)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              '${value.currentVersion} to ${value.nextVersion}',
                            ),
                          ),
                        McMenuAction<UpdateMode>(
                          label: value.mode == UpdateMode.merge
                              ? 'Merge'
                              : 'Replace',
                          choices: UpdateMode.values,
                          describe: (mode) =>
                              mode == UpdateMode.merge ? 'Merge' : 'Replace',
                          enabled: controller.canEdit,
                          onSelected: (mode) => change(mode: mode),
                        ),
                      ],
                      onSelect: (_) {
                        setState(() => inspected = true);
                        if (narrow) pane.currentState?.openEndDrawer();
                      },
                      columns: [
                        McColumn(
                          'File',
                          (row) => McCollectionName(row.path.join('/')),
                        ),
                        McColumn(
                          'Action',
                          (row) => Text(updateChange(row.change), maxLines: 2),
                          width: narrow ? 115 : 220,
                        ),
                        if (!narrow)
                          McColumn(
                            'Size',
                            (row) => Text(
                              archiveSize(
                                row.incomingBytes ?? row.existingBytes,
                              ),
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
            if (value.sourceNotices.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ExpansionTile(
                  title: const Text('Source folder'),
                  children: [
                    for (final text in value.sourceNotices)
                      ListTile(title: Text(text)),
                  ],
                ),
              ),
          ],
        ),
      );
    },
  );
}
