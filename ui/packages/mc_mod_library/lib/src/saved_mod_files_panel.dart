part of 'browser.dart';

extension _SavedModFilesPanel on _ModLibraryBrowserState {
  Widget _savedModFilesPanel(BuildContext context, bool narrow) {
    final chosen = controller.selected;
    final version = controller.selectedVersionId;
    return McCollection<FileRowId, SavedFileNode>(
      key: const ValueKey('saved-files'),
      model: controller.files,
      focusNode: _filesFocus,
      scrollController: _filesScroll,
      title: chosen?.metadata.name ?? 'Saved files',
      showTitle: !narrow || widget.filePanes.isEmpty,
      filterActions: [
        ...widget.savedFileActions,
        if (controller.selectedVersionOrigin?.bundle case final origin?)
          McIconAction(
            label: 'Archive source',
            icon: const Icon(Icons.inventory_2_outlined),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (c) => McDialog(
                title: 'Archive source',
                actions: [
                  McAction(label: 'Close', onPressed: () => Navigator.pop(c)),
                ],
                children: [
                  for (final archive in origin.archives)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: SelectableText(archive.path.join('/')),
                    ),
                  ExpansionTile(
                    title: const Text('Source details'),
                    tilePadding: EdgeInsets.zero,
                    children: [
                      SelectableText('Bundle SHA-256: ${origin.parentSha256}'),
                      for (final archive in origin.archives)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: SelectableText(
                            '${archive.path.join('/')}\nSHA-256: ${archive.sha256}',
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
      filterLabel: controller.filesComplete || version == null
          ? 'Filter files'
          : 'Filter loaded files',
      countLabel:
          '${controller.fileCount} ${controller.fileCount == 1 ? 'file' : 'files'}${controller.filesComplete || version == null ? '' : ' loaded'}',
      empty: chosen == null
          ? 'Select a mod.'
          : version == null
          ? 'No saved version.'
          : 'No saved files.',
      semanticLabel: (row) =>
          '${row.path.join('/')}, ${row.folder ? 'folder' : '${row.payload!.length} bytes'}',
      loading: controller.loadingFiles,
      problem: controller.fileProblem,
      onLoad: controller.canLoadFiles
          ? () => unawaited(controller.loadFiles())
          : null,
      onCancel: controller.cancelFiles,
      footer: Text(
        version == null
            ? 'No version selected'
            : 'Saved version ${version.substring(0, 8)}${controller.selectedVersionOrigin?.outputActionId == null ? '' : ' · Generated outputs'}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      actions: [
        if (chosen?.currentVersionId != null &&
            chosen?.currentVersionId != version)
          McIconAction(
            label: 'Open latest saved version',
            onPressed: controller.showLatestVersion,
            icon: const Icon(Icons.update),
          ),
        McIconAction(
          focusNode: _editFocus,
          label: 'Edit mod details',
          onPressed: controller.can(ModAction.editMetadata)
              ? () => _details(original: chosen)
              : null,
          icon: const Icon(Icons.edit_outlined),
        ),
        McAction(
          label: 'Save version',
          icon: Icons.save_outlined,
          onPressed: controller.can(ModAction.publish)
              ? () => unawaited(controller.saveVersion())
              : null,
        ),
      ],
      columns: [
        McColumn(
          'Name',
          (row) => McCollectionName(row.name),
          compare: (a, b) => a.name.compareTo(b.name),
        ),
        McColumn(
          'Size',
          (row) => Text(row.payload == null ? '' : _size(row.payload!.length)),
          width: 92,
          compare: (a, b) =>
              (a.payload?.length ?? -1).compareTo(b.payload?.length ?? -1),
        ),
      ],
    );
  }
}

String _size(int bytes) => bytes >= 1048576
    ? '${(bytes / 1048576).toStringAsFixed(1)} MiB'
    : bytes >= 1024
    ? '${(bytes / 1024).toStringAsFixed(1)} KiB'
    : '$bytes B';
