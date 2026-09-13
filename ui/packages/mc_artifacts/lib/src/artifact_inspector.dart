import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'controller.dart';
import 'archive_facts.dart';
import 'download_view.dart';

class ArtifactInspector extends StatelessWidget {
  const ArtifactInspector({
    super.key,
    required this.controller,
    required this.onClose,
    required this.onRead,
    this.onInstall,
    this.onBundle,
    required this.onLocate,
    required this.onLink,
    required this.onCleanup,
  });
  final ArtifactController controller;
  final VoidCallback onClose;
  final ValueChanged<Artifact> onRead;
  final ValueChanged<Artifact>? onInstall, onBundle;
  final Future<void> Function(Artifact) onLocate, onLink;
  final Future<void> Function(Artifact, bool) onCleanup;
  Widget details(BuildContext c, Artifact artifact) => ExpansionTile(
    tilePadding: EdgeInsets.zero,
    title: const Text('Archive details'),
    children: [
      if (artifact.download != null && artifact.path.isNotEmpty)
        archiveFact(c, 'Location', artifact.path),
      archiveFact(
        c,
        artifact.download == null ? 'Original file' : 'Original source',
        artifact.originalPath,
      ),
      archiveFact(c, 'Archive ID', artifact.id),
      if (artifact.sha256 != null) archiveFact(c, 'SHA-256', artifact.sha256!),
    ],
  );
  @override
  Widget build(BuildContext c) {
    final artifact = controller.selected;
    return McInspector(
      title: artifact?.originalName ?? 'Archive',
      onClose: onClose,
      footer: artifact == null
          ? null
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (onInstall != null &&
                    (artifact.state == ArtifactState.ready ||
                        artifact.state == ArtifactState.installed))
                  McAction(
                    label: 'Install',
                    icon: Icons.install_desktop,
                    emphasis: McActionEmphasis.primary,
                    onPressed: controller.canEdit
                        ? () => onInstall!(artifact)
                        : null,
                  ),
                if (artifact.state == ArtifactState.ready ||
                    artifact.state == ArtifactState.installed)
                  McAction(
                    label: 'Read contents',
                    icon: Icons.folder_open,
                    onPressed: controller.canEdit
                        ? () => onRead(artifact)
                        : null,
                  ),
                if (onBundle != null)
                  McAction(
                    label: 'Open bundle',
                    onPressed: controller.canEdit
                        ? () => onBundle!(artifact)
                        : null,
                  ),
                if (artifact.download != null)
                  DownloadControls(artifact: artifact, controller: controller),
                if (artifact.canLocate)
                  McAction(
                    label: 'Locate archive',
                    icon: Icons.folder_open,
                    onPressed: controller.canEdit
                        ? () => onLocate(artifact)
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
                        ? () => onCleanup(artifact, true)
                        : null,
                  ),
                if (artifact.canRemove)
                  McAction(
                    label: 'Remove from list',
                    icon: Icons.delete_outline,
                    onPressed: controller.canEdit
                        ? () => onCleanup(artifact, false)
                        : null,
                  ),
              ],
            ),
      children: artifact == null
          ? [const Text('Select an archive.')]
          : [
              McStatus(
                title:
                    artifact.download != null &&
                        artifact.download!.phase != DownloadPhase.complete
                    ? downloadLabel(artifact.download!)
                    : archiveState(artifact.state),
                detail: artifact.problem,
              ),
              const SizedBox(height: 24),
              if (artifact.download != null)
                DownloadDetails(download: artifact.download!),
              archiveFact(
                c,
                'Storage',
                artifact.storage == ArtifactStorage.copy
                    ? 'Library copy'
                    : 'Current folder',
              ),
              if (artifact.download != null)
                archiveFact(
                  c,
                  'Checksum',
                  downloadChecksum(artifact.download!),
                ),
              if (artifact.download == null ||
                  artifact.download!.phase == DownloadPhase.complete)
                archiveFact(c, 'Size', archiveSize(artifact.length)),
              if (artifact.path.isNotEmpty && artifact.download == null)
                archiveFact(c, 'Location', artifact.path),
              if (artifact.download != null) details(c, artifact),
              if (artifact.download == null ||
                  artifact.download!.phase == DownloadPhase.complete ||
                  artifact.links.isNotEmpty) ...[
                Text(
                  'Installed mods',
                  style: Theme.of(c).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (artifact.links.isEmpty)
                  const Text('No installed-mod links.'),
                for (final link in artifact.links) ...[
                  Text(link.modName),
                  Text(
                    link.installed
                        ? 'Installed from archive'
                        : 'Linked manually',
                    style: Theme.of(c).textTheme.bodySmall,
                  ),
                  archiveFact(c, 'Saved version', link.versionLabel),
                  if (!link.installed)
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
                  onPressed: controller.canEdit ? () => onLink(artifact) : null,
                ),
                const SizedBox(height: 16),
              ],
              if (artifact.download == null) details(c, artifact),
            ],
    );
  }
}
