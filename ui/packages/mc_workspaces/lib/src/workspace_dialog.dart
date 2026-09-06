import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

typedef DirectoryChooser = Future<String?> Function(String? initialPath);
Future<String?> chooseWorkspaceDirectory(String? initialPath) =>
    getDirectoryPath(
      initialDirectory: initialPath,
      confirmButtonText: 'Choose folder',
      canCreateDirectories: true,
    );

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
  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    if (_path == null) {
      setState(() => _error = 'Choose a folder.');
      return;
    }
    Navigator.pop(context, (name: _name.text.trim(), path: _path!));
  }

  Future<void> _choose() async {
    setState(() {
      _choosing = true;
      _error = null;
    });
    try {
      final path = await widget.chooseDirectory(_path);
      if (mounted && path != null) setState(() => _path = path);
    } on Exception {
      if (mounted) {
        setState(() => _error = 'The folder selector could not open.');
      }
    } finally {
      if (mounted) setState(() => _choosing = false);
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
        McAction(
          key: const ValueKey('choose-folder'),
          label: 'Choose folder',
          icon: Icons.folder_open,
          onPressed: _choosing ? null : _choose,
        ),
        if (_path != null) ...[
          const SizedBox(height: McSpacing.small),
          SelectableText(_path!, style: Theme.of(context).textTheme.bodySmall),
        ],
        if (_error != null) ...[
          const SizedBox(height: McSpacing.medium),
          McStatus(title: _error!, tone: McStatusTone.error),
        ],
      ],
    ),
  );
}
