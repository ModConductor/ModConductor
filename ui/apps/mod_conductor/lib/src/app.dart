import 'package:mc_bethesda/mc_bethesda.dart';
import 'package:mc_credentials/mc_credentials.dart';
import 'package:mc_artifacts/mc_artifacts.dart';
import 'package:mc_generated_outputs/mc_generated_outputs.dart';
import 'package:mc_executables/mc_executables.dart';
import 'package:mc_profile_data/mc_profile_data.dart';

import 'dart:async';
import 'dart:io';

import 'dart:ui' show AppExitType, AppExitResponse;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mc_desktop/mc_desktop.dart';
import 'package:mc_desktop/mc_desktop.dart' as desktop;
import 'package:mc_game_contexts/mc_game_contexts.dart';
import 'package:mc_file_plans/mc_file_plans.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';
import 'package:mc_mod_library/mc_mod_library.dart';
import 'package:mc_workspaces/mc_workspaces.dart';

part 'shell.dart';
part 'preferences.dart';
part 'status.dart';
part 'desktop_host.dart';

void _quitDesktop() {
  ServicesBinding.instance.exitApplication(AppExitType.cancelable);
}

void startDesktop() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DesktopHost());
}

enum _Destination { workspaces, preferences }

typedef _Preferences = ({ThemeMode theme, double scale});

String _themeLabel(ThemeMode mode) => switch (mode) {
  ThemeMode.system => 'Use system appearance',
  ThemeMode.light => 'Light',
  ThemeMode.dark => 'Dark',
};

class ModConductorApp extends StatefulWidget {
  const ModConductorApp({
    super.key,
    this.onQuit,
    this.desktopRequests,
    this.onRetry,
    this.status = const DesktopDisconnected(),
    this.workspaces,
    this.modLibrary,
    this.profileMods,
    this.modOrganization,
    this.gameContexts,
    this.filePlans,
    this.bethesda,
    this.outputs,
    this.deployments,
    this.executables,
    this.gameLaunching,
    this.profileData,
    this.artifacts,
    this.installations,
    this.maintenance,
    this.fomod,
    this.bain,
    this.credentials,
    this.nexus,
    this.nexusMetadata,
    this.linkSetup,
    this.bundles,
    this.chooseArchive = desktop.chooseArchive,
    this.chooseExecutable = desktop.chooseExecutable,
    this.steamDiscovery,
    this.protonContexts,
    this.chooseGameDirectory = desktop.chooseGameDirectory,
    this.chooseDirectory = chooseWorkspaceDirectory,
  });
  final DesktopRequests? desktopRequests;
  final DesktopStatus status;
  final WorkspacesClient? workspaces;
  final ModLibraryClient? modLibrary;
  final ProfileModsClient? profileMods;
  final ModOrganizationClient? modOrganization;
  final GameContextsClient? gameContexts;
  final FilePlansClient? filePlans;
  final BethesdaClient? bethesda;
  final GeneratedOutputsClient? outputs;
  final DeploymentsClient? deployments;
  final ExecutablesClient? executables;
  final GameLaunchingClient? gameLaunching;
  final ProfileDataClient? profileData;
  final ArtifactsClient? artifacts;
  final InstallationsClient? installations;
  final MaintenanceClient? maintenance;
  final FomodClient? fomod;
  final BainClient? bain;
  final CredentialsClient? credentials;
  final NexusClient? nexus;
  final NexusMetadataClient? nexusMetadata;
  final LinkSetupClient? linkSetup;
  final BundlesClient? bundles;
  final ArchiveChooser chooseArchive;
  final ExecutablePathChooser chooseExecutable;
  final SteamDiscoveryClient? steamDiscovery;
  final ProtonContextsClient? protonContexts;
  final GameDirectoryChooser chooseGameDirectory;
  final DirectoryChooser chooseDirectory;
  final VoidCallback? onQuit;
  final VoidCallback? onRetry;
  @override
  State<ModConductorApp> createState() => _ModConductorAppState();
}

