import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'steam_search_controller.dart';
import 'steam_chooser.dart';
import 'proton_dialog.dart';

typedef GameDirectoryChooser = Future<String?> Function(String? initialPath);

class InstallationDialog extends StatefulWidget {
  const InstallationDialog({
    super.key,
    required this.initial,
    required this.client,
    required this.chooseDirectory,
    required this.onSaved,
    required this.onUnknownSave,
    this.steamDiscovery,
    this.protonContexts,
  });
  final GameContextState initial;
  final GameContextsClient client;
  final SteamDiscoveryClient? steamDiscovery;
  final ProtonContextsClient? protonContexts;
  final GameDirectoryChooser chooseDirectory;
  final ValueChanged<GameContextState> onSaved;
  final VoidCallback onUnknownSave;
  @override
  State<InstallationDialog> createState() => _InstallationDialogState();
}

class _InstallationDialogState extends State<InstallationDialog> {
  late final folder = TextEditingController(
    text: widget.initial.binding?.path ?? '',
  );
  late GameContextState current = widget.initial;
  SteamSearchController? steamSearch;
  late ProtonSelection? proton = widget.initial.binding?.proton;
  bool busy = false;
  bool submitting = false;
  bool needsReload = false;
  bool reloaded = false;
  String? error;
  @override
  void dispose() {
    steamSearch?.dispose();
    folder.dispose();
    super.dispose();
  }

  Future<void> findInSteam() async {
    final discovery = widget.steamDiscovery;
    if (busy || discovery == null) return;
    final search = steamSearch ??= SteamSearchController(
      discovery,
      current.definition.id,
    );
    final path = await showDialog<String>(
      context: context,
      builder: (_) => SteamInstallationChooser(
        controller: search,
        gameName: current.definition.name,
        chooseDirectory: widget.chooseDirectory,
      ),
    );
    if (mounted && path != null) {
      setState(() {
        folder.text = path;
        error = null;
      });
    }
  }

  Future<void> chooseProton() async {
    final client = widget.protonContexts;
    if (busy || client == null || folder.text.isEmpty) return;
    final selected = await showDialog<ProtonSelection>(
      context: context,
      builder: (_) => ProtonDialog(
        game: current.definition,
        gamePath: folder.text,
        client: client,
        chooseDirectory: widget.chooseDirectory,
        roots: steamSearch?.additionalRoots ?? const [],
        initial: proton,
      ),
    );
    if (mounted && selected != null) {
      setState(() {
        proton = selected;
        error = null;
      });
    }
  }

  Future<void> save() async {
    if (busy || needsReload) return;
    setState(() {
      busy = true;
      submitting = true;
      error = null;
    });
    try {
      final result = await widget.client.save(
        current.workspaceId,
        current.revision,
        folder.text,
        proton: proton,
      );
      widget.onSaved(result);
      if (mounted) Navigator.pop(context);
    } on Exception catch (failure) {
      if (failure is! GameContextException) widget.onUnknownSave();
      if (mounted) {
        setState(() {
          if (failure is GameContextException) {
            needsReload = failure.code == GameContextFailure.stale;
            error = failure.candidate?.problems.map((p) => p.detail).join('\n');
            if (error == null || error!.isEmpty) error = failure.detail;
          } else {
            needsReload = true;
            error = 'Save did not return a result. Reload the saved installation before another change.';
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
          submitting = false;
        });
      }
    }
  }

  Future<void> reload() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final result = await widget.client.read(current.workspaceId);
      widget.onSaved(result);
      if (mounted) {
        setState(() {
          current = result;
          needsReload = false;
          reloaded = true;
          error = null;
        });
      }
    } on Exception {
      if (mounted) {
        setState(
          () => error = 'The saved installation could not be loaded. Your folder is unchanged.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> browse() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final selected = await widget.chooseDirectory(
        folder.text.isEmpty ? null : folder.text,
      );
      if (mounted && selected != null) {
        setState(() {
          folder.text = selected;
          error = null;
        });
      }
    } on Exception {
      if (mounted) {
        setState(() => error = 'The folder selector could not open.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => McFormDialog(
    title: 'Game installation',
    action: submitting ? 'Saving…' : 'Save',
    canCancel: !submitting,
    onSubmit: busy || needsReload ? null : save,
    children: [
      Text(
        current.definition.name,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 4),
      Text(current.definition.storefront),
      const SizedBox(height: 20),
      TextFormField(
        key: const ValueKey('installation-folder'),
        controller: folder,
        autofocus: true,
        enabled: !busy,
        minLines: 2,
        maxLines: 3,
        decoration: const InputDecoration(labelText: 'Installation folder'),
        onFieldSubmitted: (_) => save(),
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          McAction(
            key: const ValueKey('browse-installation'),
            label: 'Browse…',
            icon: Icons.folder_open,
            onPressed: busy ? null : browse,
          ),
          McAction(
            key: const ValueKey('find-in-steam'),
            label: 'Find in Steam…',
            icon: Icons.search,
            onPressed: busy || widget.steamDiscovery == null
                ? null
                : findInSteam,
          ),
        ],
      ),
      if (Platform.isLinux) ...[
        const SizedBox(height: 20),
        Text('Proton', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        if (proton case final selection?) ...[
          SelectableText(
            current.binding?.proton == selection &&
                    current.binding?.evidence.proton != null
                ? current.binding!.evidence.proton!.runtimeName
                : selection.runtimeDirectory,
          ),
          Text(
            selection.compatData,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ] else
          const Text('Not selected'),
        const SizedBox(height: 8),
        McAction(
          key: const ValueKey('select-proton'),
          label: proton == null ? 'Select Proton…' : 'Change Proton…',
          icon: Icons.tune,
          onPressed: busy || widget.protonContexts == null
              ? null
              : chooseProton,
        ),
      ],
      if (error != null) ...[
        const SizedBox(height: 16),
        McStatus(title: error!, tone: McStatusTone.error),
      ],
      if (needsReload) ...[
        const SizedBox(height: 10),
        McAction(
          key: const ValueKey('reload-installation'),
          label: 'Reload saved installation',
          icon: Icons.refresh,
          onPressed: busy ? null : reload,
        ),
      ],
      if (reloaded) ...[
        const SizedBox(height: 16),
        Text(
          'Saved installation',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 4),
        SelectableText(current.binding?.path ?? 'No installation selected'),
      ],
    ],
  );
}
