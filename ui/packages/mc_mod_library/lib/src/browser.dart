import 'deletion_controller.dart';
import 'deletion_view.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_collections/mc_ui_collections.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'controller.dart';
import 'mod_dialog.dart';
import 'category_manager.dart';
import 'filter_dialog.dart';
import 'inventory_export_controller.dart';
import 'inventory_export_dialog.dart';

typedef InventoryExportFolderOpener = Future<bool> Function(String filePath);

class ModFilePane {
  const ModFilePane(this.id, this.label, this.builder);
  final String id, label;
  final Widget Function(BuildContext context, bool narrow) builder;
}

enum _OrganizationAction { group, flat, categories }

class ModLibraryBrowser extends StatefulWidget {
  const ModLibraryBrowser({
    super.key,
    required this.controller,
    required this.workspacePath,
    this.chooseDirectory = chooseModDirectory,
    this.filePanes = const [],
    this.paneLabel = 'Files',
    this.singlePane,
    this.maintenance,
    this.onOpenDeployment,
    this.onOpenNexus,
    this.onMaintenanceOpen,
    this.savedFileActions = const [],
    this.inventoryExports,
    this.chooseExportLocation,
    this.openExportFolder,
    this.profileName,
  });
  final ModLibraryController controller;
  final String workspacePath;
  final ModDirectoryChooser chooseDirectory;
  final List<ModFilePane> filePanes;
  final String paneLabel;
  final bool? singlePane;
  final void Function(ModEntry)? onOpenNexus;
  final MaintenanceClient? maintenance;
  final VoidCallback? onOpenDeployment, onMaintenanceOpen;
  final List<Widget> savedFileActions;
  final InventoryExportClient? inventoryExports;
  final InventoryExportLocationChooser? chooseExportLocation;
  final InventoryExportFolderOpener? openExportFolder;
  final String? profileName;
  @override
  State<ModLibraryBrowser> createState() => _ModLibraryBrowserState();
}

class _ModLibraryBrowserState extends State<ModLibraryBrowser> {
  String _pane = 'mods';
  bool _selectMultiple = false;
  final _modsFocus = FocusNode(debugLabel: 'Installed mods');
  final _filesFocus = FocusNode(debugLabel: 'Saved files');
  final _modsScroll = ScrollController();
  final _filesScroll = ScrollController();
  final _addFocus = FocusNode(debugLabel: 'Add mod folder');
  final _editFocus = FocusNode(debugLabel: 'Edit mod details');
  final _exportFocus = FocusNode(debugLabel: 'Export CSV');
  InventoryExportDialogResult? _exportResult;
  bool _folderProblem = false;
  ModLibraryController get controller => widget.controller;
  late final deletion = DeletionController(
    () => controller.inventory.refreshCatalogue(),
  );
  @override
  void initState() {
    super.initState();
    controller.addListener(attachDeletion);
    attachDeletion();
  }

