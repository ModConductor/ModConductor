import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'output_controller.dart';

class OutputLocationsDialog extends StatelessWidget {
  const OutputLocationsDialog({
    super.key,
    required this.controller,
    required this.kind,
  });
  final OutputController controller;
  final OutputLocationKind kind;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final scope = controller.scope;
      final writable = kind == OutputLocationKind.writableFile;
      final locations =
          scope?.locations.where((value) => value.kind == kind).toList() ?? [];
      return McDialog(
        title: writable ? 'Writable game files' : 'Tool output folders',
        children: [
          if ((scope?.contexts.length ?? 0) > 1) ...[
            McChoice<String>(
              label: 'Installation',
              value: scope!.reference.contextId,
              choices: scope.contexts.map((value) => value.id).toList(),
              describe: (id) => scope.contexts
                  .firstWhere((value) => value.id == id)
                  .installation,
              onChanged: (id) => unawaited(controller.read(contextId: id)),
            ),
            const SizedBox(height: 16),
          ],
          if (locations.isEmpty)
            Text(
              writable ? 'No writable game files.' : 'No tool output folders.',
            ),
          for (final location in locations) ...[
            Text(location.name, style: Theme.of(context).textTheme.titleMedium),
            if (location.target != null) Text(location.target!.join('/')),
            const SizedBox(height: 8),
            SelectableText(location.physicalPath),
            Wrap(
              spacing: 8,
              children: [
                McAction(
                  label: 'Copy path',
                  icon: Icons.copy,
                  onPressed: () => Clipboard.setData(
                    ClipboardData(text: location.physicalPath),
                  ),
                ),
                if (writable)
                  McAction(
                    label: location.status == OutputLocationStatus.stopped
                        ? 'Stopped'
                        : 'Stop using…',
                    onPressed:
                        controller.changing ||
                            location.status == OutputLocationStatus.stopped
                        ? null
                        : () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => McFormDialog(
                                title: 'Stop using ${location.name}?',
                                action: 'Stop using',
                                onSubmit: () => Navigator.pop(context, true),
                                children: const [
                                  Text(
                                    'The next deployment will use the normal mod or game-folder file. Working files remain here for review.',
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await controller.stop(location);
                            }
                          },
                  ),
              ],
            ),
            const Divider(),
          ],
          if (controller.problem != null)
            McStatus(title: controller.problem!, tone: McStatusTone.error),
          if (controller.needsRead)
            McAction(
              label: 'Reload',
              onPressed: controller.changing || controller.reading
                  ? null
                  : () =>
                        controller.read(contextId: scope?.reference.contextId),
            ),
          const SizedBox(height: 12),
          if (!writable)
            const Text(
              'Tools must write to the shown paths. These folders are not deployed.',
            ),
          if (writable)
            const Text(
              'Writable files are shared across profiles. Replacing the game-side link is not captured here.',
            ),
          const SizedBox(height: 12),
          McAction(
            label: writable ? 'Add writable file' : 'Add tool folder',
            icon: Icons.add,
            onPressed:
                scope == null || controller.changing || controller.needsRead
                ? null
                : () => showDialog<void>(
                    context: context,
                    builder: (_) => AddOutputLocationDialog(
                      controller: controller,
                      kind: kind,
                    ),
                  ),
          ),
        ],
      );
    },
  );
}

class AddOutputLocationDialog extends StatefulWidget {
  const AddOutputLocationDialog({
    super.key,
    required this.controller,
    required this.kind,
  });
  final OutputController controller;
  final OutputLocationKind kind;
  @override
  State<AddOutputLocationDialog> createState() =>
      _AddOutputLocationDialogState();
}

class _AddOutputLocationDialogState extends State<AddOutputLocationDialog> {
  final _name = TextEditingController(), _path = TextEditingController();
  final _form = GlobalKey<FormState>();
  final _id = newOperationId();
  bool _saving = false;
  String? _error;
  @override
  void dispose() {
    _name.dispose();
    _path.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final value = await widget.controller.add(
      _id,
      _name.text,
      widget.kind,
      target: widget.kind == OutputLocationKind.writableFile
          ? _path.text.split(RegExp(r'[/\\]'))
          : null,
    );
    if (!mounted) return;
    if (value != null) {
      Navigator.pop(context);
    } else {
      setState(() {
        _saving = false;
        _error =
            widget.controller.problem ??
            'Read the current output locations before retrying.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _form,
    child: McFormDialog(
      title: widget.kind == OutputLocationKind.writableFile
          ? 'Add writable game file'
          : 'Add tool output folder',
      action: _saving ? 'Saving…' : 'Add',
      onSubmit: _saving || widget.controller.needsRead ? null : submit,
      canCancel: !_saving,
      children: [
        McNameField(controller: _name, onSubmit: submit),
        if (widget.kind == OutputLocationKind.writableFile) ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: _path,
            enabled: !_saving,
            decoration: const InputDecoration(labelText: 'Path inside Data'),
            validator: (value) =>
                value == null || value.isEmpty ? 'Enter a file path.' : null,
          ),
          const SizedBox(height: 12),
          const Text(
            'This file becomes writable on the next deployment. Its working bytes are shared across profiles.',
          ),
        ] else ...[
          const SizedBox(height: 12),
          const Text(
            'Set your tool to write to the path shown after creation.',
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 12),
          McStatus(title: _error!, tone: McStatusTone.error),
          if (widget.controller.needsRead)
            McAction(
              label: 'Reload',
              onPressed: _saving
                  ? null
                  : () async {
                      setState(() => _saving = true);
                      await widget.controller.read();
                      if (mounted) {
                        setState(() {
                          _saving = false;
                          _error = widget.controller.problem;
                        });
                      }
                    },
            ),
        ],
      ],
    ),
  );
}
