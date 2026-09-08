import 'dart:async';
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
    this.archiveUnavailable = false,
  });
  final ModLibraryController mods;
  final FilePlansController plans;
  final String workspacePath;
  final Future<String?> Function(String?) chooseDirectory;
  final String? profileName;
  final bool archiveUnavailable;
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
  @override
  void initState() {
    super.initState();
    _selectionRevision = widget.mods.inventory.revision;
    _catalogueRevision = widget.mods.inventory.catalogueRevision;
    widget.mods.addListener(_changed);
    widget.mods.files.addListener(_selectionChanged);
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
      _scaffold.currentState!.closeEndDrawer();
    } else {
      widget.plans.inspector.close();
      _opener?.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.plans,
    builder: (context, _) => LayoutBuilder(
      builder: (context, bounds) {
        _compact = bounds.maxWidth < 1200;
        final narrow = bounds.maxWidth < 1050;
        final saved = widget.mods.files.selected;
        final mod = widget.mods.selected;
        final version = widget.mods.selectedVersionId;
        Widget inspector() => FileSourcesInspector(
          controller: widget.plans,
          onClose: _close,
          profileName: widget.profileName,
        );
        return Scaffold(
          key: _scaffold,
          backgroundColor: Colors.transparent,
          endDrawer: Drawer(
            width: math.min(540, bounds.maxWidth),
            child: inspector(),
          ),
          onEndDrawerChanged: (open) {
            if (!open) {
              widget.plans.inspector.close();
              _opener?.requestFocus();
            }
          },
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ModLibraryBrowser(
                  controller: widget.mods,
                  workspacePath: widget.workspacePath,
                  chooseDirectory: widget.chooseDirectory,
                  singlePane: narrow,
                  extraFilePaneLabel: 'Skyrim Data',
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
                              _open();
                              unawaited(
                                widget.plans.inspector.showCopy(
                                  ManagedFileCopy(mod.id, version, saved.path),
                                ),
                              );
                            },
                    ),
                  ],
                  filePaneBuilder: (context, savedFiles, planned, narrow) =>
                      planned
                      ? PlannedFiles(
                          controller: widget.plans,
                          focusNode: _filesFocus,
                          narrow: narrow,
                          archiveUnavailable: widget.archiveUnavailable,
                          onInspect: (row) {
                            _open();
                            unawaited(
                              widget.plans.inspector.showTarget(row.path),
                            );
                          },
                        )
                      : savedFiles,
                ),
              ),
              if (!_compact && widget.plans.inspector.visible) ...[
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
