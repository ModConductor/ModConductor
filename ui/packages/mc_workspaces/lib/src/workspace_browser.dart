import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'package:mc_ui_collections/mc_ui_collections.dart';

import 'controller.dart';
import 'workspace_dialog.dart';

typedef ProfileRowId = ({String profileId});
typedef WorkspaceFolderOpener = Future<bool> Function(String path);
typedef ProfileNavigationGuard = Future<bool> Function(
  FutureOr<void> Function() navigate,
);
typedef ProfileInspectorBuilder = Widget Function(
  BuildContext,
  WorkspaceInfo,
  ProfileInfo,
  VoidCallback,
  ValueChanged<ProfileNavigationGuard?>,
);
typedef ProfileCreator = Future<void> Function(
  BuildContext context,
  WorkspaceInfo workspace,
);
typedef ProfileSetupBuilder = Widget Function(
  BuildContext context,
  WorkspaceInfo workspace,
  ProfileInfo profile,
);

class WorkspaceHelpActions {
  const WorkspaceHelpActions({
    required this.createWorkspace,
    required this.openWorkspace,
    this.createProfile,
  });

  final VoidCallback? createWorkspace;
  final VoidCallback? openWorkspace;
  final VoidCallback? createProfile;
}

typedef WorkspaceHelpBuilder = Widget Function(
  BuildContext,
  WorkspaceInfo?,
  WorkspaceHelpActions,
);

enum _WorkspaceMode { profiles, mods, game, tools, archives, help }

enum _ProfileAction { clone, rename, delete }

class WorkspaceBrowser extends StatefulWidget {
  const WorkspaceBrowser({
    super.key,
    required this.controller,
    this.chooseDirectory = chooseWorkspaceDirectory,
    this.modLibraryBuilder,
    this.gameContextBuilder,
    this.executableBuilder,
    this.artifactBuilder,
    this.entryHelpBuilder,
    this.helpBuilder,
    this.headerActions,
    this.profileInspectorBuilder,
    this.profileCreator,
    this.profileSetupBuilder,
    this.workbenchReady = true,
    this.compactCloseAction = false,
    this.openFolder,
  });
  final WorkspaceController controller;
  final DirectoryChooser chooseDirectory;
  final Widget Function(BuildContext, WorkspaceInfo)? modLibraryBuilder;
  final Widget Function(BuildContext, WorkspaceInfo)? gameContextBuilder;
  final Widget Function(BuildContext, WorkspaceInfo)? executableBuilder;
  final Widget Function(BuildContext, WorkspaceInfo, VoidCallback)?
  artifactBuilder;
  final WorkspaceHelpBuilder? entryHelpBuilder;
  final WorkspaceHelpBuilder? helpBuilder;
  final List<Widget> Function(BuildContext, WorkspaceInfo)? headerActions;
  final bool compactCloseAction;
  final WorkspaceFolderOpener? openFolder;
  final ProfileInspectorBuilder? profileInspectorBuilder;
  final ProfileCreator? profileCreator;
  final ProfileSetupBuilder? profileSetupBuilder;
  final bool workbenchReady;

  @override
  State<WorkspaceBrowser> createState() => _WorkspaceBrowserState();
}

