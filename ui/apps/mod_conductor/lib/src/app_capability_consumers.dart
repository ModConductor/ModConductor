part of 'app.dart';

mixin _CapabilityConsumers on _AppStateBase, _SettingsScope, _WorkspaceScope {
  void _gameChanged() {
    final revision = _game.state?.revision;
    if (_contextRevision != null && revision != _contextRevision) {
      _plugins.invalidate();
      _archives.invalidate();
      _files.invalidate();
      _outputs.invalidate();
      _deployments.invalidate();
      _play.invalidate();
      _profileData.invalidate();
    }
    if (revision != _contextRevision) _play.invalidate();
    _contextRevision = revision;
    _startSkseLaunchCheck();
    _syncCapabilityConsumers();
    if (mounted) setState(() {});
  }

  void _syncWorkspaceConsumers() {
    _game.attach(
      widget.gameContexts,
      workspaceId: _workspaces.workspace?.id,
      profileId: _workspaces.workspace?.selectedProfile?.id,
      editable: _workspaces.canEdit,
    );
    _startSkseLaunchCheck();
    _syncCapabilityConsumers();
    final workspace = _workspaces.workspace;
    final profileId = workspace?.selectedProfile?.id;
    _syncInstallationScope(
      workspace?.id,
      profileId,
      widget.status is DesktopConnected ? widget.installations : null,
    );
    if (_settingsProfileId != profileId) {
      _settingsProfileId = profileId;
      _workspaceSettings.generation++;
      if (_settingsWorkspaceId == workspace?.id && workspace != null) {
        unawaited(_loadWorkspaceSettings(workspace.id, force: true));
      }
    }
    unawaited(_loadWorkspaceSettings(workspace?.id));
  }

  void _startSkseLaunchCheck() {
    final workspace = _workspaces.workspace;
    final profile = workspace?.selectedProfile;
    final skse = widget.skse;
    final profileKey = workspace == null || profile == null
        ? null
        : '${workspace.id}:${profile.id}';
    if (_skseLaunchCheckStarted ||
        widget.status is! DesktopConnected ||
        !_supportsSkyrim ||
        workspace == null ||
        profile == null ||
        _skseProfilesWithoutInstall.contains(profileKey) ||
        skse == null) {
      return;
    }
    _skseLaunchCheckStarted = true;
    unawaited(_checkSkseUpdate(skse, workspace.id, profile.id));
  }

  Future<void> _checkSkseUpdate(
    SkseClient client,
    String workspaceId,
    String profileId,
  ) async {
    try {
      final checked = await client.checkUpdate(workspaceId, profileId);
      if (checked.phase == SkseStatusPhase.available) {
        _skseProfilesWithoutInstall.add('$workspaceId:$profileId');
        _skseLaunchCheckStarted = false;
        _startSkseLaunchCheck();
        return;
      }
      if (checked.phase == SkseStatusPhase.unavailable) {
        _skseLaunchCheckStarted = false;
        if (_workspaces.workspace?.id != workspaceId ||
            _workspaces.workspace?.selectedProfile?.id != profileId) {
          _startSkseLaunchCheck();
        }
        return;
      }
    } on Exception {
      // The installed setup remains usable when the update check is unavailable.
    }
  }

  void _syncCapabilityConsumers() {
    final skyrim = _supportsSkyrim;
    final archives = _supportsArchives;
    final workspace = _workspaces.workspace;
    final profile = workspace?.selectedProfile;
    _play.attach(
      skyrim ? widget.gameLaunching : null,
      skyrim ? widget.executables : null,
      skyrim ? workspace : null,
      available: skyrim && _workspaces.canEdit,
      fnis: skyrim ? widget.fnis : null,
    );
    _executables.attach(
      skyrim ? widget.executables : null,
      skyrim ? workspace : null,
      available: skyrim && _workspaces.canEdit,
    );
    _artifacts.attach(
      archives ? widget.artifacts : null,
      archives ? workspace?.id : null,
    );
    _nexusDetails.attach(
      skyrim ? widget.nexusMetadata : null,
      skyrim ? widget.nexus : null,
      skyrim ? workspace?.id : null,
      skyrim ? profile?.id : null,
    );
    _outputs.attach(
      skyrim ? widget.outputs : null,
      skyrim ? workspace?.id : null,
      profile: skyrim ? profile?.id : null,
      available: skyrim && _workspaces.canEdit,
    );
    _deployments.attach(
      skyrim ? widget.deployments : null,
      skyrim ? profile?.id : null,
      skyrim ? profile?.name : null,
      available: skyrim && _workspaces.canEdit,
    );
    _plugins.resumeAction = !skyrim || workspace == null || profile == null
        ? null
        : () => _profileData.resumeSelected(
            widget.profileData,
            workspace.id,
            profile.id,
            available: _workspaces.canEdit,
          );
    _plugins.attach(
      skyrim ? widget.bethesda : null,
      skyrim ? profile?.id : null,
      orders: skyrim ? widget.pluginOrders : null,
    );
    _sortOrder.attach(
      skyrim ? widget.loot : null,
      _plugins,
      skyrim ? profile?.id : null,
    );
    _archives.resumeAction = _plugins.resumeAction;
    _archives.attach(
      skyrim ? widget.archivePolicies : null,
      _plugins,
      skyrim ? workspace?.id : null,
      skyrim ? profile?.id : null,
    );
    _files.attach(
      skyrim ? widget.filePlans : null,
      skyrim ? profile?.id : null,
      available: skyrim && _workspaces.canEdit,
    );
    _diagnosticInputsChanged();
    _mods.attach(
      skyrim ? widget.modLibrary : null,
      skyrim ? widget.profileMods : null,
      organizationClient: skyrim ? widget.modOrganization : null,
      workspaceId: skyrim ? workspace?.id : null,
      profileId: skyrim ? profile?.id : null,
      workspaceRevision: skyrim ? workspace?.revision : null,
      editable: skyrim && _workspaces.canEdit,
    );
    _watchSetup(
      skyrim && widget.status is DesktopConnected ? widget.skyrimSetup : null,
      skyrim ? workspace?.id : null,
      skyrim ? profile?.id : null,
    );
  }
}
