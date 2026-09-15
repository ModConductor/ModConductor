import 'package:mc_bethesda/mc_bethesda.dart';
import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_file_plans/mc_file_plans.dart';
import 'package:mc_mod_library/mc_mod_library.dart';

import 'output_controller.dart';
import 'output_pane.dart';
import 'output_inspector.dart';

class DeploymentOutputsWorkbench extends StatelessWidget {
  const DeploymentOutputsWorkbench({
    super.key,
    required this.mods,
    required this.plans,
    required this.outputs,
    required this.workspacePath,
    required this.chooseDirectory,
    this.profileId,
    this.plugins,
    this.archives,
    this.sortOrder,
    this.profileName,
    this.maintenance,
    this.onOpenDeployment,
    this.onOpenProblems,
    this.onOpenNexus,
    this.organization,
    this.archiveUnavailable = false,
    this.inventoryExports,
    this.chooseExportLocation,
    this.openExportFolder,
  });
  final ModLibraryController mods;
  final FilePlansController plans;
  final PluginsController? plugins;
  final ArchivePolicyController? archives;
  final SortOrderController? sortOrder;
  final OutputController outputs;
  final String workspacePath;
  final Future<String?> Function(String?) chooseDirectory;
  final String? profileId, profileName;
  final void Function(ModEntry)? onOpenNexus;
  final MaintenanceClient? maintenance;
  final VoidCallback? onOpenDeployment;
  final VoidCallback? onOpenProblems;
  final ModOrganizationClient? organization;
  final bool archiveUnavailable;
  final InventoryExportClient? inventoryExports;
  final InventoryExportLocationChooser? chooseExportLocation;
  final InventoryExportFolderOpener? openExportFolder;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: outputs,
    builder: (context, _) => FilePlanningWorkbench(
      mods: mods,
      onOpenNexus: onOpenNexus,
      maintenance: maintenance,
      onOpenDeployment: onOpenDeployment,
      onOpenProblems: onOpenProblems,
      plans: plans,
      plugins: plugins,
      archives: archives,
      sortOrder: sortOrder,
      workspacePath: workspacePath,
      chooseDirectory: chooseDirectory,
      profileName: profileName,
      archiveUnavailable: archiveUnavailable,
      inventoryExports: inventoryExports,
      chooseExportLocation: chooseExportLocation,
      openExportFolder: openExportFolder,
      additionalFilePanes: (onInspect) => [
        ModFilePane(
          'tool-outputs',
          'Tool outputs',
          (context, narrow) => OutputPane(
            key: const ValueKey('tool-outputs'),
            controller: outputs,
            kind: OutputLocationKind.toolFolder,
            narrow: narrow,
            onInspect: onInspect,
            profileId: profileId,
            organization: organization,
            selectedMod: mods.selected,
          ),
        ),
        ModFilePane(
          'writable-files',
          'Writable game files',
          (context, narrow) => OutputPane(
            key: const ValueKey('writable-files'),
            controller: outputs,
            kind: OutputLocationKind.writableFile,
            narrow: narrow,
            onInspect: onInspect,
            profileId: profileId,
            organization: organization,
            selectedMod: mods.selected,
          ),
        ),
      ],
      additionalInspector: outputs.inspected == null
          ? null
          : (onClose) => OutputInspector(
              controller: outputs,
              onClose: onClose,
              profileId: profileId,
              organization: organization,
              selectedMod: mods.selected,
            ),
      onCloseAdditionalInspector: outputs.closeInspector,
    ),
  );
}
