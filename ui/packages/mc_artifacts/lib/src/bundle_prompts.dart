import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'archive_facts.dart';
import 'bundle_collection.dart';

Future<void> showBundleInformation(
  BuildContext context,
  String title,
  String message,
) => showDialog<void>(
  context: context,
  builder: (dialog) => McDialog(
    title: title,
    actions: [McAction(label: 'Close', onPressed: () => Navigator.pop(dialog))],
    children: [Text(message)],
  ),
);

Future<String?> askBundleName(BuildContext context, BundleItem item) async {
  final field = TextEditingController(text: item.name);
  final name = await showDialog<String>(
    context: context,
    builder: (dialog) => McFormDialog(
      title: 'Mod name',
      action: 'Save',
      onSubmit: () => Navigator.pop(dialog, field.text),
      children: [
        Text(bundlePath(item)),
        const SizedBox(height: 16),
        McNameField(
          controller: field,
          onSubmit: () => Navigator.pop(dialog, field.text),
        ),
        const SizedBox(height: 16),
        const Text('Mod starts disabled'),
      ],
    ),
  );
  field.dispose();
  return name;
}

Future<bool> confirmBundleRetry(BuildContext context, BundleItem item) async =>
    await showDialog<bool>(
      context: context,
      builder: (dialog) => McFormDialog(
        title: 'Delete incomplete files?',
        action: 'Delete files and review',
        onSubmit: () => Navigator.pop(dialog, true),
        children: [
          Text(item.name),
          const SizedBox(height: 16),
          const Text('Installed mods stay installed.'),
        ],
      ),
    ) ==
    true;

Future<bool> confirmBundleCleanup(
  BuildContext context,
  BundlePlan bundle,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (dialog) => McFormDialog(
        title: 'Delete temporary files?',
        action: 'Delete temporary files',
        onSubmit: () => Navigator.pop(dialog, true),
        children: [
          Text(bundle.archiveName),
          const SizedBox(height: 16),
          Text(
            '${archiveSize(bundle.temporaryBytes)} of temporary archive copies',
          ),
          const SizedBox(height: 16),
          const Text(
            'Installed mods and the original archive stay unchanged. This checklist will close.',
          ),
        ],
      ),
    ) ==
    true;
