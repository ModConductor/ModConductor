import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';

String archiveState(ArtifactState state) => switch (state) {
  ArtifactState.ready => 'Available',
  ArtifactState.detached => 'File not found',
  ArtifactState.incomplete => 'Incomplete',
  ArtifactState.installed => 'Installed',
};

String? archiveRemovalReason(Artifact archive) {
  if (archive.canRemove) return null;
  final installed = archive.links
      .where((link) => link.installed)
      .map((link) => link.modName)
      .toSet();
  if (installed.isNotEmpty) {
    final instruction = installed.length == 1
        ? 'Delete the mod before you remove this archive.'
        : 'Delete these mods before you remove this archive.';
    return 'Used by ${installed.join(', ')}. $instruction';
  }
  final linked = archive.links.map((link) => link.modName).toSet();
  if (linked.isNotEmpty) {
    return 'Linked to ${linked.join(', ')}. Remove the link before removing this archive.';
  }
  if (archive.canDeleteCopy) {
    return 'Delete the library copy before you remove this archive.';
  }
  if (archive.download?.active == true) {
    return 'The download must stop before you remove this archive.';
  }
  return 'An archive operation must finish before you remove this archive.';
}

String archiveSize(int? bytes) => bytes == null
    ? 'Unknown'
    : bytes < 1024
    ? '$bytes B'
    : bytes < 1024 * 1024
    ? '${(bytes / 1024).toStringAsFixed(1)} KB'
    : bytes < 1024 * 1024 * 1024
    ? '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB'
    : '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';

Widget archiveFact(BuildContext c, String label, String value) => Padding(
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