class _WorkspaceBrowserState extends State<WorkspaceBrowser> {
  WorkspaceController get controller => widget.controller;
  DirectoryChooser get chooseDirectory => widget.chooseDirectory;
  final _createWorkspaceFocus = FocusNode(debugLabel: 'Create workspace');
  final _openWorkspaceFocus = FocusNode(debugLabel: 'Open workspace');
  final _createProfileFocus = FocusNode(debugLabel: 'Create profile');
  final _helpFocus = FocusNode(debugLabel: 'Help');
  int _archiveNavigation = 0;
  int _gameNavigation = 0;
  int _helpNavigation = 0;
  bool _entryHelp = false;
  String? _shownId;
  _WorkspaceMode _mode = _WorkspaceMode.profiles;
  final _profilesFocus = FocusNode(debugLabel: 'Profiles');
  final _profiles = McCollectionModel<ProfileRowId, ProfileInfo>(
    idOf: (row) => (profileId: row.id),
    labelOf: (row) => row.name,
  );
  WorkspacePage? _shownPage;
  final _profilePane = GlobalKey<ScaffoldState>();
  bool _inspected = false,
      _compactProfile = false,
      _compactProfileActions = false;
  ProfileNavigationGuard? _profileNavigationGuard;
  String? _inspectedProfileId;
  bool _openingFolder = false, _folderProblem = false;
  bool _allowProfileDrawerClose = false, _guardingProfileDrawerClose = false;
  void _inspectProfile() {
    setState(() => _inspected = true);
    if (_compactProfile) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _profilePane.currentState?.openEndDrawer();
      });
    }
  }

  void _bindProfileNavigation(String profileId, ProfileNavigationGuard? guard) {
    if (!mounted || _inspectedProfileId != profileId) return;
    if (identical(_profileNavigationGuard, guard) ||
        (_profileNavigationGuard != null && guard != null)) {
      return;
    }
    setState(() => _profileNavigationGuard = guard);
  }

  void _selectProfile(ProfileInfo profile, [VoidCallback? after]) {
    final guard = _profileNavigationGuard;
    final prior = _inspectedProfileId;
    void select() {
      _profiles.select((profileId: profile.id));
      _profilesFocus.requestFocus();
      after?.call();
    }

    if (!_inspected || guard == null || prior == null || prior == profile.id) {
      select();
      return;
    }

    _profiles.select((profileId: prior));
    unawaited(guard(select));
  }

  void _finishProfileDrawerClose() {
    if (mounted) {
      setState(() {
        _inspected = false;
        _profileNavigationGuard = null;
        _inspectedProfileId = null;
      });
    }
    _profilesFocus.requestFocus();
  }

  void _closeProfileInspector() {
    if (_profilePane.currentState?.isEndDrawerOpen ?? false) {
      _allowProfileDrawerClose = true;
      _profilePane.currentState?.closeEndDrawer();
    } else {
      _finishProfileDrawerClose();
    }
  }

  void _guardProfileDrawerClose() {
    final guard = _profileNavigationGuard;
    if (guard == null || _guardingProfileDrawerClose) return;
    _guardingProfileDrawerClose = true;
    unawaited(
      guard(() {
        _allowProfileDrawerClose = true;
        _profilePane.currentState?.closeEndDrawer();
      }).whenComplete(() => _guardingProfileDrawerClose = false),
    );
  }

  void _profileDrawerChanged(bool open) {
    if (open) return;
    if (_allowProfileDrawerClose) {
      _allowProfileDrawerClose = false;
      _finishProfileDrawerClose();
      return;
    }
    if (_profileNavigationGuard == null) {
      _finishProfileDrawerClose();
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _profilePane.currentState?.openEndDrawer();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _guardProfileDrawerClose();
      });
    });
  }

  @override
  void initState() {
    super.initState();
    controller.addListener(_navigationChanged);
    _profiles.sort((a, b) => a.name.compareTo(b.name));
    _navigationChanged();
  }

  @override
  void didUpdateWidget(WorkspaceBrowser oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, controller)) {
      oldWidget.controller.removeListener(_navigationChanged);
      controller.addListener(_navigationChanged);
      _navigationChanged();
    }
  }

  void _navigationChanged() {
    final id = controller.workspace?.id;
    if (id != _shownId) {
      _profiles.clear();
      _mode = _WorkspaceMode.profiles;
      _entryHelp = false;
      _inspected = false;
    }
    if (_archiveNavigation != controller.archiveNavigation) {
      _archiveNavigation = controller.archiveNavigation;
      _mode = _WorkspaceMode.archives;
    }
    if (_gameNavigation != controller.gameNavigation) {
      _gameNavigation = controller.gameNavigation;
      _mode = _WorkspaceMode.game;
    }
    if (_helpNavigation != controller.helpNavigation) {
      _helpNavigation = controller.helpNavigation;
      _mode = _WorkspaceMode.help;
    }
    final page = controller.page;
    if (id != null && page != null && !identical(page, _shownPage)) {
      final selected = page.workspace.selectedProfile;
      final rows = {for (final row in page.profiles) (profileId: row.id): row};
      if (selected != null) rows[(profileId: selected.id)] = selected;
      final removed = _profiles.ids
          .where((id) => !rows.containsKey(id))
          .toList();
      _profiles.apply(
        upserts: rows.values,
        removed: page.nextProfile == null ? removed : const [],
        evicted: page.nextProfile != null ? removed : const [],
      );
      _shownPage = page;
    }
    if (id == _shownId) return;
    _shownId = id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && controller.workspace?.id == id) {
        (id == null ? _createWorkspaceFocus : _createProfileFocus)
            .requestFocus();
      }
    });
  }

  @override
  void dispose() {
    controller.removeListener(_navigationChanged);
    _profiles.dispose();
    _profilesFocus.dispose();
    _createWorkspaceFocus.dispose();
    _openWorkspaceFocus.dispose();
    _createProfileFocus.dispose();
    _helpFocus.dispose();
    super.dispose();
  }

  Future<void> _workspaceDialog(BuildContext context, bool create) async {
    (create ? _createWorkspaceFocus : _openWorkspaceFocus).requestFocus();
    final value = await showDialog<({String name, String? path})>(
      context: context,
      builder: (_) =>
          WorkspaceDialog(create: create, chooseDirectory: chooseDirectory),
    );
    if (value == null) return;
    if (create) {
      await controller.create(value.name, value.path);
    } else {
      await controller.open(value.path!);
    }
  }

  Future<void> _openFolder() async {
    final workspace = controller.workspace;
    final open = widget.openFolder;
    if (workspace == null || open == null || _openingFolder) return;
    setState(() {
      _openingFolder = true;
      _folderProblem = false;
    });
    final opened = await open(workspace.path);
    if (mounted) {
      setState(() {
        _openingFolder = false;
        _folderProblem = !opened;
      });
    }
  }

  Future<void> _profileDialog(
    BuildContext context, {
    ProfileInfo? profile,
    bool rename = false,
  }) async {
    if (profile == null && !rename && widget.profileCreator != null) {
      final workspace = controller.workspace;
      if (workspace != null) {
        _createProfileFocus.requestFocus();
        await widget.profileCreator!(context, workspace);
        if (mounted) _createProfileFocus.requestFocus();
      }
      return;
    }
    final value = await showDialog<String>(
      context: context,
      builder: (_) => McNameDialog(
        title: rename
            ? 'Rename profile'
            : profile == null
            ? 'Create profile'
            : 'Clone profile',
        action: rename
            ? 'Save'
            : profile == null
            ? 'Create'
            : 'Clone',
        initial: profile == null
            ? ''
            : rename
            ? profile.name
            : '${profile.name} copy',
      ),
    );
    if (value == null) return;
    if (rename) {
      await controller.rename(profile!, value);
    } else if (profile == null) {
      await controller.createProfile(value);
    } else {
      await controller.clone(profile, value);
    }
  }

  Future<void> _delete(BuildContext context, ProfileInfo profile) async {
    final selected = controller.workspace?.selectedProfile?.id == profile.id;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => McFormDialog(
        title: 'Delete ${profile.name}?',
        action: 'Delete profile',
        onSubmit: selected ? null : () => Navigator.pop(context, true),
        children: [
          const Text(
            'This permanently removes this profile and its private settings and saves. Installed mods and other profiles stay unchanged.',
          ),
          if (selected) ...[
            const SizedBox(height: McSpacing.large),
            const McStatus(title: 'Select another profile before deletion.'),
          ],
        ],
      ),
    );
    if (confirmed == true) {
      await controller.delete(profile);
      if (mounted &&
          controller.currentProblem == null &&
          !controller.page!.profiles.any((row) => row.id == profile.id)) {
        _profiles.apply(removed: [(profileId: profile.id)]);
      }
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) =>
        controller.workspace == null ? _entry(context) : _workspace(context),
  );

  WorkspaceHelpActions _helpActions(
    BuildContext context,
    WorkspaceInfo? workspace,
  ) {
    final canChooseWorkspace =
        controller.connected && controller.activity == null;
    return WorkspaceHelpActions(
      createWorkspace: canChooseWorkspace
          ? () => unawaited(_workspaceDialog(context, true))
          : null,
      openWorkspace: canChooseWorkspace
          ? () => unawaited(_workspaceDialog(context, false))
          : null,
      createProfile: workspace == null || !controller.canEdit
          ? null
          : () => unawaited(_profileDialog(context)),
    );
  }

  Widget _help(BuildContext context, WorkspaceInfo? workspace) =>
      widget.helpBuilder!(context, workspace, _helpActions(context, workspace));

  Widget _entry(BuildContext context) {
    final workspaces = _workspaceEntry(context);
    final help = widget.entryHelpBuilder ?? widget.helpBuilder;
    if (help == null) return workspaces;
    return IndexedStack(
      index: _entryHelp ? 1 : 0,
      children: [
        ExcludeFocus(excluding: _entryHelp, child: workspaces),
        ExcludeFocus(
          excluding: !_entryHelp,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: McAction(
                    key: const ValueKey('close-entry-help'),
                    label: 'Workspaces',
                    icon: Icons.arrow_back,
                    onPressed: () => setState(() => _entryHelp = false),
                  ),
                ),
                const SizedBox(height: McSpacing.medium),
                Expanded(
                  child: help(context, null, _helpActions(context, null)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _workspaceEntry(BuildContext context) => McPage(
    title: 'Workspaces',
    children: [
      Wrap(
        spacing: McSpacing.medium,
        runSpacing: McSpacing.medium,
        children: [
          McAction(
            key: const ValueKey('create-workspace'),
            focusNode: _createWorkspaceFocus,
            label: 'Create workspace',
            icon: Icons.add,
            emphasis: McActionEmphasis.primary,
            onPressed: controller.connected && controller.activity == null
                ? () => _workspaceDialog(context, true)
                : null,
          ),
          McAction(
            key: const ValueKey('open-workspace'),
            focusNode: _openWorkspaceFocus,
            label: 'Open workspace',
            icon: Icons.folder_open,
            onPressed: controller.connected && controller.activity == null
                ? () => _workspaceDialog(context, false)
                : null,
          ),
          if (widget.entryHelpBuilder != null || widget.helpBuilder != null)
            McAction(
              key: const ValueKey('open-entry-help'),
              focusNode: _helpFocus,
              label: 'Help',
              icon: Icons.help_center_outlined,
              onPressed: () => setState(() => _entryHelp = true),
            ),
        ],
      ),
      const SizedBox(height: McSpacing.large),
      McSection(
        title: 'Saved workspaces',
        children: [
          if (controller.recent.isEmpty) const Text('No saved workspaces.'),
          for (final workspace in controller.recent)
            Material(
              color: Colors.transparent,
              child: ListTile(
                key: ValueKey('workspace-${workspace.id}'),
                leading: const Icon(Icons.folder_outlined),
                title: Text(workspace.name),
                subtitle: Text(workspace.path),
                enabled: controller.connected,
                onTap: () => unawaited(controller.open(workspace.path)),
              ),
            ),
          if (controller.nextWorkspace != null)
            McAction(
              label: 'More workspaces',
              onPressed: () => unawaited(controller.loadRecent(more: true)),
            ),
        ],
      ),
      const SizedBox(height: McSpacing.medium),
      if (!controller.connected)
        const McStatus(title: 'The engine is not connected.'),
      if (controller.activity != null)
        McActionFeedback(
          kind: McActionFeedbackKind.pending,
          message: controller.activity!,
        ),
      if (controller.currentProblem != null) ...[
        McActionFeedback(
          kind: McActionFeedbackKind.failure,
          message: controller.currentProblem!,
        ),
        const SizedBox(height: McSpacing.medium),
        McAction(
          label: 'Refresh',
          onPressed: controller.connected
              ? () => unawaited(controller.loadRecent())
              : null,
        ),
      ],
    ],
  );

  Widget _workspace(BuildContext context) {
    final workspace = controller.workspace!;
    final current = workspace.selectedProfile;
    final ready = current == null || widget.workbenchReady;
    final mode = switch (_mode) {
      _WorkspaceMode.mods when widget.modLibraryBuilder == null =>
        _WorkspaceMode.profiles,
      _WorkspaceMode.game when widget.gameContextBuilder == null =>
        _WorkspaceMode.profiles,
      _WorkspaceMode.tools when widget.executableBuilder == null =>
        _WorkspaceMode.profiles,
      _WorkspaceMode.archives when widget.artifactBuilder == null =>
        _WorkspaceMode.profiles,
      _WorkspaceMode.help when widget.helpBuilder == null =>
        _WorkspaceMode.profiles,
      final available => available,
    };
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 24,
            runSpacing: 12,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workspace.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    workspace.path,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  Tooltip(
                    message:
                        'Current profile: ${current?.name ?? 'none'}. Open profiles',
                    child: McAction(
                      label: current?.name ?? 'Profiles',
                      icon: Icons.person_outline,
                      onPressed: ready
                          ? () =>
                                setState(() => _mode = _WorkspaceMode.profiles)
                          : null,
                    ),
                  ),
                  if (ready) ...?widget.headerActions?.call(context, workspace),
                  if (widget.openFolder != null)
                    McAction(
                      key: const ValueKey('open-workspace-folder'),
                      label: 'Open folder',
                      icon: Icons.folder_open,
                      onPressed: _openingFolder
                          ? null
                          : () => unawaited(_openFolder()),
                    ),
                  if (widget.compactCloseAction)
                    McIconAction(
                      key: const ValueKey('close-workspace'),
                      label: 'Close workspace',
                      icon: const Icon(Icons.close),
                      onPressed: controller.close,
                    )
                  else
                    McAction(
                      key: const ValueKey('close-workspace'),
                      label: 'Close workspace',
                      icon: Icons.close,
                      onPressed: controller.close,
                    ),
                  if (controller.needsCheck)
                    McAction(
                      key: const ValueKey('check-workspace'),
                      label: 'Check again',
                      onPressed:
                          controller.connected && controller.activity == null
                          ? () => unawaited(controller.check())
                          : null,
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!ready && widget.profileSetupBuilder != null)
            Expanded(
              child: widget.profileSetupBuilder!(context, workspace, current),
            )
          else ...[
            if (widget.modLibraryBuilder != null ||
                widget.gameContextBuilder != null ||
                widget.executableBuilder != null ||
                widget.artifactBuilder != null ||
                widget.helpBuilder != null) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<_WorkspaceMode>(
                    segments: [
                      ButtonSegment(
                        value: _WorkspaceMode.profiles,
                        label: Text(
                          'Profiles',
                          key: ValueKey('workspace-profiles-tab'),
                        ),
                        icon: Icon(Icons.people_outline),
                      ),
                      if (widget.modLibraryBuilder != null)
                        ButtonSegment(
                          value: _WorkspaceMode.mods,
                          label: Text(
                            'Mods',
                            key: ValueKey('workspace-mods-tab'),
                          ),
                          icon: Icon(Icons.layers_outlined),
                        ),
                      if (widget.gameContextBuilder != null)
                        ButtonSegment(
                          value: _WorkspaceMode.game,
                          label: Text(
                            'Game',
                            key: ValueKey('workspace-game-tab'),
                          ),
                          icon: Icon(Icons.videogame_asset_outlined),
                        ),
                      if (widget.executableBuilder != null)
                        ButtonSegment(
                          value: _WorkspaceMode.tools,
                          label: Text(
                            'Tools',
                            key: ValueKey('workspace-tools-tab'),
                          ),
                          icon: Icon(Icons.terminal),
                        ),
                      if (widget.artifactBuilder != null)
                        ButtonSegment(
                          value: _WorkspaceMode.archives,
                          label: Text(
                            'Archives',
                            key: ValueKey('workspace-archives-tab'),
                          ),
                          icon: Icon(Icons.inventory_2_outlined),
                        ),
                      if (widget.helpBuilder != null)
                        ButtonSegment(
                          value: _WorkspaceMode.help,
                          label: Text(
                            'Help',
                            key: ValueKey('workspace-help-tab'),
                          ),
                          icon: Icon(Icons.help_center_outlined),
                        ),
                    ],
                    selected: {mode},
                    onSelectionChanged: (value) =>
                        setState(() => _mode = value.single),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Expanded(
              child: IndexedStack(
                index: mode.index,
                children: [
                  ExcludeFocus(
                    excluding: mode != _WorkspaceMode.profiles,
                    child: _profilesSurface(context),
                  ),
                  if (widget.modLibraryBuilder != null)
                    ExcludeFocus(
                      excluding: mode != _WorkspaceMode.mods,
                      child: widget.modLibraryBuilder!(context, workspace),
                    )
                  else
                    const SizedBox.shrink(),
                  if (widget.gameContextBuilder != null)
                    ExcludeFocus(
                      excluding: mode != _WorkspaceMode.game,
                      child: widget.gameContextBuilder!(context, workspace),
                    )
                  else
                    const SizedBox.shrink(),
                  if (widget.executableBuilder != null)
                    ExcludeFocus(
                      excluding: mode != _WorkspaceMode.tools,
                      child: widget.executableBuilder!(context, workspace),
                    )
                  else
                    const SizedBox.shrink(),
                  if (widget.artifactBuilder != null)
                    ExcludeFocus(
                      excluding: mode != _WorkspaceMode.archives,
                      child: widget.artifactBuilder!(
                        context,
                        workspace,
                        () => setState(() => _mode = _WorkspaceMode.mods),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  if (widget.helpBuilder != null)
                    ExcludeFocus(
                      excluding: mode != _WorkspaceMode.help,
                      child: _help(context, workspace),
                    )
                  else
                    const SizedBox.shrink(),
                ],
              ),
            ),
          ],
          if (controller.needsCheck && controller.activity == null) ...[
            const SizedBox(height: 12),
            McActionFeedback(
              kind: McActionFeedbackKind.refusal,
              message: switch (workspace.pendingRoot?.reason) {
                WorkspaceRootIssueReason.ownershipUnproved => 'Mod Conductor cannot verify this workspace. Choose another folder for a new workspace.',
                WorkspaceRootIssueReason.identityUnverified =>
                  'Mod Conductor cannot verify this workspace.',
                WorkspaceRootIssueReason.incompleteCreation ||
                null => 'Workspace creation did not finish.',
              },
            ),
          ],
          if (controller.activity != null) ...[
            const SizedBox(height: 12),
            McActionFeedback(
              kind: McActionFeedbackKind.pending,
              message: controller.activity!,
              detail: controller.copyProgress == null
                  ? null
                  : '${controller.copyProgress!.files} files · ${controller.copyProgress!.bytes} bytes copied',
            ),
            if (controller.canCancelProfileChange)
              McAction(
                label: 'Cancel',
                onPressed: () => unawaited(controller.cancelProfileChange()),
              ),
          ],
          if (controller.currentProblem != null) ...[
            const SizedBox(height: 12),
            McActionFeedback(
              kind: McActionFeedbackKind.failure,
              message: controller.currentProblem!,
            ),
          ],
          if (_openingFolder || _folderProblem) ...[
            const SizedBox(height: 12),
            McActionFeedback(
              kind: _openingFolder
                  ? McActionFeedbackKind.pending
                  : McActionFeedbackKind.failure,
              message: _openingFolder
                  ? 'Opening workspace folder'
                  : 'The workspace folder did not open.',
            ),
          ],
        ],
      ),
    );
  }

  Widget _profilesSurface(BuildContext context) => ListenableBuilder(
    listenable: _profiles,
    builder: (context, _) => LayoutBuilder(
      builder: (context, constraints) {
        final selected = _profiles.selected;
        _compactProfileActions =
            constraints.maxHeight <
            420 * MediaQuery.textScalerOf(context).scale(1);
        _compactProfile =
            constraints.maxWidth <
            1100 * MediaQuery.textScalerOf(context).scale(1);
        Widget inspector() {
          final profile = selected!;
          _inspectedProfileId = profile.id;
          return widget.profileInspectorBuilder!(
            context,
            controller.workspace!,
            profile,
            _closeProfileInspector,
            (guard) => _bindProfileNavigation(profile.id, guard),
          );
        }

        return Scaffold(
          key: _profilePane,
          backgroundColor: Colors.transparent,
          endDrawer:
              _compactProfile &&
                  selected != null &&
                  widget.profileInspectorBuilder != null
              ? PopScope(
                  canPop:
                      _allowProfileDrawerClose ||
                      _profileNavigationGuard == null,
                  onPopInvokedWithResult: (didPop, _) {
                    if (!didPop) _guardProfileDrawerClose();
                  },
                  child: Drawer(width: 440, child: inspector()),
                )
              : null,
          onEndDrawerChanged: _profileDrawerChanged,
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _profileCollection(context)),
              if (!_compactProfile &&
                  _inspected &&
                  selected != null &&
                  widget.profileInspectorBuilder != null) ...[
                const SizedBox(width: 16),
                SizedBox(width: 390, child: inspector()),
              ],
            ],
          ),
        );
      },
    ),
  );

  Widget _profileCollection(BuildContext context) => ListenableBuilder(
    listenable: _profiles,
    builder: (context, _) {
      final selected = _profiles.selected;
      final current = controller.workspace?.selectedProfile;
      final incomplete = controller.page!.nextProfile != null;
      return Column(
        children: [
          Expanded(
            child: McCollection<ProfileRowId, ProfileInfo>(
              model: _profiles,
              title: 'Profiles',
              showTitle: !_compactProfileActions,
              filterActions: [
                if (_compactProfileActions)
                  McIconAction(
                    key: const ValueKey('create-profile'),
                    focusNode: _createProfileFocus,
                    label: 'Create profile',
                    icon: const Icon(Icons.add),
                    onPressed: controller.canEdit
                        ? () => _profileDialog(context)
                        : null,
                  ),
              ],
              focusNode: _profilesFocus,
              filterLabel: incomplete
                  ? 'Filter loaded profiles'
                  : 'Filter profiles',
              countLabel:
                  '${_profiles.length} ${_profiles.length == 1 ? 'profile' : 'profiles'}${incomplete ? ' loaded' : ''}',
              empty: 'No profiles.',
              onSelect: _selectProfile,
              onLoad: incomplete && controller.canEdit
                  ? () => unawaited(controller.moreProfiles())
                  : null,
              onRefresh: controller.connected && controller.activity == null
                  ? () => unawaited(controller.refresh())
                  : null,
              semanticLabel: (row) =>
                  '${row.name}${row.id == current?.id ? ', current profile' : ''}',
              actions: [
                if (!_compactProfileActions)
                  McAction(
                    key: const ValueKey('create-profile'),
                    focusNode: _createProfileFocus,
                    label: 'Create profile',
                    icon: Icons.add,
                    emphasis: McActionEmphasis.primary,
                    onPressed: controller.canEdit
                        ? () => _profileDialog(context)
                        : null,
                  ),
              ],
              columns: [
                McColumn(
                  'Name',
                  (row) =>
                      McCollectionName(row.name, icon: Icons.person_outline),
                  compare: (a, b) => a.name.compareTo(b.name),
                ),
                McColumn(
                  'Status',
                  (row) => Text(row.id == current?.id ? 'Current' : ''),
                  width: 120,
                ),
                McColumn(
                  '',
                  (row) => McIconMenu<_ProfileAction>(
                    key: ValueKey('profile-menu-${row.id}'),
                    label: 'Options for ${row.name}',
                    enabled: controller.canEdit,
                    onSelected: (action) {
                      _selectProfile(row, () {
                        switch (action) {
                          case _ProfileAction.clone:
                            unawaited(_profileDialog(context, profile: row));
                          case _ProfileAction.rename:
                            unawaited(
                              _profileDialog(
                                context,
                                profile: row,
                                rename: true,
                              ),
                            );
                          case _ProfileAction.delete:
                            unawaited(_delete(context, row));
                        }
                      });
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: _ProfileAction.clone,
                        child: Text('Clone'),
                      ),
                      PopupMenuItem(
                        value: _ProfileAction.rename,
                        child: Text('Rename'),
                      ),
                      PopupMenuItem(
                        value: _ProfileAction.delete,
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                  width: 42,
                  interactive: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 12,
              children: [
                Text(
                  selected?.name ?? 'No profile selected',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (widget.profileInspectorBuilder != null)
                  McAction(
                    label: 'Settings and saves',
                    icon: Icons.tune,
                    onPressed: selected == null ? null : _inspectProfile,
                  ),
                McAction(
                  key: const ValueKey('use-profile'),
                  label: 'Use profile',
                  icon: Icons.check,
                  emphasis: McActionEmphasis.primary,
                  onPressed:
                      controller.canEdit &&
                          selected != null &&
                          selected.id != current?.id
                      ? () => unawaited(controller.select(selected))
                      : null,
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
}
