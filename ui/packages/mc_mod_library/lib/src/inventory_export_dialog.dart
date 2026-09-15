import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'inventory_export_controller.dart';

class InventoryExportDialog extends StatefulWidget {
  const InventoryExportDialog({
    super.key,
    required this.client,
    required this.capture,
    required this.chooseLocation,
    required this.profileName,
    required this.selectedCount,
    required this.hiddenSelectedCount,
    required this.enabledCount,
    required this.matchingCount,
    required this.totalCount,
  });

  final InventoryExportClient client;
  final InventoryExportCapture capture;
  final InventoryExportLocationChooser chooseLocation;
  final String profileName;
  final int selectedCount,
      hiddenSelectedCount,
      enabledCount,
      matchingCount,
      totalCount;

  @override
  State<InventoryExportDialog> createState() => _InventoryExportDialogState();
}

class _InventoryExportDialogState extends State<InventoryExportDialog> {
  late final InventoryExportController controller;

  @override
  void initState() {
    super.initState();
    controller = InventoryExportController(
      client: widget.client,
      capture: widget.capture,
      chooseLocation: widget.chooseLocation,
      selectedCount: widget.selectedCount,
    )..addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    controller.removeListener(_changed);
    controller.dispose();
    super.dispose();
  }

  Future<void> _cancel() async {
    final result = await controller.cancel();
    if (mounted && result != null) Navigator.pop(context, result);
  }

