import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_collections/mc_ui_collections.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'controller.dart';
import 'nexus_view.dart';
import 'bundle_view.dart';
import 'installation_view.dart';
import 'contents_view.dart';
import 'forms.dart';
import 'download_form.dart';
import 'download_view.dart';
import 'archive_facts.dart';
import 'artifact_inspector.dart';
export 'forms.dart' show ArchiveFile, ArchiveChooser;

class ArtifactBrowser extends StatefulWidget {
  const ArtifactBrowser({
    super.key,
    required this.controller,
    required this.chooseFile,
    required this.workspacePath,
    this.installations,
    this.nexus,
    this.maintenance,
    this.fomod,
    this.bain,
    this.bundles,
    this.profileId,
    this.updateTargets,
    this.onInstalled,
    this.onInstallationDetached,
    this.onInstallationAttached,
    this.onOpenMods,
  });
  final ArtifactController controller;
  final ArchiveChooser chooseFile;
  final String workspacePath;
  final InstallationsClient? installations;
  final NexusClient? nexus;
  final MaintenanceClient? maintenance;
  final FomodClient? fomod;
  final BainClient? bain;
  final BundlesClient? bundles;
  final String? profileId;
  final Future<ModQueryPage> Function(ModQueryCursor?)? updateTargets;
  final Future<void> Function()? onInstalled;
  final void Function(InstallationStatus)? onInstallationDetached;
  final void Function(InstallationStatus)? onInstallationAttached;
  final VoidCallback? onOpenMods;
  @override
  State<ArtifactBrowser> createState() => _ArtifactBrowserState();
}

class _ArtifactBrowserState extends State<ArtifactBrowser> {
  final pane = GlobalKey<ScaffoldState>();
  final focus = FocusNode(debugLabel: 'Archives');
  final addFocus = FocusNode(debugLabel: 'Add archive');
  final scroll = ScrollController();
  int reviewNavigation = 0;
  ModEntry? suggestedTarget;
  String? suggestedVersion;
  bool inspected = false;
  bool nexus = false;
  Artifact? contents, installing, bundle;
  Future<void>? installationRefresh;
  ArtifactController get controller => widget.controller;
  @override
  void dispose() {
    focus.dispose();
    addFocus.dispose();
    scroll.dispose();
    super.dispose();
  }

  Future<void> fileForm([Artifact? original]) async {
    if (original == null) addFocus.requestFocus();
    final result =
        await showDialog<({ArchiveFile file, ArtifactStorage storage})>(
          context: context,
          builder: (_) => ArchiveFileForm(
            chooseFile: widget.chooseFile,
            workspacePath: widget.workspacePath,
            original: original,
          ),
        );
    if (!mounted || result == null) return;
    final id = newOperationId();
    await controller.change(
      original == null ? 'Adding archive' : 'Locating archive',
      (client, workspace) => original == null
          ? client.add(workspace, id, result.file.path, result.storage)
          : client.locate(original, result.file.path),
    );
    if (mounted) setState(() => inspected = true);
  }

  Future<void> download() async {
    final request = await showDialog<ArchiveDownloadRequest>(
      context: context,
      builder: (_) => const ArchiveDownloadForm(),
    );
    if (request == null || !mounted) return;
    final id = newOperationId();
    await controller.change(
      'Starting download',
      (client, workspace) => client.download(workspace, id, request),
    );
    if (mounted) setState(() => inspected = true);
  }

  Future<void> link(Artifact artifact) async {
    final client = controller.client;
    if (client == null) return;
    final result = await showDialog<ArtifactLink>(
      context: context,
      builder: (_) => ArchiveLinkForm(client: client, artifact: artifact),
    );
    if (!mounted || result == null) return;
    await controller.change(
      'Linking mod',
      (client, _) => client.link(artifact, result),
    );
  }

