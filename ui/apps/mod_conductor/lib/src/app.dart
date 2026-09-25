import 'package:mc_bethesda/mc_bethesda.dart';
import 'package:mc_credentials/mc_credentials.dart';
import 'package:mc_artifacts/mc_artifacts.dart';
import 'package:mc_generated_outputs/mc_generated_outputs.dart';
import 'package:mc_executables/mc_executables.dart';
import 'package:mc_profile_data/mc_profile_data.dart';
import 'package:mc_migration/mc_migration.dart';

import 'dart:async';
import 'dart:io';

import 'dart:ui' show AppExitType, AppExitResponse;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../l10n/app_localizations.dart';

import 'package:mc_desktop/mc_desktop.dart';
import 'package:mc_desktop/mc_desktop.dart' as desktop;
import 'package:mc_game_contexts/mc_game_contexts.dart';
import 'package:mc_skse/mc_skse.dart';
import 'package:mc_file_plans/mc_file_plans.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_collections/mc_ui_collections.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';
import 'package:mc_mod_library/mc_mod_library.dart';
import 'package:mc_workspaces/mc_workspaces.dart';

part 'shell.dart';
part 'preferences.dart';
part 'status.dart';
part 'desktop_host.dart';
part 'help.dart';

void _quitDesktop() {
  ServicesBinding.instance.exitApplication(AppExitType.cancelable);
}

void startDesktop() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DesktopHost());
}

enum _Destination { workspaces, preferences }

enum _PreferenceScope { application, workspace }

typedef _Preferences = ({
  AppearancePreference appearance,
  double textScale,
  double interfaceScale,
  ContrastPreference contrast,
});

class _PreferenceTextScaler extends TextScaler {
  const _PreferenceTextScaler(this.platform, this.multiplier);

  final TextScaler platform;
  final double multiplier;

  @override
  double scale(double fontSize) => platform.scale(fontSize) * multiplier;

  @override
  double get textScaleFactor => scale(1);

  @override
  bool operator ==(Object other) =>
      other is _PreferenceTextScaler &&
      other.platform == platform &&
      other.multiplier == multiplier;

  @override
  int get hashCode => Object.hash(platform, multiplier);
}

const _defaultPreferences = (
  appearance: AppearancePreference.system,
  textScale: 1.0,
  interfaceScale: 1.0,
  contrast: ContrastPreference.system,
);

class _SettingsFormState {
  _Preferences applied = _defaultPreferences;
  _Preferences draft = _defaultPreferences;
  bool inheritsApplied = true;
  bool inheritsDraft = true;
  bool hasConfirmed = false;
  bool loaded = false;
  bool loading = false;
  bool saving = false;
  String? problem;
  String? diagnostic;
  DateTime? savedAt;
  int generation = 0;

  void reset() {
    generation++;
    applied = draft = _defaultPreferences;
    inheritsApplied = inheritsDraft = true;
    hasConfirmed = loaded = loading = saving = false;
    problem = diagnostic = null;
    savedAt = null;
  }

  void accept(SettingsSnapshot snapshot) {
    applied = draft = _preferences(snapshot);
    inheritsApplied = inheritsDraft = snapshot.inheritsApplication;
    hasConfirmed = true;
    loaded = true;
    loading = saving = false;
    problem = diagnostic = null;
  }

  void cancel() {
    draft = applied;
    inheritsDraft = inheritsApplied;
    problem = null;
  }
}

const _profileSetupGames = [
  ProfileSetupGame(
    id: 'skyrim-se-steam',
    name: 'Skyrim Special Edition',
    storefront: 'Steam',
  ),
];

const _englishLocale = Locale('en');

Locale _resolveAppLocale(
  List<Locale>? preferredLocales,
  Iterable<Locale> supportedLocales,
) {
  for (final preferred in preferredLocales ?? const <Locale>[]) {
    for (final supported in supportedLocales) {
      if (preferred.languageCode == supported.languageCode) return supported;
    }
  }
  return _englishLocale;
}

ThemeMode _themeMode(AppearancePreference value) => switch (value) {
  AppearancePreference.system => ThemeMode.system,
  AppearancePreference.light => ThemeMode.light,
  AppearancePreference.dark => ThemeMode.dark,
};

_Preferences _preferences(SettingsSnapshot value) => (
  appearance: value.presentation.appearance,
  textScale: value.presentation.textScale,
  interfaceScale: value.presentation.interfaceScale,
  contrast: value.presentation.contrast,
);

