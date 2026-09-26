import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_collections/mc_ui_collections.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'category_manager.dart';
import 'controller.dart';
import 'deletion_controller.dart';
import 'filter_dialog.dart';
import 'inventory_export_controller.dart';
import 'inventory_export_dialog.dart';
import 'mod_dialog.dart';

part 'installed_mods_panel.dart';
part 'inventory_export_flow.dart';
part 'mod_deletion_view.dart';
part 'saved_mod_files_panel.dart';

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
  final VoidCallback? onMaintenanceOpen;
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

  void _setSelectMultiple(bool value) =>
      setState(() => _selectMultiple = value);

  void _setExportResult(InventoryExportDialogResult? result) => setState(() {
    _exportResult = result;
    _folderProblem = false;
  });

  void _showExportFolderProblem() => setState(() => _folderProblem = true);

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([controller, deletion]),
    builder: (context, _) => LayoutBuilder(
      builder: (context, constraints) {
        if (deletion.viewing) {
          return _deletionView();
        }
        final narrow = widget.singlePane ?? constraints.maxWidth < 1050;
        final compact = narrow && constraints.maxHeight < 500;
        final versionColumn = constraints.maxWidth >= 1050;
        final modPanel = _installedModsPanel(context, compact, versionColumn);
        final treePanel = _savedModFilesPanel(context, narrow);
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
              _exportStatus(context, result),
            ],
          ],
        );
      },
    ),
  );
}
