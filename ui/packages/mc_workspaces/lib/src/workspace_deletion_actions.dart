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

  Widget _workspaceOptions(BuildContext context, WorkspaceInfo workspace) =>
      McIconMenu<String>(
        label: 'Options for ${workspace.name}',
        enabled: controller.connected && controller.activity == null,
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'delete', child: Text('Delete workspace')),
        ],
        onSelected: (_) => unawaited(_deleteWorkspace(context, workspace)),
      );
}
