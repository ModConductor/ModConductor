import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_collections/mc_ui_collections.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'controller.dart';
import 'mod_dialog.dart';

enum _Pane { mods, files }

class ModLibraryBrowser extends StatefulWidget {
  const ModLibraryBrowser({
    super.key,
    required this.controller,
    required this.workspacePath,
    this.chooseDirectory = chooseModDirectory,
  });
  final ModLibraryController controller;
  final String workspacePath;
  final ModDirectoryChooser chooseDirectory;
  @override
  State<ModLibraryBrowser> createState() => _ModLibraryBrowserState();
}

class _ModLibraryBrowserState extends State<ModLibraryBrowser> {
  _Pane _pane = _Pane.mods;
  final _modsFocus = FocusNode(debugLabel: 'Installed mods');
  final _filesFocus = FocusNode(debugLabel: 'Saved files');
  final _modsScroll = ScrollController();
  final _filesScroll = ScrollController();
  final _addFocus = FocusNode(debugLabel: 'Add mod folder');
  final _editFocus = FocusNode(debugLabel: 'Edit mod details');
  ModLibraryController get controller => widget.controller;
  @override
  void dispose() {
    _modsFocus.dispose();
    _filesFocus.dispose();
    _modsScroll.dispose();
    _filesScroll.dispose();
    _addFocus.dispose();
    _editFocus.dispose();
    super.dispose();
  }

  Future<void> _details({ModEntry? original}) async {
    final opener = original == null ? _addFocus : _editFocus;
    opener.requestFocus();
    final result = await showDialog<ModDetails>(
      context: context,
      builder: (_) => ModDialog(
        original: original?.metadata,
        initialPath: widget.workspacePath,
        chooseDirectory: widget.chooseDirectory,
      ),
    );
    if (!mounted || result == null) return;
    if (original == null) {
      await controller.addFolder(result.metadata, result.path!);
    } else {
      await controller.edit(original, result.metadata);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 1050;
        final chosen = controller.mods.selected;
        final modPanel = McCollection<ModRowId, ModEntry>(
          key: const ValueKey('installed-mods'),
          model: controller.mods,
          focusNode: _modsFocus,
          scrollController: _modsScroll,
          title: 'Installed mods',
          filterLabel: controller.modsComplete
              ? 'Filter mods'
              : 'Filter loaded mods',
          countLabel:
              '${controller.mods.length} ${controller.mods.length == 1 ? 'mod' : 'mods'}${controller.modsComplete ? '' : ' loaded'}',
          empty: 'No installed mods.',
          onSelect: controller.select,
          semanticLabel: (row) =>
              '${row.metadata.name}, ${_kind(row.kind)}, ${_status(row.status)}',
          loading: controller.loadingMods,
          problem: controller.modProblem,
          onLoad: controller.canLoadMods
              ? () => unawaited(controller.loadMods())
              : null,
          onCancel: controller.cancelMods,
          onRefresh: controller.connected && !controller.loadingMods
              ? () => unawaited(controller.loadMods(refresh: true))
              : null,
          actions: [
            McAction(
              key: const ValueKey('add-mod'),
              focusNode: _addFocus,
              label: 'Add mod folder',
              icon: Icons.create_new_folder_outlined,
              onPressed: controller.canEdit && controller.activity == null
                  ? () => _details()
                  : null,
            ),
          ],
          columns: [
            McColumn(
              'Name',
              (row) => McCollectionName(
                row.metadata.name,
                icon: Icons.layers_outlined,
              ),
              compare: (a, b) => a.metadata.name.compareTo(b.metadata.name),
            ),
            McColumn(
              'Type',
              (row) => Text(_kind(row.kind)),
              width: 84,
              compare: (a, b) => _kind(a.kind).compareTo(_kind(b.kind)),
            ),
            McColumn(
              'Version',
              (row) => Text(
                row.metadata.version,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              width: 65,
            ),
            McColumn('Status', (row) => Text(_status(row.status)), width: 112),
          ],
        );
        final version = controller.selectedVersionId;
        final treePanel = McCollection<FileRowId, SavedFileNode>(
          key: const ValueKey('saved-files'),
          model: controller.files,
          focusNode: _filesFocus,
          scrollController: _filesScroll,
          title: chosen?.metadata.name ?? 'Saved files',
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
                : 'Saved version ${version.substring(0, 8)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          actions: [
            if (chosen?.currentVersionId != null &&
                chosen?.currentVersionId != version)
              IconButton(
                tooltip: 'Open latest saved version',
                onPressed: controller.showLatestVersion,
                icon: const Icon(Icons.update),
              ),
            IconButton(
              focusNode: _editFocus,
              tooltip: 'Edit mod details',
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
              (row) =>
                  Text(row.payload == null ? '' : _size(row.payload!.length)),
              width: 92,
              compare: (a, b) =>
                  (a.payload?.length ?? -1).compareTo(b.payload?.length ?? -1),
            ),
          ],
        );
        return Column(
          children: [
            if (narrow) ...[
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<_Pane>(
                  segments: const [
                    ButtonSegment(
                      value: _Pane.mods,
                      label: Text('Installed mods'),
                      icon: Icon(Icons.layers_outlined),
                    ),
                    ButtonSegment(
                      value: _Pane.files,
                      label: Text('Saved files'),
                      icon: Icon(Icons.account_tree_outlined),
                    ),
                  ],
                  selected: {_pane},
                  onSelectionChanged: (value) =>
                      setState(() => _pane = value.single),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Expanded(
              child: narrow
                  ? IndexedStack(
                      index: _pane.index,
                      children: [
                        ExcludeFocus(
                          excluding: _pane != _Pane.mods,
                          child: modPanel,
                        ),
                        ExcludeFocus(
                          excluding: _pane != _Pane.files,
                          child: treePanel,
                        ),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 11, child: modPanel),
                        const SizedBox(width: 16),
                        Expanded(flex: 10, child: treePanel),
                      ],
                    ),
            ),
            if (controller.activity != null ||
                controller.actionProblem != null) ...[
              const SizedBox(height: 12),
              McStatus(
                title:
                    controller.actionProblem ??
                    '${controller.activity} in progress.',
                tone: controller.actionProblem == null
                    ? McStatusTone.neutral
                    : McStatusTone.error,
              ),
            ],
          ],
        );
      },
    ),
  );
}

String _kind(ModKind kind) => switch (kind) {
  ModKind.regular => 'Mod',
  ModKind.separator => 'Separator',
  ModKind.backup => 'Backup',
  ModKind.unmanaged => 'Unmanaged',
  ModKind.generatedOutput => 'Output',
};
String _status(InventoryStatus status) => switch (status) {
  InventoryStatus.ready => 'Ready',
  InventoryStatus.detached => 'Folder missing',
  InventoryStatus.changed => 'Source changed',
  InventoryStatus.unproved => 'Not verified',
  InventoryStatus.publishing => 'Save in progress',
};
String _size(int bytes) => bytes >= 1048576
    ? '${(bytes / 1048576).toStringAsFixed(1)} MiB'
    : bytes >= 1024
    ? '${(bytes / 1024).toStringAsFixed(1)} KiB'
    : '$bytes B';
