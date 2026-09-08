import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'output_controller.dart';
import 'promotion_dialog.dart';

Future<void> reviewOutputAction(
  BuildContext context, {
  required OutputController controller,
  required List<OutputFile> files,
  required String action,
  required String? profileId,
  required ModOrganizationClient? organization,
  ModEntry? selectedMod,
}) async {
  if (files.isEmpty || !controller.canAct) return;
  final selection = List<OutputSelection>.unmodifiable(
    files.map((file) => file.selection),
  );
  if (action == 'keep') {
    await controller.apply(selection, const KeepOutput());
    return;
  }
  if (action == 'discard') {
    final writable = controller.scope!.locations.any(
      (location) =>
          location.kind == OutputLocationKind.writableFile &&
          files.any((file) => file.locationId == location.id),
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => McFormDialog(
        title:
            'Discard ${files.length} ${files.length == 1 ? 'file' : 'files'}?',
        action: 'Discard',
        onSubmit: () => Navigator.pop(context, true),
        children: [
          const Text('This affects all profiles.'),
          if (writable) ...[
            const SizedBox(height: 12),
            const Text(
              'Discarded working files stay absent. They are not seeded again on the next deployment.',
            ),
          ],
        ],
      ),
    );
    if (confirmed == true) {
      await controller.apply(selection, const DiscardOutput());
    }
    return;
  }
  if (profileId == null || organization == null) return;
  await showDialog<void>(
    context: context,
    builder: (_) => OutputPromotionDialog(
      controller: controller,
      files: selection,
      copy: action == 'copy',
      create: action == 'create',
      profileId: profileId,
      organization: organization,
      initialMod: selectedMod,
    ),
  );
}

String outputSize(int value) => value >= 1024 * 1024 * 1024
    ? '${(value / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB'
    : value >= 1024 * 1024
    ? '${(value / (1024 * 1024)).toStringAsFixed(1)} MB'
    : value >= 1024
    ? '${(value / 1024).toStringAsFixed(1)} KB'
    : '$value B';
String outputStatus(OutputFileStatus value) => switch (value) {
  OutputFileStatus.newFile => 'Unreviewed',
  OutputFileStatus.changed => 'Changed',
  OutputFileStatus.kept => 'Kept',
  OutputFileStatus.absent => 'Absent',
};

class OutputResultStatus extends StatelessWidget {
  const OutputResultStatus({super.key, required this.controller});
  final OutputController controller;
  @override
  Widget build(BuildContext context) {
    final result = controller.result;
    if (result == null) return const SizedBox.shrink();
    final changed = result.entries.any(
      (entry) => entry.disposition == OutputDisposition.changed,
    );
    final title = result.published
        ? (!result.complete
              ? 'Version saved; output review is incomplete'
              : changed
              ? 'Version saved; changed files kept'
              : 'Version saved')
        : !result.complete
        ? 'Output review is incomplete'
        : changed
        ? 'Changed files kept'
        : result.entries.any(
            (entry) => entry.disposition == OutputDisposition.discarded,
          )
        ? 'Selected output files discarded'
        : 'Output review saved';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: McStatus(title: title)),
        McIconAction(
          label: 'Dismiss result',
          icon: const Icon(Icons.close),
          onPressed: controller.dismissResult,
        ),
      ],
    );
  }
}
