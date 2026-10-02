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
    if (revision != _contextRevision) {
      _play.invalidate();
      _skseCheckEpoch++;
      _skseLaunchCheckStarted = false;
      final workspace = _workspaces.workspace;
      _skseProfilesWithoutInstall.remove(
        '${workspace?.id}:${workspace?.selectedProfile?.id}',
      );
    }
    _contextRevision = revision;
    _startSkseLaunchCheck();
    _syncCapabilityConsumers();
    if (mounted) setState(() {});
  }

  void _syncWorkspaceConsumers() {
    _gameCatalogue.attach(widget.gameCatalogue);
    final workspace = _workspaces.confirmedWorkspace;
    _game.attach(
      widget.gameContexts,
      workspaceId: workspace?.id,
      profileId: workspace?.selectedProfile?.id,
      editable: _workspaces.canEdit,
    );
    _startSkseLaunchCheck();
    _syncCapabilityConsumers();
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
    unawaited(
      _checkSkseUpdate(skse, workspace.id, profile.id, _skseCheckEpoch),
    );
  }

  Future<void> _checkSkseUpdate(
    SkseClient client,
    String workspaceId,
    String profileId,
    int epoch,
  ) async {
    try {
      final checked = await client.checkUpdate(workspaceId, profileId);
      if (!mounted || epoch != _skseCheckEpoch) return;
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
    final modded = _supportsGameMods;
    final bethesda = _supportsBethesda;
    final workspace = _workspaces.workspace;
    final profile = workspace?.selectedProfile;
    _play.attach(
      modded ? widget.gameLaunching : null,
      modded ? widget.executables : null,
      modded ? workspace : null,
      available: modded && _workspaces.canEdit,
      fnis: _supportsSkyrim ? widget.fnis : null,
    );
    _executables.attach(
      modded ? widget.executables : null,
      modded ? workspace : null,
      available: modded && _workspaces.canEdit,
    );
    _artifacts.attach(
      modded ? widget.artifacts : null,
      modded ? workspace?.id : null,
    );
    _nexusDetails.attach(
      bethesda ? widget.nexusMetadata : null,
      bethesda ? widget.nexus : null,
      bethesda ? workspace?.id : null,
      bethesda ? profile?.id : null,
    );
    _outputs.attach(
      modded ? widget.outputs : null,
      modded ? workspace?.id : null,
      profile: modded ? profile?.id : null,
      available: modded && _workspaces.canEdit,
    );
    _deployments.attach(
      modded ? widget.deployments : null,
      modded ? profile?.id : null,
      modded ? profile?.name : null,
      available: modded && _workspaces.canEdit,
    );
    _plugins.resumeAction = !bethesda || workspace == null || profile == null
        ? null
        : () => _profileData.resumeSelected(
            widget.profileData,
            workspace.id,
            profile.id,
            available: _workspaces.canEdit,
          );
    _plugins.attach(
      bethesda ? widget.bethesda : null,
      bethesda ? profile?.id : null,
      orders: bethesda ? widget.pluginOrders : null,
    );
    _sortOrder.attach(
      _supportsSkyrim ? widget.loot : null,
      _plugins,
      bethesda ? profile?.id : null,
    );
    _archives.definition = _game.state?.definition;
    _archives.resumeAction = _plugins.resumeAction;
    _archives.attach(
      bethesda ? widget.archivePolicies : null,
      _plugins,
      bethesda ? workspace?.id : null,
      bethesda ? profile?.id : null,
    );
    _files.attach(
      bethesda ? widget.filePlans : null,
      bethesda ? profile?.id : null,
      available: bethesda && _workspaces.canEdit,
    );
    _diagnosticInputsChanged();
    _mods.attach(
      modded ? widget.modLibrary : null,
      modded ? widget.profileMods : null,
      organizationClient: modded ? widget.modOrganization : null,
      workspaceId: modded ? workspace?.id : null,
      profileId: modded ? profile?.id : null,
      workspaceRevision: modded ? workspace?.revision : null,
      editable: modded && _workspaces.canEdit,
    );
    _watchSetup(
      _supportsSkyrim && widget.status is DesktopConnected
          ? widget.skyrimSetup
          : null,
      modded ? workspace?.id : null,
      modded ? profile?.id : null,
    );
  }
}
