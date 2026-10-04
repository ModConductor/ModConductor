part of 'app.dart';

mixin _ShellContent
    on
        _AppStateBase,
        _SettingsScope,
        _WorkspaceScope,
        _ProfileCreation,
        _ProfileTransportFlow {
  Widget _buildWorkspaceBrowser(
    BuildContext context,
    WorkspaceFrameBuilder frameBuilder,
  ) => WorkspaceBrowser(
    controller: _workspaces,
    frameBuilder: frameBuilder,
    imageClient: widget.workspaces is ProfileImagesClient
        ? widget.workspaces as ProfileImagesClient
        : null,
    gameContexts: widget.gameContexts,
    gameContext: _game.state,
    openFolder: widget.openWorkspaceFolder,
    profileCreator: _createProfile,
    onImportProfile: _openProfileImport,
    onExportProfile: _openProfileExport,
    profileSetupBuilder: _profileSetupGate,
    workbenchReady: _gameReady,
    profileInspectorBuilder: widget.profileData == null
        ? null
        : (
            context,
            workspace,
            profile,
            game,
            close,
            bindGuard,
          ) => ProfileSettingsInspector(
            controller: _profileData,
            client: widget.profileData,
            workspace: workspace,
            profile: profile,
            profiles: _workspaces.page?.profiles ?? const [],
            available:
                _workspaces.canEdit &&
                game?.binding?.needsCheck == false &&
                game?.definition?.capability(GameCapabilityId.bethesdaGame) !=
                    null,
            onClose: close,
            onNavigationGuardChanged: bindGuard,
            onResumeProfileChange: _workspaces.resumeProfileChange,
            pluginHeadersId: profile.id == _game.state?.profileId
                ? _plugins.order?.headers.id
                : null,
            savesAvailable: game?.definition?.saveExtension.isNotEmpty == true,
            imageClient: widget.workspaces is ProfileImagesClient
                ? widget.workspaces as ProfileImagesClient
                : null,
            onImageChanged: _workspaces.imageChanged,
            gameImage: game?.definition?.artworkUrl.isNotEmpty == true
                ? Uri.parse(game!.definition!.artworkUrl)
                : null,
          ),
    discoveryBuilder:
        !(_supportsBethesda &&
                widget.nexus != null &&
                widget.nexusMetadata != null &&
                widget.modOrganization != null &&
                _workspaces.confirmedWorkspace?.selectedProfile != null) &&
            (widget.thunderstore == null ||
                _game.state?.definition?.thunderstoreCommunity.isNotEmpty !=
                    true)
        ? null
        : (context, workspace, visible) {
            final profile = workspace.selectedProfile;
            if (_supportsBethesda &&
                profile != null &&
                widget.nexus != null &&
                widget.nexusMetadata != null &&
                widget.modOrganization != null) {
              return NexusDiscoveryBrowser(
                key: ValueKey((workspace.id, profile.id)),
                workspace: workspace.id,
                profile: profile.id,
                nexus: widget.nexus!,
                metadata: widget.nexusMetadata!,
                organization: widget.modOrganization!,
                inventory: _mods.inventory,
                trackedChanges: _discoveryTrackedChanges,
                localChanges: _discoveryLocalChanges,
                active: visible,
                onViewFiles: (id) {
                  setState(
                    () => _nexusFileRequest = NexusFileRequest(
                      workspace.id,
                      profile.id,
                      id,
                      ++_nexusFileRevision,
                    ),
                  );
                  _workspaces.showArchives();
                },
              );
            }
            if (widget.thunderstore == null ||
                _game.state?.definition?.thunderstoreCommunity.isNotEmpty !=
                    true) {
              return const SizedBox.shrink();
            }
            return ThunderstoreBrowser(
              key: ValueKey('thunderstore-${workspace.id}'),
              client: widget.thunderstore!,
              community: _game.state!.definition!.thunderstoreCommunity,
              workspaceId: workspace.id,
              visible: visible,
              onInstalled: () => _installationCommitted(
                workspace.id,
                workspace.selectedProfile?.id,
              ),
            );
          },
    executableBuilder: !_supportsGameMods || widget.executables == null
        ? null
        : (context, workspace) => ExecutablesBrowser(
            controller: _executables,
            chooseExecutable: widget.chooseExecutable,
            chooseDirectory: widget.chooseGameDirectory,
            fnis: _supportsSkyrim ? widget.fnis : null,
            outputs: widget.outputs,
            workspace: workspace,
          ),
    artifactBuilder: !_supportsGameMods || widget.artifacts == null
        ? null
        : (context, workspace, openMods) => ArtifactBrowser(
            nexus: widget.nexus,
            nexusFileRequest: _nexusFileRequest,
            onNexusRequestClosed: () =>
                setState(() => _nexusFileRequest = null),
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
    helpBuilder: widget.diagnostics == null
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
    workbenchActions: (context, workspace) => [
      ListenableBuilder(
        listenable: _modView,
        builder: (context, _) {
          final panes = <String, String>{
            'load-order': 'Load order',
            'saved': 'Saved mod files',
            if (_supportsBethesda && widget.bethesda != null)
              'bethesda-plugins': 'Plugin details',
            if (_supportsBethesda && widget.archivePolicies != null)
              'bethesda-archives': 'Archives',
            if (_supportsBethesda && widget.loot != null)
              'loot-sort-order': 'LOOT details',
            if (_supportsBethesda && widget.filePlans != null)
              'skyrim-data': 'File inspection',
            if (_supportsBethesda && widget.outputs != null) ...{
              'tool-outputs': 'Tool outputs',
              'writable-files': 'Writable game files',
            },
          };
          return SizedBox(
            width: 190,
            child: McChoice<String>(
              label: 'View',
              value: panes.containsKey(_modView.pane)
                  ? _modView.pane
                  : 'load-order',
              choices: panes.keys.toList(),
              describe: (id) => panes[id]!,
              onChanged: _modView.select,
            ),
          );
        },
      ),
      if (_supportsBethesda && widget.loot != null)
        ListenableBuilder(
          listenable: _sortOrder,
          builder: (context, _) => Tooltip(
            message: 'Optimise plugin load order with LOOT',
            child: McAction(
              label: 'Optimise',
              icon: Icons.auto_fix_high,
              emphasis: McActionEmphasis.primary,
              onPressed: _sortOrder.canPreview
                  ? () => unawaited(_sortOrder.optimise())
                  : null,
            ),
          ),
        ),
    ],
    headerActions: !_supportsGameMods || widget.deployments == null
        ? null
        : (context, workspace) => [
            DeploymentAction(
              controller: _deployments,
              builder: widget.gameLaunching == null
                  ? null
                  : (context, label, open) => GamePlayActions(
                      controller: _play,
                      additionalMenuItems: [
                        PopupMenuItem(
                          value: open,
                          enabled: open != null,
                          child: McIconLabel(
                            icon: const Icon(Icons.swap_horiz, size: 18),
                            label: label,
                            flexible: true,
                            maxLines: null,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
    gameContextBuilder: !_supportsInstallation
        ? null
        : (context, workspace) => GameContextBrowser(
            controller: _game,
            catalogue: _gameCatalogue.games,
            steamDiscovery: widget.steamDiscovery,
            protonContexts: widget.protonContexts,
            chooseDirectory: widget.chooseGameDirectory,
            chooseExecutable: widget.chooseExecutable,
            footer:
                _supportsUnreal &&
                    widget.unreal != null &&
                    workspace.selectedProfile != null
                ? UnrealLoaderSection(
                    key: ValueKey((
                      'unreal-loader',
                      workspace.id,
                      workspace.selectedProfile!.id,
                    )),
                    client: widget.unreal!,
                    workspace: workspace.id,
                    profile: workspace.selectedProfile!.id,
                    chooseArchive: () async =>
                        (await widget.chooseArchive())?.path,
                    changes: Listenable.merge([
                      _game,
                      _mods,
                      _deployments,
                      _play,
                    ]),
                    onChanged: () => unawaited(
                      _installationCommitted(
                        workspace.id,
                        workspace.selectedProfile!.id,
                      ),
                    ),
                  )
                : _supportsUnity &&
                      widget.bepInEx != null &&
                      widget.thunderstore != null &&
                      workspace.selectedProfile != null
                ? BepInExSection(
                    key: ValueKey((
                      'loader',
                      workspace.id,
                      workspace.selectedProfile!.id,
                    )),
                    client: widget.bepInEx!,
                    packages: widget.thunderstore!,
                    workspace: workspace.id,
                    profile: workspace.selectedProfile!.id,
                    changes: Listenable.merge([_mods, _deployments, _play]),
                    onChanged: () => unawaited(
                      _installationCommitted(
                        workspace.id,
                        workspace.selectedProfile!.id,
                      ),
                    ),
                  )
                : widget.skyrimSetup == null ||
                      workspace.selectedProfile == null ||
                      !_hasSkyrimGame
                ? (_game.state?.definition?.extenderName.isNotEmpty == true
                      ? ScriptExtenderSection(
                          definition: _game.state!.definition!,
                          client: widget.gameCatalogue,
                          onTools: _workspaces.showTools,
                        )
                      : null)
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
    modLibraryBuilder: !_supportsGameMods
        ? null
        : (context, workspace, modsVisible) {
            return ListenableBuilder(
              listenable: _nexusDetails,
              builder: (context, _) => _nexusDetails.viewing
                  ? ModNexusView(
                      controller: _nexusDetails,
                      onMapped: _mods.inventory.refreshCatalogue,
                      onLinked: () async {
                        final before = _mods.inventory.catalogueRevision;
                        await _mods.inventory.refreshCatalogue();
                        if (_mods.inventory.catalogueRevision == before) {
                          _discoveryLocalChanges.value++;
                        }
                      },
                      onRefreshed: () => _discoveryLocalChanges.value++,
                      onTrackingChanged: () => _discoveryTrackedChanges.value++,
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
                  : (widget.filePlans == null || !_supportsBethesda)
                  ? ModLibraryBrowser(
                      controller: _mods,
                      view: _modView,
                      externalPaneControls: true,
                      onOpenNexus:
                          !_supportsBethesda || widget.nexusMetadata == null
                          ? null
                          : _nexusDetails.open,
                      maintenance: widget.maintenance,
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
                      view: _modView,
                      externalPaneControls: true,
                      onOpenNexus: widget.nexusMetadata == null
                          ? null
                          : _nexusDetails.open,
                      maintenance: widget.maintenance,
                      onDeleted: _artifacts.load,
                      plans: _files,
                      onOpenProblems: _workspaces.showHelp,
                      plugins: widget.bethesda == null ? null : _plugins,
                      archives: widget.archivePolicies == null
                          ? null
                          : _archives,
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
                      view: _modView,
                      externalPaneControls: true,
                      onOpenNexus: widget.nexusMetadata == null
                          ? null
                          : _nexusDetails.open,
                      maintenance: widget.maintenance,
                      onDeleted: _artifacts.load,
                      plans: _files,
                      onOpenProblems: _workspaces.showHelp,
                      plugins: widget.bethesda == null ? null : _plugins,
                      archives: widget.archivePolicies == null
                          ? null
                          : _archives,
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
            );
          },
    chooseDirectory: widget.chooseDirectory,
  );

  Widget _buildPreferencesPage(BuildContext context) => _PreferencesPage(
    labels: AppLocalizations.of(context),
    migration: ListenableBuilder(
      listenable: _workspaces,
      builder: (context, _) => _MigrationSettingsSection(
        workspace: _workspaces.confirmedWorkspace,
        client: widget.migration,
        chooseDirectory: widget.chooseDirectory,
        onComplete: _workspaces.refresh,
      ),
    ),
    credentials: widget.credentials,
    nexus: widget.nexus,
    linkSetup: widget.linkSetup,
    updates: widget.updates,
    checkUpdatesOnStartup: _applicationSettings.checkUpdatesOnStartup,
    canChangeCheckUpdatesOnStartup:
        _applicationSettings.loaded && !_applicationSettings.saving,
    onCheckUpdatesOnStartup: (value) =>
        unawaited(_saveCheckUpdatesOnStartup(value)),
    onQuitAndUpdate: widget.onQuitAndUpdate,
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
