import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_collections/mc_ui_collections.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'archive_controller.dart';

class ArchivePolicyPane extends StatefulWidget {
  const ArchivePolicyPane({
    super.key,
    required this.controller,
    required this.narrow,
    required this.onInspect,
  });
  final ArchivePolicyController controller;
  final bool narrow;
  final VoidCallback onInspect;

  @override
  State<ArchivePolicyPane> createState() => _ArchivePolicyPaneState();
}

class _ArchivePolicyPaneState extends State<ArchivePolicyPane> {
  @override
  void initState() {
    super.initState();
    unawaited(widget.controller.validate());
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final controller = widget.controller, state = controller.state;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (controller.problem case final problem?) ...[
            McStatus(title: problem, tone: McStatusTone.error),
            const SizedBox(height: 8),
          ],
          if (controller.stale && controller.problem == null) ...[
            const McStatus(
              title: 'The profile changed',
              detail: 'Refresh to read the current archives.',
            ),
            const SizedBox(height: 8),
          ],
          if (state?.pending == true) ...[
            McStatus(
              title: 'Archive changes were not fully applied',
              detail: state!.pendingProblem.isEmpty
                  ? null
                  : state.pendingProblem,
              tone: McStatusTone.error,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: McAction(
                label: 'Resume',
                icon: Icons.play_arrow,
                onPressed: controller.writing
                    ? null
                    : () => unawaited(controller.resume()),
              ),
            ),
            const SizedBox(height: 8),
          ] else if (state != null && state.blockingProblems.isNotEmpty) ...[
            McStatus(
              title: state.blockingProblems.first,
              tone: McStatusTone.error,
            ),
            const SizedBox(height: 8),
          ] else if (state != null && !state.applied) ...[
            McStatus(
              title: 'Archive changes',
              detail: state.changes.join('\n'),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: McAction(
                label: 'Apply archive changes',
                icon: Icons.check,
                emphasis: McActionEmphasis.primary,
                onPressed: controller.canApply
                    ? () => unawaited(controller.apply())
                    : null,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Expanded(
            child: McCollection<String, ArchivePolicyEntry>(
              model: controller.rows,
              title: 'Archives',
              showTitle: false,
              showTree: false,
              compactFilter: true,
              filterLabel: 'Filter archives',
              onFilterChanged: (value) {
                controller.rows.filter(value);
                setState(() {});
              },
              countLabel: controller.reading
                  ? 'Reading archives'
                  : controller.writing
                  ? 'Saving archive changes'
                  : state == null
                  ? 'Not scanned'
                  : '${state.entries.where((row) => row.state == ArchiveState.active).length} active · ${controller.stale
                        ? 'Previous scan'
                        : state.applied
                        ? 'Up to date'
                        : 'Changes'}',
              empty: 'No archives found.',
              emptyContent: state == null
                  ? Center(
                      child: McAction(
                        label: 'Scan archives',
                        icon: Icons.search,
                        emphasis: McActionEmphasis.primary,
                        onPressed: controller.connected && !controller.reading
                            ? () => unawaited(controller.scan())
                            : null,
                      ),
                    )
                  : null,
              filterActions: [
                McIconAction(
                  label: 'Refresh archives',
                  icon: const Icon(Icons.refresh),
                  onPressed: controller.connected && !controller.reading
                      ? () => unawaited(controller.scan())
                      : null,
                ),
                McIconAction(
                  label: 'Inspect archive',
                  icon: const Icon(Icons.info_outline),
                  onPressed: controller.rows.selected == null
                      ? null
                      : () {
                          controller.inspect();
                          widget.onInspect();
                        },
                ),
                if (controller.canRestore)
                  McIconMenu<String>(
                    label: 'Archive actions',
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'restore',
                        child: Text('Restore original archive settings'),
                      ),
                    ],
                    onSelected: (_) => unawaited(controller.restore()),
                  ),
              ],
              onSelect: (_) => setState(() {}),
              onActivate: (_) {
                controller.inspect();
                widget.onInspect();
              },
              columns: [
                McColumn(
                  'Order',
                  (row) => Text(row.position == null ? '—' : '${row.position}'),
                  width: 65,
                ),
                McColumn(
                  'Archive',
                  (row) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(row.name),
                      Text(
                        row.problem.isNotEmpty
                            ? row.problem
                            : '${row.state.name[0].toUpperCase()}${row.state.name.substring(1)}${row.required ? ' · Required' : ''}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (!widget.narrow)
                  McColumn('Format', (row) => Text(row.format), width: 110),
              ],
            ),
          ),
        ],
      );
    },
  );
}
