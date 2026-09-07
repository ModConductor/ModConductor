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
  bool _selectMultiple = false;
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
        final chosen = controller.selected;
        final inventory = controller.inventory;
        final versionColumn = constraints.maxWidth >= 1050;
        Future<void> move(ProfileModMove direction) async {
          await inventory.move(direction);
          if (mounted) _modsFocus.requestFocus();
        }

        final editSelection = controller.canEdit && controller.activity == null;
        final modPanel = McCollection<ModRowId, ProfileMod>(
          key: const ValueKey('installed-mods'),
          model: controller.mods,
          focusNode: _modsFocus,
          scrollController: _modsScroll,
          title: 'Installed mods',
          filterLabel: inventory.complete
              ? 'Filter mods'
              : 'Filter loaded mods',
          countLabel:
              '${inventory.enabledCount} enabled · ${controller.mods.length}${inventory.complete ? '' : ' of ${inventory.total}'} ${inventory.total == 1 ? 'mod' : 'mods'}${inventory.complete ? '' : ' loaded'}',
          empty: 'No installed mods.',
          multiSelect: true,
          selectMultiple: _selectMultiple,
          onMoveUp: editSelection && inventory.canMove
              ? () => unawaited(move(ProfileModMove.up))
              : null,
          onMoveDown: editSelection && inventory.canMove
              ? () => unawaited(move(ProfileModMove.down))
              : null,
          onSelect: controller.select,
          semanticLabel: (row) =>
              '${row.mod.metadata.name}${row.selection.priority == null ? '' : ', priority ${row.selection.priority! + 1}'}, ${_kind(row.mod.kind)}${row.mod.metadata.version.isEmpty ? '' : ', version ${row.mod.metadata.version}'}, ${_status(row.mod.status)}',
          loading: inventory.loading,
          problem: inventory.problem,
          onLoad: inventory.canLoad ? () => unawaited(inventory.load()) : null,
          onCancel: inventory.cancel,
          onRefresh:
              inventory.connected && !inventory.loading && !inventory.changing
              ? () => unawaited(inventory.load(refresh: true))
              : null,
          toolbar: Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilterChip(
                label: const Text('Select multiple'),
                selected: _selectMultiple,
                onSelected: (value) => setState(() => _selectMultiple = value),
              ),
              Text(
                '${controller.mods.selectedIds.length} selected${inventory.hiddenSelected == 0 ? '' : ' · ${inventory.hiddenSelected} hidden'}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              TextButton(
                onPressed: editSelection && inventory.canToggle
                    ? () => unawaited(inventory.enable(true))
                    : null,
                child: const Text('Enable'),
              ),
              TextButton(
                onPressed: editSelection && inventory.canToggle
                    ? () => unawaited(inventory.enable(false))
                    : null,
                child: const Text('Disable'),
              ),
              McIconAction(
                label: 'Move selected mods up (Ctrl+Up)',
                icon: const Icon(Icons.arrow_upward),
                onPressed: editSelection && inventory.canMove
                    ? () => unawaited(move(ProfileModMove.up))
                    : null,
              ),
              McIconAction(
                label: 'Move selected mods down (Ctrl+Down)',
                icon: const Icon(Icons.arrow_downward),
                onPressed: editSelection && inventory.canMove
                    ? () => unawaited(move(ProfileModMove.down))
                    : null,
              ),
              McIconAction(
                label: 'Clear selection',
                icon: const Icon(Icons.deselect),
                onPressed: controller.mods.selectedIds.isEmpty
                    ? null
                    : controller.mods.clearSelection,
              ),
              if (!inventory.byPriority)
                TextButton(
                  onPressed: inventory.showPriority,
                  child: const Text('Show priority'),
                ),
              if (inventory.changing)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          actions: [
            McAction(
              key: const ValueKey('add-mod'),
              focusNode: _addFocus,
              label: 'Add mod folder',
              icon: Icons.create_new_folder_outlined,
              onPressed:
                  controller.canEdit &&
                      controller.activity == null &&
                      !inventory.changing
                  ? () => _details()
                  : null,
            ),
          ],
          columns: [
            McColumn(
              '',
              (row) => switch (row.selection) {
                ManagedProfileMod(:final enabled) => Semantics(
                  label: 'Enable ${row.mod.metadata.name}',
                  child: Checkbox(
                    value: enabled,
                    onChanged:
                        editSelection &&
                            inventory.connected &&
                            !inventory.changing &&
                            !inventory.stale
                        ? (value) => unawaited(
                            inventory.enable(value!, onlyModId: row.mod.id),
                          )
                        : null,
                  ),
                ),
                OrderedProfileMod() => const ExcludeSemantics(
                  child: Icon(Icons.horizontal_rule, size: 19),
                ),
                LockedProfileMod() => const ExcludeSemantics(
                  child: Icon(Icons.lock_outline, size: 19),
                ),
              },
              width: 44,
              interactive: true,
            ),
            McColumn(
              'Priority',
              (row) => Text(
                row.selection.priority == null
                    ? '—'
                    : '${row.selection.priority! + 1}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              width: 68,
            ),
            McColumn(
              'Name',
              (row) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.mod.metadata.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!versionColumn && row.mod.metadata.version.isNotEmpty)
                    Text(
                      'Version ${row.mod.metadata.version}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
              compare: (a, b) =>
                  a.mod.metadata.name.compareTo(b.mod.metadata.name),
            ),
            if (versionColumn)
              McColumn(
                'Version',
                (row) => Text(
                  row.mod.metadata.version,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                width: 65,
              ),
            McColumn(
              'Status',
              (row) => Text(
                row.selection is ManagedProfileMod
                    ? _status(row.mod.status)
                    : _kind(row.mod.kind),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              width: 112,
            ),
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
