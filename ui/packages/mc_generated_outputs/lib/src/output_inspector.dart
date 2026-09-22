import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'output_controller.dart';
import 'output_actions.dart';
import 'deployment_dialog.dart';

class OutputInspector extends StatelessWidget {
  const OutputInspector({
    super.key,
    required this.controller,
    required this.onClose,
    this.profileId,
    this.organization,
    this.selectedMod,
  });
  final OutputController controller;
  final VoidCallback onClose;
  final String? profileId;
  final ModOrganizationClient? organization;
  final ModEntry? selectedMod;
  @override
  Widget build(BuildContext context) {
    final file = controller.inspected;
    if (file == null) return const SizedBox.shrink();
    final location = controller.scope?.locations
        .where((location) => location.id == file.locationId)
        .firstOrNull;
    final writable = location?.kind == OutputLocationKind.writableFile;
    final enabled = controller.canAct && file.status != OutputFileStatus.absent;
    void action(String value) => unawaited(
      reviewOutputAction(
        context,
        controller: controller,
        files: [file],
        action: value,
        profileId: profileId,
        organization: organization,
        selectedMod: selectedMod,
      ),
    );
    return McInspector(
      title: 'File details',
      onClose: onClose,
      footer: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          McAction(
            label: 'Keep',
            onPressed: enabled ? () => action('keep') : null,
          ),
          if (!writable)
            McAction(
              label: 'Create mod…',
              onPressed: enabled && organization != null
                  ? () => action('create')
                  : null,
            ),
          McAction(
            label: writable ? 'Save copy to mod…' : 'Move to mod…',
            emphasis: McActionEmphasis.primary,
            onPressed: enabled && organization != null
                ? () => action(writable ? 'copy' : 'move')
                : null,
          ),
          McAction(
            label: 'Discard…',
            onPressed: enabled ? () => action('discard') : null,
          ),
        ],
      ),
      children: [
        Text(file.path.last, style: Theme.of(context).textTheme.headlineSmall),
        if (file.path.length > 1) ...[
          const SizedBox(height: 8),
          Text(file.path.join('/')),
        ],
        const SizedBox(height: 16),
        McStatus(
          title: controller.needsRead
              ? 'Previous output observation'
              : outputStatus(file.status),
        ),
        const SizedBox(height: 16),
        Text(
          location?.name ?? 'Output location',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (location?.target != null) Text(location!.target!.join('/')),
        const SizedBox(height: 8),
        const Text('Review actions affect all profiles.'),
        if (writable && file.status == OutputFileStatus.absent) ...[
          const SizedBox(height: 12),
          const Text(
            'This working file stays absent until you write it again or stop using this location.',
          ),
        ],
        const SizedBox(height: 16),
        Text(
          file.status == OutputFileStatus.absent
              ? 'No working file'
              : outputSize(file.length),
        ),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text('File information'),
          children: [
            McFactGroup(
              title: 'Observation',
              rows: [
                McFact('Checked', deploymentDate(file.observedAt)),
                if (file.sha256.isNotEmpty) McFact('SHA-256', file.sha256),
                if (location != null)
                  McFact('Working location', location.physicalPath, path: true),
                if (file.deploymentId case final deployment?)
                  McFact('Deployment at check', deployment),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