  void attachDeletion() =>
      deletion.attach(widget.maintenance, controller.workspaceId);
  @override
  void didUpdateWidget(ModLibraryBrowser oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller.removeListener(attachDeletion);
      controller.addListener(attachDeletion);
    }
    attachDeletion();
  }

  @override
  void dispose() {
    controller.removeListener(attachDeletion);
    deletion.dispose();
    _modsFocus.dispose();
    _filesFocus.dispose();
    _modsScroll.dispose();
    _filesScroll.dispose();
    _addFocus.dispose();
    _editFocus.dispose();
    _exportFocus.dispose();
    super.dispose();
  }

  Future<void> _details({ModEntry? original}) async {
    final opener = original == null ? _addFocus : _editFocus;
    opener.requestFocus();
    final result = await showDialog<ModDetails>(
      context: context,
      builder: (_) => ModDialog(
        original: original?.metadata,
        organization: controller.organization,
        workspaceId: controller.workspaceId,
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

  Future<void> _export() async {
    final client = widget.inventoryExports;
    final chooser = widget.chooseExportLocation;
    if (client == null || chooser == null) return;
    _exportFocus.requestFocus();
    InventoryExportDialogResult? result;
    do {
      final inventory = controller.inventory;
      final workspace = controller.workspaceId;
      final workspaceRevision = controller.workspaceRevision;
      final profile = controller.profileId;
      final queryIdentity = inventory.queryIdentity;
      final catalogueRevision = inventory.catalogueRevision;
      final selectionRevision = inventory.revision;
      if (workspace == null ||
          workspaceRevision == null ||
          profile == null ||
          queryIdentity == null ||
          catalogueRevision == null ||
          selectionRevision == null) {
        return;
      }
      result = await showDialog<InventoryExportDialogResult>(
        context: context,
        barrierDismissible: false,
        builder: (_) => InventoryExportDialog(
          client: client,
          capture: InventoryExportCapture(
            workspaceId: workspace,
            workspaceRevision: workspaceRevision,
            profileId: profile,
            scope: InventoryExportScope.selected,
            selectedModIds: controller.mods.selectedIds
                .map((id) => id.modId)
                .toList(growable: false),
            query: inventory.query,
            queryIdentity: queryIdentity,
            catalogueRevision: catalogueRevision,
            selectionRevision: selectionRevision,
            fields: const [],
          ),
          chooseLocation: chooser,
          profileName: widget.profileName ?? 'this profile',
          selectedCount: controller.mods.selectedIds.length,
          hiddenSelectedCount: inventory.hiddenSelected,
          enabledCount: inventory.enabledCount,
          matchingCount: inventory.matchingMods,
          totalCount: inventory.total,
        ),
      );
    } while (mounted && result?.retry == true);
    if (!mounted) return;
    if (result?.completed == true || result?.cancelled == true) {
      setState(() {
        _exportResult = result;
        _folderProblem = false;
      });
    }
    _modsFocus.requestFocus();
  }

  Future<void> _openExportFolder() async {
    final result = _exportResult;
    final opener = widget.openExportFolder;
    if (result?.destinationPath == null || opener == null) return;
    final opened = await opener(result!.destinationPath!);
    if (mounted && !opened) setState(() => _folderProblem = true);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([controller, deletion]),
    builder: (context, _) => LayoutBuilder(
      builder: (context, constraints) {
        if (deletion.viewing) {
          return ModDeletionView(
            controller: deletion,
            onOpenDeployment: widget.onOpenDeployment,
          );
        }
        final narrow = widget.singlePane ?? constraints.maxWidth < 1050;
        final compact = narrow && constraints.maxHeight < 500;
        final chosen = controller.selected;
        final inventory = controller.inventory;
        final versionColumn = constraints.maxWidth >= 1050;
        Future<void> move(ProfileModMove direction) async {
          await inventory.move(direction);
          if (mounted) _modsFocus.requestFocus();
        }

        final editSelection = controller.canEdit && controller.activity == null;
        final modActions = <Widget>[
          if (widget.inventoryExports != null &&
              widget.chooseExportLocation != null)
            McAction(
              key: const ValueKey('export-csv'),
              focusNode: _exportFocus,
              label: 'Export CSV',
              icon: Icons.download_outlined,
              onPressed:
                  inventory.connected &&
                      !inventory.loading &&
                      !inventory.changing &&
                      !inventory.stale &&
                      controller.workspaceRevision != null &&
                      inventory.queryIdentity != null
                  ? () => unawaited(_export())
                  : null,
            ),
          if (widget.onOpenNexus != null)
            McIconAction(
              label: 'Nexus Mods',
              icon: const Icon(Icons.public),
              onPressed:
                  chosen?.kind == ModKind.regular &&
                      !deletion.busy &&
                      controller.activity == null
                  ? () => widget.onOpenNexus!(chosen!)
                  : null,
            ),
          if (widget.maintenance != null)
            McIconAction(
              label: 'Delete mod',
              icon: const Icon(Icons.delete_outline),
              onPressed:
                  chosen?.kind == ModKind.regular &&
                      chosen?.status != InventoryStatus.deleting &&
                      controller.canEdit &&
                      !deletion.busy
                  ? () {
                      widget.onMaintenanceOpen?.call();
                      unawaited(deletion.open(chosen!));
                    }
                  : null,
            ),
          McIconMenu<_OrganizationAction>(
            label: 'Installed mods options',
            enabled: controller.organization != null,
            itemBuilder: (_) => [
              PopupMenuItem(
                value: inventory.query.view == OrganizationView.groups
                    ? _OrganizationAction.flat
                    : _OrganizationAction.group,
                child: Text(
                  inventory.query.view == OrganizationView.groups
                      ? 'Show flat list'
                      : 'Group by separators',
                ),
              ),
              const PopupMenuItem(
                value: _OrganizationAction.categories,
                child: Text('Manage categories'),
              ),
            ],
            onSelected: (action) async {
              switch (action) {
                case _OrganizationAction.group:
                  inventory.setQuery(
                    inventory.query.copyWith(view: OrganizationView.groups),
                  );
                case _OrganizationAction.flat:
                  inventory.setQuery(
                    inventory.query.copyWith(view: OrganizationView.flat),
                  );
                case _OrganizationAction.categories:
                  await manageCategories(
                    context,
                    controller.organization!,
                    controller.workspaceId!,
                  );
                  if (mounted) await inventory.refreshCatalogue();
              }
            },
          ),
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
        ];
        final modPanel = McCollection<ModRowId, OrganizedMod>(
          key: const ValueKey('installed-mods'),
          model: controller.mods,
          focusNode: _modsFocus,
          scrollController: _modsScroll,
          title: 'Installed mods',
          showTitle: !compact,
          compactFilter: compact,
          showTree: false,
          nodeIcon: (_) => const SizedBox.shrink(),
          filterText: inventory.query.text,
          filterEnabled: inventory.connected,
          onFilterChanged: inventory.search,
          onSort: inventory.sort,
          filterLabel: 'Filter mods',
          filterActions: [
            if (compact) ...modActions,
            TextButton(
              onPressed:
                  controller.organization == null ||
                      controller.workspaceId == null
                  ? null
                  : () async {
                      final query = await showDialog<ModQuery>(
                        context: context,
                        builder: (_) => ModFilterDialog(
                          query: inventory.query,
                          client: controller.organization!,
                          workspace: controller.workspaceId!,
                        ),
                      );
                      if (mounted && query != null) inventory.setQuery(query);
                    },
              child: Text(
                inventory.query.filters.isEmpty
                    ? 'Filters'
                    : 'Filters (${inventory.query.filters.length})',
              ),
            ),
          ],
          countLabel:
              '${inventory.enabledCount} enabled total · ${inventory.matchingMods} of ${inventory.total} mods · ${inventory.query.view == OrganizationView.groups ? '${inventory.matchingGroups} ${inventory.matchingGroups == 1 ? 'group' : 'groups'}' : '${inventory.matchingSeparators} separators'}${inventory.complete ? '' : ' · ${inventory.loaded} rows loaded'}',
          empty: 'No installed mods.',
          emptyContent:
              inventory.query.text.trim().isEmpty &&
                  inventory.query.filters.isEmpty
              ? null
              : Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: [
                      const Text('No mods match these filters.'),
                      TextButton(
                        onPressed: () => inventory.setQuery(
                          inventory.query.copyWith(text: '', filters: const []),
                        ),
                        child: const Text('Clear filters'),
                      ),
                    ],
                  ),
                ),
          multiSelect: true,
          selectMultiple: _selectMultiple,
          onMoveUp: editSelection && inventory.canMove
              ? () => unawaited(move(ProfileModMove.up))
              : null,
          onMoveDown: editSelection && inventory.canMove
              ? () => unawaited(move(ProfileModMove.down))
              : null,
          onSelect: (row) => controller.select(row.entry),
          semanticLabel: (row) =>
              '${row.mod.metadata.name}${row.selection.priority == null ? '' : ', priority ${row.selection.priority! + 1}'}, ${_kind(row.mod.kind)}${row.mod.metadata.version.isEmpty ? '' : ', version ${row.mod.metadata.version}'}, ${row.groupSize == null ? _status(row.mod.status) : '${row.groupSize!.matching} of ${row.groupSize!.total} mods'}',
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
              if (inventory.byPriority) ...[
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
              ],
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
          actions: compact ? const [] : modActions,
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
                OrderedProfileMod() =>
                  inventory.query.view == OrganizationView.groups
                      ? McCollectionExpander(
                          model: controller.mods,
                          id: (modId: row.mod.id),
                        )
                      : const ExcludeSemantics(
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
              (row) => Padding(
                padding: EdgeInsets.only(left: row.groupId == null ? 0 : 14),
                child: Column(
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
              (row) => Text(switch (row.groupSize) {
                final size? =>
                  '${size.matching}${size.matching == size.total ? '' : ' of ${size.total}'} ${size.total == 1 ? 'mod' : 'mods'}',
                null =>
                  row.selection is ManagedProfileMod
                      ? _status(row.mod.status)
                      : _kind(row.mod.kind),
              }, style: Theme.of(context).textTheme.bodySmall),
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
                      McAction(
                        label: 'Close',
                        onPressed: () => Navigator.pop(c),
                      ),
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
                          SelectableText(
                            'Bundle SHA-256: ${origin.parentSha256}',
                          ),
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
              (row) =>
                  Text(row.payload == null ? '' : _size(row.payload!.length)),
              width: 92,
              compare: (a, b) =>
                  (a.payload?.length ?? -1).compareTo(b.payload?.length ?? -1),
            ),
          ],
        );
        final extended = widget.filePanes.isNotEmpty;
        final extra = widget.filePanes
            .where((pane) => pane.id == _pane)
            .firstOrNull;
        Widget filesPanel() => extra?.builder(context, narrow) ?? treePanel;
        String describe(String id) => switch (id) {
          'mods' => 'Installed mods',
          'saved' => 'Saved mod files',
          _ => widget.filePanes.firstWhere((pane) => pane.id == id).label,
        };
        Widget choice(bool includeMods) {
          final selected = includeMods && _pane == 'mods'
              ? 'mods'
              : extra?.id ?? 'saved';
          if (widget.filePanes.length == 1) {
            return SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                segments: [
                  if (includeMods)
                    const ButtonSegment(
                      value: 'mods',
                      label: Text('Installed mods'),
                      icon: Icon(Icons.layers_outlined),
                    ),
                  ButtonSegment(
                    value: 'saved',
                    label: Text(
                      includeMods ? 'Saved files' : 'Saved mod files',
                    ),
                    icon: const Icon(Icons.inventory_2_outlined),
                  ),
                  ButtonSegment(
                    value: widget.filePanes.single.id,
                    label: Text(widget.filePanes.single.label),
                    icon: const Icon(Icons.folder_open),
                  ),
                ],
                selected: {selected},
                onSelectionChanged: (value) =>
                    setState(() => _pane = value.single),
              ),
            );
          }
          return McChoice<String>(
            label: includeMods ? 'View' : widget.paneLabel,
            value: selected,
            choices: [
              if (includeMods) 'mods',
              'saved',
              ...widget.filePanes.map((pane) => pane.id),
            ],
            describe: describe,
            onChanged: (value) => setState(() => _pane = value),
          );
        }

        return Column(
          children: [
            if (inventory.activeOperation case final operation?)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: McActionFeedback(
                  key: ValueKey(('library-operation', operation.id)),
                  kind: McActionFeedbackKind.pending,
                  message: '${_operationKind(operation.kind)} in progress',
                  detail:
                      'Operation ${operation.id}. ${_operationActions(operation.actions)}',
                ),
              ),
            if (inventory.activeOperation == null &&
                deletion.pending.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Expanded(child: Text('Mod deletion unfinished')),
                    McAction(
                      label: 'Open deletion',
                      onPressed: () {
                        widget.onMaintenanceOpen?.call();
                        deletion.resume(deletion.pending.first);
                      },
                    ),
                  ],
                ),
              ),
            if (deletion.problem != null)
              McStatus(title: deletion.problem!, tone: McStatusTone.error),

            if (narrow) ...[
              if (extended)
                choice(true)
              else
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'mods',
                        label: Text('Installed mods'),
                        icon: Icon(Icons.layers_outlined),
                      ),
                      ButtonSegment(
                        value: 'saved',
                        label: Text('Saved files'),
                        icon: Icon(Icons.account_tree_outlined),
                      ),
                    ],
                    selected: {_pane == 'mods' ? 'mods' : 'saved'},
                    onSelectionChanged: (value) =>
                        setState(() => _pane = value.single),
                  ),
                ),
              const SizedBox(height: 12),
            ],
            Expanded(
              child: narrow
                  ? IndexedStack(
                      index: _pane == 'mods' ? 0 : 1,
                      children: [
                        ExcludeFocus(
                          excluding: _pane != 'mods',
                          child: modPanel,
                        ),
                        ExcludeFocus(
                          excluding: _pane == 'mods',
                          child: filesPanel(),
                        ),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 11, child: modPanel),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 10,
                          child: Column(
                            children: [
                              if (extended) ...[
                                choice(false),
                                const SizedBox(height: 12),
                              ],
                              Expanded(child: filesPanel()),
                            ],
                          ),
                        ),
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
            if (_exportResult case final result?) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: result.completed
                        ? McStatus(
                            key: const ValueKey('export-completed-status'),
                            title:
                                'Mod Conductor saved ${result.rowCount} rows to ${result.fileName}.',
                            detail: _folderProblem
                                ? 'The folder did not open.'
                                : 'The file uses UTF-8, commas, quoted fields, and Windows-compatible line endings.',
                            tone: _folderProblem
                                ? McStatusTone.error
                                : McStatusTone.neutral,
                          )
                        : const McStatus(
                            key: ValueKey('export-cancelled-status'),
                            title: 'You canceled the export.',
                            detail: 'The existing CSV file did not change.',
                          ),
                  ),
                  if (result.completed && widget.openExportFolder != null) ...[
                    const SizedBox(width: 12),
                    McAction(
                      key: const ValueKey('open-export-folder'),
                      label: 'Open folder',
                      onPressed: () => unawaited(_openExportFolder()),
                    ),
                  ],
                ],
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
  InventoryStatus.deleting => 'Deletion unfinished',
};
String _operationKind(LibraryOperationKind kind) => switch (kind) {
  LibraryOperationKind.publication => 'Version save',
  LibraryOperationKind.installation => 'Mod installation',
  LibraryOperationKind.upgrade => 'Mod update',
  LibraryOperationKind.deletion => 'Mod deletion',
};
String _operationActions(List<LibraryOperationAction> actions) {
  final values = actions.toSet();
  if (values.contains(LibraryOperationAction.wait) &&
      values.contains(LibraryOperationAction.cancel)) {
    return 'You can wait or cancel it.';
  }
  if (values.contains(LibraryOperationAction.resume) &&
      values.contains(LibraryOperationAction.cancel)) {
    return 'You can resume or cancel it.';
  }
  if (values.contains(LibraryOperationAction.wait)) {
    return 'You can wait for it.';
  }
  if (values.contains(LibraryOperationAction.resume)) {
    return 'You can resume it.';
  }
  if (values.contains(LibraryOperationAction.cancel)) {
    return 'You can cancel it.';
  }
  return 'No action is available.';
}

String _size(int bytes) => bytes >= 1048576
    ? '${(bytes / 1048576).toStringAsFixed(1)} MiB'
    : bytes >= 1024
    ? '${(bytes / 1024).toStringAsFixed(1)} KiB'
    : '$bytes B';
