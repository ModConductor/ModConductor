import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_collections/mc_ui_collections.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'controller.dart';
import 'forms.dart';
export 'forms.dart' show ArchiveFile, ArchiveChooser;

String archiveState(ArtifactState state) => switch (state) {
  ArtifactState.ready => 'Available',
  ArtifactState.detached => 'File not found',
  ArtifactState.incomplete => 'Incomplete',
  ArtifactState.installed => 'Installed',
};

class ArtifactBrowser extends StatefulWidget {
  const ArtifactBrowser({
    super.key,
    required this.controller,
    required this.chooseFile,
    required this.workspacePath,
  });
  final ArtifactController controller;
  final ArchiveChooser chooseFile;
  final String workspacePath;
  @override
  State<ArtifactBrowser> createState() => _ArtifactBrowserState();
}

class _ArtifactBrowserState extends State<ArtifactBrowser> {
  final pane = GlobalKey<ScaffoldState>();
  final focus = FocusNode(debugLabel: 'Archives');
  final addFocus = FocusNode(debugLabel: 'Add archive');
  final scroll = ScrollController();
  bool inspected = false;
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
            bytes ? 'The original file and installed mods stay unchanged.' : 'Removes this archive from the list. The original file stays unchanged.',
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

  Widget fact(BuildContext c, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(c).textTheme.bodySmall),
        const SizedBox(height: 4),
        SelectableText(value),
      ],
    ),
  );
  Widget inspector(BuildContext c, VoidCallback close) {
    final artifact = controller.selected;
    return McInspector(
      title: artifact?.originalName ?? 'Archive',
      onClose: close,
      footer: artifact == null
          ? null
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (artifact.canLocate)
                  McAction(
                    label: 'Locate archive',
                    icon: Icons.folder_open,
                    onPressed: controller.canEdit
                        ? () => fileForm(artifact)
                        : null,
                  ),
                if (artifact.canRetry)
                  McAction(
                    label: 'Retry',
                    icon: Icons.refresh,
                    onPressed: controller.canEdit
                        ? () => unawaited(
                            controller.change(
                              'Reading archive',
                              (client, _) => client.retry(artifact),
                            ),
                          )
                        : null,
                  ),
                if (artifact.canDeleteCopy)
                  McAction(
                    label: 'Delete copy',
                    icon: Icons.delete_outline,
                    onPressed: controller.canEdit
                        ? () => cleanup(artifact, bytes: true)
                        : null,
                  ),
                if (artifact.canRemove)
                  McAction(
                    label: 'Remove from list',
                    icon: Icons.delete_outline,
                    onPressed: controller.canEdit
                        ? () => cleanup(artifact, bytes: false)
                        : null,
                  ),
              ],
            ),
      children: artifact == null
          ? [const Text('Select an archive.')]
          : [
              McStatus(
                title: archiveState(artifact.state),
                detail: artifact.problem,
              ),
              const SizedBox(height: 24),
              fact(
                c,
                'Storage',
                artifact.storage == ArtifactStorage.copy
                    ? 'Library copy'
                    : 'Current folder',
              ),
              fact(c, 'Size', archiveSize(artifact.length)),
              fact(c, 'Location', artifact.path),
              Text('Installed mods', style: Theme.of(c).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (artifact.links.isEmpty) const Text('No installed-mod links.'),
              for (final link in artifact.links) ...[
                Text(link.modName),
                Text('Linked manually', style: Theme.of(c).textTheme.bodySmall),
                fact(
                  c,
                  'Saved version',
                  '${link.versionLabel}\n${link.versionId}',
                ),
                McAction(
                  label: 'Remove link',
                  icon: Icons.link_off,
                  onPressed: controller.canEdit
                      ? () => unawaited(
                          controller.change(
                            'Removing mod link',
                            (client, _) =>
                                client.link(artifact, link, remove: true),
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 12),
              ],
              McAction(
                label: 'Link installed mod',
                icon: Icons.link,
                onPressed: controller.canEdit ? () => link(artifact) : null,
              ),
              const SizedBox(height: 16),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('Archive details'),
                children: [
                  fact(c, 'Original file', artifact.originalPath),
                  fact(c, 'Archive ID', artifact.id),
                  if (artifact.sha256 != null)
                    fact(c, 'SHA-256', artifact.sha256!),
                ],
              ),
            ],
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => LayoutBuilder(
      builder: (c, constraints) {
        final narrow =
            constraints.maxWidth < 1100 * MediaQuery.textScalerOf(c).scale(1);
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
                      '${controller.model.ids.length} archives${controller.next == null ? '' : ' loaded'}',
                  empty: 'No archives.',
                  loading: controller.busy,
                  problem: controller.problem,
                  filterActions: [
                    if (narrow)
                      McIconAction(
                        label: 'Add archive',
                        icon: const Icon(Icons.add),
                        focusNode: addFocus,
                        onPressed: controller.canEdit ? fileForm : null,
                      ),
                  ],
                  actions: [
                    if (!narrow)
                      McAction(
                        label: 'Add archive',
                        icon: Icons.add,
                        emphasis: McActionEmphasis.primary,
                        focusNode: addFocus,
                        onPressed: controller.canEdit ? fileForm : null,
                      ),
                  ],
                  onRefresh: controller.busy || controller.client == null
                      ? null
                      : controller.load,
                  onLoad: controller.next != null && !controller.busy
                      ? () => controller.load(more: true)
                      : null,
                  onSelect: (_) {
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
                      (a) => Text(archiveState(a.state)),
                      width: narrow ? 110 : 140,
                    ),
                    if (!narrow)
                      McColumn(
                        'Size',
                        (a) => Text(archiveSize(a.length)),
                        width: 95,
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
