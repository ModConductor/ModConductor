import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'deployment_controller.dart';

String deploymentDate(DateTime value) {
  final local = value.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

class DeploymentAction extends StatelessWidget {
  const DeploymentAction({super.key, required this.controller});
  final DeploymentController controller;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => McAction(
      label: controller.busy
          ? 'Deployment in progress…'
          : controller.state == null || controller.needsRead
          ? 'Deployment…'
          : '${controller.activeName}…',
      icon: Icons.swap_horiz,
      onPressed: controller.connected
          ? () => showDialog<void>(
              context: context,
              builder: (_) => DeploymentDialog(controller: controller),
            )
          : null,
    ),
  );
}

class DeploymentDialog extends StatefulWidget {
  const DeploymentDialog({super.key, required this.controller});
  final DeploymentController controller;
  @override
  State<DeploymentDialog> createState() => _DeploymentDialogState();
}

class _DeploymentDialogState extends State<DeploymentDialog> {
  DeploymentController get controller => widget.controller;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(controller.read());
    });
  }

  Widget datum(String label, String value, {String? detail}) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
        if (detail != null)
          Text(detail, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
  Future<void> _deactivate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => McFormDialog(
        title: 'Deactivate game files?',
        action: 'Deactivate',
        onSubmit: () => Navigator.pop(context, true),
        children: const [
          Text(
            'Game-folder files will be restored. Shared output files stay unchanged.',
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await controller.prepare(retained: true);
    if (controller.canDeploy && controller.prepared?.profile == null) {
      await controller.activate();
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final prepared = controller.prepared,
          progress = controller.progress,
          receipt = controller.receipt;
      final inactive =
          controller.state?.active == null ||
          (controller.state!.active!.known &&
              controller.state!.active!.profile == null);
      return PopScope(
        canPop: !controller.busy || controller.preparing,
        child: McDialog(
          title: 'Deployment',
          actions: [
            McAction(
              label: 'Close',
              onPressed: controller.busy && !controller.preparing
                  ? null
                  : () => Navigator.pop(context),
            ),
            if (controller.preparing)
              McAction(
                label: 'Cancel preparation',
                onPressed: () => unawaited(controller.cancelPreparation()),
              )
            else
              McAction(
                label: controller.needsRead || controller.state == null
                    ? 'Read current deployment'
                    : controller.canDeploy
                    ? 'Deploy'
                    : prepared == null
                    ? 'Prepare deployment'
                    : 'Prepare again',
                emphasis: McActionEmphasis.primary,
                onPressed: controller.busy || controller.reading
                    ? null
                    : controller.needsRead || controller.state == null
                    ? () => unawaited(controller.read())
                    : controller.canDeploy
                    ? () => unawaited(controller.activate())
                    : controller.canPrepare
                    ? () => unawaited(controller.prepare())
                    : null,
              ),
          ],
          children: [
            datum(
              'Configured profile',
              controller.configuredName ?? 'No profile selected',
            ),
            datum(
              'Prepared plan',
              controller.preparing
                  ? 'Checking game files…'
                  : prepared == null
                  ? 'Not prepared'
                  : prepared.profile?.name ?? 'Not deployed',
              detail: prepared == null
                  ? null
                  : '${prepared.profile?.enabledMods ?? 0} ${prepared.profile?.enabledMods == 1 ? 'mod' : 'mods'} · ${prepared.writableFiles} writable game ${prepared.writableFiles == 1 ? 'file' : 'files'}',
            ),
            if (controller.reading)
              const McActionFeedback(
                kind: McActionFeedbackKind.pending,
                message: 'Reading current deployment',
              ),
            if (controller.busy)
              McActionFeedback(
                kind: McActionFeedbackKind.pending,
                message: controller.preparing
                    ? 'Preparing deployment'
                    : 'Applying deployment',
                detail: progress == null
                    ? null
                    : '${progress.completed} of ${progress.total} ${controller.preparing ? 'files' : 'paths'}${progress.bytes == 0 ? '' : ' · ${progress.bytes} bytes'}',
              ),
            datum(
              'Game files',
              controller.state == null
                  ? 'Not checked'
                  : controller.needsRead
                  ? 'Read the current deployment'
                  : controller.state!.pendingReceipt != null
                  ? 'Partly changed'
                  : controller.activeName,
            ),
            if (controller.problem != null) ...[
              McActionFeedback(
                kind: McActionFeedbackKind.failure,
                message: controller.problem!,
              ),
              const SizedBox(height: 12),
            ],
            if (receipt != null &&
                controller.state?.pendingReceipt != null) ...[
              McActionFeedback(
                kind: McActionFeedbackKind.failure,
                message: receipt.detail.isEmpty
                    ? 'Deployment is incomplete'
                    : receipt.detail,
                detail:
                    '${receipt.completed} of ${receipt.total} paths applied',
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  McAction(
                    label: 'Continue',
                    onPressed: controller.busy || controller.needsRead
                        ? null
                        : () => unawaited(controller.recover(restore: false)),
                  ),
                  McAction(
                    label: 'Undo incomplete deployment',
                    onPressed: controller.busy || controller.needsRead
                        ? null
                        : () => unawaited(controller.recover(restore: true)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            if (prepared != null && !controller.stale) ...[
              const Divider(),
              Text(
                '${prepared.changedPaths} ${prepared.changedPaths == 1 ? 'path changes' : 'paths change'} · ${prepared.preservedOriginals} original ${prepared.preservedOriginals == 1 ? 'file' : 'files'} preserved',
              ),
              const SizedBox(height: 8),
              const Text('Shared outputs stay unchanged.'),
              const SizedBox(height: 16),
            ],
            if (prepared != null && controller.stale)
              const McActionFeedback(
                kind: McActionFeedbackKind.refusal,
                message: 'The prepared plan is out of date.',
              ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                McAction(
                  label: 'Saved deployments…',
                  onPressed: controller.busy
                      ? null
                      : () => showDialog<void>(
                          context: context,
                          builder: (_) =>
                              SavedDeploymentsDialog(controller: controller),
                        ),
                ),
                McAction(
                  label: 'Deactivate…',
                  onPressed: inactive || !controller.canPrepare
                      ? null
                      : _deactivate,
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

class SavedDeploymentsDialog extends StatefulWidget {
  const SavedDeploymentsDialog({super.key, required this.controller});
  final DeploymentController controller;
  @override
  State<SavedDeploymentsDialog> createState() => _SavedDeploymentsDialogState();
}

class _SavedDeploymentsDialogState extends State<SavedDeploymentsDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(widget.controller.loadSaved(reset: true));
    });
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final controller = widget.controller;
      return McDialog(
        title: 'Saved deployments',
        children: [
          for (final value in controller.saved) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                value.active ? Icons.check_circle_outline : Icons.history,
              ),
              title: Text(
                value.profile?.name ??
                    (value.known
                        ? 'Not deployed'
                        : 'Profile information unavailable'),
              ),
              subtitle: Text(
                [
                  if (value.preparedAt != null)
                    deploymentDate(value.preparedAt!),
                  if (value.active) 'Active',
                  if (value.profile != null)
                    '${value.profile!.enabledMods} ${value.profile!.enabledMods == 1 ? 'mod' : 'mods'}',
                  if (!value.canRestore)
                    value.unavailable ??
                        'Saved order and file visibility are unavailable',
                ].join(' · '),
              ),
              trailing: McAction(
                label: 'Prepare',
                onPressed: !value.canRestore || !controller.canPrepare
                    ? null
                    : () {
                        Navigator.pop(context);
                        unawaited(
                          controller.prepare(
                            retained: true,
                            generationId: value.id,
                          ),
                        );
                      },
              ),
            ),
            const Divider(),
          ],
          if (controller.saved.isEmpty && !controller.loadingSaved)
            const Text('No saved deployments.'),
          if (controller.loadingSaved) const LinearProgressIndicator(),
          if (controller.problem != null)
            McStatus(title: controller.problem!, tone: McStatusTone.error),
          if (controller.canLoadSaved)
            McAction(
              label: controller.problem == null ? 'Load more' : 'Retry',
              onPressed: controller.loadingSaved
                  ? null
                  : () => unawaited(controller.loadSaved()),
            ),
          const SizedBox(height: 16),
          const Text(
            'A saved deployment restores its mod versions and FNIS files. It does not restore shared output files.',
          ),
        ],
      );
    },
  );
}