SettingsSnapshot _snapshot(_Preferences value, {required bool inherits}) =>
    SettingsSnapshot(
      presentation: PresentationPreferences(
        appearance: value.appearance,
        textScale: value.textScale,
        interfaceScale: value.interfaceScale,
        contrast: value.contrast,
      ),
      inheritsApplication: inherits,
    );

McUiLabels _uiLabels(AppLocalizations text) => McUiLabels(
  close: text.close,
  cancel: text.cancel,
  name: text.name,
  enterName: text.enterName,
  closeInspector: text.closeInspector,
  closeFilter: text.closeFilter,
  noItems: text.noItems,
  noMatches: text.noMatches,
  expanded: text.expanded,
  collapsed: text.collapsed,
  cancelLoad: text.cancelLoad,
  loadMore: text.loadMore,
  retry: text.retry,
  refreshCollection: text.refreshCollection,
  collapseItem: text.collapseItem,
  expandItem: text.expandItem,
  available: text.statusAvailable,
  unavailable: text.statusUnavailable,
  unsupported: text.statusUnsupported,
  information: text.statusInformation,
  error: text.statusError,
);

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
    this.inventoryExports,
    this.gameContexts,
    this.filePlans,
    this.diagnostics,
    this.bethesda,
    this.pluginOrders,
    this.loot,
    this.archivePolicies,
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
    this.migration,
    this.settings,
    this.chooseArchive = desktop.chooseArchive,
    this.chooseExecutable = desktop.chooseExecutable,
    this.steamDiscovery,
    this.protonContexts,
    this.skse,
    this.enb,
    this.fnis,
    this.skyrimSetup,
    this.chooseGameDirectory = desktop.chooseGameDirectory,
    this.chooseDirectory = chooseWorkspaceDirectory,
    this.chooseExportLocation = desktop.chooseInventoryExportDestination,
    this.openExportFolder = desktop.openInventoryExportFolder,
    this.openWorkspaceFolder = desktop.openFolder,
  });
  final DesktopRequests? desktopRequests;
  final DesktopStatus status;
  final WorkspacesClient? workspaces;
  final ModLibraryClient? modLibrary;
  final ProfileModsClient? profileMods;
  final ModOrganizationClient? modOrganization;
  final InventoryExportClient? inventoryExports;
  final GameContextsClient? gameContexts;
  final FilePlansClient? filePlans;
  final DiagnosticsClient? diagnostics;
  final BethesdaClient? bethesda;
  final PluginOrderClient? pluginOrders;
  final LootClient? loot;
  final ArchivePolicyClient? archivePolicies;
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
  final MigrationClient? migration;
  final SettingsClient? settings;
  final ArchiveChooser chooseArchive;
  final ExecutablePathChooser chooseExecutable;
  final SteamDiscoveryClient? steamDiscovery;
  final ProtonContextsClient? protonContexts;
  final SkseClient? skse;
  final EnbClient? enb;
  final FnisClient? fnis;
  final SkyrimSetupClient? skyrimSetup;
  final GameDirectoryChooser chooseGameDirectory;
  final DirectoryChooser chooseDirectory;
  final InventoryExportLocationChooser chooseExportLocation;
  final InventoryExportFolderOpener openExportFolder;
  final WorkspaceFolderOpener openWorkspaceFolder;
  final VoidCallback? onQuit;
  final VoidCallback? onRetry;
  @override
  State<ModConductorApp> createState() => _ModConductorAppState();
}

