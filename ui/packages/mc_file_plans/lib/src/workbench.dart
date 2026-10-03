import 'dart:async';

import 'package:mc_bethesda/mc_bethesda.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_mod_library/mc_mod_library.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'controller.dart';
import 'inspector.dart';
import 'planned_files.dart';

class FilePlanningWorkbench extends StatefulWidget {
  const FilePlanningWorkbench({
    super.key,
    required this.mods,
    required this.plans,
    required this.workspacePath,
    required this.chooseDirectory,
    this.profileName,
    this.plugins,
    this.archives,
    this.sortOrder,
    this.maintenance,
    this.onDeleted,
    this.onOpenNexus,
    this.onOpenProblems,
    this.archiveUnavailable = false,
    this.additionalFilePanes,
    this.additionalInspector,
    this.onCloseAdditionalInspector,
    this.inventoryExports,
    this.chooseExportLocation,
    this.openExportFolder,
    this.view,
    this.externalPaneControls = false,
  });
  final ModLibraryController mods;
  final FilePlansController plans;
  final String workspacePath;
  final Future<String?> Function(String?) chooseDirectory;
  final String? profileName;
  final PluginsController? plugins;
  final ArchivePolicyController? archives;
  final SortOrderController? sortOrder;
  final void Function(ModEntry)? onOpenNexus;
  final MaintenanceClient? maintenance;
  final Future<void> Function()? onDeleted;
  final VoidCallback? onOpenProblems;
  final bool archiveUnavailable;
  final List<ModFilePane> Function(VoidCallback onInspect)? additionalFilePanes;
  final Widget Function(VoidCallback onClose)? additionalInspector;
  final VoidCallback? onCloseAdditionalInspector;
  final InventoryExportClient? inventoryExports;
  final InventoryExportLocationChooser? chooseExportLocation;
  final InventoryExportFolderOpener? openExportFolder;
  final ModWorkbenchView? view;
  final bool externalPaneControls;

  @override
  State<FilePlanningWorkbench> createState() => _FilePlanningWorkbenchState();
}

class _FilePlanningWorkbenchState extends State<FilePlanningWorkbench> {
  final _scaffold = GlobalKey<ScaffoldState>();
  final _filesFocus = FocusNode(debugLabel: 'Planned files');
  final _savedInspectFocus = FocusNode(debugLabel: 'Inspect saved file');
  FocusNode? _opener;
  int? _selectionRevision, _catalogueRevision;
  bool _compact = false;
  bool _allowDrawerClose = false, _guardingDrawerClose = false;
  @override
  void initState() {
    super.initState();
    widget.mods.startLoadOrder();
    _selectionRevision = widget.mods.inventory.revision;
    _catalogueRevision = widget.mods.inventory.catalogueRevision;
    widget.mods.addListener(_changed);
    widget.mods.files.addListener(_selectionChanged);
    widget.plugins?.addListener(_pluginsChanged);
    widget.plans.addListener(_plansChanged);
    _plansChanged();
    _pluginsChanged();
    if (widget.plugins?.state == null) unawaited(widget.plugins?.scan());
  }

