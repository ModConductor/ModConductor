import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'archive_facts.dart';
import 'installation_controller.dart';
import 'installation_tree.dart';

Widget installationInspector(
  BuildContext c,
  InstallationRow? row,
  InstallationController controller,
  Future<void> Function(InstallationRow) destination,
  VoidCallback close,
) {
  return McInspector(
    title: row?.name ?? 'File',
    onClose: close,
    children: [
      if (row != null) ...[
        archiveFact(c, 'Archive path', row.path),
        archiveFact(
          c,
          'Destination',
          row.included == false
              ? 'Excluded'
              : row.destination == null
              ? 'Multiple destinations'
              : row.destination!.isEmpty
              ? 'Mod root'
              : row.destination!.join('/'),
        ),
        if (row.directory) ...[
          McAction(
            label: 'Use as root',
            icon: Icons.folder_open,
            onPressed: controller.canEdit
                ? () => unawaited(
                    controller.change(InstallationRootChange(row.components)),
                  )
                : null,
          ),
          const SizedBox(height: 16),
        ],
        McAction(
          label: 'Change destination',
          icon: Icons.drive_file_move_outline,
          onPressed: controller.canEdit && row.included != false
              ? () => unawaited(destination(row))
              : null,
        ),
        const SizedBox(height: 16),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Include in mod'),
          tristate: true,
          value: row.included,
          onChanged: controller.canEdit
              ? (_) => unawaited(
                  controller.change(
                    InstallationInclusionChange(
                      row.components,
                      row.included != true,
                    ),
                  ),
                )
              : null,
        ),
      ],
    ],
  );
}

Widget installationResult(
  BuildContext c,
  InstallationStatus status,
  InstallationController controller,
  VoidCallback onOpenMods,
) {
  final installing = status.phase == InstallationPhase.running,
      success = status.phase == InstallationPhase.complete;
  return Align(
    alignment: Alignment.topLeft,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 660),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 20, 4, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              McStatus(
                title: installing
                    ? '${status.isUpdate ? 'Updating' : 'Installing'} ${status.name}'
                    : success
                    ? '${status.name} ${status.isUpdate ? 'updated' : 'installed'}'
                    : status.isUpdate
                    ? 'Update stopped'
                    : 'Installation stopped',
                detail: status.problem,
              ),
              const SizedBox(height: 24),
              if (installing) ...[
                LinearProgressIndicator(
                  value: status.totalBytes == 0
                      ? null
                      : status.bytes / status.totalBytes,
                ),
                const SizedBox(height: 16),
                Text(
                  '${status.files} of ${status.totalFiles} files · ${archiveSize(status.bytes)} of ${archiveSize(status.totalBytes)}',
                ),
                const SizedBox(height: 24),
                McAction(
                  label: status.isUpdate
                      ? 'Cancel update'
                      : 'Cancel installation',
                  icon: Icons.close,
                  onPressed: controller.busy
                      ? null
                      : () => unawaited(controller.control(discard: false)),
                ),
              ] else if (success) ...[
                if (status.version.isNotEmpty)
                  archiveFact(c, 'Version', status.version),
                archiveFact(c, 'Archive', status.archiveName),
                McAction(
                  label: 'Open Mods',
                  icon: Icons.layers_outlined,
                  emphasis: McActionEmphasis.primary,
                  onPressed: onOpenMods,
                ),
              ] else ...[
                archiveFact(
                  c,
                  'Temporary files',
                  '${status.files} ${status.files == 1 ? 'file' : 'files'} · ${archiveSize(status.temporaryBytes)}',
                ),
                McAction(
                  label: status.files == 0
                      ? 'Dismiss'
                      : 'Delete temporary files',
                  icon: Icons.delete_outline,
                  onPressed: controller.busy
                      ? null
                      : () => unawaited(controller.control(discard: true)),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
