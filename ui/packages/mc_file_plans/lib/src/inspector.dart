import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'controller.dart';
import 'file_inspector_controller.dart';

String fileSize(int bytes) => bytes >= 1024 * 1024 * 1024
    ? '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GiB'
    : bytes >= 1024 * 1024
    ? '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MiB'
    : bytes >= 1024
    ? '${(bytes / 1024).toStringAsFixed(1)} KiB'
    : '$bytes B';

class FileSourcesInspector extends StatelessWidget {
  const FileSourcesInspector({
    super.key,
    required this.controller,
    required this.onClose,
    this.profileName,
  });
  final FilePlansController controller;
  final VoidCallback onClose;
  final String? profileName;
  @override
  Widget build(BuildContext context) {
    final view = controller.inspector;
    final selected = view.selected;
    final state = controller.state;
    final path = view.target ?? view.requestedCopy?.path ?? const <String>[];
    final copies = [...view.copies];
    final focused = view.focusedCopy;
    if (focused != null &&
        !copies.any(
          (copy) =>
              FileInspectorController.key(copy) ==
              FileInspectorController.key(focused),
        )) {
      copies.insert(0, focused);
    }
    final winner = copies.where((copy) => copy.winner).firstOrNull;
    final blocked = (state?.problemCount ?? 0) > 0;
    final stale = state?.stale == true || controller.needsRead;
    final available =
        controller.connected &&
        !controller.changing &&
        !controller.loading &&
        !controller.reading &&
        !controller.needsRead &&
        !view.loading;
    String status(InspectedFileCopy copy) => [
      if (copy.historical) 'Previous saved version',
      if (copy.hidden) 'Hidden',
      if (copy.copy != null && !copy.enabled && !copy.historical)
        profileName == null
            ? 'Disabled in this profile'
            : 'Disabled in $profileName',
      if (copy.winner) stale ? 'Previous winner' : 'Winner',
      if (!copy.winner && !copy.hidden && copy.enabled && !copy.historical)
        blocked ? 'Unresolved' : 'Overridden',
    ].join(' · ');
    return McInspector(
      title: 'File sources',
      onClose: onClose,
      footer: selected?.copy == null
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Hide and Unhide affect all profiles.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                McAction(
                  label: selected!.hidden
                      ? 'Unhide this copy'
                      : 'Hide this copy',
                  icon: selected.hidden
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  onPressed:
                      available &&
                          (selected.hidden
                              ? selected.canUnhide
                              : selected.canHide)
                      ? () => unawaited(
                          controller.change(hidden: !selected.hidden),
                        )
                      : null,
                ),
              ],
            ),
      children: [
        Text(
          path.isEmpty ? 'File' : path.last,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        if (path.length > 1)
          Text(path.join('/'), style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 16),
        if (view.problem != null) ...[
          McStatus(title: view.problem!, tone: McStatusTone.error),
          TextButton(
            onPressed: view.loading ? null : () => unawaited(view.reload()),
            child: const Text('Retry'),
          ),
        ] else if (view.loading && copies.isEmpty)
          const LinearProgressIndicator()
        else
          McStatus(
            title: selected?.historical == true
                ? 'Previous saved version'
                : blocked
                ? 'Files cannot be planned'
                : stale
                ? (winner == null
                      ? 'Previous file view'
                      : 'Previous winner: ${winner.name}')
                : winner != null
                ? 'Winner: ${winner.name}'
                : view.canLoad
                ? 'More sources available'
                : 'Absent from planned files',
            detail: blocked
                ? state?.problems.firstOrNull
                : stale
                ? 'Refresh to check the current files.'
                : null,
            tone: blocked ? McStatusTone.error : McStatusTone.neutral,
          ),
        const SizedBox(height: 16),
        RadioGroup<Object>(
          groupValue: selected == null
              ? null
              : FileInspectorController.key(selected),
          onChanged: (value) {
            final row = copies
                .where((row) => FileInspectorController.key(row) == value)
                .firstOrNull;
            if (row != null) view.select(row);
          },
          child: Column(
            children: [
              for (final copy in copies) ...[
                RadioListTile<Object>(
                  value: FileInspectorController.key(copy),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(
                    copy.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          [
                            if (copy.versionLabel.isNotEmpty) copy.versionLabel,
                            if (copy.priority != null)
                              'Priority ${copy.priority! + 1}',
                            fileSize(copy.length),
                          ].join(' · '),
                        ),
                        if (status(copy).isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(status(copy)),
                        ],
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1),
              ],
            ],
          ),
        ),
        if (view.canLoad)
          TextButton(
            onPressed: view.loading ? null : () => unawaited(view.load()),
            child: const Text('Load more sources'),
          ),
        if (selected != null)
          ExpansionTile(
            key: ValueKey(FileInspectorController.key(selected)),
            tilePadding: EdgeInsets.zero,
            title: Text(
              selected.copy == null
                  ? 'File details'
                  : 'Saved version and history',
            ),
            onExpansionChanged: (expanded) {
              if (expanded && selected.copy != null && !view.historyLoaded) {
                unawaited(view.loadHistory());
              }
            },
            children: [
              if (selected.copy != null)
                SelectableText(
                  'Saved version ${selected.copy!.versionId}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              if (selected.copy == null && state?.observedAt != null)
                Text(
                  MaterialLocalizations.of(context)
                      .formatMediumDate(state!.observedAt!.toLocal()),
                ),
              const SizedBox(height: 8),
              SelectableText(
                selected.sourcePath.join('/'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              SelectableText(
                'SHA-256 ${selected.sha256}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (selected.copy != null) ...[
                const SizedBox(height: 12),
                if (view.loadingHistory) const LinearProgressIndicator(),
                if (view.historyProblem != null)
                  McStatus(
                    title: view.historyProblem!,
                    tone: McStatusTone.error,
                  ),
                if (view.historyLoaded && view.history.isEmpty)
                  const Text('No file visibility changes.'),
                for (final change in view.history)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(change.hidden ? 'Hidden' : 'Unhidden'),
                    subtitle: Text(
                      '${MaterialLocalizations.of(context).formatMediumDate(change.recordedAt.toLocal())} · ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(change.recordedAt.toLocal()))}',
                    ),
                  ),
                if (view.canLoadHistory)
                  TextButton(
                    onPressed: view.loadingHistory
                        ? null
                        : () => unawaited(view.loadHistory()),
                    child: Text(
                      view.historyProblem == null
                          ? 'Load more history'
                          : 'Retry',
                    ),
                  ),
              ],
            ],
          ),
      ],
    );
  }
}
