part of 'app.dart';

mixin _ShellContent
    on _AppStateBase, _SettingsScope, _WorkspaceScope, _ProfileCreation {
  Widget _buildWorkspaceBrowser(BuildContext context) => WorkspaceBrowser(
    controller: _workspaces,
    openFolder: widget.openWorkspaceFolder,
    profileCreator: _createProfile,
    profileSetupBuilder: _profileSetupGate,
    workbenchReady: _gameReady,
    profileInspectorBuilder: !_supportsSkyrim || widget.profileData == null
        ? null
        : (context, workspace, profile, close, bindGuard) =>
              ProfileSettingsInspector(
                controller: _profileData,
                client: widget.profileData,
                workspace: workspace,
                profile: profile,
                profiles: _workspaces.page?.profiles ?? const [],
                available:
                    _workspaces.canEdit &&
                    _game.state?.binding?.needsCheck == false,
                onClose: close,
                onNavigationGuardChanged: bindGuard,
                onResumeProfileChange: _workspaces.resumeProfileChange,
                pluginHeadersId: _plugins.order?.headers.id,
              ),
    executableBuilder: !_supportsSkyrim || widget.executables == null
        ? null
        : (context, workspace) => ExecutablesBrowser(
            controller: _executables,
            chooseExecutable: widget.chooseExecutable,
            chooseDirectory: widget.chooseGameDirectory,
            fnis: widget.fnis,
            workspace: workspace,
          ),
    artifactBuilder: !_supportsArchives || widget.artifacts == null
        ? null
        : (context, workspace, openMods) => ArtifactBrowser(
            nexus: widget.nexus,
            controller: _artifacts,
            installations: widget.installations,
            fomod: widget.fomod,
            bain: widget.bain,
            bundles: widget.bundles,
            profileId: workspace.selectedProfile?.id,
            maintenance: widget.maintenance,
            updateTargets:
                widget.modOrganization == null ||
                    workspace.selectedProfile == null
                ? null
                : (cursor) => widget.modOrganization!.query(
                    workspace.selectedProfile!.id,
                    const ModQuery(
                      filters: [KindFilter(ModKind.regular)],
                      sort: OrganizationSort.name,
                    ),
                    cursor: cursor,
                  ),
            onOpenMods: openMods,
            onInstalled: () => _installationCommitted(
              workspace.id,
              workspace.selectedProfile?.id,
            ),
            onInstallationDetached: (status) => _observeDetachedInstallation(
              widget.installations!,
              status,
              workspace.selectedProfile?.id,
            ),
            onInstallationAttached: (status) =>
                _installationReattached(status, workspace.selectedProfile?.id),
            chooseFile: widget.chooseArchive,
            workspacePath: workspace.path,
          ),
    entryHelpBuilder: widget.diagnostics == null
        ? null
        : (context, workspace, actions) => HelpBrowser(
            controller: _diagnostics,
            settingsDiagnostic: _settingsHelpDiagnostic,
            onCreateWorkspace: actions.createWorkspace,
            onOpenWorkspace: actions.openWorkspace,
            onCreateProfile: actions.createProfile,
          ),
    helpBuilder: !_supportsSkyrim || widget.diagnostics == null
        ? null
        : (context, workspace, actions) => HelpBrowser(
            controller: _diagnostics,
            settingsDiagnostic: _settingsHelpDiagnostic,
            onCreateWorkspace: actions.createWorkspace,
            onOpenWorkspace: actions.openWorkspace,
            onCreateProfile: actions.createProfile,
            onOpenSkyrimSetup:
                widget.skyrimSetup == null || workspace?.selectedProfile == null
                ? null
                : _workspaces.showGame,
          ),
    compactCloseAction:
        widget.gameLaunching != null && MediaQuery.sizeOf(context).width < 950,
    headerActions:
        !_supportsSkyrim ||
            (widget.deployments == null && widget.migration == null)
        ? null
        : (context, workspace) => [
            if (widget.migration != null)
              MigrationAction(
                client: widget.migration!,
                workspaceId: workspace.id,
                chooseDirectory: widget.chooseDirectory,
                onComplete: _workspaces.refresh,
              ),
            if (widget.deployments != null)
              SizedBox(
                width:
                    widget.gameLaunching != null &&
                        MediaQuery.sizeOf(context).width < 950
                    ? 250
                    : null,
                child: DeploymentAction(controller: _deployments),
              ),
            if (widget.gameLaunching != null && widget.deployments != null)
              GamePlayActions(controller: _play),
          ],
    gameContextBuilder: !_supportsInstallation
        ? null
        : (context, workspace) => GameContextBrowser(
            controller: _game,
            steamDiscovery: widget.steamDiscovery,
            protonContexts: widget.protonContexts,
            chooseDirectory: widget.chooseGameDirectory,
            footer:
                widget.skyrimSetup == null ||
                    workspace.selectedProfile == null ||
                    _game.state?.binding?.evidence.definitionId !=
                        'skyrim-se-steam'
                ? null
                : Padding(
                    padding: const EdgeInsets.only(top: McSpacing.large),
                    child: SkyrimSetupSection(
                      client: widget.skyrimSetup!,
                      chooseArchive: widget.chooseArchive,
                      workspaceId: workspace.id,
                      profileId: workspace.selectedProfile!.id,
                      contextRevision: _game.state?.revision,
                    ),
                  ),
          ),
    modLibraryBuilder: !_supportsSkyrim
        ? null
        : (context, workspace) => ListenableBuilder(
            listenable: _nexusDetails,
            builder: (context, _) => _nexusDetails.viewing
                ? ModNexusView(
                    controller: _nexusDetails,
                    onMapped: _mods.inventory.refreshCatalogue,
                    organization: widget.modOrganization,
                    localCategories:
                        _mods.selected?.metadata.categories ?? const [],
                    onDownloaded: (artifact, details, version) async {
                      await _artifacts.load();
                      _artifacts.model.select(artifact.id);
                      final target = _mods.selected;
                      if (target?.id == details.reference.mod &&
                          target?.currentVersionId ==
                              details.reference.version) {
                        _artifacts.reviewUpdate(
                          artifact,
                          target!,
                          version: version,
                          open:
                              artifact.state == ArtifactState.ready ||
                              artifact.state == ArtifactState.installed,
                        );
                      }
                      _nexusDetails.close();
                      _workspaces.showArchives();
                    },
                  )
                : widget.filePlans == null
                ? ModLibraryBrowser(
                    controller: _mods,
                    onOpenNexus: widget.nexusMetadata == null
                        ? null
                        : _nexusDetails.open,
                    maintenance: widget.maintenance,
                    deactivateGameFiles: _deactivateGameFilesForDeletion,
                    onDeleted: _artifacts.load,
                    workspacePath: workspace.path,
                    chooseDirectory: widget.chooseDirectory,
                    inventoryExports: widget.inventoryExports,
                    chooseExportLocation: widget.chooseExportLocation,
                    openExportFolder: widget.openExportFolder,
                    profileName: workspace.selectedProfile?.name,
                  )
                : widget.outputs == null
                ? FilePlanningWorkbench(
                    mods: _mods,
                    onOpenNexus: widget.nexusMetadata == null
                        ? null
                        : _nexusDetails.open,
                    maintenance: widget.maintenance,
                    deactivateGameFiles: _deactivateGameFilesForDeletion,
                    onDeleted: _artifacts.load,
                    plans: _files,
                    onOpenProblems: _workspaces.showHelp,
                    plugins: widget.bethesda == null ? null : _plugins,
                    archives: widget.archivePolicies == null ? null : _archives,
                    sortOrder: widget.loot == null ? null : _sortOrder,
                    workspacePath: workspace.path,
                    chooseDirectory: widget.chooseDirectory,
                    profileName: workspace.selectedProfile?.name,
                    inventoryExports: widget.inventoryExports,
                    chooseExportLocation: widget.chooseExportLocation,
                    openExportFolder: widget.openExportFolder,
                    archiveUnavailable:
                        _game.state?.definition?.unavailable(
                          GameCapabilityId.archiveInspection,
                        ) ??
                        false,
                  )
                : DeploymentOutputsWorkbench(
                    mods: _mods,
                    onOpenNexus: widget.nexusMetadata == null
                        ? null
                        : _nexusDetails.open,
                    maintenance: widget.maintenance,
                    deactivateGameFiles: _deactivateGameFilesForDeletion,
                    onDeleted: _artifacts.load,
                    plans: _files,
                    onOpenProblems: _workspaces.showHelp,
                    plugins: widget.bethesda == null ? null : _plugins,
                    archives: widget.archivePolicies == null ? null : _archives,
                    sortOrder: widget.loot == null ? null : _sortOrder,
                    outputs: _outputs,
                    profileId: workspace.selectedProfile?.id,
                    organization: widget.modOrganization,
                    workspacePath: workspace.path,
                    chooseDirectory: widget.chooseDirectory,
                    profileName: workspace.selectedProfile?.name,
                    inventoryExports: widget.inventoryExports,
                    chooseExportLocation: widget.chooseExportLocation,
                    openExportFolder: widget.openExportFolder,
                    archiveUnavailable:
                        _game.state?.definition?.unavailable(
                          GameCapabilityId.archiveInspection,
                        ) ??
                        false,
                  ),
          ),
    chooseDirectory: widget.chooseDirectory,
  );

  Widget _buildPreferencesPage(BuildContext context) => _PreferencesPage(
    labels: AppLocalizations.of(context),
    credentials: widget.credentials,
    nexus: widget.nexus,
    linkSetup: widget.linkSetup,
    scope: _preferenceScope,
    onScope: _selectPreferenceScope,
    workspaceAvailable: _settingsWorkspaceId != null,
    inheritsApplication: _workspaceSettings.inheritsDraft,
    inheritsApplicationApplied: _workspaceSettings.inheritsApplied,
    onInheritsApplication: (value) => setState(() {
      _workspaceSettings.inheritsDraft = value;
      _workspaceSettings.draft = value || _workspaceSettings.inheritsApplied
          ? _applicationSettings.applied
          : _workspaceSettings.applied;
    }),
    applied: _selectedApplied,
    draft: _selectedDraft,
    loaded: _selectedSettingsLoaded,
    loading: _selectedSettingsLoading,
    busy: _selectedSettings.saving,
    problem: _selectedSettingsProblem,
    savedAt: _selectedSettings.savedAt,
    detailsFocus: _detailsFocus,
    onDraft: _changePreferenceDraft,
    onSave: () => unawaited(_savePreferences()),
    onCancel: _cancelPreferences,
    onRetry: () => unawaited(_retrySettings()),
  );
}
