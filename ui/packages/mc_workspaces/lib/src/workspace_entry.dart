part of 'workspace_browser.dart';

extension _WorkspaceEntry on _WorkspaceBrowserState {
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
                    onPressed: () => _change(() => _entryHelp = false),
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
              onPressed: () => _change(() => _entryHelp = true),
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
}