  Future<void> cleanup(Artifact artifact, {required bool bytes}) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (c) => McFormDialog(
        title: bytes ? 'Delete library copy?' : 'Remove archive from list?',
        action: bytes ? 'Delete copy' : 'Remove from list',
        onSubmit: () => Navigator.pop(c, true),
        children: [
          Text(artifact.originalName),
          const SizedBox(height: 16),
          Text(
            bytes
                ? (artifact.download == null
                      ? 'The original file and installed mods stay unchanged.'
                      : 'Installed mods stay unchanged.')
                : 'Removes this archive from the list. The original file stays unchanged.',
          ),
          if (bytes) ...[
            const SizedBox(height: 16),
            const Text('The archive stays in this list with its mod links.'),
          ],
        ],
      ),
    );
    if (!mounted || accepted != true) return;
    await controller.change(
      bytes ? 'Deleting library copy' : 'Removing archive',
      (client, _) async {
        if (bytes) return client.deleteCopy(artifact);
        await client.remove(artifact);
        return null;
      },
      removed: bytes ? null : artifact.id,
    );
  }

  Widget inspector(BuildContext c, VoidCallback close) => ArtifactInspector(
    controller: controller,
    onClose: close,
    onRead: (artifact) {
      pane.currentState?.closeEndDrawer();
      setState(() => contents = artifact);
    },
    onBundle: widget.bundles == null || widget.installations == null
        ? null
        : (artifact) {
            close();
            setState(() => bundle = artifact);
          },
    onInstall: widget.installations == null
        ? null
        : (artifact) {
            pane.currentState?.closeEndDrawer();
            setState(() {
              installing = artifact;
              suggestedVersion =
                  controller.updateReview?.artifact.id == artifact.id
                  ? controller.updateReview?.version
                  : null;
              suggestedTarget =
                  controller.updateReview?.artifact.id == artifact.id
                  ? controller.updateReview?.target
                  : null;
            });
          },
    onLocate: fileForm,
    onLink: link,
    onCleanup: (artifact, bytes) => cleanup(artifact, bytes: bytes),
  );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => LayoutBuilder(
      builder: (c, constraints) {
        final narrow =
            constraints.maxWidth < 1100 * MediaQuery.textScalerOf(c).scale(1);
        if (nexus &&
            widget.nexus != null &&
            controller.workspaceId != null &&
            widget.profileId != null) {
          return NexusFilesView(
            key: ValueKey((controller.workspaceId, widget.nexus)),
            client: widget.nexus!,
            workspace: controller.workspaceId!,
            profile: widget.profileId!,
            onBack: () => setState(() => nexus = false),
            onDownloaded: (artifact) async {
              if (!mounted || artifact.workspaceId != controller.workspaceId)
                return;
              final foreground = nexus;
              controller.acceptDownload(artifact, select: foreground);
              if (foreground) {
                setState(() {
                  nexus = false;
                  inspected = true;
                });
                if (narrow)
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) pane.currentState?.openEndDrawer();
                  });
              }
            },
          );
        }
        if (bundle?.workspaceId != controller.workspaceId) bundle = null;
        if (bundle != null &&
            widget.bundles != null &&
            widget.installations != null) {
          return ModBundleView(
            key: ValueKey((bundle!.id, widget.bundles)),
            artifact: bundle!,
            client: widget.bundles!,
            installations: widget.installations!,
            fomod: widget.fomod,
            bain: widget.bain,
            profileId: widget.profileId,
            onBack: () => setState(() => bundle = null),
            onCommitted: () {
              installationRefresh = () async {
                await widget.onInstalled?.call();
                if (mounted) await controller.load();
              }();
            },
            onDetached: widget.onInstallationDetached,
            onAttached: widget.onInstallationAttached,
            onOpenMods: () async {
              await installationRefresh;
              if (mounted) widget.onOpenMods?.call();
            },
          );
        }
        if (contents?.workspaceId != controller.workspaceId) contents = null;
        if (installing?.workspaceId != controller.workspaceId)
          installing = null;
        if (reviewNavigation != controller.reviewNavigation) {
          reviewNavigation = controller.reviewNavigation;
          final review = controller.updateReview;
          if (review?.artifact.workspaceId == controller.workspaceId) {
            installing = review!.artifact;
            suggestedTarget = review.target;
            suggestedVersion = review.version;
          }
        }
        if (installing != null && widget.installations != null) {
          return ArchiveInstallationView(
            key: ValueKey((installing!.id, widget.installations)),
            artifact: installing!,
            suggestedTarget: suggestedTarget,
            suggestedVersion: suggestedVersion,
            client: widget.installations!,
            maintenance: widget.maintenance,
            fomod: widget.fomod,
            bain: widget.bain,
            profileId: widget.profileId,
            updateTargets: widget.updateTargets,
            onBack: () => setState(() {
              installing = null;
              suggestedTarget = null;
              suggestedVersion = null;
            }),
            onCommitted: () {
              installationRefresh = () async {
                await widget.onInstalled?.call();
                if (mounted) await controller.load();
              }();
            },
            onDetached: widget.onInstallationDetached,
            onAttached: widget.onInstallationAttached,
            onOpenMods: () async {
              await installationRefresh;
              if (mounted) widget.onOpenMods?.call();
            },
          );
        }
        final archive = contents;
        if (archive != null &&
            archive.workspaceId == controller.workspaceId &&
            controller.client != null) {
          return ArchiveContentsView(
            key: ValueKey(archive.id),
            artifact: archive,
            client: controller.client!,
            onBack: () => setState(() => contents = null),
          );
        }
        return Scaffold(
          key: pane,
          backgroundColor: Colors.transparent,
          endDrawer: Drawer(
            width: 440,
            child: inspector(c, () => pane.currentState?.closeEndDrawer()),
          ),
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: McCollection<String, Artifact>(
                  model: controller.model,
                  title: 'Archives',
                  showTitle: !narrow,
                  showTree: false,
                  focusNode: focus,
                  scrollController: scroll,
                  filterLabel: controller.next == null
                      ? 'Filter archives'
                      : 'Filter loaded archives',
                  countLabel:
                      '${controller.model.ids.length} ${controller.model.ids.length == 1 ? 'archive' : 'archives'}${controller.next == null ? '' : ' loaded'}',
                  empty: 'No archives.',
                  loading: controller.busy,
                  problem: controller.problem ?? controller.progressProblem,
                  filterActions: [
                    if (narrow) ...[
                      McIconAction(
                        label: 'Add archive',
                        icon: const Icon(Icons.add),
                        focusNode: addFocus,
                        onPressed: controller.canEdit ? fileForm : null,
                      ),
                      McIconAction(
                        label: 'Download archive',
                        icon: const Icon(Icons.download),
                        onPressed: controller.canEdit ? download : null,
                      ),
                    ],
                    if (narrow && widget.nexus != null)
                      McAction(
                        label: 'Nexus Mods',
                        onPressed: () => setState(() => nexus = true),
                      ),
                  ],
                  actions: [
                    if (!narrow && widget.nexus != null)
                      McAction(
                        label: 'Nexus Mods',
                        onPressed: () => setState(() => nexus = true),
                      ),
                    if (!narrow)
                      McAction(
                        label: 'Add archive',
                        icon: Icons.add,
                        focusNode: addFocus,
                        onPressed: controller.canEdit ? fileForm : null,
                      ),
                    if (!narrow) ...[
                      const SizedBox(width: 8),
                      McAction(
                        label: 'Download',
                        icon: Icons.download,
                        emphasis: McActionEmphasis.primary,
                        onPressed: controller.canEdit ? download : null,
                      ),
                    ],
                  ],
                  onRefresh: controller.busy || controller.client == null
                      ? null
                      : controller.load,
                  onLoad: controller.next != null && !controller.busy
                      ? () => controller.load(more: true)
                      : null,
                  onSelect: (_) {
                    controller.observe();
                    setState(() => inspected = true);
                    if (narrow) pane.currentState?.openEndDrawer();
                  },
                  columns: [
                    McColumn(
                      'Name',
                      (a) => McCollectionName(
                        a.originalName,
                        icon: Icons.inventory_2_outlined,
                      ),
                    ),
                    McColumn(
                      'Status',
                      (a) => Text(
                        a.download != null &&
                                a.download!.phase != DownloadPhase.complete
                            ? downloadLabel(a.download!)
                            : archiveState(a.state),
                      ),
                      width: 160,
                    ),
                    if (!narrow)
                      McColumn(
                        'Size',
                        (a) => Text(
                          a.download != null &&
                                  a.download!.phase != DownloadPhase.complete
                              ? downloadSize(a.download!)
                              : archiveSize(a.length),
                        ),
                        width: 150,
                      ),
                  ],
                ),
              ),
              if (!narrow && inspected && controller.selected != null) ...[
                const SizedBox(width: 16),
                SizedBox(
                  width: 360,
                  child: inspector(c, () => setState(() => inspected = false)),
                ),
              ],
            ],
          ),
        );
      },
    ),
  );
}
