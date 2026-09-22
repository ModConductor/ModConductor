import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_collections/mc_ui_collections.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'controller.dart';
import 'problems_dialog.dart';

class PlannedFiles extends StatefulWidget {
  const PlannedFiles({
    super.key,
    required this.controller,
    required this.onInspect,
    required this.focusNode,
    this.narrow = false,
    this.archiveUnavailable = false,
    this.onOpenProblems,
  });

  final FilePlansController controller;
  final ValueChanged<PlannedFileNode> onInspect;
  final FocusNode focusNode;
  final bool narrow, archiveUnavailable;
  final VoidCallback? onOpenProblems;

  @override
  State<PlannedFiles> createState() => _PlannedFilesState();
}

class _PlannedFilesState extends State<PlannedFiles> {
  String? _automaticRequest;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
    _scheduleAutomaticLoad();
  }

  @override
  void didUpdateWidget(PlannedFiles oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller.removeListener(_changed);
      widget.controller.addListener(_changed);
      _automaticRequest = null;
    }
    _scheduleAutomaticLoad();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
    _scheduleAutomaticLoad();
  }

  void _scheduleAutomaticLoad() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startAutomaticLoad();
    });
  }

  void _startAutomaticLoad() {
    final controller = widget.controller;
    final state = controller.state;
    if (!controller.connected ||
        controller.loading ||
        controller.reading ||
        controller.changing ||
        state == null) {
      return;
    }
    final needsLoad = !state.loaded || state.stale || controller.needsRead;
    if (!needsLoad) return;
    final request =
        '${state.id}:${state.fingerprint}:${state.loaded}:'
        '${state.stale}:${controller.needsRead}';
    if (_automaticRequest == request) return;
    _automaticRequest = request;
    unawaited(controller.acquire(refresh: state.loaded));
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
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
    final loaded = state?.loaded == true;

    if (!loaded) {
      if (controller.problem case final problem?) {
        return McStructuredState(
          tone: McStructuredStateTone.error,
          title: 'The Data folder cannot be read',
          detail: problem,
          action: McAction(
            label: 'Retry',
            icon: Icons.refresh,
            onPressed: busy
                ? null
                : state == null
                ? () => unawaited(controller.read())
                : () => unawaited(controller.acquire(refresh: false)),
          ),
        );
      }
      if (!controller.connected) {
        return const McStructuredState(
          tone: McStructuredStateTone.unavailable,
          title: 'Skyrim Data is unavailable',
        );
      }
      return McStructuredState(
        tone: McStructuredStateTone.loading,
        title: 'Reading file names',
        detail: progress == null
            ? null
            : progress.totalFiles == 0
            ? '${progress.files} files'
            : '${progress.files} of ${progress.totalFiles} files',
      );
    }

    String origin(PlannedFileNode row) => row.directory
        ? ''
        : switch (row.disposition) {
            PlannedFileDisposition.writable => row.sourceName,
            PlannedFileDisposition.planned => row.sourceName,
            PlannedFileDisposition.absent => 'Absent',
            PlannedFileDisposition.unresolved => 'Unresolved',
          };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (controller.loading) ...[
          const McActionFeedback(
            kind: McActionFeedbackKind.pending,
            message: 'Refreshing file names',
          ),
          const SizedBox(height: 8),
        ] else if (controller.problem case final problem?) ...[
          McActionFeedback(
            kind: McActionFeedbackKind.failure,
            message: 'The file list could not refresh',
            detail: problem,
          ),
          const SizedBox(height: 8),
        ],
        if (blocked) ...[
          McActionFeedback(
            kind: McActionFeedbackKind.failure,
            message: state!.problems.firstOrNull ?? 'Files cannot be planned',
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed:
                  widget.onOpenProblems ??
                  () => showDialog<void>(
                    context: context,
                    builder: (_) =>
                        FileProblemsDialog(load: controller.problems),
                  ),
              child: const Text('Show problems'),
            ),
          ),
          const SizedBox(height: 8),
        ],
        Expanded(
          child: LayoutBuilder(
            builder: (context, bounds) {
              final compact = bounds.maxWidth < 500;
              return McCollection<String, PlannedFileNode>(
                model: tree.model,
                focusNode: widget.focusNode,
                title: 'Skyrim Data',
                showTitle: false,
                filterLabel: 'Filter files',
                filterText: tree.filter,
                onFilterChanged: tree.search,
                countLabel: blocked
                    ? '${state!.inspectedFiles} files inspected'
                    : stale
                    ? '${state!.plannedFiles} files from the previous scan'
                    : '${state!.plannedFiles} ${state.plannedFiles == 1 ? 'file' : 'files'}${tree.filter.trim().isEmpty ? '' : ' total'}${state.absentTargets == 0 ? '' : ' · ${state.absentTargets} absent ${state.absentTargets == 1 ? 'target' : 'targets'}'}',
                empty: tree.filter.trim().isEmpty
                    ? 'No files found.'
                    : 'No matching files.',
                emptyContent: tree.filter.trim().isEmpty
                    ? const McStructuredState(
                        tone: McStructuredStateTone.empty,
                        title: 'No files found',
                        detail: 'The Data folder is empty.',
                      )
                    : null,
                loading: tree.loading,
                problem: tree.problem,
                onLoad: tree.canLoad ? () => unawaited(tree.loadMore()) : null,
                onRefresh: busy
                    ? null
                    : () => unawaited(controller.acquire(refresh: true)),
                filterActions: [
                  McIconAction(
                    label: 'Inspect file',
                    icon: const Icon(Icons.info_outline),
                    onPressed: selected == null || selected.directory
                        ? null
                        : () => widget.onInspect(selected),
                  ),
                ],
                onActivate: (row) {
                  if (!row.directory) widget.onInspect(row);
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
        if (widget.archiveUnavailable) ...[
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
