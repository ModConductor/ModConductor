import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

typedef SourceDirectoryChooser = Future<String?> Function(String? initialPath);

Future<String?> chooseSourceDirectory(String? initialPath) => getDirectoryPath(
  initialDirectory: initialPath,
  confirmButtonText: 'Choose source folder',
  canCreateDirectories: false,
);

class MigrationAction extends StatelessWidget {
  const MigrationAction({
    super.key,
    required this.client,
    required this.workspaceId,
    required this.onComplete,
    this.chooseDirectory = chooseSourceDirectory,
  });

  final MigrationClient client;
  final String workspaceId;
  final Future<void> Function() onComplete;
  final SourceDirectoryChooser chooseDirectory;

  @override
  Widget build(BuildContext context) => McAction(
    key: const ValueKey('migrate-from-manager'),
    label: 'Migrate from another manager',
    icon: Icons.move_to_inbox_outlined,
    onPressed: () async {
      final changed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => MigrationDialog(
          client: client,
          workspaceId: workspaceId,
          chooseDirectory: chooseDirectory,
        ),
      );
      if (changed == true) await onComplete();
    },
  );
}

class MigrationDialog extends StatefulWidget {
  const MigrationDialog({
    super.key,
    required this.client,
    required this.workspaceId,
    this.chooseDirectory = chooseSourceDirectory,
  });

  final MigrationClient client;
  final String workspaceId;
  final SourceDirectoryChooser chooseDirectory;

  @override
  State<MigrationDialog> createState() => _MigrationDialogState();
}

class _MigrationDialogState extends State<MigrationDialog> {
  MigrationManager? _manager;
  String? _path, _problem;
  MigrationProgress? _progress;
  StreamSubscription<MigrationEvent>? _operation;
  bool _choosing = false, _complete = false;

  Future<void> _choose() async {
    setState(() {
      _choosing = true;
      _problem = null;
    });
    try {
      final path = await widget.chooseDirectory(_path);
      if (mounted && path != null) setState(() => _path = path);
    } on Exception {
      if (mounted) {
        setState(() => _problem = 'The folder selector could not open.');
      }
    } finally {
      if (mounted) setState(() => _choosing = false);
    }
  }

  void _start() {
    if (_manager == null || _path == null || _operation != null) return;
    setState(() {
      _problem = null;
      _progress = const MigrationProgress(0, 0, 'Starting migration');
    });
    late final StreamSubscription<MigrationEvent> operation;
    operation = widget.client
        .migrate(widget.workspaceId, _manager!, _path!)
        .listen(
          (event) {
            if (!mounted) return;
            switch (event) {
              case MigrationProgress():
                setState(() => _progress = event);
              case MigrationFailure():
                setState(() {
                  _problem = event.detail;
                  _progress = null;
                });
              case MigrationResult():
                setState(() {
                  _complete = true;
                  _progress = null;
                });
            }
          },
          onError: (_) {
            if (mounted) {
              setState(() {
                _problem = 'Migration did not return a result.';
                _progress = null;
              });
            }
          },
          onDone: () {
            if (mounted) setState(() => _operation = null);
          },
        );
    setState(() => _operation = operation);
  }

  Future<void> _cancel() async {
    await _operation?.cancel();
    if (mounted) Navigator.pop(context, false);
  }

  @override
  void dispose() {
    unawaited(_operation?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_complete) {
      return McDialog(
        title: 'Migration complete',
        actions: [
          McAction(
            key: const ValueKey('close-migration'),
            label: 'Close',
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
        children: const [
          Text('Your mods and profiles are ready in this workspace.'),
        ],
      );
    }

    final progress = _progress;
    if (progress != null) {
      final determinate = progress.total > 0;
      return McDialog(
        title: 'Migrating data',
        actions: [
          McAction(
            key: const ValueKey('cancel-migration'),
            label: 'Cancel',
            onPressed: _cancel,
          ),
        ],
        children: [
          Text(progress.message),
          const SizedBox(height: McSpacing.medium),
          LinearProgressIndicator(
            value: determinate ? progress.completed / progress.total : null,
          ),
        ],
      );
    }

    return McFormDialog(
      title: 'Migrate from another manager',
      action: 'Migrate',
      onSubmit: _manager != null && _path != null && !_choosing ? _start : null,
      children: [
        DropdownButtonFormField<MigrationManager>(
          key: const ValueKey('source-manager'),
          initialValue: _manager,
          decoration: const InputDecoration(labelText: 'Source manager'),
          items: const [
            DropdownMenuItem(
              value: MigrationManager.modOrganizer,
              child: Text('Mod Organizer'),
            ),
          ],
          onChanged: (value) => setState(() => _manager = value),
        ),
        const SizedBox(height: McSpacing.large),
        McAction(
          key: const ValueKey('choose-source-folder'),
          label: 'Choose source folder',
          icon: Icons.folder_open,
          onPressed: _choosing ? null : _choose,
        ),
        if (_path != null) ...[
          const SizedBox(height: McSpacing.small),
          SelectableText(_path!, style: Theme.of(context).textTheme.bodySmall),
        ],
        if (_problem != null) ...[
          const SizedBox(height: McSpacing.medium),
          McStatus(title: _problem!, tone: McStatusTone.error),
        ],
      ],
    );
  }
}
