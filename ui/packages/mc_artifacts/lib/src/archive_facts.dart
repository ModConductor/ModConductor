import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';

String archiveState(ArtifactState state) => switch (state) {
  ArtifactState.ready => 'Available',
  ArtifactState.detached => 'File not found',
  ArtifactState.incomplete => 'Incomplete',
  ArtifactState.installed => 'Installed',
};

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
