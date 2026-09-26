import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_file_plans/mc_file_plans.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'controller.dart';
import 'settings_dialogs.dart';
import 'settings_view.dart';

class ProfileSettingsInspector extends StatefulWidget {
  const ProfileSettingsInspector({
    super.key,
    required this.controller,
    required this.client,
    required this.workspace,
    required this.profile,
    required this.profiles,
    required this.available,
    required this.onClose,
    required this.onResumeProfileChange,
    required this.onNavigationGuardChanged,
    this.pluginHeadersId,
  });
  final ProfileDataController controller;
  final ProfileDataClient? client;
  final WorkspaceInfo workspace;
  final ProfileInfo profile;
  final List<ProfileInfo> profiles;
  final bool available;
  final VoidCallback onClose;
  final Future<void> Function(String) onResumeProfileChange;
  final ValueChanged<Future<bool> Function(FutureOr<void> Function())?>
  onNavigationGuardChanged;
  final String? pluginHeadersId;
  @override
  State<ProfileSettingsInspector> createState() =>
      _ProfileSettingsInspectorState();
}

class _ProfileSettingsInspectorState extends State<ProfileSettingsInspector> {
  ProfileDataController get controller => widget.controller;
  final _filesButtonFocus = FocusNode();
  final _editor = GlobalKey<TextEditorToolboxState>();
  bool _showFiles = false, _loadingFiles = false;
  List<ProfileConfigurationFile> _files = const [];
  ProfileConfigurationDocument? _configuration;
  String? _editingProfileName;
  String? _fileProblem;
  int _fileEpoch = 0;
  bool _pendingAttachment = false, _guardingAttachment = false;
  @override
  void initState() {
    super.initState();
    _attach();
  }

