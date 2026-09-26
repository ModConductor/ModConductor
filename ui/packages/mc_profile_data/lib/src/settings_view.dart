import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'controller.dart';
import 'save_files.dart';

class ProfileSettingsView extends StatelessWidget {
  const ProfileSettingsView({
    super.key,
    required this.controller,
    required this.client,
    required this.workspace,
    required this.profile,
    required this.available,
    required this.onClose,
    required this.onEdit,
    required this.onOpenFiles,
    required this.onRestore,
    required this.onResumeProfileChange,
    required this.activeName,
    required this.filesButtonFocus,
    this.pluginHeadersId,
  });

  final ProfileDataController controller;
  final ProfileDataClient? client;
  final WorkspaceInfo workspace;
  final ProfileInfo profile;
  final bool available;
  final VoidCallback onClose;
  final VoidCallback onEdit;
  final VoidCallback onOpenFiles;
  final VoidCallback onRestore;
  final Future<void> Function(String) onResumeProfileChange;
  final String Function(String) activeName;
  final FocusNode filesButtonFocus;
  final String? pluginHeadersId;

  Widget item(BuildContext context, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        SelectableText(value),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final problem = controller.problem ?? state?.problem;
    final pending = state?.pendingActionId;
    final active = state?.inUseProfileId;
    return McInspector(
      title: profile.name,
      onClose: onClose,
      footer: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          McAction(
            label: 'Edit settings',
            icon: Icons.tune,
            onPressed: controller.canEdit ? onEdit : null,
          ),
        ],
      ),
      children: [
        Text(
          'Settings and saves',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 16),
        if (controller.busy) ...[
          McStatus(
            title: '${controller.activity}…',
            detail: controller.progress == null
                ? null
                : '${controller.progress!.files} files · ${controller.progress!.bytes} bytes copied',
          ),
          const SizedBox(height: 12),
          const LinearProgressIndicator(),
          const SizedBox(height: 12),
          if (controller.activity != 'Reading settings and saves')
            McAction(
              label: 'Cancel',
              onPressed: () => unawaited(controller.cancel()),
            ),
        ] else if (problem != null)
          McStatus(title: problem, tone: McStatusTone.error)
        else if (state != null)
          McStatus(
            title: active == null
                ? 'Global settings and saves in use'
                : active == profile.id
                ? 'In use'
                : 'In use: ${activeName(active)}',
            detail: active != profile.id
                ? 'Play applies the selected profile.'
                : null,
          ),
        if (controller.result case final result? when !result.complete)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              '${result.completedFiles} file changes completed. The action did not finish.',
            ),
          ),
        if (!controller.busy &&
            (controller.needsRead || problem != null || state == null))
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: McAction(
              label: 'Read again',
              icon: Icons.refresh,
              onPressed: client == null
                  ? null
                  : () => unawaited(controller.read()),
            ),
          ),
        if (!controller.busy && pending != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                McAction(
                  label: state?.pendingConfiguration == null
                      ? 'Continue'
                      : 'Continue saving',
                  onPressed: !available
                      ? null
                      : () => unawaited(
                          state!.pendingProfileChange
                              ? onResumeProfileChange(pending)
                                    .then((_) => controller.read())
                              : controller.resume(),
                        ),
                ),
                if (state?.pendingConfiguration != null)
                  McAction(
                    label: 'Restore original',
                    onPressed: available
                        ? () => unawaited(controller.restoreConfiguration())
                        : null,
                  ),
              ],
            ),
          ),
        const SizedBox(height: 24),
        if (state != null) ...[
          item(
            context,
            'Local game settings',
            '${state.options.settings ? 'On' : 'Off'} · ${state.settingsFiles} ${state.settingsFiles == 1 ? 'file' : 'files'}',
          ),
          item(
            context,
            'Local saves',
            '${state.options.saves ? 'On' : 'Off'} · ${state.saveFiles} ${state.saveFiles == 1 ? 'file' : 'files'}',
          ),
          if (state.savesInitialized)
            McAction(
              label: 'View save files',
              icon: Icons.folder_outlined,
              onPressed: client == null
                  ? null
                  : () => showDialog<void>(
                      context: context,
                      builder: (_) => ProfileSaveFiles(
                        client: client!,
                        workspace: workspace.id,
                        profile: profile,
                        expected: state.reference,
                        headersId: pluginHeadersId,
                        onChanged: controller.invalidate,
                      ),
                    ),
            ),
          if (state.settingsInitialized) ...[
            const SizedBox(height: 12),
            McAction(
              label: 'Edit profile files',
              icon: Icons.description_outlined,
              focusNode: filesButtonFocus,
              onPressed: client == null || !controller.canEdit
                  ? null
                  : onOpenFiles,
            ),
          ],
          const SizedBox(height: 16),
          McAction(
            label: 'Restore',
            icon: Icons.restore,
            onPressed: controller.canEdit && active != null ? onRestore : null,
          ),
          const SizedBox(height: 16),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('Details'),
            children: [
              if (state.settingsPath.isNotEmpty)
                item(context, 'Private settings', state.settingsPath),
              if (state.savesPath.isNotEmpty)
                item(context, 'Private saves', state.savesPath),
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Applied options also affect direct launches from Steam. Closing Mod Conductor does not restore them. Steam Cloud is not isolated.',
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
