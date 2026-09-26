part of 'workspace_browser.dart';

extension _WorkspaceShell on _WorkspaceBrowserState {
  Future<void> _openFolder() async {
    final workspace = controller.workspace;
    final open = widget.openFolder;
    if (workspace == null || open == null || _openingFolder) return;
    _change(() {
      _openingFolder = true;
      _folderProblem = false;
    });
    final opened = await open(workspace.path);
    if (mounted) {
      _change(() {
        _openingFolder = false;
        _folderProblem = !opened;
      });
    }
  }

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
          _workspaceHeader(context, workspace, current, ready),
          const SizedBox(height: 16),
          ..._workspaceBody(context, workspace, current, ready, mode),
          ..._workspaceFeedback(workspace),
        ],
      ),
    );
  }

  Widget _workspaceHeader(
    BuildContext context,
    WorkspaceInfo workspace,
    ProfileInfo? current,
    bool ready,
  ) => Wrap(
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
                  ? () => _change(() => _mode = _WorkspaceMode.profiles)
                  : null,
            ),
          ),
          if (ready) ...?widget.headerActions?.call(context, workspace),
          if (widget.openFolder != null)
            McAction(
              key: const ValueKey('open-workspace-folder'),
              label: 'Open folder',
              icon: Icons.folder_open,
              onPressed: _openingFolder ? null : () => unawaited(_openFolder()),
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
              onPressed: controller.connected && controller.activity == null
                  ? () => unawaited(controller.check())
                  : null,
            ),
        ],
      ),
    ],
  );

  List<Widget> _workspaceFeedback(WorkspaceInfo workspace) => [
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
  ];
}
