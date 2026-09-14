import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mc_ui_collections/mc_ui_collections.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'sort_controller.dart';

class SortOrderPane extends StatelessWidget {
  const SortOrderPane({
    super.key,
    required this.controller,
    required this.narrow,
    required this.onInspect,
  });
  final SortOrderController controller;
  final bool narrow;
  final VoidCallback onInspect;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final proposal = controller.proposal;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (controller.problem case final problem?) ...[
            McStatus(title: problem, tone: McStatusTone.error),
            const SizedBox(height: 8),
          ],
          if (controller.stale && controller.problem == null) ...[
            const McStatus(title: 'The plugin order changed'),
            const SizedBox(height: 8),
          ],
          if (proposal != null) ...[
            McStatus(
              title: 'Proposed order is ready',
              detail:
                  '${proposal.moves.length} moves · ${proposal.messages.length} messages',
            ),
            const SizedBox(height: 8),
          ] else if (controller.state case final state?) ...[
            if (!state.available)
              McStatus(
                title: state.reason.isEmpty
                    ? 'LOOT sorting is not available.'
                    : state.reason,
                tone: McStatusTone.error,
              ),
            const SizedBox(height: 8),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (proposal == null)
                McAction(
                  label: 'Preview sort',
                  icon: Icons.sort,
                  emphasis: McActionEmphasis.primary,
                  onPressed: controller.canPreview
                      ? () => unawaited(controller.preview())
                      : null,
                )
              else ...[
                McAction(
                  label: 'Apply proposed order',
                  icon: Icons.check_circle_outline,
                  emphasis: McActionEmphasis.primary,
                  onPressed: controller.canApply
                      ? () => unawaited(controller.apply())
                      : null,
                ),
                McAction(
                  label: 'Dismiss proposal',
                  icon: Icons.close,
                  onPressed: controller.reading
                      ? null
                      : () => unawaited(controller.dismiss()),
                ),
              ],
              McAction(
                label: 'Refresh metadata',
                icon: Icons.cloud_download_outlined,
                onPressed: controller.reading || controller.writing
                    ? null
                    : () => unawaited(controller.refreshMetadata()),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: McCollection<String, SortOrderRow>(
              model: controller.rows,
              title: 'Proposed plugin order',
              showTitle: false,
              showTree: false,
              compactFilter: true,
              filterLabel: 'Filter proposed order',
              onFilterChanged: controller.rows.filter,
              countLabel: controller.reading
                  ? 'LOOT action in progress'
                  : proposal == null
                  ? 'No proposal'
                  : '${proposal.sorted.length} plugins · ${proposal.moves.length} moves',
              empty: 'Preview a sort to review proposed changes.',
              filterActions: [
                McIconAction(
                  label: 'Inspect plugin move',
                  icon: const Icon(Icons.info_outline),
                  onPressed: controller.rows.selected == null
                      ? null
                      : () {
                          controller.inspect();
                          onInspect();
                        },
                ),
              ],
              onSelect: controller.select,
              onActivate: (_) {
                controller.inspect();
                onInspect();
              },
              columns: [
                McColumn(
                  'Order',
                  (row) => Text(
                    row.current == row.proposed
                        ? '${row.proposed}'
                        : '${row.current} to ${row.proposed}',
                  ),
                  width: narrow ? 84 : 100,
                ),
                McColumn(
                  'Plugin',
                  (row) => narrow
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              row.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              row.messages.isEmpty
                                  ? row.reason
                                  : row.messages.first.text,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        )
                      : Text(
                          row.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
                if (!narrow)
                  McColumn(
                    'Reason',
                    (row) => Text(row.reason, maxLines: 2),
                    width: 230,
                  ),
              ],
            ),
          ),
        ],
      );
    },
  );
}