class _ModConductorAppState extends State<ModConductorApp> {
  _Destination _destination = _Destination.workspaces;
  _PreferenceScope _preferenceScope = _PreferenceScope.application;
  final _applicationSettings = _SettingsFormState();
  final _workspaceSettings = _SettingsFormState();
  String? _settingsWorkspaceId;
  String? _settingsProfileId;
  final _workspacesFocus = FocusNode(debugLabel: 'Workspaces navigation');
  final _preferencesFocus = FocusNode(debugLabel: 'Preferences navigation');
  final _detailsFocus = FocusNode(debugLabel: 'Active preferences');
  final _quitFocus = FocusNode(debugLabel: 'Quit');
  final _workspaces = WorkspaceController();
  final _mods = ModLibraryController();
  final _game = GameContextController();
  final _files = FilePlansController();
  final _diagnostics = DiagnosticsController();
  final _plugins = PluginsController();
  final _sortOrder = SortOrderController();
  final _archives = ArchivePolicyController();
  final _outputs = OutputController();
  final _artifacts = ArtifactController();
  final _nexusDetails = ModNexusController();
  final _deployments = DeploymentController();
  final _executables = ExecutablesController();
  final _play = GamePlayController();
  final _profileData = ProfileDataController();
  bool _skseLaunchCheckStarted = false;
  final _skseProfilesWithoutInstall = <String>{};
  SkyrimSetupClient? _setupEventClient;
  StreamSubscription<SkyrimSetupStatus>? _setupEvents;
  Timer? _setupReconnect;
  String? _setupEventWorkspace, _setupEventProfile;
  SkyrimSetupStatus? _observedSetup;
  int _setupEventEpoch = 0;
  final _detachedInstallations =
      <String, StreamSubscription<InstallationStatus>>{};
  final _installationRetries = <String, Timer>{};
  String? _installationWorkspace, _installationProfile;
  InstallationsClient? _installationClient;
  int _installationEpoch = 0;
  int? _selectionRevision, _catalogueRevision;
  int? _contextRevision;
  bool get _gameReady {
    final state = _game.state;
    final binding = state?.binding;
    return state?.definition != null &&
        binding != null &&
        !binding.needsCheck &&
        binding.failure == null &&
        binding.evidence.problems.isEmpty;
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

  _Preferences get _effectivePreferences =>
      _settingsWorkspaceId != null &&
          _workspaceSettings.hasConfirmed &&
          !_workspaceSettings.inheritsApplied
      ? _workspaceSettings.applied
      : _applicationSettings.applied;

  _SettingsFormState get _selectedSettings =>
      _preferenceScope == _PreferenceScope.application
      ? _applicationSettings
      : _workspaceSettings;

  bool get _selectedSettingsLoaded =>
      _selectedSettings.loaded &&
      (_preferenceScope == _PreferenceScope.application ||
          !_workspaceSettings.inheritsDraft ||
          _applicationSettings.loaded);

  bool get _selectedSettingsLoading =>
      _selectedSettings.loading ||
      (_preferenceScope == _PreferenceScope.workspace &&
          _workspaceSettings.inheritsDraft &&
          _applicationSettings.loading);

  String? get _selectedSettingsProblem =>
      _selectedSettings.problem ??
      (_preferenceScope == _PreferenceScope.workspace &&
              _workspaceSettings.inheritsDraft &&
              !_applicationSettings.loaded
          ? _applicationSettings.problem
          : null);

  _Preferences get _selectedApplied =>
      _preferenceScope == _PreferenceScope.application
      ? _applicationSettings.applied
      : _workspaceSettings.inheritsApplied
      ? _applicationSettings.applied
      : _workspaceSettings.applied;

  _Preferences get _selectedDraft =>
      _preferenceScope == _PreferenceScope.application
      ? _applicationSettings.draft
      : _workspaceSettings.inheritsDraft
      ? _applicationSettings.applied
      : _workspaceSettings.draft;

  bool get _selectedInherits =>
      _preferenceScope == _PreferenceScope.workspace &&
      _workspaceSettings.inheritsDraft;

  String _settingsDiagnostic(Object error) => error is SettingsException
      ? '${error.fault.name}: ${error.detail}'
      : '${error.runtimeType}: $error';

  String? get _settingsHelpDiagnostic {
    final failures = <String>[
      if (_applicationSettings.problem != null &&
          _applicationSettings.diagnostic != null)
        'Application: ${_applicationSettings.diagnostic}',
      if (_workspaceSettings.problem != null &&
          _workspaceSettings.diagnostic != null &&
          _settingsWorkspaceId != null)
        'Workspace: ${_workspaceSettings.diagnostic}',
    ];
    return failures.isEmpty ? null : failures.join('\n');
  }

  Future<void> _loadSettings(
    _PreferenceScope scope, {
    String? workspaceId,
  }) async {
    final form = scope == _PreferenceScope.application
        ? _applicationSettings
        : _workspaceSettings;
    final client = widget.settings;
    final generation = ++form.generation;
    setState(() {
      form.loaded = false;
      form.loading = client != null;
      form.saving = false;
      form.problem = client == null ? 'load' : null;
      form.diagnostic = client == null
          ? 'Engine connection unavailable.'
          : null;
      form.savedAt = null;
    });
    if (client == null) return;
    bool current() =>
        mounted &&
        generation == form.generation &&
        client == widget.settings &&
        (scope == _PreferenceScope.application ||
            workspaceId == _settingsWorkspaceId);
    try {
      final loaded = scope == _PreferenceScope.application
          ? await client.readApplication()
          : await client.readWorkspace(workspaceId!);
      if (!current()) return;
      setState(() => form.accept(loaded));
    } on Exception catch (error) {
      if (!current()) return;
      setState(() {
        form.loading = false;
        form.problem = 'load';
        form.diagnostic = _settingsDiagnostic(error);
      });
    }
  }

  Future<void> _loadApplicationSettings() =>
      _loadSettings(_PreferenceScope.application);

  Future<void> _loadWorkspaceSettings(
    String? workspaceId, {
    bool force = false,
  }) async {
    if (_settingsWorkspaceId == workspaceId && !force) return;
    if (_settingsWorkspaceId != workspaceId) {
      _settingsWorkspaceId = workspaceId;
      _workspaceSettings.reset();
    }
    if (workspaceId == null) {
      if (mounted) {
        setState(() {
          if (_preferenceScope == _PreferenceScope.workspace) {
            _preferenceScope = _PreferenceScope.application;
          }
        });
      }
      return;
    }
    await _loadSettings(_PreferenceScope.workspace, workspaceId: workspaceId);
  }

  void _selectPreferenceScope(_PreferenceScope value) {
    if (value == _preferenceScope) return;
    setState(() {
      for (final form in [_applicationSettings, _workspaceSettings]) {
        form.generation++;
        if (form.loading || form.saving) form.loaded = false;
        form.loading = form.saving = false;
      }
      _selectedSettings.cancel();
      _preferenceScope = value;
      _selectedSettings.cancel();
    });
    if (!_applicationSettings.loaded) {
      unawaited(_loadApplicationSettings());
    }
    if (value == _PreferenceScope.workspace && !_workspaceSettings.loaded) {
      unawaited(_loadWorkspaceSettings(_settingsWorkspaceId, force: true));
    }
  }

  void _changePreferenceDraft(_Preferences value) => setState(() {
    _selectedSettings.draft = value;
    _selectedSettings.savedAt = null;
  });

  Future<void> _retrySettings() {
    if (widget.settings == null) {
      widget.onRetry?.call();
      return Future.value();
    }
    return _preferenceScope == _PreferenceScope.application ||
            (_preferenceScope == _PreferenceScope.workspace &&
                _workspaceSettings.loaded &&
                _workspaceSettings.inheritsDraft &&
                !_applicationSettings.loaded)
        ? _loadApplicationSettings()
        : _loadWorkspaceSettings(_settingsWorkspaceId, force: true);
  }

  Future<bool> _persistPreferences(
    _PreferenceScope scope,
    _Preferences value, {
    required bool inherits,
    bool allowUnselectedScope = false,
  }) async {
    final client = widget.settings;
    final workspaceId = scope == _PreferenceScope.workspace
        ? _settingsWorkspaceId
        : null;
    final form = scope == _PreferenceScope.application
        ? _applicationSettings
        : _workspaceSettings;
    if (client == null ||
        !form.loaded ||
        form.saving ||
        (scope == _PreferenceScope.workspace && workspaceId == null)) {
      return false;
    }
    final generation = ++form.generation;
    setState(() {
      form.saving = true;
      form.problem = null;
      form.savedAt = null;
    });
    bool current() =>
        mounted &&
        generation == form.generation &&
        (allowUnselectedScope || scope == _preferenceScope) &&
        workspaceId ==
            (scope == _PreferenceScope.workspace
                ? _settingsWorkspaceId
                : null) &&
        client == widget.settings;
    try {
      final saved = scope == _PreferenceScope.application
          ? await client.saveApplication(_snapshot(value, inherits: false))
          : await client.saveWorkspace(
              workspaceId!,
              _snapshot(value, inherits: inherits),
            );
      if (!current()) return false;
      setState(() {
        form.accept(saved);
        form.savedAt = DateTime.now();
      });
      return true;
    } on Exception catch (error) {
      if (current()) {
        setState(() {
          form.saving = false;
          form.problem = 'save';
          form.diagnostic = _settingsDiagnostic(error);
        });
      }
      return false;
    }
  }

  Future<void> _savePreferences() async {
    await _persistPreferences(
      _preferenceScope,
      _selectedDraft,
      inherits: _selectedInherits,
    );
  }

  void _cancelPreferences() => setState(() => _selectedSettings.cancel());

  @override
  void initState() {
    super.initState();
    _game.addListener(_gameChanged);
    _mods.addListener(_modsChanged);
    _files.addListener(_diagnosticInputsChanged);
    _plugins.addListener(_diagnosticInputsChanged);
    _outputs.onChanged = _outputsChanged;
    _deployments.onChanged = _deploymentChanged;
    _plugins.onChanged = () {
      _play.invalidate();
      _profileData.invalidate();
      _archives.invalidate();
    };
    _archives.onChanged = () {
      _play.invalidate();
      _profileData.invalidate();
    };
    _profileData.onChanged = () {
      _play.invalidate();
      _plugins.invalidate();
      _archives.invalidate();
    };
    _play.onDeploymentChanged = () {
      _profileData.invalidate();
      _deployments.invalidate();
      _deploymentChanged();
    };
    _workspaces.addListener(_syncWorkspaceConsumers);
    _workspaces.attach(widget.workspaces);
    _syncWorkspaceConsumers();
    unawaited(_loadApplicationSettings());
  }

  @override
  void didUpdateWidget(ModConductorApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    _workspaces.attach(widget.workspaces);
    _syncWorkspaceConsumers();
    if (oldWidget.settings != widget.settings) {
      unawaited(_loadApplicationSettings());
      unawaited(_loadWorkspaceSettings(_workspaces.workspace?.id, force: true));
    }
  }

  @override
  void dispose() {
    ++_setupEventEpoch;
    _syncInstallationScope(null, null, null);
    _setupReconnect?.cancel();
    unawaited(_setupEvents?.cancel() ?? Future.value());
    _workspaces.removeListener(_syncWorkspaceConsumers);
    _game.removeListener(_gameChanged);
    _mods.removeListener(_modsChanged);
    _files.removeListener(_diagnosticInputsChanged);
    _plugins.removeListener(_diagnosticInputsChanged);
    _outputs.dispose();
    _deployments.dispose();
    _artifacts.dispose();
    _nexusDetails.dispose();
    _executables.dispose();
    _play.dispose();
    _profileData.dispose();
    _plugins.dispose();
    _sortOrder.dispose();
    _archives.dispose();
    _files.dispose();
    _diagnostics.dispose();
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

  Future<void> _quickTheme(AppearancePreference value) async {
    final scope =
        _settingsWorkspaceId != null &&
            _workspaceSettings.loaded &&
            !_workspaceSettings.inheritsApplied
        ? _PreferenceScope.workspace
        : _PreferenceScope.application;
    final form = scope == _PreferenceScope.application
        ? _applicationSettings
        : _workspaceSettings;
    if (!form.loaded) return;
    final current = form.applied;
    await _persistPreferences(
      scope,
      (
        appearance: value,
        textScale: current.textScale,
        interfaceScale: current.interfaceScale,
        contrast: current.contrast,
      ),
      inherits: false,
      allowUnselectedScope: true,
    );
  }

  String _profileSetupFailure(Object failure) {
    if (failure case GameContextException(:final detail, :final candidate)) {
      final problems = candidate?.problems.map((item) => item.detail).toList();
      return problems == null || problems.isEmpty
          ? detail
          : problems.join('\n');
    }
    if (failure case WorkspaceException(:final detail)) return detail;
    return 'Profile setup did not return a result. Try again.';
  }

  Future<String?> _saveProfileSetup(
    WorkspaceInfo workspace,
    ProfileInfo profile,
    ProfileSetupSelection selection,
  ) async {
    final client = widget.gameContexts;
    final state = _game.state;
    if (client == null ||
        state == null ||
        state.workspaceId != workspace.id ||
        state.profileId != profile.id) {
      return 'The profile setup is not ready. Try again.';
    }
    try {
      final saved = await client.save(
        workspace.id,
        profile.id,
        selection.game.id,
        state.revision,
        selection.installation,
      );
      _game.accept(saved, client);
      return null;
    } on Exception catch (failure) {
      return _profileSetupFailure(failure);
    }
  }

  Widget _profileSetupGate(
    BuildContext context,
    WorkspaceInfo workspace,
    ProfileInfo profile,
  ) {
    final state = _game.state;
    final binding = state?.binding;
    if (_game.loading && (state == null || binding?.needsCheck == true)) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: const McActionFeedback(
            kind: McActionFeedbackKind.pending,
            message: 'Checking profile setup',
          ),
        ),
      );
    }
    if (state == null) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              McActionFeedback(
                kind: McActionFeedbackKind.failure,
                message: _game.problem ?? 'The profile setup is not available.',
              ),
              const SizedBox(height: McSpacing.medium),
              McAction(
                label: 'Try again',
                icon: Icons.refresh,
                onPressed: _game.client == null
                    ? null
                    : () => unawaited(_game.load()),
              ),
            ],
          ),
        ),
      );
    }
    return ProfileSetupSurface(
      key: ValueKey(('profile-setup', profile.id)),
      initialName: profile.name,
      nameEditable: false,
      games: _profileSetupGames,
      discovery: widget.steamDiscovery,
      chooseDirectory: widget.chooseGameDirectory,
      initialInstallation: binding?.path,
      initialProblem: _game.problem ?? binding?.failure,
      actionLabel: 'Save profile',
      onSubmit: (selection) => _saveProfileSetup(workspace, profile, selection),
    );
  }

  Future<void> _createProfile(
    BuildContext context,
    WorkspaceInfo workspace,
  ) async {
    final pendingProfileId = newOperationId();
    ProfileInfo? created;
    GameContextState? committedContext;
    GameContextsClient? committedClient;
    ProfileSetupSelection? committedSelection;
    ProfileSetupSelection? attemptedSelection;
    var selectionAttempted = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760, maxHeight: 760),
          child: ProfileSetupSurface(
            initialName: '',
            games: _profileSetupGames,
            discovery: widget.steamDiscovery,
            chooseDirectory: widget.chooseGameDirectory,
            actionLabel: 'Create profile',
            canCancel: true,
            onCancel: () => Navigator.pop(dialogContext),
            onComplete: () => Navigator.pop(dialogContext),
            onSubmit: (selection) async {
              if (_workspaces.workspace?.id != workspace.id) {
                return 'The workspace changed. Start profile setup again.';
              }
              final client = widget.gameContexts;
              if (client == null) {
                return 'The profile setup is not available.';
              }
              created ??= await _workspaces.createProfile(
                selection.name,
                profileId: pendingProfileId,
              );
              final profile = created;
              if (profile == null) {
                return _workspaces.currentProblem ??
                    'The profile could not be created.';
              }
              try {
                var saved = committedContext;
                if (saved == null ||
                    !identical(committedClient, client) ||
                    !_sameProfileSetup(committedSelection, selection)) {
                  final loaded = await client.read(workspace.id, profile.id);
                  if (_sameProfileSetup(attemptedSelection, selection) &&
                      _profileSetupIsReady(loaded, selection)) {
                    saved = loaded;
                  } else {
                    attemptedSelection = selection;
                    committedContext = null;
                    committedClient = null;
                    committedSelection = null;
                    saved = await client.save(
                      workspace.id,
                      profile.id,
                      selection.game.id,
                      loaded.revision,
                      selection.installation,
                    );
                  }
                  committedContext = saved;
                  committedClient = client;
                  committedSelection = selection;
                }
                if (selectionAttempted) {
                  await _workspaces.refresh();
                  if (_workspaces.currentProblem != null) {
                    return _workspaces.currentProblem;
                  }
                }
                if (_workspaces.workspace?.id != workspace.id) {
                  return 'The workspace changed. Start profile setup again.';
                }
                if (_workspaces.workspace?.selectedProfile?.id != profile.id) {
                  selectionAttempted = true;
                  await _workspaces.select(profile);
                }
                if (_workspaces.workspace?.selectedProfile?.id != profile.id) {
                  return _workspaces.currentProblem ??
                      'The profile was created but did not open.';
                }
                selectionAttempted = false;
                _game.accept(saved, client);
                return null;
              } on Exception catch (failure) {
                return _profileSetupFailure(failure);
              }
            },
          ),
        ),
      ),
    );
  }

  bool _sameProfileSetup(
    ProfileSetupSelection? previous,
    ProfileSetupSelection current,
  ) =>
      previous?.game.id == current.game.id &&
      previous?.installation == current.installation;

  bool _profileSetupIsReady(
    GameContextState state,
    ProfileSetupSelection selection,
  ) {
    final binding = state.binding;
    return state.definition?.id == selection.game.id &&
        binding != null &&
        !binding.needsCheck &&
        binding.failure == null &&
        binding.evidence.problems.isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final preferences = _effectivePreferences;
    final explicitHigh = preferences.contrast == ContrastPreference.high;
    final systemContrast = preferences.contrast == ContrastPreference.system;
    final allowPlatformHighContrast =
        preferences.contrast != ContrastPreference.standard;
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      localeListResolutionCallback: _resolveAppLocale,
      theme: mcTheme(Brightness.light, highContrast: explicitHigh),
      darkTheme: mcTheme(Brightness.dark, highContrast: explicitHigh),
      highContrastTheme: mcTheme(
        Brightness.light,
        highContrast: allowPlatformHighContrast,
      ),
      highContrastDarkTheme: mcTheme(
        Brightness.dark,
        highContrast: allowPlatformHighContrast,
      ),
      themeMode: _themeMode(preferences.appearance),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: _PreferenceTextScaler(
              media.textScaler,
              preferences.textScale,
            ),
            highContrast: systemContrast ? media.highContrast : explicitHigh,
          ),
          child: McUiScale(
            scale: preferences.interfaceScale,
            child: McUiLocalization(
              labels: _uiLabels(AppLocalizations.of(context)),
              child: child!,
            ),
          ),
        );
      },
      home: Builder(
        builder: (context) => CallbackShortcuts(
          bindings: {
            const SingleActivator(
              LogicalKeyboardKey.comma,
              control: true,
            ): () =>
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
              requests.selectContext(
                _workspaces.workspace?.id,
                _workspaces.workspace?.selectedProfile?.id,
              );
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
            labels: AppLocalizations.of(context),
            onToggleTheme: !_applicationSettings.loaded
                ? null
                : () => unawaited(
                    _quickTheme(
                      Theme.of(context).brightness == Brightness.dark
                          ? AppearancePreference.light
                          : AppearancePreference.dark,
                    ),
                  ),
            child: IndexedStack(
              index: _destination.index,
              children: [
                ExcludeFocus(
                  excluding: _destination != _Destination.workspaces,
                  child: switch (widget.status) {
                    DesktopFailure(:final reason) => _FailurePage(
                      labels: AppLocalizations.of(context),
                      reason: reason,
                      onRetry: widget.onRetry,
                      onPreferences: () => _navigate(_Destination.preferences),
                    ),
                    DesktopDisconnected() ||
                    DesktopConnecting() ||
                    DesktopConnected() => WorkspaceBrowser(
                      controller: _workspaces,
                      openFolder: widget.openWorkspaceFolder,
                      profileCreator: _createProfile,
                      profileSetupBuilder: _profileSetupGate,
                      workbenchReady: _gameReady,
                      profileInspectorBuilder:
                          !_supportsSkyrim || widget.profileData == null
                          ? null
                          : (context, workspace, profile, close, bindGuard) =>
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
                                  onNavigationGuardChanged: bindGuard,
                                  onResumeProfileChange:
                                      _workspaces.resumeProfileChange,
                                  pluginHeadersId: _plugins.order?.headers.id,
                                ),
                      executableBuilder:
                          !_supportsSkyrim || widget.executables == null
                          ? null
                          : (context, workspace) => ExecutablesBrowser(
                              controller: _executables,
                              chooseExecutable: widget.chooseExecutable,
                              chooseDirectory: widget.chooseGameDirectory,
                              fnis: widget.fnis,
                              workspace: workspace,
                            ),
                      artifactBuilder:
                          !_supportsArchives || widget.artifacts == null
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
                              onInstallationDetached: (status) =>
                                  _observeDetachedInstallation(
                                    widget.installations!,
                                    status,
                                    workspace.selectedProfile?.id,
                                  ),
                              onInstallationAttached: (status) =>
                                  _installationReattached(
                                    status,
                                    workspace.selectedProfile?.id,
                                  ),
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
                      helpBuilder:
                          !_supportsSkyrim || widget.diagnostics == null
                          ? null
                          : (context, workspace, actions) => HelpBrowser(
                              controller: _diagnostics,
                              settingsDiagnostic: _settingsHelpDiagnostic,
                              onCreateWorkspace: actions.createWorkspace,
                              onOpenWorkspace: actions.openWorkspace,
                              onCreateProfile: actions.createProfile,
                              onOpenSkyrimSetup:
                                  widget.skyrimSetup == null ||
                                      workspace?.selectedProfile == null
                                  ? null
                                  : _workspaces.showGame,
                            ),
                      compactCloseAction:
                          widget.gameLaunching != null &&
                          MediaQuery.sizeOf(context).width < 950,
                      headerActions:
                          !_supportsSkyrim ||
                              (widget.deployments == null &&
                                  widget.migration == null)
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
                                  child: DeploymentAction(
                                    controller: _deployments,
                                  ),
                                ),
                              if (widget.gameLaunching != null &&
                                  widget.deployments != null)
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
                                      _game
                                              .state
                                              ?.binding
                                              ?.evidence
                                              .definitionId !=
                                          'skyrim-se-steam'
                                  ? null
                                  : Padding(
                                      padding: const EdgeInsets.only(
                                        top: McSpacing.large,
                                      ),
                                      child: SkyrimSetupSection(
                                        client: widget.skyrimSetup!,
                                        chooseArchive: widget.chooseArchive,
                                        workspaceId: workspace.id,
                                        profileId:
                                            workspace.selectedProfile!.id,
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
                                      onMapped:
                                          _mods.inventory.refreshCatalogue,
                                      organization: widget.modOrganization,
                                      localCategories:
                                          _mods.selected?.metadata.categories ??
                                          const [],
                                      onDownloaded:
                                          (artifact, details, version) async {
                                            await _artifacts.load();
                                            _artifacts.model.select(
                                              artifact.id,
                                            );
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
                                      workspacePath: workspace.path,
                                      chooseDirectory: widget.chooseDirectory,
                                      inventoryExports: widget.inventoryExports,
                                      chooseExportLocation:
                                          widget.chooseExportLocation,
                                      openExportFolder: widget.openExportFolder,
                                      profileName:
                                          workspace.selectedProfile?.name,
                                    )
                                  : widget.outputs == null
                                  ? FilePlanningWorkbench(
                                      mods: _mods,
                                      onOpenNexus: widget.nexusMetadata == null
                                          ? null
                                          : _nexusDetails.open,
                                      maintenance: widget.maintenance,
                                      plans: _files,
                                      onOpenProblems: _workspaces.showHelp,
                                      plugins: widget.bethesda == null
                                          ? null
                                          : _plugins,
                                      archives: widget.archivePolicies == null
                                          ? null
                                          : _archives,
                                      sortOrder: widget.loot == null
                                          ? null
                                          : _sortOrder,
                                      workspacePath: workspace.path,
                                      chooseDirectory: widget.chooseDirectory,
                                      profileName:
                                          workspace.selectedProfile?.name,
                                      inventoryExports: widget.inventoryExports,
                                      chooseExportLocation:
                                          widget.chooseExportLocation,
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
                                      plans: _files,
                                      onOpenProblems: _workspaces.showHelp,
                                      plugins: widget.bethesda == null
                                          ? null
                                          : _plugins,
                                      archives: widget.archivePolicies == null
                                          ? null
                                          : _archives,
                                      sortOrder: widget.loot == null
                                          ? null
                                          : _sortOrder,
                                      outputs: _outputs,
                                      profileId: workspace.selectedProfile?.id,
                                      organization: widget.modOrganization,
                                      workspacePath: workspace.path,
                                      chooseDirectory: widget.chooseDirectory,
                                      profileName:
                                          workspace.selectedProfile?.name,
                                      inventoryExports: widget.inventoryExports,
                                      chooseExportLocation:
                                          widget.chooseExportLocation,
                                      openExportFolder: widget.openExportFolder,
                                      archiveUnavailable:
                                          _game.state?.definition?.unavailable(
                                            GameCapabilityId.archiveInspection,
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
                    labels: AppLocalizations.of(context),
                    credentials: widget.credentials,
                    nexus: widget.nexus,
                    linkSetup: widget.linkSetup,
                    scope: _preferenceScope,
                    onScope: _selectPreferenceScope,
                    workspaceAvailable: _settingsWorkspaceId != null,
                    inheritsApplication: _workspaceSettings.inheritsDraft,
                    inheritsApplicationApplied:
                        _workspaceSettings.inheritsApplied,
                    onInheritsApplication: (value) => setState(() {
                      _workspaceSettings.inheritsDraft = value;
                      _workspaceSettings.draft =
                          value || _workspaceSettings.inheritsApplied
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
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
