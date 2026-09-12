import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'archive_facts.dart';

class InstallationMetadataForm extends StatefulWidget {
  const InstallationMetadataForm({super.key, required this.draft});
  final InstallationDraft draft;
  @override
  State<InstallationMetadataForm> createState() =>
      _InstallationMetadataFormState();
}

class _InstallationMetadataFormState extends State<InstallationMetadataForm> {
  late final name = TextEditingController(text: widget.draft.name);
  late final version = TextEditingController(text: widget.draft.version);
  @override
  void dispose() {
    name.dispose();
    version.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) => McFormDialog(
    title: 'New mod',
    action: 'Save',
    onSubmit: () =>
        Navigator.pop(c, InstallationMetadataChange(name.text, version.text)),
    children: [
      TextField(
        controller: name,
        decoration: const InputDecoration(labelText: 'Name'),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: version,
        decoration: const InputDecoration(labelText: 'Version (optional)'),
      ),
    ],
  );
}

class InstallationDestinationForm extends StatefulWidget {
  const InstallationDestinationForm({
    super.key,
    required this.source,
    required this.destination,
    required this.directory,
  });
  final List<String> source, destination;
  final bool directory;
  @override
  State<InstallationDestinationForm> createState() =>
      _InstallationDestinationFormState();
}

class _InstallationDestinationFormState
    extends State<InstallationDestinationForm> {
  late final target = TextEditingController(text: widget.destination.join('/'));
  @override
  void dispose() {
    target.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) => McFormDialog(
    title: 'Change destination',
    action: 'Apply',
    onSubmit: () => Navigator.pop(
      c,
      InstallationDestinationChange(
        widget.source,
        target.text.isEmpty
            ? <String>[]
            : target.text.replaceAll('\\', '/').split('/'),
      ),
    ),
    children: [
      archiveFact(
        c,
        widget.directory ? 'Archive folder' : 'Archive file',
        widget.source.join('/'),
      ),
      TextField(
        controller: target,
        decoration: InputDecoration(
          labelText: widget.directory ? 'Folder in mod' : 'File in mod',
        ),
      ),
    ],
  );
}