class _ModConductorAppState extends State<ModConductorApp> {
  _Destination _destination = _Destination.workspaces;
  _Preferences _applied = (theme: ThemeMode.system, scale: 1);
  _Preferences _draft = (theme: ThemeMode.system, scale: 1);
  final _workspacesFocus = FocusNode(debugLabel: 'Workspaces navigation');
  final _preferencesFocus = FocusNode(debugLabel: 'Preferences navigation');
  final _detailsFocus = FocusNode(debugLabel: 'Active preferences');
  final _quitFocus = FocusNode(debugLabel: 'Quit');
  final _workspaces = WorkspaceController();
  final _mods = ModLibraryController();
  final _game = GameContextController();
  final _files = FilePlansController();
  final _plugins = PluginsController();
  final _outputs = OutputController();
  final _artifacts = ArtifactController();
  final _nexusDetails = ModNexusController();
  final _deployments = DeploymentController();
  final _executables = ExecutablesController();
  final _play = GamePlayController();
  final _profileData = ProfileDataController();
  int? _selectionRevision, _catalogueRevision;
  int? _contextRevision;
  void _modsChanged() {
    if ((_selectionRevision != null &&
            _selectionRevision != _mods.inventory.revision) ||
        (_catalogueRevision != null &&
            _catalogueRevision != _mods.inventory.catalogueRevision)) {
      _plugins.invalidate();
      _deployments.invalidate();
      _play.invalidate();
    }
    _selectionRevision = _mods.inventory.revision;
    _catalogueRevision = _mods.inventory.catalogueRevision;
  }

  void _outputsChanged() {
    _plugins.invalidate();
    _files.invalidate();
    _deployments.invalidate();
    unawaited(_mods.inventory.refreshCatalogue());
  }

  void _deploymentChanged() {
    _plugins.invalidate();
    _files.invalidate();
    _outputs.invalidate();
  }

  void _gameChanged() {
    final revision = _game.state?.revision;
    if (_contextRevision != null && revision != _contextRevision) {
      _plugins.invalidate();
      _files.invalidate();
      _outputs.invalidate();
      _deployments.invalidate();
      _play.invalidate();
      _profileData.invalidate();
    }
    if (revision != _contextRevision) _play.invalidate();
    _contextRevision = revision;
    if (mounted) setState(() {});
  }

  void _syncWorkspaceConsumers() {
    _play.attach(
      widget.gameLaunching,
      widget.executables,
      _workspaces.workspace,
      available: _workspaces.canEdit,
    );
    _executables.attach(
      widget.executables,
      _workspaces.workspace,
      available: _workspaces.canEdit,
    );
    _artifacts.attach(widget.artifacts, _workspaces.workspace?.id);
    _nexusDetails.attach(
      widget.nexusMetadata,
      widget.nexus,
      _workspaces.workspace?.id,
    );
    _outputs.attach(
      widget.outputs,
      _workspaces.workspace?.id,
      available: _workspaces.canEdit,
    );
    _deployments.attach(
      widget.deployments,
      _workspaces.workspace?.selectedProfile?.id,
      _workspaces.workspace?.selectedProfile?.name,
      available: _workspaces.canEdit,
    );
    _plugins.attach(
      widget.bethesda,
      _workspaces.workspace?.selectedProfile?.id,
    );
    _files.attach(
      widget.filePlans,
      _workspaces.workspace?.selectedProfile?.id,
      available: _workspaces.canEdit,
    );
    _game.attach(
      widget.gameContexts,
      workspaceId: _workspaces.workspace?.id,
      editable: _workspaces.canEdit,
    );
    _mods.attach(
      widget.modLibrary,
      widget.profileMods,
      organizationClient: widget.modOrganization,
      workspaceId: _workspaces.workspace?.id,
      profileId: _workspaces.workspace?.selectedProfile?.id,
      editable: _workspaces.canEdit,
    );
  }

  @override
  void initState() {
    super.initState();
    _game.addListener(_gameChanged);
    _mods.addListener(_modsChanged);
    _outputs.onChanged = _outputsChanged;
    _deployments.onChanged = _deploymentChanged;
    _profileData.onChanged = _play.invalidate;
    _play.onDeploymentChanged = () {
      _profileData.invalidate();
      _deployments.invalidate();
      _deploymentChanged();
    };
    _workspaces.addListener(_syncWorkspaceConsumers);
    _workspaces.attach(widget.workspaces);
    _syncWorkspaceConsumers();
  }

  @override
  void didUpdateWidget(ModConductorApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    _workspaces.attach(widget.workspaces);
    _syncWorkspaceConsumers();
  }

  @override
  void dispose() {
    _workspaces.removeListener(_syncWorkspaceConsumers);
    _game.removeListener(_gameChanged);
    _mods.removeListener(_modsChanged);
    _outputs.dispose();
    _deployments.dispose();
    _artifacts.dispose();
    _nexusDetails.dispose();
    _executables.dispose();
    _play.dispose();
    _profileData.dispose();
    _plugins.dispose();
    _files.dispose();
    _mods.dispose();
    _game.dispose();
    _workspaces.dispose();
    for (final node in [
      _workspacesFocus,
      _preferencesFocus,
      _detailsFocus,
      _quitFocus,
    ]) {
      node.dispose();
    }
    super.dispose();
  }

