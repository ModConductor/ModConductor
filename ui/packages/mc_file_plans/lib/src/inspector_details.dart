part of 'inspector.dart';

class _FileDetails extends StatelessWidget {
  const _FileDetails({
    required this.selected,
    required this.view,
    required this.state,
  });

  final InspectedFileCopy selected;
  final FileInspectorController view;
  final FilePlanState? state;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      key: ValueKey(FileInspectorController.key(selected)),
      tilePadding: EdgeInsets.zero,
      title: Text(
        selected.copy == null ? 'File details' : 'Saved version and history',
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
        if (selected.sha256 case final sha256?) ...[
          const SizedBox(height: 8),
          SelectableText(
            selected.source is QualifiedArchiveEntryPreviewSource
                ? 'Archive SHA-256 $sha256'
                : 'SHA-256 $sha256',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        if (selected.copy != null) ...[
          const SizedBox(height: 12),
          if (view.loadingHistory) const LinearProgressIndicator(),
          if (view.historyProblem != null)
            McStatus(title: view.historyProblem!, tone: McStatusTone.error),
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
                view.historyProblem == null ? 'Load more history' : 'Retry',
              ),
            ),
        ],
      ],
    );
  }
}
