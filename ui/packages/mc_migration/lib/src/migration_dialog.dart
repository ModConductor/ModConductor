import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

typedef SourceDirectoryChooser = Future<String?> Function(String? initialPath);
typedef SourceFileChooser = Future<String?> Function(String? initialPath);

Future<String?> chooseSourceDirectory(String? initialPath) => getDirectoryPath(
  initialDirectory: initialPath,
  confirmButtonText: 'Choose folder',
  canCreateDirectories: false,
);

Future<String?> chooseSourceFile(String? _) async {
  const json = XTypeGroup(label: 'JSON', extensions: ['json']);
  final file = await openFile(
    acceptedTypeGroups: const [json],
    confirmButtonText: 'Choose backup',
  );
  return file?.path;
}

class MigrationAction extends StatelessWidget {
  const MigrationAction({
    super.key,
    required this.client,
    required this.workspaceId,
    required this.onComplete,
    this.chooseDirectory = chooseSourceDirectory,
    this.chooseFile = chooseSourceFile,
  });

  final MigrationClient client;
  final String workspaceId;
  final Future<void> Function() onComplete;
  final SourceDirectoryChooser chooseDirectory;
  final SourceFileChooser chooseFile;

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
          chooseFile: chooseFile,
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
    this.chooseFile = chooseSourceFile,
  });

  final MigrationClient client;
  final String workspaceId;
  final SourceDirectoryChooser chooseDirectory;
  final SourceFileChooser chooseFile;

  @override
  State<MigrationDialog> createState() => _MigrationDialogState();
}

class _MigrationDialogState extends State<MigrationDialog> {
  MigrationManager? _manager;
  String? _sourcePath, _stagingRoot, _downloadRoot, _problem;
  BackupProfile? _profile;
  List<BackupProfile> _profiles = const [];
  MigrationProgress? _progress;
  StreamSubscription<MigrationEvent>? _operation;
  bool _choosing = false, _complete = false;

  void _selectManager(MigrationManager? value) {
    setState(() {
      _manager = value;
      _sourcePath = null;
      _stagingRoot = null;
      _downloadRoot = null;
      _profile = null;
      _profiles = const [];
      _problem = null;
    });
  }

  Future<void> _chooseModOrganizer() async {
    await _chooseDirectory(
      current: _sourcePath,
      selected: (path) => _sourcePath = path,
    );
  }

  Future<void> _chooseDirectory({
    required String? current,
    required void Function(String path) selected,
  }) async {
    setState(() {
      _choosing = true;
      _problem = null;
    });
    try {
      final path = await widget.chooseDirectory(current);
      if (mounted && path != null) setState(() => selected(path));
    } on Exception {
      if (mounted) {
        setState(() => _problem = 'The folder selector could not open.');
      }
    } finally {
      if (mounted) setState(() => _choosing = false);
    }
  }

  Future<void> _chooseBackup() async {
    setState(() {
      _choosing = true;
      _problem = null;
    });
    try {
      final path = await widget.chooseFile(_sourcePath);
      if (path == null) return;
      if (mounted) {
        setState(() {
          _sourcePath = path;
          _profiles = const [];
          _profile = null;
        });
      }
      final profiles = await widget.client.profiles(
        MigrationManager.vortex,
        path,
      );
      if (!mounted) return;
      setState(() {
        _profiles = profiles;
        _profile = profiles.length == 1 ? profiles.single : null;
        if (profiles.isEmpty) _problem = 'The backup has no profiles.';
      });
    } on MigrationFailure catch (error) {
      if (mounted) setState(() => _problem = error.detail);
    } on Exception {
      if (mounted) setState(() => _problem = 'The backup could not be read.');
    } finally {
      if (mounted) setState(() => _choosing = false);
    }
  }

  bool get _ready => switch (_manager) {
    MigrationManager.modOrganizer => _sourcePath != null,
    MigrationManager.vortex =>
      _sourcePath != null &&
          _profile != null &&
          _stagingRoot != null &&
          _downloadRoot != null,
    null => false,
  };

  void _start() {
    if (!_ready || _operation != null) return;
    setState(() {
      _problem = null;
      _progress = const MigrationProgress(0, 0, 'Starting migration');
    });
    late final StreamSubscription<MigrationEvent> operation;
    operation = widget.client
        .migrate(
          widget.workspaceId,
          _manager!,
          _sourcePath!,
          profileId: _profile?.id ?? '',
          stagingRoot: _stagingRoot ?? '',
          downloadRoot: _downloadRoot ?? '',
        )
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

  Widget _path(String value) => Padding(
    padding: const EdgeInsets.only(top: McSpacing.small),
    child: SelectableText(value, style: Theme.of(context).textTheme.bodySmall),
  );

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
      onSubmit: _ready && !_choosing ? _start : null,
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
            DropdownMenuItem(
              value: MigrationManager.vortex,
              child: Text('Vortex'),
            ),
          ],
          onChanged: _selectManager,
        ),
        if (_manager == MigrationManager.modOrganizer) ...[
          const SizedBox(height: McSpacing.large),
          McAction(
            key: const ValueKey('choose-source-folder'),
            label: 'Choose Mod Organizer folder',
            icon: Icons.folder_open,
            onPressed: _choosing ? null : _chooseModOrganizer,
          ),
          if (_sourcePath != null) _path(_sourcePath!),
        ],
        if (_manager == MigrationManager.vortex) ...[
          const SizedBox(height: McSpacing.large),
          McAction(
            key: const ValueKey('choose-backup-file'),
            label: 'Choose Vortex backup',
            icon: Icons.description_outlined,
            onPressed: _choosing ? null : _chooseBackup,
          ),
          if (_sourcePath != null) _path(_sourcePath!),
          if (_profiles.isNotEmpty) ...[
            const SizedBox(height: McSpacing.large),
            DropdownButtonFormField<BackupProfile>(
              key: const ValueKey('source-profile'),
              initialValue: _profile,
              decoration: const InputDecoration(labelText: 'Profile'),
              items: [
                for (final profile in _profiles)
                  DropdownMenuItem(value: profile, child: Text(profile.name)),
              ],
              onChanged: (value) => setState(() => _profile = value),
            ),
          ],
          const SizedBox(height: McSpacing.large),
          McAction(
            key: const ValueKey('choose-staging-root'),
            label: 'Choose staging folder',
            icon: Icons.folder_open,
            onPressed: _choosing
                ? null
                : () => _chooseDirectory(
                    current: _stagingRoot,
                    selected: (path) => _stagingRoot = path,
                  ),
          ),
          if (_stagingRoot != null) _path(_stagingRoot!),
          const SizedBox(height: McSpacing.medium),
          McAction(
            key: const ValueKey('choose-download-root'),
            label: 'Choose download folder',
            icon: Icons.folder_open,
            onPressed: _choosing
                ? null
                : () => _chooseDirectory(
                    current: _downloadRoot,
                    selected: (path) => _downloadRoot = path,
                  ),
          ),
          if (_downloadRoot != null) _path(_downloadRoot!),
        ],
        if (_problem != null) ...[
          const SizedBox(height: McSpacing.medium),
          McStatus(title: _problem!, tone: McStatusTone.error),
        ],
      ],
    );
  }
}
