import 'fomod_view.dart';
import 'bain_view.dart';
import 'update_form.dart';
import 'update_view.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_collections/mc_ui_collections.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'archive_facts.dart';
import 'installation_controller.dart';
import 'installation_forms.dart';
import 'installation_tree.dart';
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
      final included = draft?.files.length ?? 0,
          omitted =
              (draft?.manifest.entries.where((e) => !e.directory).length ?? 0) -
              included;
      Widget rootChoice() => McMenuAction<List<String>>(
        label: narrow
            ? 'Root: ${draft!.root.isEmpty ? 'Archive' : draft.root.join(' / ')}'
            : 'Root folder',
        choices: [
          for (var i = 0; i <= draft!.root.length; ++i)
            draft.root.take(i).toList(),
        ],
        describe: (path) => path.isEmpty ? 'Archive root' : path.join(' / '),
        enabled: controller.canEdit,
        onSelected: (path) =>
            unawaited(controller.change(InstallationRootChange(path))),
      );
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
            Row(
              children: [
                McIconAction(
                  label: status == null && manual && draft?.canInstall == true
                      ? 'Back to review'
                      : widget.backLabel,
                  icon: const Icon(Icons.arrow_back),
                  onPressed:
                      status == null && manual && draft?.canInstall == true
                      ? () => layout(false)
                      : widget.onBack,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    status != null
                        ? status.archiveName
                        : manual
                        ? 'Archive layout'
                        : draft == null
                        ? widget.artifact.originalName
                        : 'New mod: ${draft.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(c).textTheme.titleMedium,
                  ),
                ),
                if (draft != null && status == null) ...[
                  if (!manual) ...[
                    if (widget.maintenance != null &&
                        widget.updateTargets != null)
                      McIconAction(
                        label: widget.suggestedTarget == null
                            ? 'Update installed mod'
                            : 'Review update',
                        icon: const Icon(Icons.system_update_alt),
                        onPressed: controller.canEdit && draft.canInstall
                            ? updateTarget
                            : null,
                      ),
                    McIconAction(
                      label: 'Edit mod details',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: controller.canEdit ? metadata : null,
                    ),
                    const SizedBox(width: 8),
                  ],
                  McAction(
                    label: manual ? 'Review' : 'Install',
                    icon: manual ? Icons.check : Icons.install_desktop,
                    emphasis: McActionEmphasis.primary,
                    onPressed: controller.busy || !draft.canInstall
                        ? null
                        : manual
                        ? () => layout(false)
                        : () => unawaited(controller.install()),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            if (draft != null && status == null && !narrow) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Archive folder: ${draft.root.isEmpty ? 'Archive root' : draft.root.join(' / ')}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(c).textTheme.bodySmall,
                    ),
                  ),
                  if (manual)
                    rootChoice()
                  else
                    McAction(
                      label: 'Change layout',
                      icon: Icons.account_tree_outlined,
                      onPressed: controller.canEdit ? () => layout(true) : null,
                    ),
                ],
              ),
              const SizedBox(height: 8),
            ],
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
                          child: McCollection<String, InstallationRow>(
                            model: tree.model,
                            title: manual
                                ? 'Archive files'
                                : excluded
                                ? 'Excluded archive files'
                                : 'Files in new mod',
                            showTitle: !narrow,
                            showTree: true,
                            filterLabel: 'Filter files',
                            filterEnabled: !controller.busy,
                            compactFilter: narrow,
                            countLabel: manual
                                ? '$included included · $omitted excluded'
                                : excluded
                                ? '$omitted excluded ${omitted == 1 ? 'file' : 'files'}'
                                : narrow
                                ? '$included ${included == 1 ? 'file' : 'files'} · ${archiveSize(draft.bytes)} · Mod starts disabled'
                                : '$included ${included == 1 ? 'file' : 'files'} · ${archiveSize(draft.bytes)} · $omitted excluded',
                            filterActions: [
                              if (draft.wizardScripts.isNotEmpty) ...[
                                Text(
                                  'Wizard script not supported',
                                  style: Theme.of(c).textTheme.bodySmall,
                                ),
                                const SizedBox(width: 8),
                              ],
                              if (narrow) ...[
                                if (manual)
                                  rootChoice()
                                else ...[
                                  Flexible(
                                    child: Text(
                                      draft.root.isEmpty
                                          ? 'Archive root'
                                          : draft.root.join(' / '),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(c).textTheme.bodySmall,
                                    ),
                                  ),
                                  McIconAction(
                                    label: 'Change layout',
                                    icon: const Icon(
                                      Icons.account_tree_outlined,
                                    ),
                                    onPressed: controller.canEdit
                                        ? () => layout(true)
                                        : null,
                                  ),
                                ],
                              ],
                              if (!manual) ...[
                                const SizedBox(width: 8),
                                McMenuAction<bool>(
                                  label: excluded
                                      ? 'Excluded ($omitted)'
                                      : 'Included ($included)',
                                  choices: const [false, true],
                                  describe: (v) => v
                                      ? 'Excluded ($omitted)'
                                      : 'Included ($included)',
                                  onSelected: (v) {
                                    setState(() => excluded = v);
                                    tree.apply(
                                      draft,
                                      manual: manual,
                                      excluded: excluded,
                                    );
                                  },
                                ),
                              ],
                            ],
                            onSelect: manual
                                ? (_) {
                                    setState(() => inspected = true);
                                    if (narrow)
                                      pane.currentState?.openEndDrawer();
                                  }
                                : null,
                            columns: [
                              McColumn(
                                manual || excluded
                                    ? 'Archive path'
                                    : 'Destination',
                                (r) => Row(
                                  children: [
                                    if (manual)
                                      Checkbox(
                                        tristate: true,
                                        value: r.included,
                                        onChanged: controller.canEdit
                                            ? (_) => unawaited(
                                                controller.change(
                                                  InstallationInclusionChange(
                                                    r.components,
                                                    r.included != true,
                                                  ),
                                                ),
                                              )
                                            : null,
                                      ),
                                    Expanded(
                                      child: McCollectionName(
                                        r.name,
                                        icon: r.directory
                                            ? Icons.folder_outlined
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),
                                interactive: manual,
                              ),
                              if (!narrow && manual)
                                McColumn(
                                  'Destination',
                                  (r) => Text(
                                    r.included == false
                                        ? 'Excluded'
                                        : r.destination == null
                                        ? ''
                                        : r.destination!.isEmpty
                                        ? 'Mod root'
                                        : r.destination!.join('/'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  width: 270,
                                ),
                              if (!narrow)
                                McColumn(
                                  'Size',
                                  (r) => Text(
                                    r.directory ? '' : archiveSize(r.size),
                                  ),
                                  width: 90,
                                ),
                            ],
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