  @override
  void didUpdateWidget(ProfileSettingsInspector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile.id != widget.profile.id ||
        oldWidget.client != widget.client) {
      if (_configuration != null) {
        _pendingAttachment = true;
        _guardAttachment();
        return;
      }
      _closeFiles(restoreFocus: false);
    }
    _attach();
  }

  void _guardAttachment() {
    if (_guardingAttachment) return;
    _guardingAttachment = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final editor = _editor.currentState;
      if (editor == null) {
        _guardingAttachment = false;
        return;
      }
      unawaited(
        editor
            .guardNavigation(() {
              _closeFiles(restoreFocus: false);
            })
            .whenComplete(() => _guardingAttachment = false),
      );
    });
  }

  void _attach() => controller.attach(
    widget.client,
    widget.workspace.id,
    widget.profile.id,
    available: widget.available,
  );

  Future<void> _openFiles() async {
    final client = widget.client, state = controller.state;
    if (client == null || state == null || !state.settingsInitialized) return;
    final epoch = ++_fileEpoch;
    setState(() {
      _showFiles = true;
      _loadingFiles = true;
      _fileProblem = null;
      _files = const [];
    });
    try {
      final files = await client.configurationFiles(state.reference);
      if (!mounted || epoch != _fileEpoch) return;
      setState(() => _files = files);
    } on Exception catch (error) {
      if (!mounted || epoch != _fileEpoch) return;
      setState(() {
        _fileProblem = error is ProfileDataProblem
            ? error.detail
            : 'The profile files could not be read.';
      });
    } finally {
      if (mounted && epoch == _fileEpoch) setState(() => _loadingFiles = false);
    }
  }

  Future<void> _openConfiguration(String name) async {
    final client = widget.client, state = controller.state;
    if (client == null || state == null) return;
    final epoch = ++_fileEpoch;
    setState(() {
      _loadingFiles = true;
      _fileProblem = null;
    });
    try {
      final value = await client.readConfiguration(state.reference, name);
      if (!mounted || epoch != _fileEpoch) return;
      setState(() {
        _configuration = value;
        _editingProfileName = widget.profile.name;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _configuration != value) return;
        widget.onNavigationGuardChanged(
          (navigate) => _editor.currentState!.guardNavigation(navigate),
        );
      });
    } on Exception catch (error) {
      if (!mounted || epoch != _fileEpoch) return;
      setState(() {
        _fileProblem = error is ProfileDataProblem
            ? error.detail
            : 'The profile file could not be opened.';
      });
    } finally {
      if (mounted && epoch == _fileEpoch) setState(() => _loadingFiles = false);
    }
  }

  void _closeConfiguration() {
    widget.onNavigationGuardChanged(null);
    setState(() {
      _configuration = null;
      _editingProfileName = null;
    });
  }

  void _closeFiles({bool restoreFocus = true}) {
    ++_fileEpoch;
    widget.onNavigationGuardChanged(null);
    if (mounted) {
      setState(() {
        _showFiles = false;
        _loadingFiles = false;
        _files = const [];
        _configuration = null;
        _editingProfileName = null;
        _fileProblem = null;
      });
      if (_pendingAttachment) {
        _pendingAttachment = false;
        _attach();
      }
      if (restoreFocus) _filesButtonFocus.requestFocus();
    }
  }

  String name(String id) =>
      widget.profiles.where((p) => p.id == id).firstOrNull?.name ??
      (widget.workspace.selectedProfile?.id == id
          ? widget.workspace.selectedProfile!.name
          : 'Another profile');

  Future<void> edit() async {
    final current = controller.state;
    if (current == null) return;
    final choice = await chooseProfileOptions(
      context,
      current,
      widget.profile.name,
    );
    if (choice == null || !mounted) return;
    final disabling =
        (current.options.settings && !choice.options.settings) ||
        (current.options.saves && !choice.options.saves);
    var disabled = DisabledProfileFiles.keep;
    if (disabling) {
      final selected = await chooseDisabledFiles(
        context,
        current,
        choice.options,
        widget.profile,
      );
      if (selected == null || !mounted) return;
      disabled = selected;
    }
    await controller.edit(choice.options, choice.initial, disabled);
  }

  Future<void> restore() async {
    final active = controller.state?.inUseProfileId;
    if (active == null) return;
    final confirmed = await confirmProfileRestore(context, name(active));
    if (confirmed == true) await controller.restore();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      if (_configuration case final document?) {
        return McInspector(
          title: 'Edit profile file',
          onClose: () => unawaited(_editor.currentState?.requestExit()),
          children: [
            TextEditorToolbox(
              key: _editor,
              document: document.document,
              name: document.name,
              source: _editingProfileName ?? widget.profile.name,
              saveLabel: 'Replace profile ${document.name}',
              saving: controller.busy,
              problem: controller.problem,
              onClose: _closeFiles,
              onExit: widget.onClose,
              onReadAgain: () async {
                _closeConfiguration();
                await controller.read();
                if (mounted && !controller.needsRead) {
                  await _openConfiguration(document.name);
                }
              },
              onSave: (content) async {
                return controller.saveConfiguration(document, content);
              },
            ),
          ],
        );
      }
      if (_showFiles) {
        return McInspector(
          title: 'Profile files',
          onClose: _closeFiles,
          children: [
            if (_loadingFiles) const LinearProgressIndicator(),
            if (_fileProblem != null) ...[
              McStatus(title: _fileProblem!, tone: McStatusTone.error),
              const SizedBox(height: 12),
              McAction(label: 'Read again', onPressed: _openFiles),
            ],
            for (final file in _files)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(file.name),
                subtitle: Text(
                  file.exists ? fileSize(file.bytes) : 'Not created',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _loadingFiles
                    ? null
                    : () => unawaited(_openConfiguration(file.name)),
              ),
          ],
        );
      }
      return ProfileSettingsView(
        controller: controller,
        client: widget.client,
        workspace: widget.workspace,
        profile: widget.profile,
        available: widget.available,
        onClose: widget.onClose,
        onEdit: edit,
        onOpenFiles: _openFiles,
        onRestore: restore,
        onResumeProfileChange: widget.onResumeProfileChange,
        activeName: name,
        filesButtonFocus: _filesButtonFocus,
        pluginHeadersId: widget.pluginHeadersId,
      );
    },
  );

  @override
  void dispose() {
    ++_fileEpoch;
    widget.onNavigationGuardChanged(null);
    _filesButtonFocus.dispose();
    super.dispose();
  }
}
