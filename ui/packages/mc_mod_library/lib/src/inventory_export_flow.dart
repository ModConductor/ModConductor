part of 'browser.dart';

extension _InventoryExportFlow on _ModLibraryBrowserState {
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
      _setExportResult(result);
    }
    _modsFocus.requestFocus();
  }

  Future<void> _openExportFolder() async {
    final result = _exportResult;
    final opener = widget.openExportFolder;
    if (result?.destinationPath == null || opener == null) return;
    final opened = await opener(result!.destinationPath!);
    if (mounted && !opened) _showExportFolderProblem();
  }

  Widget _exportStatus(
    BuildContext context,
    InventoryExportDialogResult result,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: result.completed
              ? McStatus(
                  key: const ValueKey('export-completed-status'),
                  title:
                      'Mod Conductor saved ${result.rowCount} rows to ${result.fileName}.',
                  detail: _folderProblem ? 'The folder did not open.' : 'The file uses UTF-8, commas, quoted fields, and Windows-compatible line endings.',
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
    );
  }
}
