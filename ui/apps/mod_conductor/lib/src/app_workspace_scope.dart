part of 'app.dart';

mixin _WorkspaceScope on _AppStateBase, _SettingsScope {
  bool _deletionScopeMatches(String workspaceId, String profileId) =>
      _workspaces.workspace?.id == workspaceId &&
      _workspaces.workspace?.selectedProfile?.id == profileId &&
      _deployments.profileId == profileId;

  Future<String?> _deactivateGameFilesForDeletion(String workspaceId) async {
    final workspace = _workspaces.workspace;
    final profile = workspace?.selectedProfile;
    if (workspace?.id != workspaceId || profile == null) {
      return 'The selected workspace changed. Open the mod again.';
    }
    if (!_deployments.connected || _deployments.profileId != profile.id) {
      return 'The deployment is unavailable.';
    }
    if (_deployments.busy || _deployments.reading) {
      return 'Finish the current deployment operation and try again.';
    }
    if (_deployments.needsRead || _deployments.state == null) {
      await _deployments.read();
    }
    if (!_deletionScopeMatches(workspaceId, profile.id)) {
      return 'The selected profile changed. Open the mod again.';
    }
    if (!_deployments.canPrepare) {
      return _deployments.problem ?? 'The deployment cannot be changed.';
    }
    if (_deployments.state?.workspaceId != workspaceId) {
      return 'The deployment belongs to another workspace.';
    }
    final active = _deployments.state?.active;
    if (active == null || (active.known && active.profile == null)) return null;
    if (!active.known || active.profile?.id != profile.id) {
      return 'Another profile has active game files. Select that profile and delete the mod again.';
    }
    await _deployments.prepare(retained: true);
    if (!_deletionScopeMatches(workspaceId, profile.id)) {
      return 'The selected profile changed. Open the mod again.';
    }
    if (!_deployments.canDeploy || _deployments.prepared?.profile != null) {
      return _deployments.problem ?? 'Game files could not be deactivated.';
    }
    await _deployments.activate();
    if (!_deletionScopeMatches(workspaceId, profile.id)) {
      return 'The selected profile changed. Open the mod again.';
    }
    final after = _deployments.state?.active;
    if (_deployments.problem != null ||
        _deployments.needsRead ||
        after == null ||
        !after.known ||
        after.profile != null) {
      return _deployments.problem ??
          'Check the deployment before deleting the mod.';
    }
    return null;
  }

  bool get _gameReady {
    final state = _game.state;
    final binding = state?.binding;
    return state?.definition != null &&
        binding != null &&
        !binding.needsCheck &&
        binding.failure == null &&
        binding.evidence.problems.isEmpty &&
        (binding.evidence.platform != GameContextPlatform.proton ||
            binding.proton != null);
  }

  bool _supports(GameCapabilityId id) {
    if (!_gameReady) return false;
    final state = _game.state!;
    final definition = state.definition!;
    final platform = state.binding!.evidence.platform;
    final capability = definition.capability(id);
    return capability?.disposition == GameCapabilityDisposition.available &&
        capability!.supports(definition.id, platform);
  }

  bool get _supportsSkyrim => _supports(GameCapabilityId.skyrimSpecialEdition);
  bool get _supportsArchives => _supports(GameCapabilityId.archiveInspection);
  bool get _supportsInstallation =>
      _supports(GameCapabilityId.gameInstallationValidation);

  void _modsChanged() {
    if ((_selectionRevision != null &&
            _selectionRevision != _mods.inventory.revision) ||
        (_catalogueRevision != null &&
            _catalogueRevision != _mods.inventory.catalogueRevision)) {
      _plugins.invalidate();
      _archives.invalidate();
      _deployments.invalidate();
      _play.invalidate();
    }
    _selectionRevision = _mods.inventory.revision;
    _catalogueRevision = _mods.inventory.catalogueRevision;
  }

  void _outputsChanged() {
    _plugins.invalidate();
    _archives.invalidate();
    _files.invalidate();
    _deployments.invalidate();
    unawaited(_mods.inventory.refreshCatalogue());
  }

  void _deploymentChanged() {
    _plugins.invalidate();
    _archives.invalidate();
    _files.invalidate();
    _outputs.invalidate();
    _diagnosticInputsChanged();
  }

  void _setupSettled() {
    unawaited(_mods.inventory.refreshCatalogue());
    _deployments.invalidate();
    _deploymentChanged();
    _play.invalidate();
    _profileData.invalidate();
  }

  Future<void> _installationCommitted(String workspace, String? profile) async {
    if (_installationWorkspace != workspace ||
        _installationProfile != profile) {
      return;
    }
    await _mods.inventory.refreshCatalogue();
    if (!mounted ||
        _installationWorkspace != workspace ||
        _installationProfile != profile) {
      return;
    }
    _deploymentChanged();
    _play.invalidate();
    _profileData.invalidate();
  }

  void _syncInstallationScope(
    String? workspace,
    String? profile,
    InstallationsClient? client,
  ) {
    if (_installationWorkspace == workspace &&
        _installationProfile == profile &&
        identical(_installationClient, client)) {
      return;
    }
    _installationWorkspace = workspace;
    _installationProfile = profile;
    _installationClient = client;
    ++_installationEpoch;
    for (final watch in _detachedInstallations.values) {
      unawaited(watch.cancel());
    }
    _detachedInstallations.clear();
    for (final retry in _installationRetries.values) {
      retry.cancel();
    }
    _installationRetries.clear();
  }

  void _observeDetachedInstallation(
    InstallationsClient client,
    InstallationStatus status,
    String? profile,
  ) {
    final workspace = status.workspaceId;
    if (!mounted ||
        _installationWorkspace != workspace ||
        _installationProfile != profile ||
        !identical(_installationClient, client) ||
        _detachedInstallations.containsKey(status.id) ||
        _installationRetries.containsKey(status.id)) {
      return;
    }
    final epoch = _installationEpoch;
    void observe(InstallationStatus last) {
      if (!mounted || epoch != _installationEpoch) return;
      _detachedInstallations[status.id] = client
          .watch(last)
          .listen(
            (next) {
              if (!mounted || epoch != _installationEpoch) return;
              if (next.phase == InstallationPhase.running) return;
              unawaited(
                _detachedInstallations.remove(status.id)?.cancel() ??
                    Future.value(),
              );
              _installationRetries.remove(status.id)?.cancel();
              if (next.phase == InstallationPhase.complete) {
                unawaited(_installationCommitted(workspace, profile));
              }
            },
            onError: (Object _) {
              if (!mounted || epoch != _installationEpoch) return;
              unawaited(
                _detachedInstallations.remove(status.id)?.cancel() ??
                    Future.value(),
              );
              _installationRetries[status.id] = Timer(
                const Duration(seconds: 1),
                () {
                  _installationRetries.remove(status.id);
                  observe(last);
                },
              );
            },
            onDone: () {
              if (!mounted ||
                  epoch != _installationEpoch ||
                  !_detachedInstallations.containsKey(status.id)) {
                return;
              }
              _detachedInstallations.remove(status.id);
              _installationRetries[status.id] = Timer(
                const Duration(seconds: 1),
                () {
                  _installationRetries.remove(status.id);
                  observe(last);
                },
              );
            },
            cancelOnError: true,
          );
    }

    observe(status);
  }

  void _installationReattached(InstallationStatus status, String? profile) {
    if (_installationWorkspace != status.workspaceId ||
        _installationProfile != profile) {
      return;
    }
    unawaited(
      _detachedInstallations.remove(status.id)?.cancel() ?? Future.value(),
    );
    _installationRetries.remove(status.id)?.cancel();
  }

  void _watchSetup(
    SkyrimSetupClient? client,
    String? workspace,
    String? profile, {
    bool retry = false,
  }) {
    if (!retry &&
        identical(_setupEventClient, client) &&
        _setupEventWorkspace == workspace &&
        _setupEventProfile == profile) {
      return;
    }
    final epoch = ++_setupEventEpoch;
    _setupReconnect?.cancel();
    unawaited(_setupEvents?.cancel() ?? Future.value());
    _setupEventClient = client;
    _setupEventWorkspace = workspace;
    _setupEventProfile = profile;
    if (!retry) _observedSetup = null;
    if (client == null || workspace == null || profile == null) return;
    var first = true;
    void reconnect() {
      if (!mounted || epoch != _setupEventEpoch) return;
      _setupReconnect?.cancel();
      _setupReconnect = Timer(
        const Duration(seconds: 1),
        () => _watchSetup(client, workspace, profile, retry: true),
      );
    }

    _setupEvents = client
        .watch(workspace, profile, selection: const SkyrimSetupSelection())
        .listen(
          (next) {
            if (!mounted || epoch != _setupEventEpoch) return;
            final previous = _observedSetup;
            _observedSetup = next;
            if (retry && first && !next.active) {
              _setupSettled();
            } else if (previous != null &&
                previous.phase != next.phase &&
                (previous.active || previous.canCancel) &&
                !next.active &&
                (next.ready ||
                    next.phase == SkyrimSetupStatusPhase.available ||
                    next.phase == SkyrimSetupStatusPhase.cancelled ||
                    next.phase == SkyrimSetupStatusPhase.failed)) {
              _setupSettled();
            }
            first = false;
          },
          onError: (Object _) => reconnect(),
          onDone: reconnect,
          cancelOnError: true,
        );
  }

  void _diagnosticInputsChanged() {
    final available = _supportsSkyrim;
    final receipt = _deployments.receipt;
    _diagnostics.attach(
      available ? widget.diagnostics : null,
      available ? _workspaces.workspace?.id : null,
      available ? _workspaces.workspace?.selectedProfile?.id : null,
      fileSnapshotId: _files.state?.id,
      pluginSnapshotId: _plugins.order?.headers.id,
      deploymentId: receipt?.id,
      deploymentRevision: receipt?.revision,
    );
  }
}
