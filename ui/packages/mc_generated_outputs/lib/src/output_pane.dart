import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_collections/mc_ui_collections.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'output_controller.dart';
import 'output_tree.dart';
import 'location_dialog.dart';
import 'output_actions.dart';
import 'unfinished_review.dart';

class OutputPane extends StatefulWidget {
  const OutputPane({
    super.key,
    required this.controller,
    required this.kind,
    required this.narrow,
    required this.onInspect,
    this.profileId,
    this.organization,
    this.selectedMod,
  });
  final OutputController controller;
  final OutputLocationKind kind;
  final bool narrow;
  final VoidCallback onInspect;
  final String? profileId;
  final ModOrganizationClient? organization;
  final ModEntry? selectedMod;
  @override
  State<OutputPane> createState() => _OutputPaneState();
}

class _OutputPaneState extends State<OutputPane> {
  final _focus = FocusNode(debugLabel: 'Output files');
  bool _multiple = false;
  OutputTree get tree => widget.kind == OutputLocationKind.toolFolder
      ? widget.controller.tools
      : widget.controller.writable;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.controller.snapshot == null) {
        unawaited(widget.controller.refresh());
      }
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void inspect(OutputFile file) {
    widget.controller.inspect(file);
    widget.onInspect();
  }

  void action(String action) => unawaited(
    reviewOutputAction(
      context,
      controller: widget.controller,
      files: tree.selected,
      action: action,
      profileId: widget.profileId,
      organization: widget.organization,
      selectedMod: widget.selectedMod,
    ),
  );
  List<Widget> recoveryActions(OutputController controller) => [
    if (controller.pendingAction != null) ...[
      McAction(
        label: 'Read action result',
        onPressed: controller.changing
            ? null
            : () => unawaited(controller.checkResult()),
      ),
      if (controller.result?.complete == false)
        McAction(
          label: 'Continue review',
          onPressed: controller.changing
              ? null
              : () => unawaited(controller.resume(controller.pendingAction!)),
        ),
    ],
  ];
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([widget.controller, tree]),
    builder: (context, _) {
      final controller = widget.controller,
          writable = widget.kind == OutputLocationKind.writableFile;
      final locations =
          controller.scope?.locations
              .where((location) => location.kind == widget.kind)
              .toList() ??
          [];
      if (controller.problem != null ||
          (controller.pendingAction != null &&
              (controller.needsRead || !controller.changing))) {
        return SingleChildScrollView(
          child: McSection(
            title: writable ? 'Writable game files' : 'Tool outputs',
            children: [
              if (controller.problem != null)
                McStatus(title: controller.problem!, tone: McStatusTone.error),
              if (controller.result != null) ...[
                const SizedBox(height: 12),
                OutputResultStatus(controller: controller),
              ],
              if (controller.changing || controller.loading) ...[
                const SizedBox(height: 12),
                Text(
                  controller.changing
                      ? 'Saving output review…'
                      : 'Reading output files…',
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...recoveryActions(controller),
                  McAction(
                    label: controller.loading ? 'Cancel load' : 'Refresh',
                    onPressed: controller.changing
                        ? null
                        : controller.loading
                        ? () => unawaited(controller.cancel())
                        : () => unawaited(controller.refresh()),
                  ),
                ],
              ),
            ],
          ),
        );
      }
      final selected = tree.selected;
      final canAct = controller.canAct && selected.isNotEmpty;
      final actions = <Widget>[
        McAction(
          label: 'Keep',
          onPressed: canAct ? () => action('keep') : null,
        ),
        if (!writable)
          McAction(
            label: 'Create mod…',
            onPressed: canAct && widget.organization != null
                ? () => action('create')
                : null,
          ),
        McAction(
          label: writable ? 'Save copy to mod…' : 'Move to mod…',
          onPressed: canAct && widget.organization != null
              ? () => action(writable ? 'copy' : 'move')
              : null,
        ),
        McAction(
          label: 'Discard…',
          onPressed: canAct ? () => action('discard') : null,
        ),
      ];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (controller.scope?.pendingActions.isNotEmpty ?? false)
            Align(
              alignment: Alignment.centerLeft,
              child: McAction(
                label: 'Unfinished output reviews…',
                onPressed: controller.changing
                    ? null
                    : () => showDialog<void>(
                        context: context,
                        builder: (_) =>
                            UnfinishedOutputReview(controller: controller),
                      ),
              ),
            ),
          if (controller.result != null) ...[
            OutputResultStatus(controller: controller),
            const SizedBox(height: 8),
          ],
          if (controller.needsRead &&
              !controller.loading &&
              controller.result == null) ...[
            const McStatus(title: 'Refresh to check the current output files.'),
            const SizedBox(height: 8),
          ],
          Expanded(
            child: LayoutBuilder(
              builder: (context, bounds) {
                final compactActions =
                    widget.narrow ||
                    bounds.maxWidth <
                        640 * MediaQuery.textScalerOf(context).scale(1);
                return McCollection<String, OutputNode>(
                  model: tree.model,
                  focusNode: _focus,
                  title: writable ? 'Writable game files' : 'Tool outputs',
                  showTitle: false,
                  filterLabel: writable
                      ? 'Filter game files'
                      : 'Filter tool outputs',
                  filterText: tree.filter,
                  onFilterChanged: tree.search,
                  countLabel:
                      '${tree.unreviewed} unreviewed · ${tree.files} ${tree.files == 1 ? 'file' : 'files'}${tree.canLoad ? ' · ${tree.loadedFiles} paths loaded' : ''}',
                  empty: locations.isEmpty
                      ? (writable
                            ? 'No writable game files.'
                            : 'No tool output folders.')
                      : 'No output files match this view.',
                  emptyContent: locations.isEmpty
                      ? Center(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  writable
                                      ? 'No writable game files'
                                      : 'No tool output folders',
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  writable
                                      ? 'Add an exact game file to make it writable.'
                                      : 'Only files written to these folders appear here.',
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                McAction(
                                  label: writable
                                      ? 'Add writable file'
                                      : 'Add tool folder',
                                  onPressed:
                                      controller.scope == null ||
                                          controller.needsRead ||
                                          controller.changing
                                      ? null
                                      : () => showDialog<void>(
                                          context: context,
                                          builder: (_) =>
                                              AddOutputLocationDialog(
                                                controller: controller,
                                                kind: widget.kind,
                                              ),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : null,
                  filterActions: [
                    McIconAction(
                      label: writable
                          ? 'Writable game files'
                          : 'Tool output folders',
                      icon: const Icon(Icons.folder_open_outlined),
                      onPressed: controller.scope == null
                          ? null
                          : () => showDialog<void>(
                              context: context,
                              builder: (_) => OutputLocationsDialog(
                                controller: controller,
                                kind: widget.kind,
                              ),
                            ),
                    ),
                    if (compactActions)
                      PopupMenuButton<String>(
                        tooltip: 'Review selected outputs',
                        enabled: canAct,
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'keep',
                            child: Text('Keep'),
                          ),
                          if (!writable)
                            const PopupMenuItem(
                              value: 'create',
                              child: Text('Create mod…'),
                            ),
                          PopupMenuItem(
                            value: writable ? 'copy' : 'move',
                            child: Text(
                              writable ? 'Save copy to mod…' : 'Move to mod…',
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'discard',
                            child: Text('Discard…'),
                          ),
                        ],
                        onSelected: action,
                      ),
                    McIconAction(
                      label: 'Inspect output',
                      icon: const Icon(Icons.info_outline),
                      onPressed: tree.model.selected?.file == null
                          ? null
                          : () => inspect(tree.model.selected!.file!),
                    ),
                  ],
                  toolbar: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      FilterChip(
                        label: const Text('Select multiple'),
                        selected: _multiple,
                        onSelected: (value) =>
                            setState(() => _multiple = value),
                      ),
                      Text('${tree.selected.length} selected'),
                      if (!compactActions) ...actions,
                      if (controller.changing)
                        const Text('Saving output review…'),
                    ],
                  ),
                  multiSelect: true,
                  selectMultiple: _multiple,
                  onActivate: (row) {
                    if (row.file != null) inspect(row.file!);
                  },
                  semanticLabel: (row) =>
                      '${row.path.join('/')}, ${row.folder ? 'folder' : outputStatus(row.file!.status)}',
                  loading:
                      controller.loading || controller.reading || tree.loading,
                  problem: tree.problem,
                  onLoad: tree.canLoad && !controller.loading
                      ? () => unawaited(tree.load())
                      : null,
                  onCancel: controller.loading
                      ? () => unawaited(controller.cancel())
                      : null,
                  onRefresh: controller.changing
                      ? null
                      : () => unawaited(controller.refresh()),
                  footer: Text(
                    controller.snapshot == null
                        ? 'Not checked'
                        : controller.loading
                        ? 'Reading output files…'
                        : 'Shared across profiles',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  columns: [
                    McColumn('Name', (row) => McCollectionName(row.path.last)),
                    if (!widget.narrow)
                      McColumn(
                        'Location',
                        (row) => Text(
                          locations
                                  .where(
                                    (location) => location.id == row.locationId,
                                  )
                                  .firstOrNull
                                  ?.name ??
                              '',
                          maxLines: 2,
                        ),
                        width: 120,
                      ),
                    McColumn(
                      'Size',
                      (row) => Text(
                        row.file == null ||
                                row.file!.status == OutputFileStatus.absent
                            ? ''
                            : outputSize(row.file!.length),
                      ),
                      width: 85,
                    ),
                    McColumn(
                      'Status',
                      (row) => Text(
                        row.file == null ? '' : outputStatus(row.file!.status),
                      ),
                      width: 100,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      );
    },
  );
}
