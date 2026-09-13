import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_collections/mc_ui_collections.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'controller.dart';

class PluginsPane extends StatefulWidget {
  const PluginsPane({
    super.key,
    required this.controller,
    required this.narrow,
    required this.onInspect,
  });
  final PluginsController controller;
  final bool narrow;
  final VoidCallback onInspect;
  @override
  State<PluginsPane> createState() => _PluginsPaneState();
}

class _PluginsPaneState extends State<PluginsPane> {
  PluginsController get controller => widget.controller;
  bool get narrow => widget.narrow;
  VoidCallback get onInspect => widget.onInspect;
  @override
  void initState() {
    super.initState();
    unawaited(controller.validate());
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (c, _) {
      final state = controller.state;
      final order = controller.order;
      final count = state?.entries.length ?? 0,
          issues = state?.entries.where((r) => r.hasIssues).length ?? 0;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (controller.stale &&
              controller.problem == null &&
              !controller.reading) ...[
            const McStatus(
              title: 'The profile changed',
              detail: 'Refresh to read the current plugins.',
            ),
            const SizedBox(height: 8),
          ],
          if (controller.problem case final problem?) ...[
            McStatus(title: problem, tone: McStatusTone.error),
            const SizedBox(height: 8),
          ],
          if (state != null && state.problems.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: McAction(
                label: 'File source problems',
                icon: Icons.warning_amber,
                onPressed: () => showDialog<void>(
                  context: c,
                  builder: (_) => McDialog(
                    title: 'File source problems',
                    children: [
                      for (final problem in state.problems)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(problem),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (order?.pending == true) ...[
            McStatus(
              title: 'Plugin order was not fully applied',
              detail: order!.problem.isEmpty ? null : order.problem,
              tone: McStatusTone.error,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: McAction(
                label: 'Resume',
                icon: Icons.play_arrow,
                onPressed: !controller.reading && !controller.writing
                    ? () => unawaited(controller.resume())
                    : null,
              ),
            ),
            const SizedBox(height: 8),
          ] else if (order?.externalChanged == true) ...[
            const McStatus(
              title: 'The game plugin list changed',
              tone: McStatusTone.error,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: McAction(
                label: 'Use game order',
                icon: Icons.refresh,
                onPressed:
                    !controller.reading &&
                        !controller.writing &&
                        !controller.stale
                    ? () => unawaited(controller.useGameOrder())
                    : null,
              ),
            ),
            const SizedBox(height: 8),
          ] else if (order != null && order.issues.isNotEmpty) ...[
            McStatus(
              title: order.issues.first.detail,
              tone: McStatusTone.error,
            ),
            const SizedBox(height: 8),
          ],
          Expanded(
            child: McCollection<String, PluginEntry>(
              model: controller.rows,
              title: 'Plugins',
              showTitle: false,
              showTree: false,
              compactFilter: true,
              filterLabel: 'Filter plugins',
              onFilterChanged: (value) {
                controller.rows.filter(value);
                setState(() {});
              },
              multiSelect: true,
              selectMultiple: controller.multiple,
              onMoveUp: controller.canMove
                  ? () => unawaited(controller.change(PluginOrderAction.up))
                  : null,
              onMoveDown: controller.canMove
                  ? () => unawaited(controller.change(PluginOrderAction.down))
                  : null,
              onSort: controller.sort,
              countLabel: controller.reading
                  ? 'Read in progress'
                  : controller.writing
                  ? 'Saving plugin order'
                  : order != null
                  ? '${controller.rows.selectedIds.length > 1 ? '${controller.rows.selectedIds.length} selected · ' : ''}${order.full + order.light} enabled · ${controller.stale
                        ? 'Previous scan'
                        : order.issues.isNotEmpty
                        ? 'Needs attention'
                        : controller.rows.sortLabel != 'Order'
                        ? 'Sorted by name'
                        : order.applied
                        ? 'Applied'
                        : order.saved
                        ? 'Saved'
                        : 'Game order'}'
                  : state == null
                  ? 'Not scanned'
                  : '$count ${count == 1 ? 'plugin' : 'plugins'}${issues == 0 ? '' : ' · $issues with issues'}',
              empty: 'No plugins found.',
              emptyContent: state == null
                  ? Center(
                      child: McAction(
                        label: 'Scan plugins',
                        icon: Icons.search,
                        emphasis: McActionEmphasis.primary,
                        onPressed: controller.connected && !controller.reading
                            ? () => unawaited(controller.scan())
                            : null,
                      ),
                    )
                  : null,
              filterActions: [
                if (order != null) ...[
                  McIconAction(
                    label: 'Move selected plugins up (Ctrl+Up)',
                    icon: const Icon(Icons.arrow_upward),
                    onPressed: controller.canMove
                        ? () =>
                              unawaited(controller.change(PluginOrderAction.up))
                        : null,
                  ),
                  McIconAction(
                    label: 'Move selected plugins down (Ctrl+Down)',
                    icon: const Icon(Icons.arrow_downward),
                    onPressed: controller.canMove
                        ? () => unawaited(
                            controller.change(PluginOrderAction.down),
                          )
                        : null,
                  ),
                  McIconAction(
                    label:
                        controller
                                .setting(controller.rows.selectedId ?? '')
                                ?.lockedIndex !=
                            null
                        ? 'Unlock load position'
                        : 'Lock load position',
                    icon: Icon(
                      controller
                                  .setting(controller.rows.selectedId ?? '')
                                  ?.lockedIndex !=
                              null
                          ? Icons.lock
                          : Icons.lock_open,
                    ),
                    onPressed:
                        controller.canEdit &&
                            controller.rows.selectedIds.isNotEmpty &&
                            controller.rows.selectedIds.every(
                              (name) =>
                                  controller.setting(name)?.required == false &&
                                  (controller.setting(name)?.enabled == true ||
                                      controller.setting(name)?.lockedIndex !=
                                          null),
                            )
                        ? () => unawaited(
                            controller.change(
                              controller
                                          .setting(
                                            controller.rows.selectedId ?? '',
                                          )
                                          ?.lockedIndex !=
                                      null
                                  ? PluginOrderAction.unlock
                                  : PluginOrderAction.lock,
                            ),
                          )
                        : null,
                  ),
                ],
                McIconAction(
                  label: 'Refresh plugins',
                  icon: const Icon(Icons.refresh),
                  onPressed: controller.connected && !controller.reading
                      ? () => unawaited(controller.scan())
                      : null,
                ),
                McIconAction(
                  label: 'Inspect plugin',
                  icon: const Icon(Icons.info_outline),
                  onPressed: controller.rows.selected == null
                      ? null
                      : () {
                          controller.inspect();
                          onInspect();
                        },
                ),
                if (order != null)
                  McIconMenu<String>(
                    label: 'Plugin actions',
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'select',
                        child: Text(
                          controller.multiple
                              ? 'Select one'
                              : 'Select multiple',
                        ),
                      ),
                      PopupMenuItem(
                        value: 'enable',
                        enabled:
                            controller.canEdit &&
                            controller.rows.selectedIds.isNotEmpty,
                        child: const Text('Enable selected'),
                      ),
                      PopupMenuItem(
                        value: 'disable',
                        enabled:
                            controller.canEdit &&
                            controller.rows.selectedIds.isNotEmpty,
                        child: const Text('Disable selected'),
                      ),
                      const PopupMenuItem(
                        value: 'order',
                        child: Text('Show load order'),
                      ),
                      PopupMenuItem(
                        value: 'read',
                        enabled:
                            !controller.reading &&
                            !controller.writing &&
                            !controller.stale &&
                            !order.pending,
                        child: const Text('Use game order'),
                      ),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case 'select':
                          controller.toggleMultiple();
                        case 'enable':
                          unawaited(
                            controller.change(PluginOrderAction.enable),
                          );
                        case 'disable':
                          unawaited(
                            controller.change(PluginOrderAction.disable),
                          );
                        case 'order':
                          controller.sort('Order');
                        case 'read':
                          unawaited(controller.useGameOrder());
                      }
                    },
                  ),
              ],
              onSelect: (_) => setState(() {}),
              onActivate: (r) {
                controller.select(r);
                controller.inspect();
                onInspect();
              },
              columns: [
                if (order != null) ...[
                  McColumn(
                    '',
                    (r) => Checkbox(
                      value: controller.setting(r.name)?.enabled,
                      tristate: true,
                      onChanged: controller.canToggle(r.name)
                          ? (_) => unawaited(
                              controller.change(
                                controller.setting(r.name)?.enabled == true
                                    ? PluginOrderAction.disable
                                    : PluginOrderAction.enable,
                                name: r.name,
                              ),
                            )
                          : null,
                    ),
                    width: 40,
                    interactive: true,
                  ),
                  McColumn(
                    'Order',
                    (r) => Text(
                      controller.position(r.name) == 0
                          ? '—'
                          : '${controller.position(r.name)}',
                    ),
                    width: 65,
                    compare: (a, b) => controller
                        .position(a.name)
                        .compareTo(controller.position(b.name)),
                  ),
                ],
                McColumn(
                  'Plugin',
                  (r) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(r.name),
                      Text(
                        controller.issue(r.name) ??
                            (r.hasIssues
                                ? r.status
                                : '${r.kind}${controller.setting(r.name)?.required == true
                                      ? ' · Required'
                                      : controller.setting(r.name)?.lockedIndex != null
                                      ? ' · Locked'
                                      : ''}'),
                        style: Theme.of(c).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  compare: (a, b) =>
                      a.name.toLowerCase().compareTo(b.name.toLowerCase()),
                ),
                if (order == null)
                  McColumn('Status', (r) => Text(r.status), width: 190),
              ],
            ),
          ),
        ],
      );
    },
  );
}
