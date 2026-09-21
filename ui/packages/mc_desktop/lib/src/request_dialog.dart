import 'nxm_request_dialog.dart';

import 'package:flutter/material.dart';
import 'package:mc_artifacts/mc_artifacts.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_workspaces/mc_workspaces.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'requests.dart';

class DesktopRequestChoice {
  const DesktopRequestChoice(this.id, this.intent, this.workspace)
    : artifact = null;
  DesktopRequestChoice.nexus(this.id, Artifact value, WorkspaceInfo target)
    : artifact = value,
      workspace = target,
      intent = DesktopIntent(
        DesktopIntentKind.archives,
        target.path,
        target.id,
        0,
      );
  final Artifact? artifact;
  final int id;
  final DesktopIntent intent;
  final WorkspaceInfo? workspace;
}

class OpenRequestsDialog extends StatelessWidget {
  const OpenRequestsDialog({
    super.key,
    required this.requests,
    required this.workspaces,
    this.onRetry,
    this.onPreferences,
  });
  final DesktopRequests requests;
  final WorkspaceController workspaces;
  final VoidCallback? onRetry;
  final VoidCallback? onPreferences;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([requests, workspaces]),
    builder: (context, _) {
      if (requests.isNexus)
        return NexusRequestDialog(
          requests: requests,
          workspaces: workspaces,
          onPreferences: onPreferences,
        );
      final intent = requests.intent;
      final archive = intent?.kind == DesktopIntentKind.archive;
      final selected = workspaces.recent
          .where(
            (w) =>
                w.id ==
                (requests.hasWorkspaceSelection
                    ? requests.workspaceId
                    : workspaces.workspace?.id),
          )
          .firstOrNull;
      return McDialog(
        title: 'Open requests',
        children: [
          if (requests.count == 0)
            const Text('No pending requests.')
          else ...[
            if (requests.count > 1) ...[
              Text(
                '1 of ${requests.count}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
            ],
            if (intent != null) ...[
              Text(
                archive ? 'Archive' : 'Workspace',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              SelectableText(intent.path),
              const SizedBox(height: 16),
              if (archive) ...[
                McChoice<String?>(
                  label: 'Workspace',
                  value: selected?.id,
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
            ],
            if (requests.resolving)
              const McActionFeedback(
                kind: McActionFeedbackKind.pending,
                message: 'Checking request',
              ),
            if (requests.problem case final problem?)
              McActionFeedback(
                kind: McActionFeedbackKind.failure,
                message: problem,
              ),
            if (!requests.connected && requests.problem == null)
              const McActionFeedback(
                kind: McActionFeedbackKind.refusal,
                message: 'Not connected',
                detail: 'Reconnect to open this request.',
              ),
          ],
        ],
        actions: [
          McAction(label: 'Close', onPressed: () => Navigator.pop(context)),
          if (requests.id case final id?)
            McAction(
              label: 'Dismiss',
              onPressed: () async {
                await requests.dismiss(id);
                if (context.mounted) Navigator.pop(context);
              },
            ),
          if (requests.count > 0 &&
              !requests.connected &&
              requests.problem == null)
            McAction(
              label: 'Retry connection',
              onPressed: onRetry,
              emphasis: McActionEmphasis.primary,
            ),
          if (intent != null)
            McAction(
              label: archive ? 'Review archive' : 'Open workspace',
              emphasis: McActionEmphasis.primary,
              onPressed: archive && selected == null
                  ? null
                  : () => Navigator.pop(
                      context,
                      DesktopRequestChoice(requests.id!, intent, selected),
                    ),
            ),
        ],
      );
    },
  );
}

Future<void> openDesktopRequest(
  BuildContext context,
  DesktopRequestChoice choice, {
  required DesktopRequests requests,
  required WorkspaceController workspaces,
  required ArtifactController artifacts,
  required ArchiveChooser chooseFile,
  required VoidCallback onWorkspaceOpened,
}) async {
  final archive = choice.intent.kind == DesktopIntentKind.archive;
  final target = archive ? choice.workspace!.path : choice.intent.path;
  await workspaces.open(target);
  if (!context.mounted) return;
  if (workspaces.workspace?.path != target || workspaces.problem != null) {
    requests.fail(workspaces.problem ?? 'The workspace could not be opened.');
    return;
  }
  onWorkspaceOpened();
  if (archive || choice.intent.kind == DesktopIntentKind.archives)
    workspaces.showArchives();
  if (archive) {
    if (artifacts.needsRead) await artifacts.load();
    if (!context.mounted) return;
    final result =
        await showDialog<({ArchiveFile file, ArtifactStorage storage})>(
          context: context,
          builder: (_) => ArchiveFileForm(
            chooseFile: chooseFile,
            workspacePath: target,
            initialFile: ArchiveFile(choice.intent.path, choice.intent.length),
          ),
        );
    if (result == null || !context.mounted) return;
    final id = requests.operationId(
      choice.workspace!.id,
      result.file.path,
      result.storage,
    );
    final changed = await artifacts.change(
      'Adding archive',
      (client, workspace) =>
          client.add(workspace, id, result.file.path, result.storage),
    );
    if (!context.mounted) return;
    if (!changed) {
      requests.fail(
        artifacts.problem ??
            'An archive operation is still in progress. Try again.',
      );
      return;
    }
  }
  if (choice.artifact case final artifact?)
    artifacts.acceptDownload(artifact, select: true);
  await requests.dismiss(choice.id);
}
