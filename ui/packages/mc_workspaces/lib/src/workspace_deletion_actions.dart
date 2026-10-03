part of 'workspace_browser.dart';

extension _WorkspaceDeletionActions on _WorkspaceBrowserState {
  Future<void> _deleteWorkspace(
    BuildContext context,
    WorkspaceInfo workspace,
  ) => showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) =>
        WorkspaceDeletionDialog(controller: controller, workspace: workspace),
  );

  Widget _workspaceOptions(BuildContext context, WorkspaceInfo workspace) {
    final canOpenFolder = widget.openFolder != null && !_openingFolder;
    final canDelete = controller.connected && controller.activity == null;
    return McIconMenu<String>(
      label: 'Options for ${workspace.name}',
      enabled: canOpenFolder || canDelete,
      itemBuilder: (_) => [
        if (widget.openFolder != null)
          PopupMenuItem(
            value: 'folder',
            enabled: canOpenFolder,
            child: const Text('Open folder'),
          ),
        PopupMenuItem(
          value: 'delete',
          enabled: canDelete,
          child: const Text('Delete workspace'),
        ),
      ],
      onSelected: (value) => unawaited(
        value == 'folder'
            ? _openFolder()
            : _deleteWorkspace(context, workspace),
      ),
    );
  }
}
