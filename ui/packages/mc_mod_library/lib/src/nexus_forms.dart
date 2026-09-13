import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'category_controller.dart';
import 'category_picker.dart';

class NexusLinkForm extends StatefulWidget {
  const NexusLinkForm({super.key, required this.details, required this.client});
  final ModNexusDetails details;
  final NexusClient client;
  @override
  State<NexusLinkForm> createState() => _NexusLinkFormState();
}

class _NexusLinkFormState extends State<NexusLinkForm> {
  late final number = TextEditingController(
    text: widget.details.reference.providerMod?.toString() ?? '',
  );
  NexusMod? mod;
  int file = 0;
  bool busy = false;
  String? problem;
  @override
  void dispose() {
    number.dispose();
    super.dispose();
  }

  Future<void> lookup() async {
    final id = int.tryParse(number.text.trim());
    if (id == null || id <= 0) return;
    setState(() {
      busy = true;
      problem = null;
    });
    try {
      final value = await widget.client.mod(
        widget.details.reference.workspace,
        id,
      );
      if (mounted) {
        setState(() {
          mod = value;
          file = value.files.any((f) => f.id == widget.details.installedFile)
              ? widget.details.installedFile!
              : 0;
        });
      }
    } on NexusProblem catch (error) {
      if (mounted) setState(() => problem = error.message);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => McFormDialog(
    title: 'Link Nexus mod',
    action: 'Link mod',
    onSubmit: busy || mod == null
        ? null
        : () => Navigator.pop(context, (
            mod: mod!.id,
            file: file == 0 ? null : file,
          )),
    children: [
      Text('${widget.details.name} · current saved version'),
      const SizedBox(height: 16),
      McChoice<String>(
        label: 'Game',
        value: 'Skyrim Special Edition',
        choices: const ['Skyrim Special Edition'],
        describe: (v) => v,
        onChanged: (_) {},
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: number,
        enabled: !busy,
        decoration: const InputDecoration(labelText: 'Nexus mod number'),
        keyboardType: TextInputType.number,
        onChanged: (_) => setState(() => mod = null),
      ),
      const SizedBox(height: 16),
      McAction(label: 'Look up mod', onPressed: busy ? null : lookup),
      if (problem != null) ...[
        const SizedBox(height: 16),
        McStatus(title: problem!, tone: McStatusTone.error),
      ],
      if (mod != null) ...[
        const SizedBox(height: 16),
        Text(mod!.name),
        const SizedBox(height: 16),
        McChoice<int>(
          label: 'Installed file',
          value: file,
          choices: [
            0,
            ...(widget.details.reference.version.isEmpty
                    ? <NexusFile>[]
                    : mod!.files)
                .map((f) => f.id),
          ],
          describe: (id) => id == 0
              ? 'Not linked'
              : '${mod!.files.firstWhere((f) => f.id == id).name} · ${mod!.files.firstWhere((f) => f.id == id).version}',
          onChanged: (value) => setState(() => file = value),
        ),
        const SizedBox(height: 16),
      ],
    ],
  );
}

class NexusCategoryForm extends StatefulWidget {
  const NexusCategoryForm({
    super.key,
    required this.details,
    required this.client,
    required this.categories,
  });
  final ModNexusDetails details;
  final ModOrganizationClient client;
  final List<CategoryReference> categories;
  @override
  State<NexusCategoryForm> createState() => _NexusCategoryFormState();
}

class _NexusCategoryFormState extends State<NexusCategoryForm> {
  late final controller = CategoryController(
    widget.client,
    widget.details.reference.workspace,
    multiple: false,
  );
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (c, _) => McFormDialog(
      title: 'Map Nexus category',
      action: 'Add category',
      onSubmit:
          controller.loading ||
              controller.stale ||
              controller.selected.length != 1
          ? null
          : () => Navigator.pop(c, controller.selected.single.id),
      children: [
        Text(widget.details.name),
        const SizedBox(height: 16),
        Text(
          'Nexus category: ${widget.details.metadata?.category ?? 'Unknown'}',
        ),
        const SizedBox(height: 16),
        CategoryPicker(controller: controller),
        const SizedBox(height: 16),
        Text(
          'Current categories: ${widget.categories.isEmpty ? 'None' : widget.categories.map((c) => c.label).join(', ')}',
        ),
      ],
    ),
  );
}
