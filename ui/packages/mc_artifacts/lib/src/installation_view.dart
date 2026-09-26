import 'fomod_view.dart';
import 'bain_view.dart';
import 'update_form.dart';
import 'update_view.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'installation_controller.dart';
import 'installation_forms.dart';
import 'installation_tree.dart';
import 'installation_file_collection.dart';
import 'installation_header.dart';
import 'installation_details.dart';

class ArchiveInstallationView extends StatefulWidget {
  const ArchiveInstallationView({
    super.key,
    required this.artifact,
    required this.client,
    this.initialDraft,
    this.suggestedTarget,
    this.suggestedVersion,
    this.initialStatus,
    this.backLabel = 'Back to archives',
    this.maintenance,
    this.fomod,
    this.bain,
    this.profileId,
    this.updateTargets,
    required this.onBack,
    required this.onCommitted,
    this.onDetached,
    this.onAttached,
    required this.onOpenMods,
  });
  final ModEntry? suggestedTarget;
  final String? suggestedVersion;
  final InstallationDraft? initialDraft;
  final InstallationStatus? initialStatus;
  final String backLabel;
  final Artifact artifact;
  final InstallationsClient client;
  final MaintenanceClient? maintenance;
  final FomodClient? fomod;
  final BainClient? bain;
  final String? profileId;
  final Future<ModQueryPage> Function(ModQueryCursor?)? updateTargets;
  final VoidCallback onBack, onCommitted, onOpenMods;
  final void Function(InstallationStatus)? onDetached;
  final void Function(InstallationStatus)? onAttached;
  @override
  State<ArchiveInstallationView> createState() =>
      _ArchiveInstallationViewState();
}

class _ArchiveInstallationViewState extends State<ArchiveInstallationView> {
  final pane = GlobalKey<ScaffoldState>();
  final tree = InstallationTree();
  late final controller = InstallationController(
    widget.client,
    widget.artifact,
    widget.onCommitted,
    onDetached: widget.onDetached,
    onAttached: widget.onAttached,
    initialDraft: widget.initialDraft,
    initialStatus: widget.initialStatus,
  );
  bool manual = false, excluded = false, inspected = false;
  InstallationDraft? rendered;
  @override
  void initState() {
    super.initState();
    controller.addListener(changed);
    unawaited(controller.open());
  }

