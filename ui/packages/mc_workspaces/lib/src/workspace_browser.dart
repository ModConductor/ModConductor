import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'package:mc_ui_collections/mc_ui_collections.dart';

import 'controller.dart';
import 'workspace_dialog.dart';

typedef ProfileRowId = ({String profileId});

enum _ProfileAction { clone, rename, delete }

class WorkspaceBrowser extends StatefulWidget {
  const WorkspaceBrowser({
    super.key,
    required this.controller,
    this.chooseDirectory = chooseWorkspaceDirectory,
    this.modLibraryBuilder,
  });
  final WorkspaceController controller;
  final DirectoryChooser chooseDirectory;
  final Widget Function(BuildContext, WorkspaceInfo)? modLibraryBuilder;

  @override
  State<WorkspaceBrowser> createState() => _WorkspaceBrowserState();
}

class _WorkspaceBrowserState extends State<WorkspaceBrowser> {
  WorkspaceController get controller => widget.controller;
  DirectoryChooser get chooseDirectory => widget.chooseDirectory;
  final _createWorkspaceFocus = FocusNode(debugLabel: 'Create workspace');
  final _openWorkspaceFocus = FocusNode(debugLabel: 'Open workspace');
  final _createProfileFocus = FocusNode(debugLabel: 'Create profile');
  String? _shownId;
  bool _showMods = false;
  final _profilesFocus = FocusNode(debugLabel: 'Profiles');
  final _profiles = McCollectionModel<ProfileRowId, ProfileInfo>(
    idOf: (row) => (profileId: row.id),
    labelOf: (row) => row.name,
  );
  WorkspacePage? _shownPage;

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
      _showMods = false;
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
    super.dispose();
  }

  Future<void> _workspaceDialog(BuildContext context, bool create) async {
    (create ? _createWorkspaceFocus : _openWorkspaceFocus).requestFocus();
    final value = await showDialog<({String name, String path})>(
      context: context,
      builder: (_) =>
          WorkspaceDialog(create: create, chooseDirectory: chooseDirectory),
    );
    if (value == null) return;
    if (create) {
      await controller.create(value.name, value.path);
    } else {
      await controller.open(value.path);
    }
  }

  Future<void> _profileDialog(
    BuildContext context, {
    ProfileInfo? profile,
    bool rename = false,
  }) async {
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
            'This permanently removes this profile. Installed mods and other profiles stay unchanged.',
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

  Widget _entry(BuildContext context) => McPage(
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
        McStatus(title: '${controller.activity} in progress.'),
      if (controller.currentProblem != null) ...[
        McStatus(title: controller.currentProblem!, tone: McStatusTone.error),
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
                      onPressed: () => setState(() => _showMods = false),
                    ),
                  ),
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
          if (widget.modLibraryBuilder != null) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text('Profiles'),
                    icon: Icon(Icons.people_outline),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('Mods'),
                    icon: Icon(Icons.layers_outlined),
                  ),
                ],
                selected: {_showMods},
                onSelectionChanged: (value) =>
                    setState(() => _showMods = value.single),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Expanded(
            child: IndexedStack(
              index: _showMods && widget.modLibraryBuilder != null ? 1 : 0,
              children: [
                ExcludeFocus(
                  excluding: _showMods,
                  child: _profilesSurface(context),
                ),
                if (widget.modLibraryBuilder != null)
                  ExcludeFocus(
                    excluding: !_showMods,
                    child: widget.modLibraryBuilder!(context, workspace),
                  ),
              ],
            ),
          ),
          if (controller.needsCheck && controller.activity == null) ...[
            const SizedBox(height: 12),
            McStatus(
              title: switch (workspace.pendingRoot?.reason) {
                WorkspaceRootIssueReason.ownershipUnproved => 'Mod Conductor cannot verify this workspace. Choose another folder for a new workspace.',
                WorkspaceRootIssueReason.identityUnverified =>
                  'Mod Conductor cannot verify this workspace.',
                WorkspaceRootIssueReason.incompleteCreation ||
                null => 'Workspace creation did not finish.',
              },
              tone: McStatusTone.error,
            ),
          ],
          if (controller.activity != null) ...[
            const SizedBox(height: 12),
            McStatus(title: '${controller.activity} in progress.'),
          ],
          if (controller.currentProblem != null) ...[
            const SizedBox(height: 12),
            McStatus(
              title: controller.currentProblem!,
              tone: McStatusTone.error,
            ),
          ],
        ],
      ),
    );
  }

  Widget _profilesSurface(BuildContext context) => ListenableBuilder(
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
              focusNode: _profilesFocus,
              filterLabel: incomplete
                  ? 'Filter loaded profiles'
                  : 'Filter profiles',
              countLabel:
                  '${_profiles.length} ${_profiles.length == 1 ? 'profile' : 'profiles'}${incomplete ? ' loaded' : ''}',
              empty: 'No profiles.',
              onLoad: incomplete && controller.canEdit
                  ? () => unawaited(controller.moreProfiles())
                  : null,
              onRefresh: controller.connected && controller.activity == null
                  ? () => unawaited(controller.refresh())
                  : null,
              semanticLabel: (row) =>
                  '${row.name}${row.id == current?.id ? ', current profile' : ''}',
              actions: [
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
                  (row) => PopupMenuButton<_ProfileAction>(
                    key: ValueKey('profile-menu-${row.id}'),
                    tooltip: 'Options for ${row.name}',
                    enabled: controller.canEdit,
                    onSelected: (action) {
                      _profiles.select((profileId: row.id));
                      _profilesFocus.requestFocus();
                      switch (action) {
                        case _ProfileAction.clone:
                          unawaited(_profileDialog(context, profile: row));
                        case _ProfileAction.rename:
                          unawaited(
                            _profileDialog(context, profile: row, rename: true),
                          );
                        case _ProfileAction.delete:
                          unawaited(_delete(context, row));
                      }
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