  void _navigate(_Destination value) {
    setState(() => _destination = value);
    if (value == _Destination.workspaces && _nexusDetails.viewing) {
      unawaited(_nexusDetails.readAccount());
    }
    (value == _Destination.workspaces ? _workspacesFocus : _preferencesFocus)
        .requestFocus();
  }

  void _quickTheme(ThemeMode value) => setState(() {
    _applied = (theme: value, scale: _applied.scale);
    _draft = (theme: value, scale: _draft.scale);
  });

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Mod Conductor',
    debugShowCheckedModeBanner: false,
    theme: mcTheme(Brightness.light),
    darkTheme: mcTheme(Brightness.dark),
    themeMode: _applied.theme,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(_applied.scale)),
      child: child!,
    ),
    home: Builder(
      builder: (context) => CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.comma, control: true): () =>
              _navigate(_Destination.preferences),
          const SingleActivator(LogicalKeyboardKey.digit1, alt: true): () =>
              _navigate(_Destination.workspaces),
          const SingleActivator(LogicalKeyboardKey.digit2, alt: true): () =>
              _navigate(_Destination.preferences),
          const SingleActivator(LogicalKeyboardKey.keyQ, control: true):
              widget.onQuit ?? _quitDesktop,
        },
        child: _DesktopShell(
          requests: widget.desktopRequests,
          onRequests: () async {
            final requests = widget.desktopRequests;
            if (requests == null) return;
            if (!requests.hasWorkspaceSelection) {
              requests.selectWorkspace(_workspaces.workspace?.id);
            } else {
              unawaited(requests.recheck());
            }
            final choice = await showDialog<DesktopRequestChoice>(
              context: context,
              builder: (_) => OpenRequestsDialog(
                requests: requests,
                workspaces: _workspaces,
                onRetry: widget.onRetry,
                onPreferences: () => _navigate(_Destination.preferences),
              ),
            );
            if (choice != null && context.mounted) {
              await openDesktopRequest(
                context,
                choice,
                requests: requests,
                workspaces: _workspaces,
                artifacts: _artifacts,
                chooseFile: widget.chooseArchive,
                onWorkspaceOpened: () => _navigate(_Destination.workspaces),
              );
            }
          },
          connectionStatus: widget.status,
          destination: _destination,
          onNavigate: _navigate,
          onQuit: widget.onQuit ?? _quitDesktop,
          workspacesFocus: _workspacesFocus,
          preferencesFocus: _preferencesFocus,
          quitFocus: _quitFocus,
          onToggleTheme: () => _quickTheme(
            Theme.of(context).brightness == Brightness.dark
                ? ThemeMode.light
                : ThemeMode.dark,
          ),
          child: IndexedStack(
            index: _destination.index,
            children: [
              ExcludeFocus(
                excluding: _destination != _Destination.workspaces,
                child: switch (widget.status) {
                  DesktopFailure(:final reason) => _FailurePage(
                    reason: reason,
                    onRetry: widget.onRetry,
                    onPreferences: () => _navigate(_Destination.preferences),
                  ),
                  DesktopDisconnected() ||
                  DesktopConnecting() ||
                  DesktopConnected() => WorkspaceBrowser(
                    controller: _workspaces,
                    profileInspectorBuilder: widget.profileData == null
                        ? null
                        : (context, workspace, profile, close) =>
                              ProfileSettingsInspector(
                                controller: _profileData,
                                client: widget.profileData,
                                workspace: workspace,
                                profile: profile,
                                profiles:
                                    _workspaces.page?.profiles ?? const [],
                                available:
                                    _workspaces.canEdit &&
                                    _game.state?.binding?.needsCheck == false,
                                onClose: close,
                                onResumeProfileChange:
                                    _workspaces.resumeProfileChange,
                              ),
                    executableBuilder: widget.executables == null
                        ? null
                        : (context, workspace) => ExecutablesBrowser(
                            controller: _executables,
                            chooseExecutable: widget.chooseExecutable,
                            chooseDirectory: widget.chooseGameDirectory,
                          ),
                    artifactBuilder: widget.artifacts == null
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
                            onInstalled: _mods.inventory.refreshCatalogue,
                            chooseFile: widget.chooseArchive,
                            workspacePath: workspace.path,
                          ),
                    compactCloseAction:
                        widget.gameLaunching != null &&
                        MediaQuery.sizeOf(context).width < 950,
                    headerActions: widget.deployments == null
                        ? null
                        : (context, workspace) => [
                            SizedBox(
                              width:
                                  widget.gameLaunching != null &&
                                      MediaQuery.sizeOf(context).width < 950
                                  ? 250
                                  : null,
                              child: DeploymentAction(controller: _deployments),
                            ),
                            if (widget.gameLaunching != null)
                              GamePlayActions(controller: _play),
                          ],
                    gameContextBuilder: (context, workspace) =>
                        GameContextBrowser(
                          controller: _game,
                          steamDiscovery: widget.steamDiscovery,
                          protonContexts: widget.protonContexts,
                          chooseDirectory: widget.chooseGameDirectory,
                        ),
                    modLibraryBuilder: (context, workspace) =>
                        ListenableBuilder(
                          listenable: _nexusDetails,
                          builder: (context, _) => _nexusDetails.viewing
                              ? ModNexusView(
                                  controller: _nexusDetails,
                                  onMapped: _mods.inventory.refreshCatalogue,
                                  organization: widget.modOrganization,
                                  localCategories:
                                      _mods.selected?.metadata.categories ??
                                      const [],
                                  onDownloaded:
                                      (artifact, details, version) async {
                                        await _artifacts.load();
                                        _artifacts.model.select(artifact.id);
                                        final target = _mods.selected;
                                        if (target?.id ==
                                                details.reference.mod &&
                                            target?.currentVersionId ==
                                                details.reference.version) {
                                          _artifacts.reviewUpdate(
                                            artifact,
                                            target!,
                                            version: version,
                                            open:
                                                artifact.state ==
                                                    ArtifactState.ready ||
                                                artifact.state ==
                                                    ArtifactState.installed,
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
                                  onOpenDeployment: widget.deployments == null
                                      ? null
                                      : () => showDialog<void>(
                                          context: context,
                                          builder: (_) => DeploymentDialog(
                                            controller: _deployments,
                                          ),
                                        ),
                                  workspacePath: workspace.path,
                                  chooseDirectory: widget.chooseDirectory,
                                )
                              : widget.outputs == null
                              ? FilePlanningWorkbench(
                                  mods: _mods,
                                  onOpenNexus: widget.nexusMetadata == null
                                      ? null
                                      : _nexusDetails.open,
                                  maintenance: widget.maintenance,
                                  onOpenDeployment: widget.deployments == null
                                      ? null
                                      : () => showDialog<void>(
                                          context: context,
                                          builder: (_) => DeploymentDialog(
                                            controller: _deployments,
                                          ),
                                        ),
                                  plans: _files,
                                  plugins: widget.bethesda == null
                                      ? null
                                      : _plugins,
                                  workspacePath: workspace.path,
                                  chooseDirectory: widget.chooseDirectory,
                                  profileName: workspace.selectedProfile?.name,
                                  archiveUnavailable:
                                      _game
                                          .state
                                          ?.definition
                                          .unavailableCapabilities
                                          .any(
                                            (capability) =>
                                                capability.name ==
                                                'Archive inspection',
                                          ) ??
                                      false,
                                )
                              : DeploymentOutputsWorkbench(
                                  mods: _mods,
                                  onOpenNexus: widget.nexusMetadata == null
                                      ? null
                                      : _nexusDetails.open,
                                  maintenance: widget.maintenance,
                                  onOpenDeployment: widget.deployments == null
                                      ? null
                                      : () => showDialog<void>(
                                          context: context,
                                          builder: (_) => DeploymentDialog(
                                            controller: _deployments,
                                          ),
                                        ),
                                  plans: _files,
                                  plugins: widget.bethesda == null
                                      ? null
                                      : _plugins,
                                  outputs: _outputs,
                                  profileId: workspace.selectedProfile?.id,
                                  organization: widget.modOrganization,
                                  workspacePath: workspace.path,
                                  chooseDirectory: widget.chooseDirectory,
                                  profileName: workspace.selectedProfile?.name,
                                  archiveUnavailable:
                                      _game
                                          .state
                                          ?.definition
                                          .unavailableCapabilities
                                          .any(
                                            (capability) =>
                                                capability.name ==
                                                'Archive inspection',
                                          ) ??
                                      false,
                                ),
                        ),
                    chooseDirectory: widget.chooseDirectory,
                  ),
                },
              ),
              ExcludeFocus(
                excluding: _destination != _Destination.preferences,
                child: _PreferencesPage(
                  credentials: widget.credentials,
                  nexus: widget.nexus,
                  linkSetup: widget.linkSetup,
                  applied: _applied,
                  draft: _draft,
                  detailsFocus: _detailsFocus,
                  onDraft: (value) => setState(() => _draft = value),
                  onSave: () => setState(() => _applied = _draft),
                  onCancel: () => setState(() => _draft = _applied),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
