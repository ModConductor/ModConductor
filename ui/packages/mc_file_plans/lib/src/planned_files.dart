import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_collections/mc_ui_collections.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'controller.dart';
import 'inspector.dart';
import 'problems_dialog.dart';

class PlannedFiles extends StatelessWidget {
  const PlannedFiles({
    super.key,
    required this.controller,
    required this.onInspect,
    required this.focusNode,
    this.narrow = false,
    this.archiveUnavailable = false,
  });
  final FilePlansController controller;
  final ValueChanged<PlannedFileNode> onInspect;
  final FocusNode focusNode;
  final bool narrow, archiveUnavailable;
  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final tree = controller.tree;
    final selected = tree.model.selected;
    final progress = controller.progress;
    final busy =
        !controller.connected ||
        controller.loading ||
        controller.reading ||
        controller.changing;
    final stale = state?.stale == true || controller.needsRead;
    final blocked = (state?.problemCount ?? 0) != 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (controller.problem != null ||
            controller.needsRead ||
            (state?.loaded == true && blocked)) ...[
          McStatus(
            title:
                controller.problem ??
                (controller.needsRead
                    ? 'The file view needs a check.'
                    : 'Files cannot be planned'),
            detail: controller.problem == null && blocked
                ? state?.problems.firstOrNull
                : null,
            tone: McStatusTone.error,
          ),
          if (controller.needsRead)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: busy ? null : () => unawaited(controller.read()),
                child: const Text('Reload'),
              ),
            ),
          if (blocked)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => FileProblemsDialog(load: controller.problems),
                ),
                child: const Text('Show problems'),
              ),
            ),
          const SizedBox(height: 12),
        ],
        if (controller.loading || state?.loaded != true)
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: McSection(
                title: 'Planned files',
                children: [
                  McStatus(
                    title: controller.loading
                        ? 'Checking game files…'
                        : 'Skyrim Data',
                    detail: progress == null
                        ? 'Game folder and enabled mods'
                        : '${fileSize(progress.bytes)} of ${fileSize(progress.totalBytes)} · ${progress.files} of ${progress.totalFiles} files',
                  ),
                  const SizedBox(height: 24),
                  if (controller.loading) ...[
                    LinearProgressIndicator(
                      value: progress == null || progress.totalBytes == 0
                          ? null
                          : progress.bytes / progress.totalBytes,
                    ),
                    const SizedBox(height: 24),
                  ],
                  McAction(
                    label: controller.loading ? 'Cancel' : 'Load files',
                    icon: controller.loading ? Icons.close : Icons.folder_open,
                    emphasis: controller.loading
                        ? McActionEmphasis.secondary
                        : McActionEmphasis.primary,
                    onPressed: controller.loading
                        ? () => unawaited(controller.cancel())
                        : busy || !controller.connected
                        ? null
                        : () => unawaited(controller.acquire(refresh: false)),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: LayoutBuilder(
              builder: (context, bounds) {
                final compact = bounds.maxWidth < 500;
                String origin(PlannedFileNode row) => row.directory
                    ? ''
                    : switch (row.disposition) {
                        PlannedFileDisposition.writable => row.sourceName,
                        PlannedFileDisposition.planned => row.sourceName,
                        PlannedFileDisposition.absent => 'Absent',
                        PlannedFileDisposition.unresolved => 'Unresolved',
                      };
                return McCollection<String, PlannedFileNode>(
                  model: tree.model,
                  focusNode: focusNode,
                  title: 'Planned files',
                  showTitle: !narrow,
                  filterLabel: 'Filter files',
                  filterText: tree.filter,
                  onFilterChanged: tree.search,
                  countLabel: blocked
                      ? '${state!.inspectedFiles} files inspected'
                      : stale
                      ? '${state!.plannedFiles} previously planned files'
                      : '${state!.plannedFiles} planned ${state.plannedFiles == 1 ? 'file' : 'files'}${tree.filter.trim().isEmpty ? '' : ' total'}${state.absentTargets == 0 ? '' : ' · ${state.absentTargets} absent ${state.absentTargets == 1 ? 'target' : 'targets'}'}',
                  empty: tree.filter.trim().isEmpty
                      ? 'No planned files.'
                      : 'No matching files.',
                  loading: tree.loading,
                  problem: tree.problem,
                  onLoad: tree.canLoad
                      ? () => unawaited(tree.loadMore())
                      : null,
                  onRefresh: busy
                      ? null
                      : () => unawaited(controller.acquire(refresh: true)),
                  filterActions: [
                    McIconAction(
                      label: 'Inspect file',
                      icon: const Icon(Icons.info_outline),
                      onPressed: selected == null || selected.directory
                          ? null
                          : () => onInspect(selected),
                    ),
                  ],
                  onActivate: (row) {
                    if (!row.directory) onInspect(row);
                  },
                  semanticLabel: (row) => row.directory
                      ? '${row.path.last}, folder'
                      : '${row.path.join('/')}, ${origin(row)}',
                  columns: [
                    McColumn(
                      'Name',
                      (row) => compact && !row.directory
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  row.path.last,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  origin(row),
                                  style: Theme.of(context).textTheme.bodySmall,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            )
                          : McCollectionName(row.path.last),
                    ),
                    if (!compact)
                      McColumn(
                        'Source',
                        (row) =>
                            Text(origin(row), overflow: TextOverflow.ellipsis),
                        width: 120,
                      ),
                  ],
                );
              },
            ),
          ),
        if (archiveUnavailable) ...[
          const SizedBox(height: 8),
          Text(
            'Archive contents are not shown.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}
