import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'package:file_selector/file_selector.dart';

typedef ModDirectoryChooser = Future<String?> Function(String? initial);
Future<String?> chooseModDirectory(String? initial) => getDirectoryPath(
  initialDirectory: initial,
  confirmButtonText: 'Choose folder',
);

typedef ModDetails = ({ModMetadata metadata, String? path});

class ModDialog extends StatefulWidget {
  const ModDialog({
    super.key,
    this.original,
    required this.initialPath,
    required this.chooseDirectory,
  });
  final ModMetadata? original;
  final String initialPath;
  final ModDirectoryChooser chooseDirectory;
  @override
  State<ModDialog> createState() => _ModDialogState();
}

class _ModDialogState extends State<ModDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.original?.name ?? '');
  late final _version = TextEditingController(
    text: widget.original?.version ?? '',
  );
  late final _notes = TextEditingController(text: widget.original?.notes ?? '');
  String? _path, _problem;
  bool _choosing = false;
  @override
  void dispose() {
    _name.dispose();
    _version.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    if (widget.original == null && _path == null) {
      setState(() => _problem = 'Choose a mod folder inside this workspace.');
      return;
    }
    Navigator.pop(context, (
      metadata: ModMetadata(
        name: _name.text.trim(),
        version: _version.text,
        notes: _notes.text,
        comment: widget.original?.comment ?? '',
        source: widget.original?.source ?? '',
        category: widget.original?.category ?? '',
      ),
      path: _path,
    ));
  }

  Future<void> _choose() async {
    setState(() {
      _choosing = true;
      _problem = null;
    });
    try {
      final path = await widget.chooseDirectory(_path ?? widget.initialPath);
      if (mounted && path != null) setState(() => _path = path);
    } on Exception {
      if (mounted) {
        setState(() => _problem = 'The folder selector could not open.');
      }
    } finally {
      if (mounted) setState(() => _choosing = false);
    }
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _form,
    child: McFormDialog(
      title: widget.original == null ? 'Add mod folder' : 'Edit mod details',
      action: widget.original == null ? 'Add mod' : 'Save',
      onSubmit: _choosing ? null : _submit,
      children: [
        McNameField(controller: _name, onSubmit: _submit),
        const SizedBox(height: 16),
        TextFormField(
          controller: _version,
          decoration: const InputDecoration(labelText: 'Version'),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _notes,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Notes'),
        ),
        if (widget.original == null) ...[
          const SizedBox(height: 16),
          const Text('Choose a mod folder inside this workspace.'),
          const SizedBox(height: 8),
          McAction(
            label: 'Choose folder',
            icon: Icons.folder_open,
            onPressed: _choosing ? null : _choose,
          ),
          if (_path != null) ...[
            const SizedBox(height: 8),
            SelectableText(_path!),
          ],
        ],
        if (_problem != null) ...[
          const SizedBox(height: 12),
          McStatus(title: _problem!, tone: McStatusTone.error),
        ],
      ],
    ),
  );
}
