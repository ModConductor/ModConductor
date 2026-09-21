import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

typedef DirectoryChooser = Future<String?> Function(String? initialPath);
Future<String?> chooseWorkspaceDirectory(String? initialPath) async {
  if (Platform.isLinux) {
    try {
      final schemas = await Process.run('gsettings', const ['list-schemas']);
      final available =
          schemas.exitCode == 0 &&
          (schemas.stdout as String)
              .split('\n')
              .contains('org.gtk.Settings.FileChooser');
      if (!available) throw Exception('The GTK file chooser is unavailable.');
    } on ProcessException {
      throw Exception('The GTK file chooser is unavailable.');
    }
  }
  return getDirectoryPath(
    initialDirectory: initialPath,
    confirmButtonText: 'Choose folder',
    canCreateDirectories: true,
  );
}

class WorkspaceDialog extends StatefulWidget {
  const WorkspaceDialog({
    super.key,
    required this.create,
    this.chooseDirectory = chooseWorkspaceDirectory,
  });
  final bool create;
  final DirectoryChooser chooseDirectory;
  @override
  State<WorkspaceDialog> createState() => _WorkspaceDialogState();
}

class _WorkspaceDialogState extends State<WorkspaceDialog> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  String? _path;
  String? _error;
  bool _choosing = false;
  final _chooseFocus = FocusNode(debugLabel: 'Choose workspace folder');
  @override
  void dispose() {
    _name.dispose();
    _chooseFocus.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    if (!widget.create && _path == null) {
      setState(() => _error = 'Choose a folder.');
      return;
    }
    Navigator.pop(context, (name: _name.text.trim(), path: _path));
  }

  Future<void> _choose() async {
    setState(() {
      _choosing = true;
      _error = null;
    });
    try {
      final path = await widget.chooseDirectory(_path);
      if (mounted && path != null) setState(() => _path = path);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'The folder selector could not open.');
      }
    } finally {
      if (mounted) {
        setState(() => _choosing = false);
        _chooseFocus.requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _form,
    child: McFormDialog(
      title: widget.create ? 'Create workspace' : 'Open workspace',
      action: widget.create ? 'Create' : 'Open',
      onSubmit: _choosing ? null : _submit,
      children: [
        if (widget.create) ...[
          McNameField(controller: _name, onSubmit: _submit),
          const SizedBox(height: McSpacing.large),
        ],
        if (widget.create && _path == null)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              key: const ValueKey('choose-folder'),
              focusNode: _chooseFocus,
              onPressed: _choosing ? null : _choose,
              icon: const Icon(Icons.folder_outlined),
              label: const Text('Change storage location'),
            ),
          )
        else if (_path case final path?)
          Container(
            padding: const EdgeInsets.all(McSpacing.medium),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.create) ...[
                  Text(
                    'Storage location',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: McSpacing.small),
                ],
                SelectableText(
                  path,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: McSpacing.medium),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    McAction(
                      key: const ValueKey('choose-folder'),
                      focusNode: _chooseFocus,
                      label: 'Choose folder',
                      icon: Icons.folder_open,
                      onPressed: _choosing ? null : _choose,
                    ),
                    if (widget.create)
                      McAction(
                        key: const ValueKey('use-default-folder'),
                        label: 'Use default',
                        icon: Icons.restart_alt,
                        onPressed: _choosing
                            ? null
                            : () => setState(() {
                                _path = null;
                                _error = null;
                              }),
                      ),
                  ],
                ),
              ],
            ),
          )
        else
          McAction(
            key: const ValueKey('choose-folder'),
            focusNode: _chooseFocus,
            label: 'Choose folder',
            icon: Icons.folder_open,
            onPressed: _choosing ? null : _choose,
          ),
        if (_choosing) ...[
          const SizedBox(height: McSpacing.small),
          const McActionFeedback(
            kind: McActionFeedbackKind.pending,
            message: 'Opening folder selector',
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: McSpacing.medium),
          McActionFeedback(
            kind: McActionFeedbackKind.failure,
            message: _error!,
          ),
        ],
      ],
    ),
  );
}