  void changed() {
    if (!mounted) return;
    final draft = controller.draft;
    if (draft != null && !identical(draft, rendered)) {
      if (rendered == null && !draft.canInstall) manual = true;
      rendered = draft;
      tree.apply(draft, manual: manual, excluded: excluded);
    }
    if (controller.status?.phase == InstallationPhase.discarded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onBack();
      });
    }
    setState(() {});
  }

  @override
  void dispose() {
    controller.removeListener(changed);
    controller.dispose();
    tree.dispose();
    super.dispose();
  }

  void layout(bool value) {
    manual = value;
    excluded = false;
    inspected = false;
    final draft = controller.draft;
    if (draft != null) tree.apply(draft, manual: manual, excluded: excluded);
    setState(() {});
  }

  Future<void> metadata() async {
    final draft = controller.draft;
    if (draft == null) return;
    final change = await showDialog<InstallationMetadataChange>(
      context: context,
      builder: (_) => InstallationMetadataForm(draft: draft),
    );
    if (change != null && mounted) await controller.change(change);
  }

  Future<void> destination(InstallationRow row) async {
    final change = await showDialog<InstallationDestinationChange>(
      context: context,
      builder: (_) => InstallationDestinationForm(
        source: row.components,
        destination: row.destination ?? row.components,
        directory: row.directory,
      ),
    );
    if (change != null && mounted) await controller.change(change);
  }

  Future<void> updateTarget() async {
    final draft = controller.draft;
    if (draft == null ||
        widget.maintenance == null ||
        widget.updateTargets == null)
      return;
    final result = await showDialog<({ModEntry target, String version})>(
      context: context,
      builder: (_) => UpdateTargetForm(
        archiveName: draft.archiveName,
        load: widget.updateTargets!,
        target: controller.updateTarget ?? widget.suggestedTarget,
        version:
            controller.updatePreview?.nextVersion ??
            widget.suggestedVersion ??
            draft.version,
      ),
    );
    if (result != null && mounted)
      await controller.prepareUpdate(
        widget.maintenance!,
        result.target,
        result.version,
      );
  }

  @override
  Widget build(BuildContext c) => LayoutBuilder(
    builder: (c, box) {
      final narrow = box.maxWidth < 1100 * MediaQuery.textScalerOf(c).scale(1),
          draft = controller.draft,
          status = controller.status;
      if (controller.updatePreview != null &&
          status == null &&
          widget.maintenance != null) {
        return ModUpdateView(
          controller: controller,
          client: widget.maintenance!,
          edit: updateTarget,
          onBack: widget.onBack,
        );
      }
      if (draft?.installer == InstallationMode.bain &&
          widget.bain != null &&
          status == null) {
        return BainView(
          key: ValueKey((draft!.id, widget.bain)),
          client: widget.bain!,
          backLabel: widget.backLabel,
          initial: draft,
          available: controller.canEdit,
          operationProblem: controller.problem,
          onReviewed: controller.adoptDraft,
          onModeChanged: (value) {
            controller.adoptDraft(value);
            layout(!value.canInstall);
          },
          onInstall: () => unawaited(controller.install()),
          onBack: widget.onBack,
          onUpdate: widget.maintenance != null && widget.updateTargets != null
              ? () => unawaited(updateTarget())
              : null,
        );
      }
      if (draft?.installer == InstallationMode.fomod &&
          widget.fomod != null &&
          status == null) {
        return FomodView(
          key: ValueKey((draft!.id, widget.fomod)),
          client: widget.fomod!,
          backLabel: widget.backLabel,
          packages: widget.bain,
          initial: draft,
          profileId: widget.profileId,
          available: controller.canEdit,
          operationProblem: controller.problem,
          onReviewed: controller.adoptDraft,
          onManual: (value) {
            controller.adoptDraft(value);
            layout(!value.canInstall);
          },
          onInstall: () => unawaited(controller.install()),
          onBack: widget.onBack,
          onUpdate: widget.maintenance != null && widget.updateTargets != null
              ? () => unawaited(updateTarget())
              : null,
        );
      }
      return Scaffold(
        key: pane,
        backgroundColor: Colors.transparent,
        endDrawer: Drawer(
          width: 440,
          child: installationInspector(
            c,
            tree.model.selected,
            controller,
            destination,
            () => pane.currentState?.closeEndDrawer(),
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InstallationHeader(
              artifactName: widget.artifact.originalName,
              backLabel: widget.backLabel,
              draft: draft,
              status: status,
              controller: controller,
              manual: manual,
              narrow: narrow,
              canUpdate:
                  widget.maintenance != null && widget.updateTargets != null,
              reviewUpdate: widget.suggestedTarget != null,
              onBack: widget.onBack,
              onLayout: layout,
              onMetadata: () => unawaited(metadata()),
              onUpdate: () => unawaited(updateTarget()),
            ),
            if (controller.problem != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: McStatus(
                        title: controller.problem!,
                        tone: McStatusTone.error,
                      ),
                    ),
                    if (status != null &&
                        status.phase == InstallationPhase.running)
                      McAction(
                        label: 'Check progress',
                        onPressed: controller.observe,
                      ),
                    if (draft == null && status == null)
                      McAction(
                        label: 'Retry',
                        onPressed: controller.busy
                            ? null
                            : () => unawaited(controller.open()),
                      ),
                  ],
                ),
              ),
            Expanded(
              child: status != null
                  ? installationResult(c, status, controller, widget.onOpenMods)
                  : draft == null
                  ? controller.busy
                        ? const Center(child: CircularProgressIndicator())
                        : const SizedBox.shrink()
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: InstallationFileCollection(
                            draft: draft,
                            tree: tree,
                            controller: controller,
                            manual: manual,
                            excluded: excluded,
                            narrow: narrow,
                            onLayout: layout,
                            onExcluded: (value) {
                              setState(() => excluded = value);
                              tree.apply(
                                draft,
                                manual: manual,
                                excluded: excluded,
                              );
                            },
                            onInspect: () {
                              setState(() => inspected = true);
                              if (narrow) pane.currentState?.openEndDrawer();
                            },
                          ),
                        ),
                        if (manual && inspected && !narrow) ...[
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 360,
                            child: installationInspector(
                              c,
                              tree.model.selected,
                              controller,
                              destination,
                              () => setState(() => inspected = false),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
            if (draft != null && status == null && !manual && !narrow) ...[
              const SizedBox(height: 8),
              Text(
                'The new mod will be added disabled.',
                style: Theme.of(c).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      );
    },
  );
}
