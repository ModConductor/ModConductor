part of 'app.dart';

class _MigrationSettingsSection extends StatelessWidget {
  const _MigrationSettingsSection({
    required this.workspace,
    required this.client,
    required this.chooseDirectory,
    required this.onComplete,
  });

  final WorkspaceInfo? workspace;
  final MigrationClient? client;
  final SourceDirectoryChooser chooseDirectory;
  final Future<void> Function() onComplete;

  @override
  Widget build(BuildContext context) => McSection(
    title: 'Migration',
    children: [
      Text(
        workspace == null
            ? 'Open a workspace to migrate.'
            : 'Workspace: ${workspace!.name}',
      ),
      const SizedBox(height: 12),
      if (workspace != null && client != null)
        MigrationAction(
          client: client!,
          workspaceId: workspace!.id,
          chooseDirectory: chooseDirectory,
          onComplete: onComplete,
        )
      else
        const McAction(
          label: 'Migrate from another manager',
          icon: Icons.move_to_inbox_outlined,
          onPressed: null,
        ),
    ],
  );
}
