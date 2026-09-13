import 'package:mc_artifacts/mc_artifacts.dart';
import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_workspaces/mc_workspaces.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'requests.dart';
import 'request_dialog.dart';

class NexusRequestDialog extends StatelessWidget {
  const NexusRequestDialog({
    super.key,
    required this.requests,
    required this.workspaces,
    this.onPreferences,
  });
  final DesktopRequests requests;
  final WorkspaceController workspaces;
  final VoidCallback? onPreferences;
  @override
  Widget build(BuildContext context) {
    final link = requests.nexusLink;
    final file = link?.file;
    final selected = workspaces.recent
        .where((w) => w.id == requests.workspaceId)
        .firstOrNull;
    final existing = link?.artifact;
    final ready =
        existing?.state == ArtifactState.ready ||
        existing?.state == ArtifactState.installed;
    return McDialog(
      title: 'Open requests',
      children: [
        if (requests.count > 1) ...[
          Text(
            '1 of ${requests.count}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
        ],
        Text(
          'Nexus Mods download',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (file != null) ...[const SizedBox(height: 8), Text(file.name)],
        if (link != null && link.game.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            '${link.game}${file?.bytes == null ? '' : ' · ${archiveSize(file!.bytes)}'}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          McChoice<String?>(
            label: 'Workspace',
            value: selected?.id,
            enabled: !requests.startingNexus,
            choices: [null, ...workspaces.recent.map((w) => w.id)],
            describe: (id) => id == null
                ? 'Choose a workspace'
                : workspaces.recent.firstWhere((w) => w.id == id).name,
            onChanged: requests.selectWorkspace,
          ),
          if (selected != null) ...[
            const SizedBox(height: 8),
            SelectableText(
              selected.path,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (workspaces.nextWorkspace != null)
            McAction(
              label: 'Load more workspaces',
              onPressed: () => workspaces.loadRecent(more: true),
            ),
        ],
        if (requests.resolving || requests.startingNexus) ...[
          const SizedBox(height: 16),
          McStatus(
            title: requests.startingNexus
                ? 'Starting download'
                : 'Checking request',
          ),
        ],
        if (requests.problem case final problem?) ...[
          const SizedBox(height: 16),
          McStatus(
            title: problem,
            detail: link?.detail.isNotEmpty == true ? link!.detail : null,
            tone: McStatusTone.error,
          ),
        ] else if (existing != null) ...[
          const SizedBox(height: 16),
          McStatus(
            title: ready
                ? 'This file is already in Archives'
                : existing.download?.active == true
                ? 'This file is already downloading'
                : 'A partial download already exists',
          ),
        ],
      ],
      actions: [
        McAction(label: 'Close', onPressed: () => Navigator.pop(context)),
        McAction(
          label: 'Dismiss',
          onPressed: requests.startingNexus
              ? null
              : () async {
                  await requests.dismiss(requests.id!);
                  if (context.mounted) Navigator.pop(context);
                },
        ),
        if (requests.nexusFailed)
          McAction(label: 'Retry connection', onPressed: requests.connectNexus),
        if (link?.signInRequired == true)
          McAction(
            label: 'Open Preferences',
            emphasis: McActionEmphasis.primary,
            onPressed: () {
              Navigator.pop(context);
              onPreferences?.call();
            },
          )
        else if (requests.problem == null && !requests.nexusPending)
          McAction(
            label: existing != null
                ? (ready ? 'Open Archives' : 'Open Downloads')
                : 'Download',
            icon: existing == null ? Icons.download : null,
            emphasis: McActionEmphasis.primary,
            onPressed:
                selected == null ||
                    file == null ||
                    requests.resolving ||
                    requests.startingNexus
                ? null
                : () async {
                    final id = requests.id!;
                    final artifact = await requests.startNexus(selected.id);
                    if (context.mounted &&
                        artifact != null &&
                        requests.id == id)
                      Navigator.pop(
                        context,
                        DesktopRequestChoice.nexus(id, artifact, selected),
                      );
                  },
          ),
      ],
    );
  }
}
