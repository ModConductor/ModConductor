import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'controller.dart';
import 'workspace_dialog.dart';

enum _ProfileAction { clone, rename, delete }

class WorkspaceBrowser extends StatefulWidget {
  const WorkspaceBrowser({
    super.key,
    required this.controller,
    this.chooseDirectory = chooseWorkspaceDirectory,
  });
  final WorkspaceController controller;
  final DirectoryChooser chooseDirectory;

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

  @override
  void initState() {
    super.initState();
    controller.addListener(_navigationChanged);
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
    if (confirmed == true) await controller.delete(profile);
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
    final selected = workspace.selectedProfile;
    final profiles = [
      if (selected != null &&
          !controller.page!.profiles.any(
            (profile) => profile.id == selected.id,
          ))
        selected,
      ...controller.page!.profiles,
    ];
    return McPage(
      title: workspace.name,
      children: [
        SelectableText(
          workspace.path,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: McSpacing.medium),
        Wrap(
          spacing: McSpacing.medium,
          runSpacing: McSpacing.small,
          children: [
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
                onPressed: controller.connected && controller.activity == null
                    ? () => unawaited(controller.check())
                    : null,
              ),
            McAction(
              label: 'Refresh',
              icon: Icons.refresh,
              onPressed: controller.connected && controller.activity == null
                  ? () => unawaited(controller.refresh())
                  : null,
            ),
          ],
        ),
        if (controller.needsCheck && controller.activity == null) ...[
          const SizedBox(height: McSpacing.medium),
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
        const SizedBox(height: McSpacing.large),
        McSection(
          title: 'Profiles',
          children: [
            if (profiles.isEmpty) const Text('No profiles.'),
            for (final profile in profiles)
              _ProfileTile(
                profile: profile,
                selected: selected?.id == profile.id,
                enabled: controller.canEdit,
                onSelect: () => unawaited(controller.select(profile)),
                onAction: (action) => switch (action) {
                  _ProfileAction.clone => unawaited(
                    _profileDialog(context, profile: profile),
                  ),
                  _ProfileAction.rename => unawaited(
                    _profileDialog(context, profile: profile, rename: true),
                  ),
                  _ProfileAction.delete => unawaited(_delete(context, profile)),
                },
              ),
            if (controller.page!.nextProfile != null)
              McAction(
                label: 'More profiles',
                onPressed: controller.canEdit
                    ? () => unawaited(controller.moreProfiles())
                    : null,
              ),
          ],
        ),
        const SizedBox(height: McSpacing.medium),
        if (controller.activity != null)
          McStatus(title: '${controller.activity} in progress.'),
        if (controller.currentProblem != null)
          McStatus(title: controller.currentProblem!, tone: McStatusTone.error),
      ],
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.profile,
    required this.selected,
    required this.enabled,
    required this.onSelect,
    required this.onAction,
  });
  final ProfileInfo profile;
  final bool selected;
  final bool enabled;
  final VoidCallback onSelect;
  final ValueChanged<_ProfileAction> onAction;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Material(
      color: selected
          ? Theme.of(context).colorScheme.primary.withValues(alpha: .1)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              selected: selected,
              child: ListTile(
                key: ValueKey('profile-${profile.id}'),
                enabled: enabled,
                leading: Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                ),
                title: Text(profile.name),
                trailing: SizedBox(
                  width: 90,
                  child: selected ? const Text('Selected') : null,
                ),
                onTap: enabled ? onSelect : null,
              ),
            ),
          ),
          PopupMenuButton<_ProfileAction>(
            key: ValueKey('profile-menu-${profile.id}'),
            tooltip: 'Options for ${profile.name}',
            enabled: enabled,
            onSelected: onAction,
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: _ProfileAction.clone,
                child: Text('Clone'),
              ),
              const PopupMenuItem(
                value: _ProfileAction.rename,
                child: Text('Rename'),
              ),
              const PopupMenuItem(
                value: _ProfileAction.delete,
                child: Text('Delete'),
              ),
            ],
          ),
          const SizedBox(width: McSpacing.small),
        ],
      ),
    ),
  );
}