  void _plansChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.plans.ensureLoaded();
    });
  }

  void _pluginsChanged() {
    final plugins = widget.plugins;
    widget.mods.loadOrder.syncPlugins(
      plugins?.state?.entries ?? const [],
      plugins?.order?.entries.map((row) => row.name).toList() ?? const [],
      ready: plugins == null || plugins.state != null,
    );
  }

  @override
  void didUpdateWidget(FilePlanningWorkbench oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.mods, widget.mods)) {
      oldWidget.mods.removeListener(_changed);
      oldWidget.mods.files.removeListener(_selectionChanged);
      widget.mods.addListener(_changed);
      widget.mods.files.addListener(_selectionChanged);
      widget.mods.startLoadOrder();
      _selectionRevision = widget.mods.inventory.revision;
      _catalogueRevision = widget.mods.inventory.catalogueRevision;
      _pluginsChanged();
    }
    if (!identical(oldWidget.plugins, widget.plugins)) {
      oldWidget.plugins?.removeListener(_pluginsChanged);
      widget.plugins?.addListener(_pluginsChanged);
      _pluginsChanged();
      if (widget.plugins?.state == null) unawaited(widget.plugins?.scan());
    }
    if (!identical(oldWidget.plans, widget.plans)) {
      oldWidget.plans.removeListener(_plansChanged);
      widget.plans.addListener(_plansChanged);
      _plansChanged();
    }
  }

  void _selectionChanged() {
    if (mounted) setState(() {});
  }

  void _changed() {
    final inventory = widget.mods.inventory;
    if ((_selectionRevision != null &&
            _selectionRevision != inventory.revision) ||
        (_catalogueRevision != null &&
            _catalogueRevision != inventory.catalogueRevision)) {
      widget.plans.invalidate();
    }
    _selectionRevision = inventory.revision;
    _catalogueRevision = inventory.catalogueRevision;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.mods.removeListener(_changed);
    widget.mods.files.removeListener(_selectionChanged);
    widget.plugins?.removeListener(_pluginsChanged);
    widget.plans.removeListener(_plansChanged);
    _filesFocus.dispose();
    _savedInspectFocus.dispose();
    super.dispose();
  }

  void _open() {
    _opener = FocusManager.instance.primaryFocus;
    if (_compact) _scaffold.currentState?.openEndDrawer();
  }

  void _close() {
    if (_scaffold.currentState?.isEndDrawerOpen ?? false) {
      _allowDrawerClose = true;
      _scaffold.currentState!.closeEndDrawer();
    } else {
      widget.plans.inspector.close();
      widget.archives?.closeInspector();
      widget.sortOrder?.closeInspector();
      widget.onCloseAdditionalInspector?.call();
      _opener?.requestFocus();
    }
  }

  void _finishDrawerClose() {
    widget.plans.inspector.close();
    widget.plugins?.closeInspector();
    widget.archives?.closeInspector();
    widget.sortOrder?.closeInspector();
    widget.onCloseAdditionalInspector?.call();
    _opener?.requestFocus();
  }

  void _guardDrawerClose() {
    if (_guardingDrawerClose) return;
    _guardingDrawerClose = true;
    unawaited(
      widget.plans.inspector
          .guardTextNavigation(() {
            _allowDrawerClose = true;
            _scaffold.currentState?.closeEndDrawer();
          })
          .whenComplete(() => _guardingDrawerClose = false),
    );
  }

  void _drawerChanged(bool open) {
    if (open) return;
    if (_allowDrawerClose) {
      _allowDrawerClose = false;
      _finishDrawerClose();
      return;
    }
    if (!widget.plans.inspector.editingText) {
      _finishDrawerClose();
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scaffold.currentState?.openEndDrawer();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _guardDrawerClose();
      });
    });
  }

  void _changeInspector(VoidCallback change) {
    unawaited(widget.plans.inspector.guardTextNavigation(change));
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      widget.plans,
      if (widget.plugins != null) widget.plugins!,
      if (widget.archives != null) widget.archives!,
      if (widget.sortOrder != null) widget.sortOrder!,
    ]),
    builder: (context, _) => LayoutBuilder(
      builder: (context, bounds) {
        _compact = bounds.maxWidth < 1200;
        final narrow = bounds.maxWidth < 1050;
        final saved = widget.mods.files.selected;
        final mod = widget.mods.selected;
        final version = widget.mods.selectedVersionId;
        Widget inspector() => widget.plugins?.inspecting == true
            ? PluginInspector(controller: widget.plugins!, onClose: _close)
            : widget.archives?.inspecting == true
            ? ArchivePolicyInspector(
                controller: widget.archives!,
                onClose: _close,
              )
            : widget.sortOrder?.inspecting == true
            ? SortOrderInspector(controller: widget.sortOrder!, onClose: _close)
            : widget.additionalInspector?.call(_close) ??
                  FileSourcesInspector(
                    controller: widget.plans,
                    onClose: _close,
                    profileName: widget.profileName,
                  );
        return Scaffold(
          key: _scaffold,
          backgroundColor: Colors.transparent,
          endDrawer: PopScope(
            canPop: _allowDrawerClose || !widget.plans.inspector.editingText,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) _guardDrawerClose();
            },
            child: Drawer(
              width: math.min(540, bounds.maxWidth),
              child: inspector(),
            ),
          ),
          onEndDrawerChanged: _drawerChanged,
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ModLibraryBrowser(
                  controller: widget.mods,
                  view: widget.view,
                  externalPaneControls: widget.externalPaneControls,
                  paneActions: [
                    if (widget.sortOrder case final sort?)
                      Tooltip(
                        message: 'Optimise plugin load order with LOOT',
                        child: McAction(
                          label: 'Optimise',
                          icon: Icons.auto_fix_high,
                          emphasis: McActionEmphasis.primary,
                          onPressed: sort.canPreview
                              ? () => unawaited(sort.optimise())
                              : null,
                        ),
                      ),
                  ],
                  onOpenNexus: widget.onOpenNexus,
                  maintenance: widget.maintenance,
                  onDeleted: widget.onDeleted,
                  onMaintenanceOpen: _close,
                  workspacePath: widget.workspacePath,
                  chooseDirectory: widget.chooseDirectory,
                  singlePane: narrow,
                  inventoryExports: widget.inventoryExports,
                  chooseExportLocation: widget.chooseExportLocation,
                  openExportFolder: widget.openExportFolder,
                  profileName: widget.profileName,
                  savedFileActions: [
                    McIconAction(
                      label: 'Inspect file',
                      focusNode: _savedInspectFocus,
                      icon: const Icon(Icons.info_outline),
                      onPressed:
                          saved == null ||
                              saved.folder ||
                              mod == null ||
                              version == null ||
                              widget.plans.state == null
                          ? null
                          : () {
                              widget.onCloseAdditionalInspector?.call();
                              _open();
                              unawaited(
                                widget.plans.inspector.showCopy(
                                  ManagedFileCopy(mod.id, version, saved.path),
                                ),
                              );
                            },
                    ),
                  ],
                  paneLabel: widget.plugins == null ? 'Files' : 'View',
                  filePanes: [
                    ModFilePane(
                      'load-order',
                      'Load order',
                      (context, narrow) => LoadOrderPane(
                        controller: widget.mods.loadOrder,
                        narrow: narrow,
                        problem:
                            widget.plugins?.problem ??
                            widget.sortOrder?.problem,
                        pluginSetting: widget.plugins?.setting,
                        canTogglePlugin: widget.plugins?.canToggle,
                        onTogglePlugin: (plugin) => unawaited(
                          widget.plugins!.change(
                            widget.plugins!.setting(plugin.name)?.enabled ==
                                    true
                                ? PluginOrderAction.disable
                                : PluginOrderAction.enable,
                            name: plugin.name,
                          ),
                        ),
                        onInspectPlugin: (plugin) => _changeInspector(() {
                          widget.plans.inspector.close();
                          widget.archives?.closeInspector();
                          widget.sortOrder?.closeInspector();
                          widget.plugins!.select(plugin);
                          widget.plugins!.inspect();
                          _open();
                        }),
                        onMovePlugins: widget.plugins == null
                            ? null
                            : (names, direction) async {
                                final plugins = widget.plugins!;
                                await plugins.change(
                                  direction == ProfileModMove.up
                                      ? PluginOrderAction.up
                                      : PluginOrderAction.down,
                                  names: names,
                                );
                                return plugins.problem == null;
                              },
                        onInspectCopy: (copy) => _changeInspector(() {
                          widget.plugins?.closeInspector();
                          widget.archives?.closeInspector();
                          widget.sortOrder?.closeInspector();
                          _open();
                          unawaited(widget.plans.inspector.showCopy(copy));
                        }),
                      ),
                    ),
                    if (widget.plugins case final plugins?)
                      ModFilePane(
                        'bethesda-plugins',
                        'Plugins',
                        (context, narrow) => PluginsPane(
                          controller: plugins,
                          narrow: narrow,
                          onInspect: () => _changeInspector(() {
                            widget.plans.inspector.close();
                            widget.onCloseAdditionalInspector?.call();
                            _opener = FocusManager.instance.primaryFocus;
                            _scaffold.currentState?.openEndDrawer();
                          }),
                        ),
                      ),
                    if (widget.archives case final archives?)
                      ModFilePane(
                        'bethesda-archives',
                        'Archives',
                        (context, narrow) => ArchivePolicyPane(
                          controller: archives,
                          narrow: narrow,
                          onInspect: () => _changeInspector(() {
                            widget.plans.inspector.close();
                            widget.plugins?.closeInspector();
                            widget.onCloseAdditionalInspector?.call();
                            _opener = FocusManager.instance.primaryFocus;
                            _scaffold.currentState?.openEndDrawer();
                          }),
                        ),
                      ),
                    if (widget.sortOrder case final sortOrder?)
                      ModFilePane(
                        'loot-sort-order',
                        'LOOT details',
                        (context, narrow) => SortOrderPane(
                          controller: sortOrder,
                          narrow: narrow,
                          onInspect: () => _changeInspector(() {
                            widget.plans.inspector.close();
                            widget.plugins?.closeInspector();
                            widget.archives?.closeInspector();
                            widget.onCloseAdditionalInspector?.call();
                            _opener = FocusManager.instance.primaryFocus;
                            _scaffold.currentState?.openEndDrawer();
                          }),
                        ),
                      ),
                    ModFilePane(
                      'skyrim-data',
                      'File inspection',
                      (context, narrow) => PlannedFiles(
                        controller: widget.plans,
                        focusNode: _filesFocus,
                        narrow: narrow,
                        archiveUnavailable: widget.archiveUnavailable,
                        onOpenProblems: widget.onOpenProblems,
                        onInspect: (row) {
                          widget.onCloseAdditionalInspector?.call();
                          _open();
                          unawaited(
                            widget.plans.inspector.showTarget(row.path),
                          );
                        },
                      ),
                    ),
                    ...?widget.additionalFilePanes?.call(
                      () => _changeInspector(() {
                        widget.plans.inspector.close();
                        _open();
                      }),
                    ),
                  ],
                ),
              ),
              if (!_compact &&
                  (widget.plans.inspector.visible ||
                      widget.archives?.inspecting == true ||
                      widget.sortOrder?.inspecting == true ||
                      widget.additionalInspector != null)) ...[
                const SizedBox(width: 16),
                SizedBox(width: 350, child: inspector()),
              ],
            ],
          ),
        );
      },
    ),
  );
}
