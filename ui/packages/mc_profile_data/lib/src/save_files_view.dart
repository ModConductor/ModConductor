part of 'save_files.dart';

String _displaySavePath(ProfileSavePath value) => value.windowsPath == null
    ? value.hostPath
    : '${value.windowsPath}\n${value.hostPath}';

String _saveSize(int value) {
  if (value >= 1024 * 1024) {
    return '${(value / (1024 * 1024)).toStringAsFixed(1)} MiB';
  }
  if (value >= 1024) return '${(value / 1024).toStringAsFixed(1)} KiB';
  return '$value B';
}

class _SaveFact extends StatelessWidget {
  const _SaveFact(this.label, this.value);
  final String label, value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        SelectableText(value),
      ],
    ),
  );
}

class _SaveActionButton extends StatelessWidget {
  const _SaveActionButton({required this.session, required this.onPreview});

  final _SaveFilesSession session;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    if (session.action != null) {
      return McAction(
        label: 'Cancel',
        onPressed: () => unawaited(session.cancel()),
      );
    }
    return McAction(
      label: session.source == ProfileSaveSource.global
          ? 'Copy to profile'
          : 'Delete',
      icon: session.source == ProfileSaveSource.global
          ? Icons.content_copy
          : Icons.delete_outline,
      onPressed: !session.busy && session.selected.isNotEmpty
          ? onPreview
          : null,
    );
  }
}

class _SaveGroupCollection extends StatelessWidget {
  const _SaveGroupCollection({required this.session, required this.onPreview});

  final _SaveFilesSession session;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    final model = session.model;
    return McCollection<String, ProfileSaveGroupEntry>(
      model: model,
      title: 'Save groups',
      showTitle: false,
      filterLabel: 'Filter loaded saves',
      countLabel:
          '${model.length} ${model.length == 1 ? 'entry' : 'entries'}${session.next != null ? ' loaded' : ''}',
      empty: session.busy ? 'Reading save groups…' : 'No save groups.',
      loading: session.busy,
      problem: session.problem,
      onRefresh: session.busy ? null : () => unawaited(session.read()),
      onLoad: session.busy || session.next == null
          ? null
          : () => unawaited(session.read(more: true)),
      onSelect: (entry) => unawaited(session.inspect(entry)),
      multiSelect: true,
      columns: [
        McColumn(
          'Save',
          (entry) => Row(
            children: [
              Icon(
                entry.kind == ProfileSaveEntryKind.save
                    ? Icons.save_outlined
                    : entry.kind == ProfileSaveEntryKind.directory
                    ? Icons.folder_outlined
                    : Icons.insert_drive_file_outlined,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(entry.name, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
        McColumn(
          'Files',
          (entry) => Text(entry.companion == null ? '1' : '2'),
          width: 56,
        ),
        McColumn(
          'Size',
          (entry) => Text(_saveSize(entry.bytes + entry.companionBytes)),
          width: 90,
        ),
      ],
      toolbar: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          SegmentedButton<ProfileSaveSource>(
            segments: const [
              ButtonSegment(
                value: ProfileSaveSource.profile,
                label: Text('Profile'),
              ),
              ButtonSegment(
                value: ProfileSaveSource.global,
                label: Text('Global'),
              ),
            ],
            selected: {session.source},
            onSelectionChanged: session.busy
                ? null
                : (value) => session.chooseSource(value.single),
          ),
          _SaveActionButton(session: session, onPreview: onPreview),
        ],
      ),
    );
  }
}

class _SaveDetails extends StatelessWidget {
  const _SaveDetails({
    required this.session,
    required this.onClose,
    required this.onPreview,
    this.actionInFooter = false,
  });

  final _SaveFilesSession session;
  final VoidCallback onClose, onPreview;
  final bool actionInFooter;

  @override
  Widget build(BuildContext context) {
    final value = session.inspection;
    final entry = value?.entry ?? session.model.selected;
    return McInspector(
      title: entry?.name ?? 'Save details',
      onClose: onClose,
      footer: actionInFooter
          ? _SaveActionButton(session: session, onPreview: onPreview)
          : null,
      children: [
        if (entry == null)
          const Text('Select a save to view its details.')
        else ...[
          _SaveFact('Files', [entry.name, ?entry.companion].join('\n')),
          _SaveFact('Size', _saveSize(entry.bytes + entry.companionBytes)),
          if (entry.problem case final detail?)
            McStatus(title: detail, tone: McStatusTone.error),
          if (value?.metadataProblem case final detail?)
            McStatus(title: 'Metadata unavailable', detail: detail),
          if (value?.metadata case final metadata?) ...[
            _SaveFact(
              'Character',
              '${metadata.character} · Level ${metadata.level}',
            ),
            _SaveFact('Location', metadata.location),
            _SaveFact('Game time', metadata.gameTime),
            _SaveFact('Save number', '${metadata.saveNumber}'),
            _SaveFact(
              'Format',
              'Skyrim save ${metadata.headerVersion} · form ${metadata.formVersion} · ${metadata.compression.name.toUpperCase()}',
            ),
          ],
          if (value?.pluginCheckProblem case final detail?)
            McStatus(title: 'Plugin check unavailable', detail: detail)
          else if (value != null &&
              value.pluginIssues.isEmpty &&
              value.metadata != null)
            const McStatus(title: 'No missing or inactive plugins found.')
          else if (value != null && value.pluginIssues.isNotEmpty) ...[
            Text(
              'Plugin issues',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            for (final issue in value.pluginIssues)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(issue.name),
                subtitle: issue.source == null ? null : Text(issue.source!),
                trailing: Text(
                  issue.state == SavePluginState.missing
                      ? 'Missing'
                      : 'Inactive',
                ),
              ),
          ],
          const SizedBox(height: 16),
          const McStatus(
            title: 'Steam Cloud is not managed here.',
            detail: 'Cloud copies and remote state will not be changed.',
          ),
        ],
      ],
    );
  }
}
