import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'controller.dart';
import 'queue_controller.dart';
import 'nexus_view.dart';
import 'bundle_view.dart';
import 'installation_view.dart';
import 'contents_view.dart';
import 'forms.dart';
import 'download_form.dart';
import 'artifact_inspector.dart';
import 'artifact_collection.dart';
export 'forms.dart' show ArchiveFile, ArchiveChooser;

class NexusFileRequest {
  const NexusFileRequest(
    this.workspace,
    this.profile,
    this.modId,
    this.revision,
  );
  final String workspace, profile;
  final int modId, revision;
}

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
    this.onQueueInstalled,
    this.onInstallationDetached,
    this.onInstallationAttached,
    this.onOpenMods,
    this.nexusFileRequest,
    this.onNexusRequestClosed,
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
  final Future<bool> Function()? onQueueInstalled;
  final void Function(InstallationStatus)? onInstallationDetached;
  final void Function(InstallationStatus)? onInstallationAttached;
  final VoidCallback? onOpenMods;
  final NexusFileRequest? nexusFileRequest;
  final VoidCallback? onNexusRequestClosed;
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
  bool installImmediately = false;
  Artifact? contents, installing, bundle;
  Future<void>? installationRefresh;
  ArtifactController get controller => widget.controller;
  late final queue = ArchiveQueueController(
    resolve: (id) => controller.model[id],
    refresh: () => refreshInstallation(queued: true),
    onInstalled: (id) => controller.installed(id),
  );
  Object? installationContext;

  Future<bool> refreshInstallation({bool queued = false}) async {
    final context = installationContext;
    if (queued && widget.onQueueInstalled != null) {
      if (!await widget.onQueueInstalled!()) return false;
    } else {
      await widget.onInstalled?.call();
    }
    if (!mounted || context != installationContext) return false;
    return controller.load();
  }

  void bindInstallationContext() {
    final context = (
      controller,
      controller.client,
      controller.workspaceId,
      widget.profileId,
      widget.installations,
    );
    if (context == installationContext) return;
    installationContext = context;
    installing = null;
    suggestedTarget = null;
    suggestedVersion = null;
    queue.bind(context);
  }

  bool get hasDiscoveryRequest =>
      widget.nexusFileRequest?.workspace == controller.workspaceId &&
      widget.nexusFileRequest?.profile == widget.profileId;

  @override
  void initState() {
    super.initState();
    nexus = hasDiscoveryRequest;
    bindInstallationContext();
    controller.addListener(bindInstallationContext);
  }

  @override
  void didUpdateWidget(ArtifactBrowser oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != controller) {
      oldWidget.controller.removeListener(bindInstallationContext);
      controller.addListener(bindInstallationContext);
    }
    bindInstallationContext();
    if (!hasDiscoveryRequest) {
      nexus = false;
    } else if (widget.nexusFileRequest != null &&
        widget.nexusFileRequest?.revision !=
            oldWidget.nexusFileRequest?.revision) {
      nexus = true;
    }
  }

  @override
  void dispose() {
    controller.removeListener(bindInstallationContext);
    queue.dispose();
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

  void install(Artifact artifact, {required bool immediately}) {
    pane.currentState?.closeEndDrawer();
    setState(() {
      installing = artifact;
      installImmediately = immediately;
      suggestedVersion = controller.updateReview?.artifact.id == artifact.id
          ? controller.updateReview?.version
          : null;
      suggestedTarget = controller.updateReview?.artifact.id == artifact.id
          ? controller.updateReview?.target
          : null;
    });
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
        : (artifact) => install(artifact, immediately: true),
    onInstallOptions: widget.installations == null
        ? null
        : (artifact) => install(artifact, immediately: false),
    onLocate: fileForm,
    onLink: link,
    onCleanup: (artifact, bytes) => cleanup(artifact, bytes: bytes),
  );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([controller, queue]),
    builder: (context, _) => LayoutBuilder(
      builder: (c, constraints) {
        final narrow =
            constraints.maxWidth < 1100 * MediaQuery.textScalerOf(c).scale(1);
        if (nexus &&
            widget.nexus != null &&
            controller.workspaceId != null &&
            widget.profileId != null) {
          return NexusFilesView(
            key: ValueKey((
              controller.workspaceId,
              widget.nexus,
              widget.nexusFileRequest?.revision,
            )),
            client: widget.nexus!,
            workspace: controller.workspaceId!,
            profile: widget.profileId!,
            initialModId: hasDiscoveryRequest
                ? widget.nexusFileRequest?.modId
                : null,
            onBack: () {
              widget.onNexusRequestClosed?.call();
              setState(() => nexus = false);
            },
            onDownloaded: (artifact) async {
              if (!mounted || artifact.workspaceId != controller.workspaceId)
                return;
              final foreground = nexus;
              controller.acceptDownload(artifact, select: foreground);
              if (foreground) {
                widget.onNexusRequestClosed?.call();
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
            installImmediately = false;
            suggestedTarget = review.target;
            suggestedVersion = review.version;
          }
        }
        final queued = queue.current;
        final currentInstallation = queued ?? installing;
        if (currentInstallation != null && widget.installations != null) {
          final archive = currentInstallation;
          final view = ArchiveInstallationView(
            key: ValueKey((
              archive.id,
              widget.installations,
              installationContext,
            )),
            artifact: archive,
            installImmediately: queued != null || installImmediately,
            suggestedTarget: suggestedTarget,
            suggestedVersion: suggestedVersion,
            client: widget.installations!,
            maintenance: widget.maintenance,
            fomod: widget.fomod,
            bain: widget.bain,
            profileId: widget.profileId,
            updateTargets: widget.updateTargets,
            onBack: () => setState(() {
              queue.leave();
              this.installing = null;
              suggestedTarget = null;
              suggestedVersion = null;
            }),
            onCommitted: () {
              installationRefresh = queued == null
                  ? refreshInstallation()
                  : queue.committed(archive);
            },
            onInterrupted: queued == null
                ? null
                : () => queue.interrupted(archive),
            onDetached: widget.onInstallationDetached,
            onAttached: widget.onInstallationAttached,
            onOpenMods: () async {
              queue.stop();
              await installationRefresh;
              if (mounted) widget.onOpenMods?.call();
            },
          );
          if (queued == null) return view;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        queue.active
                            ? 'Installing ${queue.position} of ${queue.total}'
                            : 'Queue ended · ${controller.checkedArtifacts.length} selected',
                      ),
                    ),
                    McAction(
                      label: 'Stop queue',
                      onPressed: queue.active ? queue.stop : null,
                    ),
                  ],
                ),
              ),
              if (queue.problem != null)
                McStatus(title: queue.problem!, tone: McStatusTone.error),
              Expanded(child: view),
            ],
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
                child: ArtifactCollection(
                  controller: controller,
                  narrow: narrow,
                  hasNexus: widget.nexus != null,
                  focus: focus,
                  addFocus: addFocus,
                  scroll: scroll,
                  onInstallAll: widget.installations == null
                      ? null
                      : () {
                          pane.currentState?.closeEndDrawer();
                          suggestedTarget = null;
                          suggestedVersion = null;
                          queue.start(controller.checkedArtifacts);
                        },
                  onAdd: () => unawaited(fileForm()),
                  onDownload: () => unawaited(download()),
                  onNexus: () => setState(() => nexus = true),
                  onSelect: () {
                    controller.observe();
                    setState(() => inspected = true);
                    if (narrow) pane.currentState?.openEndDrawer();
                  },
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