  Future<void> _close() async {
    await controller.cancel();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _export() async {
    final result = await controller.export();
    if (mounted && result != null) Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !controller.busy,
    child: switch (controller.view) {
      InventoryExportView.stale => _problem(
        title: 'Export stopped',
        message: 'The selected mods changed.',
        detail: 'Mod Conductor did not change the CSV file.',
        action: 'Use current selection',
        onAction: () =>
            Navigator.pop(context, const InventoryExportDialogResult.retry()),
      ),
      InventoryExportView.failed => _problem(
        title: 'Export failed',
        message: 'Mod Conductor cannot write the CSV file.',
        detail: 'The existing CSV file did not change.',
        action: 'Choose another location',
        onAction: () => unawaited(controller.chooseAgain()),
      ),
      InventoryExportView.choices || InventoryExportView.progress => _form(),
    },
  );

  Widget _problem({
    required String title,
    required String message,
    required String detail,
    required String action,
    required VoidCallback onAction,
  }) => McDialog(
    title: title,
    actions: [
      McAction(label: 'Close', onPressed: () => unawaited(_close())),
      McAction(
        key: const ValueKey('export-problem-action'),
        label: action,
        emphasis: McActionEmphasis.primary,
        onPressed: onAction,
      ),
    ],
    children: [
      McStatus(title: message, detail: detail, tone: McStatusTone.error),
    ],
  );

  Widget _form() {
    final progress = controller.view == InventoryExportView.progress;
    return McDialog(
      title: 'Export CSV',
      contentWidth: 620,
      actions: [
        McAction(
          key: const ValueKey('export-cancel'),
          label: progress ? 'Cancel export' : 'Cancel',
          onPressed: controller.canceling ? null : () => unawaited(_cancel()),
        ),
        if (!progress)
          McAction(
            key: const ValueKey('export-submit'),
            label: 'Export CSV',
            emphasis: McActionEmphasis.primary,
            onPressed: controller.canExport ? () => unawaited(_export()) : null,
          ),
      ],
      children: [
        IgnorePointer(
          ignoring: controller.busy,
          child: Opacity(
            opacity: controller.busy ? 0.56 : 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle('Mods'),
                RadioGroup<InventoryExportScope>(
                  groupValue: controller.scope,
                  onChanged: (value) {
                    if (value != null) controller.changeScope(value);
                  },
                  child: Column(
                    children: [
                      _ScopeChoice(
                        choice: InventoryExportScope.selected,
                        title: 'Selected mods',
                        detail: widget.selectedCount == 0
                            ? 'No mods are selected.'
                            : 'The selection contains ${_modCount(widget.selectedCount)}. The filter hides ${widget.hiddenSelectedCount} selected ${widget.hiddenSelectedCount == 1 ? 'mod' : 'mods'}.',
                        enabled: controller.selectedAvailable,
                      ),
                      _ScopeChoice(
                        choice: InventoryExportScope.enabled,
                        title: 'Enabled profile mods',
                        detail:
                            '${_modCount(widget.enabledCount)} ${widget.enabledCount == 1 ? 'is' : 'are'} enabled in ${widget.profileName}.',
                      ),
                      _ScopeChoice(
                        choice: InventoryExportScope.currentQuery,
                        title: 'Current filter results',
                        detail:
                            '${_modCount(widget.matchingCount)} ${widget.matchingCount == 1 ? 'matches' : 'match'} the current filter.',
                      ),
                      _ScopeChoice(
                        choice: InventoryExportScope.all,
                        title: 'All profile items',
                        detail:
                            'The profile contains ${_modCount(widget.totalCount)}, separators, and locked items.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: McSpacing.medium),
                const _SectionTitle('Columns'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final field in _fieldOrder)
                      FilterChip(
                        key: ValueKey(('export-field', field)),
                        label: Text(_fieldLabel(field)),
                        selected: controller.fields.contains(field),
                        onSelected: (_) => controller.toggleField(field),
                      ),
                  ],
                ),
                if (!controller.hasIdentity) ...[
                  const SizedBox(height: McSpacing.small),
                  const Text('Select Name or Mod ID.'),
                ],
                const SizedBox(height: McSpacing.large),
                const _SectionTitle('File'),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: ValueKey(controller.destinationPath),
                        readOnly: true,
                        initialValue: controller.destinationPath ?? '',
                        decoration: const InputDecoration(
                          labelText: 'Destination',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    McAction(
                      key: const ValueKey('choose-export-location'),
                      label: 'Choose location',
                      onPressed: controller.choosing
                          ? null
                          : () => unawaited(controller.choose()),
                    ),
                  ],
                ),
                if (controller.destination?.exists ?? false) ...[
                  const McStatus(
                    title: 'This CSV file exists.',
                    detail: 'Select Replace existing file to continue.',
                  ),
                  const SizedBox(height: 4),
                  CheckboxListTile(
                    key: const ValueKey('replace-export-destination'),
                    contentPadding: EdgeInsets.zero,
                    value: controller.replacing,
                    onChanged: (value) => controller.setReplacing(value!),
                    title: const Text('Replace existing file'),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
                const SizedBox(height: McSpacing.small),
                const _SectionTitle('Formula safety'),
                const McStatus(
                  title: 'Mod Conductor adds an apostrophe before text that can start a spreadsheet formula.',
                  detail: 'The apostrophe stays in the CSV file.',
                ),
              ],
            ),
          ),
        ),
        if (progress) ...[
          const SizedBox(height: McSpacing.large),
          LinearProgressIndicator(
            key: const ValueKey('export-progress'),
            value: controller.totalRows == 0
                ? null
                : controller.writtenRows / controller.totalRows,
          ),
          const SizedBox(height: McSpacing.small),
          Text(
            'Mod Conductor wrote ${controller.writtenRows} of ${controller.totalRows} rows.',
          ),
        ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );
}

class _ScopeChoice extends StatelessWidget {
  const _ScopeChoice({
    required this.choice,
    required this.title,
    required this.detail,
    this.enabled = true,
  });

  final InventoryExportScope choice;
  final String title, detail;
  final bool enabled;

  @override
  Widget build(BuildContext context) => RadioListTile<InventoryExportScope>(
    key: ValueKey(('export-scope', choice)),
    dense: true,
    contentPadding: EdgeInsets.zero,
    value: choice,
    title: Text(title),
    subtitle: Text(detail),
    enabled: enabled,
  );
}

const _fieldOrder = [
  InventoryExportField.name,
  InventoryExportField.modId,
  InventoryExportField.priority,
  InventoryExportField.enabled,
  InventoryExportField.version,
  InventoryExportField.status,
  InventoryExportField.categories,
  InventoryExportField.notes,
  InventoryExportField.source,
  InventoryExportField.sourcePath,
  InventoryExportField.comment,
  InventoryExportField.kind,
];

String _fieldLabel(InventoryExportField field) => switch (field) {
  InventoryExportField.name => 'Name',
  InventoryExportField.modId => 'Mod ID',
  InventoryExportField.priority => 'Priority',
  InventoryExportField.enabled => 'Enabled',
  InventoryExportField.version => 'Version',
  InventoryExportField.status => 'Status',
  InventoryExportField.categories => 'Categories',
  InventoryExportField.notes => 'Notes',
  InventoryExportField.source => 'Source',
  InventoryExportField.sourcePath => 'Source path',
  InventoryExportField.comment => 'Comment',
  InventoryExportField.kind => 'Kind',
};

String _modCount(int value) => '$value ${value == 1 ? 'mod' : 'mods'}';
