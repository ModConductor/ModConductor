import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_file_plans/mc_file_plans.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'controller.dart';
import 'save_files.dart';

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
    var settings = current.options.settings, saves = current.options.saves;
    var initial = InitialProfileSaves.empty;
    final choice =
        await showDialog<
          ({ProfileDataOptions options, InitialProfileSaves initial})
        >(
          context: context,
          builder: (context) => StatefulBuilder(
            builder: (context, update) => McFormDialog(
              title: '${widget.profile.name} settings',
              action: 'Save',
              onSubmit: () => Navigator.pop(context, (
                options: ProfileDataOptions(settings: settings, saves: saves),
                initial: initial,
              )),
              children: [
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Local game settings'),
                  value: settings,
                  onChanged: (value) => update(() => settings = value!),
                ),
                if (settings && !current.settingsInitialized)
                  const Padding(
                    padding: EdgeInsets.only(left: 16, bottom: 12),
                    child: Text('Starts from the global game settings.'),
                  ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Local saves'),
                  value: saves,
                  onChanged: (value) => update(() => saves = value!),
                ),
                if (saves && !current.savesInitialized) ...[
                  const SizedBox(height: 8),
                  McChoice<InitialProfileSaves>(
                    label: 'Initial saves',
                    value: initial,
                    choices: InitialProfileSaves.values,
                    describe: (value) => value == InitialProfileSaves.empty
                        ? 'Start empty'
                        : 'Copy existing global saves',
                    onChanged: (value) => update(() => initial = value),
                  ),
                  if (initial == InitialProfileSaves.empty)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text('Global saves are not moved or deleted.'),
                    ),
                ],
                const SizedBox(height: 16),
                const McStatus(
                  title: 'Applied on Play',
                  detail: 'The settings stay in use for direct Steam launches until restored.',
                ),
              ],
            ),
          ),
        );
    if (choice == null || !mounted) return;
    final disabling =
        (current.options.settings && !choice.options.settings) ||
        (current.options.saves && !choice.options.saves);
    var disabled = DisabledProfileFiles.keep;
    if (disabling) {
      final selected = await disable(current, choice.options);
      if (selected == null || !mounted) return;
      disabled = selected;
    }
    await controller.edit(choice.options, choice.initial, disabled);
  }

  Future<DisabledProfileFiles?> disable(
    ProfileDataState current,
    ProfileDataOptions next,
  ) async {
    var choice = DisabledProfileFiles.keep;
    final settings = current.options.settings && !next.settings;
    final saves = current.options.saves && !next.saves;
    final subject = settings && saves
        ? 'local settings and saves'
        : settings
        ? 'local game settings'
        : 'local saves';
    final count =
        (settings ? current.settingsFiles : 0) +
        (saves ? current.saveFiles : 0);
    return showDialog<DisabledProfileFiles>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => McDialog(
          title: 'Turn off $subject?',
          actions: [
            McAction(label: 'Cancel', onPressed: () => Navigator.pop(context)),
            McAction(
              label: choice == DisabledProfileFiles.delete
                  ? 'Turn off and delete'
                  : 'Turn off',
              emphasis: McActionEmphasis.primary,
              onPressed: () => Navigator.pop(context, choice),
            ),
          ],
          children: [
            if (current.inUseProfileId == widget.profile.id)
              Text(
                '${widget.profile.name} is in use. The affected global settings or save location will be restored first.',
              ),
            const SizedBox(height: 16),
            McChoice<DisabledProfileFiles>(
              label: 'Local files',
              value: choice,
              choices: DisabledProfileFiles.values,
              describe: (value) => value == DisabledProfileFiles.keep
                  ? 'Keep local files'
                  : 'Delete local files',
              onChanged: (value) => update(() => choice = value),
            ),
            const SizedBox(height: 16),
            Text(
              choice == DisabledProfileFiles.keep
                  ? 'Keep $count ${count == 1 ? 'file' : 'files'} for a later re-enable.'
                  : 'Delete $count ${count == 1 ? 'file' : 'files'} from ${widget.profile.name}. Global saves are not deleted.',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> restore() async {
    final active = controller.state?.inUseProfileId;
    if (active == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => McDialog(
        title: 'Restore settings, saves and plugin order?',
        actions: [
          McAction(label: 'Cancel', onPressed: () => Navigator.pop(context)),
          McAction(
            label: 'Restore',
            emphasis: McActionEmphasis.primary,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
        children: [
          Text(
            'Keep ${name(active)}’s profile data and restore the global settings, save location and any applied plugin order.',
          ),
          const SizedBox(height: 16),
          const Text('Local options stay enabled. Play can apply them again.'),
        ],
      ),
    );
    if (confirmed == true) await controller.restore();
  }

  Widget item(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        SelectableText(value),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final state = controller.state;
      final problem = controller.problem ?? state?.problem;
      final pending = state?.pendingActionId;
      final active = state?.inUseProfileId;
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
      return McInspector(
        title: widget.profile.name,
        onClose: widget.onClose,
        footer: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            McAction(
              label: 'Edit settings',
              icon: Icons.tune,
              onPressed: controller.canEdit ? edit : null,
            ),
          ],
        ),
        children: [
          Text(
            'Settings and saves',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 16),
          if (controller.busy) ...[
            McStatus(
              title: '${controller.activity}…',
              detail: controller.progress == null
                  ? null
                  : '${controller.progress!.files} files · ${controller.progress!.bytes} bytes copied',
            ),
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
            const SizedBox(height: 12),
            if (controller.activity != 'Reading settings and saves')
              McAction(
                label: 'Cancel',
                onPressed: () => unawaited(controller.cancel()),
              ),
          ] else if (problem != null)
            McStatus(title: problem, tone: McStatusTone.error)
          else if (state != null)
            McStatus(
              title: active == null
                  ? 'Global settings and saves in use'
                  : active == widget.profile.id
                  ? 'In use'
                  : 'In use: ${name(active)}',
              detail: active != widget.profile.id
                  ? 'Play applies the selected profile.'
                  : null,
            ),
          if (controller.result case final result? when !result.complete)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                '${result.completedFiles} file changes completed. The action did not finish.',
              ),
            ),
          if (!controller.busy &&
              (controller.needsRead || problem != null || state == null))
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: McAction(
                label: 'Read again',
                icon: Icons.refresh,
                onPressed: widget.client == null
                    ? null
                    : () => unawaited(controller.read()),
              ),
            ),
          if (!controller.busy && pending != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  McAction(
                    label: state?.pendingConfiguration == null
                        ? 'Continue'
                        : 'Continue saving',
                    onPressed: !widget.available
                        ? null
                        : () => unawaited(
                            state!.pendingProfileChange
                                ? widget
                                      .onResumeProfileChange(pending)
                                      .then((_) => controller.read())
                                : controller.resume(),
                          ),
                  ),
                  if (state?.pendingConfiguration != null)
                    McAction(
                      label: 'Restore original',
                      onPressed: widget.available
                          ? () => unawaited(controller.restoreConfiguration())
                          : null,
                    ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          if (state != null) ...[
            item(
              'Local game settings',
              '${state.options.settings ? 'On' : 'Off'} · ${state.settingsFiles} ${state.settingsFiles == 1 ? 'file' : 'files'}',
            ),
            item(
              'Local saves',
              '${state.options.saves ? 'On' : 'Off'} · ${state.saveFiles} ${state.saveFiles == 1 ? 'file' : 'files'}',
            ),
            if (state.savesInitialized)
              McAction(
                label: 'View save files',
                icon: Icons.folder_outlined,
                onPressed: widget.client == null
                    ? null
                    : () => showDialog<void>(
                        context: context,
                        builder: (_) => ProfileSaveFiles(
                          client: widget.client!,
                          workspace: widget.workspace.id,
                          profile: widget.profile,
                          expected: state.reference,
                          headersId: widget.pluginHeadersId,
                          onChanged: controller.invalidate,
                        ),
                      ),
              ),
            if (state.settingsInitialized) ...[
              const SizedBox(height: 12),
              McAction(
                label: 'Edit profile files',
                icon: Icons.description_outlined,
                focusNode: _filesButtonFocus,
                onPressed: widget.client == null || !controller.canEdit
                    ? null
                    : _openFiles,
              ),
            ],
            const SizedBox(height: 16),
            McAction(
              label: 'Restore',
              icon: Icons.restore,
              onPressed: controller.canEdit && active != null ? restore : null,
            ),
            const SizedBox(height: 16),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('Details'),
              children: [
                if (state.settingsPath.isNotEmpty)
                  item('Private settings', state.settingsPath),
                if (state.savesPath.isNotEmpty)
                  item('Private saves', state.savesPath),
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Applied options also affect direct launches from Steam. Closing Mod Conductor does not restore them. Steam Cloud is not isolated.',
                  ),
                ),
              ],
            ),
          ],
        ],
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
