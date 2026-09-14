import 'package:flutter/material.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'sort_controller.dart';

class SortOrderInspector extends StatelessWidget {
  const SortOrderInspector({
    super.key,
    required this.controller,
    required this.onClose,
  });
  final SortOrderController controller;
  final VoidCallback onClose;

  Widget _fact(BuildContext context, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 4),
        SelectableText(value),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final row = controller.rows.selected, proposal = controller.proposal;
      return McInspector(
        title: row?.name ?? 'Plugin move',
        onClose: onClose,
        children: [
          if (row == null || proposal == null)
            const Text('Select a proposed plugin order entry.')
          else ...[
            _fact(context, 'Current order', '${row.current}'),
            _fact(context, 'Proposed order', '${row.proposed}'),
            _fact(context, 'Reason', row.reason),
            if (row.messages.isNotEmpty)
              _fact(
                context,
                'Messages',
                row.messages.map((message) => message.text).join('\n'),
              ),
            const Divider(),
            const SizedBox(height: 12),
            _fact(
              context,
              'Metadata',
              'Skyrim SE v0.29 · ${proposal.metadata.masterlistCommit.substring(0, 7)}',
            ),
            _fact(
              context,
              'Helper',
              'libloot ${proposal.liblootVersion} · protocol 1',
            ),
            _fact(
              context,
              'Context',
              'Checked Skyrim Special Edition Steam projection',
            ),
          ],
        ],
      );
    },
  );
}
