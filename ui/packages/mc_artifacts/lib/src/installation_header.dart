import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'installation_controller.dart';
import 'installation_file_collection.dart';

class InstallationHeader extends StatelessWidget {
  const InstallationHeader({
    super.key,
    required this.artifactName,
    required this.backLabel,
    required this.draft,
    required this.status,
    required this.controller,
    required this.manual,
    required this.narrow,
    required this.canUpdate,
    required this.reviewUpdate,
    required this.onBack,
    required this.onLayout,
    required this.onMetadata,
    required this.onUpdate,
  });

  final String artifactName, backLabel;
  final InstallationDraft? draft;
  final InstallationStatus? status;
  final InstallationController controller;
  final bool manual, narrow, canUpdate, reviewUpdate;
  final VoidCallback onBack;
  final ValueChanged<bool> onLayout;
  final VoidCallback onMetadata, onUpdate;

  String get title {
    if (status != null) return status!.archiveName;
    if (manual) return 'Archive layout';
    return draft == null ? artifactName : 'New mod: ${draft!.name}';
  }

  Widget rootChoice(InstallationDraft current) => InstallationRootChoice(
    draft: current,
    narrow: false,
    enabled: controller.canEdit,
    onSelected: (path) =>
        unawaited(controller.change(InstallationRootChange(path))),
  );

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          McIconAction(
            label: status == null && manual && draft?.canInstall == true
                ? 'Back to review'
                : backLabel,
            icon: const Icon(Icons.arrow_back),
            onPressed: status == null && manual && draft?.canInstall == true
                ? () => onLayout(false)
                : onBack,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (draft != null && status == null) ...[
            if (!manual) ...[
              if (canUpdate)
                McIconAction(
                  label: reviewUpdate
                      ? 'Review update'
                      : 'Update installed mod',
                  icon: const Icon(Icons.system_update_alt),
                  onPressed: controller.canEdit && draft!.canInstall
                      ? onUpdate
                      : null,
                ),
              McIconAction(
                label: 'Edit mod details',
                icon: const Icon(Icons.edit_outlined),
                onPressed: controller.canEdit ? onMetadata : null,
              ),
              const SizedBox(width: 8),
            ],
            McAction(
              label: manual ? 'Review' : 'Install',
              icon: manual ? Icons.check : Icons.install_desktop,
              emphasis: McActionEmphasis.primary,
              onPressed: controller.busy || !draft!.canInstall
                  ? null
                  : manual
                  ? () => onLayout(false)
                  : () => unawaited(controller.install()),
            ),
          ],
        ],
      ),
      const SizedBox(height: 8),
      if (draft != null && status == null && !narrow) ...[
        Row(
          children: [
            Expanded(
              child: Text(
                'Archive folder: ${draft!.root.isEmpty ? 'Archive root' : draft!.root.join(' / ')}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            if (manual)
              rootChoice(draft!)
            else
              McAction(
                label: 'Change layout',
                icon: Icons.account_tree_outlined,
                onPressed: controller.canEdit ? () => onLayout(true) : null,
              ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    ],
  );
}
