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
          Expanded(
            child: McCollection<String, PluginEntry>(
              model: controller.rows,
              title: 'Plugins',
              showTitle: false,
              showTree: false,
              compactFilter: true,
              filterLabel: 'Filter plugins',
              onFilterChanged: controller.rows.filter,
              countLabel: controller.reading
                  ? 'Read in progress'
                  : state == null
                  ? 'Not scanned'
                  : '$count ${count == 1 ? 'plugin' : 'plugins'}${controller.stale
                        ? ' · Previous scan'
                        : issues == 0
                        ? ''
                        : ' · $issues with issues'}',
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
              ],
              onSelect: controller.select,
              onActivate: (r) {
                controller.select(r);
                controller.inspect();
                onInspect();
              },
              columns: [
                McColumn(
                  'Plugin',
                  (r) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(r.name),
                      Text(
                        narrow
                            ? r.kind
                            : '${r.kind} · ${r.winner?.name ?? 'Unresolved'}',
                        style: Theme.of(c).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                McColumn(
                  'Status',
                  (r) => Text(r.status),
                  width: 190,
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
}
