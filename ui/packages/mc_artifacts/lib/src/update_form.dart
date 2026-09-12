import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

class UpdateTargetForm extends StatefulWidget {
  const UpdateTargetForm({
    super.key,
    required this.archiveName,
    required this.load,
    this.target,
    this.version = '',
  });
  final String archiveName, version;
  final ModEntry? target;
  final Future<ModQueryPage> Function(ModQueryCursor?) load;
  @override
  State<UpdateTargetForm> createState() => _UpdateTargetFormState();
}

class _UpdateTargetFormState extends State<UpdateTargetForm> {
  final entries = <ModEntry>[];
  late final version = TextEditingController(text: widget.version);
  ModEntry? target;
  ModQueryCursor? cursor;
  String? problem;
  bool loading = false;
  @override
  void initState() {
    super.initState();
    target = widget.target;
    if (target != null) entries.add(target!);
    unawaited(load());
  }

  @override
  void dispose() {
    version.dispose();
    super.dispose();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      problem = null;
    });
    try {
      final page = await widget.load(cursor);
      if (!mounted) return;
      for (final entry
          in page.entries
              .map((row) => row.mod)
              .where(
                (mod) =>
                    mod.currentVersionId != null &&
                    mod.status != InventoryStatus.deleting,
              )) {
        final index = entries.indexWhere((current) => current.id == entry.id);
        if (index < 0) {
          entries.add(entry);
        } else {
          entries[index] = entry;
        }
      }
      cursor = page.next;
      target =
          entries.where((entry) => entry.id == target?.id).firstOrNull ??
          entries.firstOrNull;
    } on Exception catch (_) {
      if (mounted) problem = 'The mod list is unavailable. Try again.';
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => McFormDialog(
    title: 'Update an installed mod',
    action: 'Review update',
    onSubmit: target == null || loading
        ? null
        : () =>
              Navigator.pop(context, (target: target!, version: version.text)),
    children: [
      Text(widget.archiveName),
      const SizedBox(height: 16),
      if (entries.isNotEmpty)
        McChoice<ModEntry>(
          label: 'Mod',
          value: target!,
          choices: entries,
          describe: (entry) => entry.metadata.name,
          onChanged: (entry) => setState(() => target = entry),
        ),
      if (entries.isEmpty && !loading && problem == null)
        const Text('No installed mods are available.'),
      if (loading) const LinearProgressIndicator(),
      if (problem != null) McStatus(title: problem!, tone: McStatusTone.error),
      if (cursor != null || problem != null)
        McAction(
          label: problem == null ? 'Load more mods' : 'Retry',
          onPressed: loading ? null : load,
        ),
      const SizedBox(height: 16),
      TextField(
        controller: version,
        decoration: const InputDecoration(labelText: 'New version (optional)'),
      ),
    ],
  );
}
