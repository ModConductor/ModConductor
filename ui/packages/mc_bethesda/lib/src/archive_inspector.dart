import 'package:flutter/material.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'archive_controller.dart';

class ArchivePolicyInspector extends StatelessWidget {
  const ArchivePolicyInspector({
    super.key,
    required this.controller,
    required this.onClose,
  });
  final ArchivePolicyController controller;
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
      final row = controller.rows.selected;
      return McInspector(
        title: row?.name ?? 'Archive',
        onClose: onClose,
        children: [
          if (row == null)
            const Text('Select an archive.')
          else ...[
            if (row.problem.isNotEmpty) ...[
              McStatus(title: row.problem, tone: McStatusTone.error),
              const SizedBox(height: 12),
            ],
            _fact(context, 'State', row.state.name),
            if (row.position case final position?)
              _fact(context, 'Archive order', '${position + 1}'),
            if (row.iniKey.isNotEmpty)
              _fact(
                context,
                'Skyrim.ini',
                '${row.iniKey}, position ${(row.iniPosition ?? 0) + 1}',
              ),
            if (row.associatedPlugin.isNotEmpty)
              _fact(context, 'Enabled plugin', row.associatedPlugin),
            if (row.format.isNotEmpty) _fact(context, 'Format', row.format),
            if (row.source case final source?) ...[
              _fact(context, 'Source', source.label),
              _fact(context, 'File', source.path),
            ],
            if (row.reasons.isNotEmpty)
              _fact(context, 'Why', row.reasons.join('\n')),
            _fact(
              context,
              'Archive invalidation',
              'Not available for this game.',
            ),
          ],
        ],
      );
    },
  );
}
