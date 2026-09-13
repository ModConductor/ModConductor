import 'dart:async';

import 'package:mc_client/mc_client.dart';
import 'package:flutter/material.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'controller.dart';

class PluginInspector extends StatelessWidget {
  const PluginInspector({
    super.key,
    required this.controller,
    required this.onClose,
  });
  final PluginsController controller;
  final VoidCallback onClose;
  Widget fact(BuildContext c, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(c).textTheme.labelMedium),
        const SizedBox(height: 4),
        SelectableText(value),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (c, _) {
      final row = controller.rows.selected, header = row?.header;
      final order = controller.order,
          setting = controller.setting(row?.name ?? '');
      return McInspector(
        title: row?.name ?? 'Plugin',
        onClose: onClose,
        children: [
          if (row == null)
            const Text('Select a plugin.')
          else ...[
            if (order != null) ...[
              if (controller.issue(row.name) case final issue?) ...[
                McStatus(title: issue, tone: McStatusTone.error),
                const SizedBox(height: 12),
              ],
              fact(
                c,
                'Order',
                controller.position(row.name) == 0
                    ? 'Not in the saved order'
                    : '${controller.position(row.name)}',
              ),
              if (controller.loadPosition(row.name) case final position?)
                fact(c, 'Load position', '$position'),
              fact(
                c,
                'Enabled',
                setting?.enabled == null
                    ? 'Choose an active state'
                    : setting!.enabled!
                    ? 'Yes'
                    : 'No',
              ),
              if (setting?.required == true)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text('Required by Skyrim Special Edition'),
                ),
              if (setting?.lockedIndex case final locked?)
                fact(c, 'Locked load position', '${locked + 1}'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  McAction(
                    label: setting?.enabled == true ? 'Disable' : 'Enable',
                    icon: setting?.enabled == true
                        ? Icons.check_box_outline_blank
                        : Icons.check_box,
                    onPressed: controller.canToggle(row.name)
                        ? () => unawaited(
                            controller.change(
                              setting?.enabled == true
                                  ? PluginOrderAction.disable
                                  : PluginOrderAction.enable,
                              name: row.name,
                            ),
                          )
                        : null,
                  ),
                  McAction(
                    label: setting?.lockedIndex == null
                        ? 'Lock load position'
                        : 'Unlock load position',
                    icon: setting?.lockedIndex == null
                        ? Icons.lock_open
                        : Icons.lock,
                    onPressed:
                        controller.canEdit &&
                            setting?.required == false &&
                            (setting?.enabled == true ||
                                setting?.lockedIndex != null)
                        ? () => unawaited(
                            controller.change(
                              setting?.lockedIndex == null
                                  ? PluginOrderAction.lock
                                  : PluginOrderAction.unlock,
                              name: row.name,
                            ),
                          )
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            if (row.hasIssues) ...[
              McStatus(
                title: row.status,
                detail: row.problem,
                tone: McStatusTone.error,
              ),
              const SizedBox(height: 16),
            ],
            if (order?.unknown.any((entry) => entry.name == row.name) == true)
              fact(c, 'Source', 'Game list'),
            if (row.winner case final source?) ...[
              fact(c, 'Source', source.label),
              fact(c, 'File', source.path),
            ],
            if (header != null) ...[
              fact(c, 'Type', row.kind),
              fact(c, 'Header flags', header.flagLabels),
              fact(
                c,
                'Header version',
                header.headerVersion
                    .toStringAsFixed(2)
                    .replaceFirst(RegExp(r'0$'), ''),
              ),
              fact(c, 'Form version', '${header.formVersion}'),
              Text('Masters', style: Theme.of(c).textTheme.titleSmall),
              const SizedBox(height: 8),
              if (row.masters.isEmpty) const Text('None'),
              for (final master in row.masters) ...[
                Text(
                  master.status == 'Found'
                      ? master.name
                      : '${master.name} — ${master.status}',
                ),
                if (master.source case final source?)
                  Text(source.label, style: Theme.of(c).textTheme.bodySmall),
                const SizedBox(height: 12),
              ],
            ],
            if (order != null)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('Plugin slots'),
                children: [
                  fact(
                    c,
                    'Full plugins',
                    '${order.full} of ${order.fullLimit}',
                  ),
                  fact(c, 'Light plugins', '${order.light} of 4096'),
                ],
              ),
            if (row.alternatives.isNotEmpty)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                initiallyExpanded: row.winner == null,
                title: Text(
                  row.winner == null ? 'Sources' : 'Other file sources',
                ),
                children: [
                  for (final source in row.alternatives)
                    fact(c, source.label, source.path),
                ],
              ),
            if (header != null)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('Header details'),
                children: [
                  fact(c, 'Extension', header.extension),
                  fact(
                    c,
                    'Flags',
                    '0x${header.flags.toRadixString(16).padLeft(8, '0')}',
                  ),
                  if (header.author.isNotEmpty)
                    fact(c, 'Author', header.author),
                  if (header.description.isNotEmpty)
                    fact(c, 'Description', header.description),
                  fact(c, 'Declared records', '${header.records}'),
                ],
              ),
          ],
        ],
      );
    },
  );
}
