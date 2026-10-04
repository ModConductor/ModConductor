import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_collections/mc_ui_collections.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'load_order_controller.dart';

class LoadOrderPane extends StatelessWidget {
  const LoadOrderPane({
    super.key,
    required this.controller,
    required this.narrow,
    this.pluginSetting,
    this.canTogglePlugin,
    this.onTogglePlugin,
    this.onInspectPlugin,
    this.onInspectCopy,
    this.onMovePlugins,
    this.problem,
  });
  final LoadOrderController controller;
  final bool narrow;
  final PluginSetting? Function(String)? pluginSetting;
  final bool Function(String)? canTogglePlugin;
  final ValueChanged<PluginEntry>? onTogglePlugin, onInspectPlugin;
  final ValueChanged<ManagedFileCopy>? onInspectCopy;
  final Future<bool> Function(List<String>, ProfileModMove)? onMovePlugins;
  final String? problem;

  void _inspect(LoadOrderRow row) {
    if (row.plugin case final plugin?) onInspectPlugin?.call(plugin);
    if (row.copy case final copy?) onInspectCopy?.call(copy);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final rows = controller.rows;
      final entryActions = <Widget>[
        McIconAction(
          label: 'Move selected entries up',
          icon: const Icon(Icons.arrow_upward),
          onPressed: controller.canMove && rows.selectedIds.isNotEmpty
              ? () => unawaited(
                  controller.move(
                    ProfileModMove.up,
                    movePlugins: onMovePlugins,
                  ),
                )
              : null,
        ),
        McIconAction(
          label: 'Move selected entries down',
          icon: const Icon(Icons.arrow_downward),
          onPressed: controller.canMove && rows.selectedIds.isNotEmpty
              ? () => unawaited(
                  controller.move(
                    ProfileModMove.down,
                    movePlugins: onMovePlugins,
                  ),
                )
              : null,
        ),
        McIconAction(
          label: 'Inspect selected entry',
          icon: const Icon(Icons.info_outline),
          onPressed:
              rows.selected?.plugin != null || rows.selected?.copy != null
              ? () => _inspect(rows.selected!)
              : null,
        ),
      ];
      return LayoutBuilder(
        builder: (context, bounds) {
          final compact = narrow && bounds.maxHeight < 250;
          return McCollection<String, LoadOrderRow>(
            model: rows,
            title: 'Load order',
            showTitle: false,
            compactFilter: compact,
            showTree: false,
            filterLabel: 'Filter plugins and files',
            countLabel:
                '${controller.layout.where((id) => id.startsWith('plugin:')).length} plugins · ${controller.sources.length} file groups',
            empty: 'No load order entries.',
            loading: controller.reading,
            problem: controller.problem ?? problem,
            multiSelect: true,
            onMoveUp: controller.canMove
                ? () => unawaited(
                    controller.move(
                      ProfileModMove.up,
                      movePlugins: onMovePlugins,
                    ),
                  )
                : null,
            onMoveDown: controller.canMove
                ? () => unawaited(
                    controller.move(
                      ProfileModMove.down,
                      movePlugins: onMovePlugins,
                    ),
                  )
                : null,
            onActivate: _inspect,
            filterActions: compact ? entryActions : const [],
            footer: compact
                ? null
                : Row(mainAxisSize: MainAxisSize.min, children: entryActions),
            columns: [
              McColumn(
                '',
                (row) => row.group
                    ? McCollectionExpander(model: rows, id: row.id)
                    : row.plugin != null &&
                          pluginSetting?.call(row.plugin!.name) != null
                    ? Checkbox(
                        value: pluginSetting!(row.plugin!.name)!.enabled,
                        tristate: true,
                        onChanged:
                            canTogglePlugin?.call(row.plugin!.name) == true
                            ? (_) => onTogglePlugin?.call(row.plugin!)
                            : null,
                      )
                    : const SizedBox.shrink(),
                width: 40,
                interactive: true,
              ),
              McColumn(
                'Entry',
                (row) => Padding(
                  padding: EdgeInsets.only(left: row.parent == null ? 0 : 18),
                  child: narrow
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Tooltip(
                              message: row.name,
                              child: McIconLabel(
                                icon: Icon(
                                  row.plugin != null
                                      ? Icons.extension_outlined
                                      : row.group
                                      ? Icons.folder_outlined
                                      : Icons.insert_drive_file_outlined,
                                  size: 19,
                                ),
                                label: row.name,
                                expanded: true,
                                maxLines: 1,
                                gap: 9,
                              ),
                            ),
                            Text(
                              row.type,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        )
                      : McCollectionName(
                          row.name,
                          icon: row.plugin != null
                              ? Icons.extension_outlined
                              : row.group
                              ? Icons.folder_outlined
                              : Icons.insert_drive_file_outlined,
                        ),
                ),
                compare: (a, b) =>
                    a.name.toLowerCase().compareTo(b.name.toLowerCase()),
              ),
              if (!narrow)
                McColumn('Type', (row) => Text(row.type), width: 160),
              McColumn(
                'Order',
                (row) => Text(
                  row.parent != null
                      ? ''
                      : '${controller.position(row.id)}'.padLeft(2, '0'),
                ),
                width: 66,
                compare: (a, b) => controller
                    .position(a.id)
                    .compareTo(controller.position(b.id)),
              ),
            ],
          );
        },
      );
    },
  );
}
