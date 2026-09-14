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
    String status(InspectedFileCopy copy) => [
      switch (copy.standing) {
        FileSourceStanding.winner => stale ? 'Previous winner' : 'Winner',
        FileSourceStanding.alternative =>
          blocked ? 'Unresolved' : 'Alternative',
        FileSourceStanding.selected => 'Selected source',
        FileSourceStanding.previous => 'Previous saved version',
        FileSourceStanding.unavailable => 'Unavailable',
      },
      if (copy.hidden) 'Hidden',
      if (copy.copy != null && !copy.enabled && !copy.historical)
        profileName == null
            ? 'Disabled in this profile'
            : 'Disabled in $profileName',
    ].join(' · ');
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
                            copy.source.kindLabel,
                            if (copy.versionLabel.isNotEmpty &&
                                copy.source
                                    is! QualifiedArchiveEntryPreviewSource)
                              copy.versionLabel,
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
        if (selected != null) ...[
          const SizedBox(height: 16),
          SegmentedButton<FilePreviewRepresentation>(
            segments: const [
              ButtonSegment(
                value: FilePreviewRepresentation.text,
                label: Text('Text'),
              ),
              ButtonSegment(
                value: FilePreviewRepresentation.image,
                label: Text('Image'),
              ),
              ButtonSegment(
                value: FilePreviewRepresentation.hex,
                label: Text('Hex'),
              ),
            ],
            selected: {view.previewRepresentation},
            onSelectionChanged: (values) =>
                view.setPreviewRepresentation(values.single),
          ),
          const SizedBox(height: 12),
          if (view.previewLoading) ...[
            const LinearProgressIndicator(),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: view.cancelPreview,
                child: const Text('Cancel preview'),
              ),
            ),
          ] else if (view.previewProblem != null) ...[
            McStatus(title: view.previewProblem!, tone: McStatusTone.error),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => unawaited(view.loadPreview()),
                child: const Text('Retry preview'),
              ),
            ),
          ] else if (view.preview != null)
            _PreviewBody(preview: view.preview!),
        ],
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
              Text(selected.source.kindLabel),
              const SizedBox(height: 8),
              SelectableText(
                selected.source is QualifiedArchiveEntryPreviewSource
                    ? 'Archive SHA-256 ${selected.sha256}'
                    : 'SHA-256 ${selected.sha256}',
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

class _PreviewBody extends StatelessWidget {
  const _PreviewBody({required this.preview});
  final FilePreviewResult preview;

  @override
  Widget build(BuildContext context) {
    if (preview.status != FilePreviewStatus.ready) {
      return McStatus(
        title: preview.detail ?? 'This source cannot be previewed.',
        tone: preview.status == FilePreviewStatus.changed
            ? McStatusTone.error
            : McStatusTone.neutral,
      );
    }
    return switch (preview.content) {
      FilePreviewText value => DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SelectableText(
                value.content,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
          ),
        ),
      ),
      FilePreviewImage value => Semantics(
        label:
            '${value.format} image, ${value.width} by ${value.height} pixels',
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 420),
          child: Image.memory(
            value.content,
            cacheWidth: value.width,
            cacheHeight: value.height,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, _, _) => const McStatus(
              title: 'This image cannot be decoded safely.',
              tone: McStatusTone.error,
            ),
          ),
        ),
      ),
      FilePreviewHex value => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (value.truncated)
            Text(
              'Showing the first ${fileSize(value.content.length)} of ${fileSize(value.totalLength)}.',
            ),
          if (value.truncated) const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 420),
            child: SingleChildScrollView(
              child: SelectableText(
                _hex(value.content),
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
          ),
        ],
      ),
      null => const McStatus(title: 'This source has no preview.'),
    };
  }

  static String _hex(List<int> bytes) {
    final output = StringBuffer();
    for (var offset = 0; offset < bytes.length; offset += 16) {
      output.write(offset.toRadixString(16).padLeft(8, '0'));
      output.write('  ');
      final end = (offset + 16).clamp(0, bytes.length);
      for (var index = offset; index < end; ++index) {
        output.write(bytes[index].toRadixString(16).padLeft(2, '0'));
        output.write(index == offset + 7 ? '  ' : ' ');
      }
      output.writeln();
    }
    return output.toString();
  }
}
