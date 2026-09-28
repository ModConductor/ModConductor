part of 'app.dart';

mixin _ProfileTransportFlow on _AppStateBase, _ProfileCreation {
  Future<CreatedProfileWorkspace?> _createImportWorkspace(
    BuildContext context,
  ) async {
    final chosen = await showDialog<({String name, String? path})>(
      context: context,
      builder: (_) => WorkspaceDialog(
        create: true,
        chooseDirectory: widget.chooseDirectory,
      ),
    );
    if (chosen == null || !context.mounted) return null;
    await _workspaces.create(chosen.name, chosen.path);
    final workspace = _workspaces.workspace;
    if (!context.mounted ||
        workspace == null ||
        _workspaces.currentProblem != null) {
      return null;
    }
    await _createProfile(context, workspace);
    if (!context.mounted || _workspaces.workspace?.id != workspace.id) {
      return null;
    }
    final gameProfile = _workspaces.workspace?.selectedProfile;
    if (gameProfile == null) return null;
    return (workspace: _workspaces.workspace!, gameProfile: gameProfile);
  }

  Future<void> _importProfilePath(BuildContext context, String path) async {
    final client = widget.profileTransport;
    final workspaceClient = widget.workspaces;
    final gameContexts = widget.gameContexts;
    if (client == null || workspaceClient == null || gameContexts == null) {
      return;
    }
    final imported = await showDialog<ProfileImportResult>(
      context: context,
      builder: (_) => ProfileImportDialog(
        path: path,
        client: client,
        workspaces: _workspaces,
        workspaceClient: workspaceClient,
        gameContexts: gameContexts,
        createWorkspace: _createImportWorkspace,
      ),
    );
    if (!context.mounted || imported == null) return;
    if (_workspaces.workspace?.id != imported.workspace.id) {
      await _workspaces.open(imported.workspace.path);
    } else {
      await _workspaces.refresh();
    }
    if (!context.mounted ||
        _workspaces.workspace?.id != imported.workspace.id) {
      return;
    }
    final profile = _workspaces.page?.profiles
        .where((value) => value.id == imported.profile)
        .firstOrNull;
    if (profile != null) await _workspaces.select(profile);
    _navigate(_Destination.workspaces);
    unawaited(_mods.inventory.refreshCatalogue());
    _files.invalidate();
    _profileData.invalidate();
  }

  Future<void> _openProfileImport(BuildContext context) async {
    final path = await desktop.chooseProfileFile();
    if (path != null && context.mounted) {
      await _importProfilePath(context, path);
    }
  }

  Future<void> _openProfileExport(
    BuildContext context,
    WorkspaceInfo workspace,
    ProfileInfo profile,
  ) async {
    final client = widget.profileTransport;
    if (client == null) return;
    await showDialog<String>(
      context: context,
      builder: (_) => ProfileExportDialog(
        client: client,
        workspace: workspace,
        profile: profile,
        chooseDestination: desktop.chooseProfileDestination,
      ),
    );
  }
}
