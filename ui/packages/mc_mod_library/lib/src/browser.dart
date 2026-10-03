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
import 'load_order_pane.dart';
import 'workbench_view.dart';

part 'installed_mods_panel.dart';
part 'organization_menu.dart';
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
    this.onDeleted,
    this.savedFileActions = const [],
    this.inventoryExports,
    this.chooseExportLocation,
    this.openExportFolder,
    this.profileName,
    this.view,
    this.paneActions = const [],
    this.externalPaneControls = false,
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
  final Future<void> Function()? onDeleted;
  final List<Widget> savedFileActions;
  final InventoryExportClient? inventoryExports;
  final InventoryExportLocationChooser? chooseExportLocation;
  final InventoryExportFolderOpener? openExportFolder;
  final String? profileName;
  final ModWorkbenchView? view;
  final List<Widget> paneActions;
  final bool externalPaneControls;
  @override
  State<ModLibraryBrowser> createState() => _ModLibraryBrowserState();
}

class _ModLibraryBrowserState extends State<ModLibraryBrowser> {
  final _ownView = ModWorkbenchView();
  ModWorkbenchView get _view => widget.view ?? _ownView;
  String get _pane => _view.pane;
  void _viewChanged() {
    if (mounted) setState(() {});
  }

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
  late final deletion = DeletionController(() async {
    await controller.inventory.refreshCatalogue();
    await widget.onDeleted?.call();
  });
  @override
  void initState() {
    super.initState();
    _view.addListener(_viewChanged);
    controller.startLoadOrder();
    if (!widget.filePanes.any((pane) => pane.id == 'load-order')) {
      controller.loadOrder.syncPlugins(const [], const []);
    }
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
      controller.startLoadOrder();
      if (!widget.filePanes.any((pane) => pane.id == 'load-order')) {
        controller.loadOrder.syncPlugins(const [], const []);
      }
      controller.addListener(attachDeletion);
    }
    if (!identical(oldWidget.view, widget.view)) {
      (oldWidget.view ?? _ownView).removeListener(_viewChanged);
      _view.addListener(_viewChanged);
    }
    attachDeletion();
  }

  @override
  void dispose() {
    controller.removeListener(attachDeletion);
    _view.removeListener(_viewChanged);
    _ownView.dispose();
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
        final panes = [
          if (!widget.filePanes.any((pane) => pane.id == 'load-order'))
            ModFilePane(
              'load-order',
              'Load order',
              (context, narrow) => LoadOrderPane(
                controller: controller.loadOrder,
                narrow: narrow,
              ),
            ),
          ModFilePane(
            'saved',
            'Saved mod files',
            (context, narrow) => treePanel,
          ),
          ...widget.filePanes,
        ];
        final extra =
            panes.where((pane) => pane.id == _pane).firstOrNull ?? panes.first;
        Widget filesPanel() => extra.builder(context, narrow);
        Widget choice() => Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 190,
              child: McChoice<String>(
                label: 'View',
                value: extra.id,
                choices: panes.map((pane) => pane.id).toList(),
                describe: (id) =>
                    panes.firstWhere((pane) => pane.id == id).label,
                onChanged: (value) => _view.select(value),
              ),
            ),
            ...widget.paneActions,
          ],
        );
        return Column(
          children: [
            if (deletion.problem != null)
              McStatus(title: deletion.problem!, tone: McStatusTone.error),

            Expanded(
              child: narrow
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: modPanel),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: choice(),
                        ),
                        Expanded(child: filesPanel()),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 9, child: modPanel),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 11,
                          child: Column(
                            children: [
                              if (!widget.externalPaneControls) ...[
                                choice(),
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
