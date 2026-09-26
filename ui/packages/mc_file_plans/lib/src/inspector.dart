import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'controller.dart';
import 'file_inspector_controller.dart';
import 'preview_image.dart';
import 'text_editor.dart';

part 'inspector_details.dart';
part 'inspector_preview.dart';
part 'inspector_sources.dart';
part 'inspector_text_editor.dart';

class FileSourcesInspector extends StatelessWidget {
  const FileSourcesInspector({
    super.key,
    this.controller,
    this.inspector,
    required this.onClose,
    this.profileName,
  }) : assert(controller != null || inspector != null);
  final FilePlansController? controller;
  final FileInspectorController? inspector;
  final VoidCallback onClose;
  final String? profileName;
  @override
  Widget build(BuildContext context) {
    final owner = controller;
    final view = inspector ?? owner!.inspector;
    final selected = view.selected;
    final state = owner?.state;
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
    final stale = state?.stale == true || owner?.needsRead == true;
    final available =
        owner != null &&
        owner.connected &&
        !owner.changing &&
        !owner.loading &&
        !owner.reading &&
        !owner.needsRead &&
        !view.loading;
    if (view.textDocument case final document?) {
      return _ManagedTextEditorInspector(
        controller: view,
        owner: owner,
        document: document,
        onClose: onClose,
      );
    }
    return McInspector(
      title: 'File sources',
      onClose: onClose,
      footer: selected?.copy == null || owner == null
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
                      ? () => unawaited(owner.change(hidden: !selected.hidden))
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
                : view.writable
                ? 'Writable game file'
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
        _FileCopyList(
          copies: copies,
          selected: selected,
          view: view,
          blocked: blocked,
          stale: stale,
          profileName: profileName,
        ),
        if (view.canLoad)
          TextButton(
            onPressed: view.loading ? null : () => unawaited(view.load()),
            child: const Text('Load more sources'),
          ),
        if (selected != null) ..._filePreviewChildren(view, available),
        if (selected != null)
          _FileDetails(selected: selected, view: view, state: state),
      ],
    );
  }
}
