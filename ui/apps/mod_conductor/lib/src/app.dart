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
  double scale,
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
  scale: 1.0,
  contrast: ContrastPreference.system,
);

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
  scale: value.presentation.textScale,
  contrast: value.presentation.contrast,
);

SettingsSnapshot _snapshot(_Preferences value, {required bool inherits}) =>
    SettingsSnapshot(
      presentation: PresentationPreferences(
        appearance: value.appearance,
        textScale: value.scale,
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
  _Preferences _applicationApplied = _defaultPreferences;
  _Preferences _applicationDraft = _defaultPreferences;
  _Preferences _workspaceApplied = _defaultPreferences;
  _Preferences _workspaceDraft = _defaultPreferences;
  bool _workspaceInheritsApplied = true;
  bool _workspaceInheritsDraft = true;
  bool _settingsBusy = false;
  String? _settingsProblem;
  String? _settingsWorkspaceId;
  DateTime? _settingsSavedAt;
  int _applicationSettingsGeneration = 0;
  int _workspaceSettingsGeneration = 0;
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
  int? _selectionRevision, _catalogueRevision;
  int? _contextRevision;
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

  void _diagnosticInputsChanged() {
    final receipt = _deployments.receipt;
    _diagnostics.attach(
      widget.diagnostics,
      _workspaces.workspace?.id,
      _workspaces.workspace?.selectedProfile?.id,
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
    if (mounted) setState(() {});
  }

  void _syncWorkspaceConsumers() {
    _play.attach(
      widget.gameLaunching,
      widget.executables,
      _workspaces.workspace,
      available: _workspaces.canEdit,
      fnis: widget.fnis,
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
    _plugins.resumeAction = () => _profileData.resumeSelected(
      widget.profileData,
      _workspaces.workspace!.id,
      _workspaces.workspace!.selectedProfile!.id,
      available: _workspaces.canEdit,
    );
    _plugins.attach(
      widget.bethesda,
      _workspaces.workspace?.selectedProfile?.id,
      orders: widget.pluginOrders,
    );
    _sortOrder.attach(
      widget.loot,
      _plugins,
      _workspaces.workspace?.selectedProfile?.id,
    );
    _archives.resumeAction = _plugins.resumeAction;
    _archives.attach(
      widget.archivePolicies,
      _plugins,
      _workspaces.workspace?.id,
      _workspaces.workspace?.selectedProfile?.id,
    );
    _files.attach(
      widget.filePlans,
      _workspaces.workspace?.selectedProfile?.id,
      available: _workspaces.canEdit,
    );
    _diagnosticInputsChanged();
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
      workspaceRevision: _workspaces.workspace?.revision,
      editable: _workspaces.canEdit,
    );
    _loadWorkspaceSettings(_workspaces.workspace?.id);
  }

  _Preferences get _effectivePreferences =>
      _settingsWorkspaceId != null && !_workspaceInheritsApplied
      ? _workspaceApplied
      : _applicationApplied;

  _Preferences get _selectedApplied =>
      _preferenceScope == _PreferenceScope.application
      ? _applicationApplied
      : _workspaceInheritsApplied
      ? _applicationApplied
      : _workspaceApplied;

  _Preferences get _selectedDraft =>
      _preferenceScope == _PreferenceScope.application
      ? _applicationDraft
      : _workspaceInheritsDraft
      ? _applicationApplied
      : _workspaceDraft;

  bool get _selectedInherits =>
      _preferenceScope == _PreferenceScope.workspace && _workspaceInheritsDraft;

  Future<void> _loadApplicationSettings() async {
    final client = widget.settings;
    if (client == null) return;
    final generation = ++_applicationSettingsGeneration;
    try {
      final loaded = await client.readApplication();
      if (!mounted || generation != _applicationSettingsGeneration) return;
      setState(() {
        _applicationApplied = _preferences(loaded);
        _applicationDraft = _applicationApplied;
        _settingsProblem = null;
      });
    } on Exception {
      if (!mounted || generation != _applicationSettingsGeneration) return;
      setState(() => _settingsProblem = 'load');
    }
  }

  Future<void> _loadWorkspaceSettings(String? workspaceId) async {
    if (_settingsWorkspaceId == workspaceId) return;
    _settingsWorkspaceId = workspaceId;
    _workspaceApplied = _workspaceDraft = _applicationApplied;
    _workspaceInheritsApplied = _workspaceInheritsDraft = true;
    final generation = ++_workspaceSettingsGeneration;
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
    final client = widget.settings;
    if (client == null) return;
    try {
      final loaded = await client.readWorkspace(workspaceId);
      if (!mounted ||
          generation != _workspaceSettingsGeneration ||
          workspaceId != _settingsWorkspaceId) {
        return;
      }
      setState(() {
        _workspaceApplied = _preferences(loaded);
        _workspaceDraft = _workspaceApplied;
        _workspaceInheritsApplied = loaded.inheritsApplication;
        _workspaceInheritsDraft = loaded.inheritsApplication;
        _settingsProblem = null;
      });
    } on Exception {
      if (!mounted ||
          generation != _workspaceSettingsGeneration ||
          workspaceId != _settingsWorkspaceId) {
        return;
      }
      setState(() => _settingsProblem = 'load');
    }
  }

  void _selectPreferenceScope(_PreferenceScope value) => setState(() {
    _preferenceScope = value;
    if (value == _PreferenceScope.application) {
      _applicationDraft = _applicationApplied;
    } else {
      _workspaceDraft = _workspaceApplied;
      _workspaceInheritsDraft = _workspaceInheritsApplied;
    }
  });

  void _changePreferenceDraft(_Preferences value) => setState(() {
    if (_preferenceScope == _PreferenceScope.application) {
      _applicationDraft = value;
    } else {
      _workspaceDraft = value;
    }
  });

  Future<bool> _persistPreferences(
    _PreferenceScope scope,
    _Preferences value, {
    required bool inherits,
  }) async {
    final client = widget.settings;
    final workspaceId = scope == _PreferenceScope.workspace
        ? _settingsWorkspaceId
        : null;
    if (scope == _PreferenceScope.workspace && workspaceId == null) {
      return false;
    }
    final generation = scope == _PreferenceScope.application
        ? ++_applicationSettingsGeneration
        : ++_workspaceSettingsGeneration;

    bool isCurrent() => scope == _PreferenceScope.application
        ? generation == _applicationSettingsGeneration
        : generation == _workspaceSettingsGeneration &&
              workspaceId == _settingsWorkspaceId;

    SettingsSnapshot saved;
    if (client == null) {
      saved = _snapshot(value, inherits: inherits);
    } else {
      try {
        saved = scope == _PreferenceScope.application
            ? await client.saveApplication(_snapshot(value, inherits: false))
            : await client.saveWorkspace(
                workspaceId!,
                _snapshot(value, inherits: inherits),
              );
      } on Exception {
        if (mounted && isCurrent()) {
          setState(() => _settingsProblem = 'save');
        }
        return false;
      }
    }
    if (!mounted || !isCurrent()) return false;
    setState(() {
      final applied = _preferences(saved);
      if (scope == _PreferenceScope.application) {
        _applicationApplied = _applicationDraft = applied;
      } else {
        _workspaceApplied = _workspaceDraft = applied;
        _workspaceInheritsApplied = _workspaceInheritsDraft =
            saved.inheritsApplication;
      }
      _settingsProblem = null;
      _settingsSavedAt = DateTime.now();
    });
    return true;
  }

  Future<void> _savePreferences() async {
    if (_settingsBusy) return;
    setState(() => _settingsBusy = true);
    await _persistPreferences(
      _preferenceScope,
      _selectedDraft,
      inherits: _selectedInherits,
    );
    if (mounted) setState(() => _settingsBusy = false);
  }

  void _cancelPreferences() => setState(() {
    if (_preferenceScope == _PreferenceScope.application) {
      _applicationDraft = _applicationApplied;
    } else {
      _workspaceDraft = _workspaceApplied;
      _workspaceInheritsDraft = _workspaceInheritsApplied;
    }
    _settingsProblem = null;
  });

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
      _settingsWorkspaceId = null;
      unawaited(_loadWorkspaceSettings(_workspaces.workspace?.id));
    }
  }

  @override
  void dispose() {
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
    final scope = _settingsWorkspaceId != null && !_workspaceInheritsApplied
        ? _PreferenceScope.workspace
        : _PreferenceScope.application;
    final current = scope == _PreferenceScope.application
        ? _applicationApplied
        : _workspaceApplied;
    await _persistPreferences(scope, (
      appearance: value,
      scale: current.scale,
      contrast: current.contrast,
    ), inherits: false);
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
        return McUiLocalization(
          labels: _uiLabels(AppLocalizations.of(context)),
          child: MediaQuery(
            data: media.copyWith(
              textScaler: _PreferenceTextScaler(
                media.textScaler,
                preferences.scale,
              ),
              highContrast: systemContrast ? media.highContrast : explicitHigh,
            ),
            child: child!,
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
            labels: AppLocalizations.of(context),
            onToggleTheme: () => unawaited(
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
                      profileInspectorBuilder: widget.profileData == null
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
                      helpBuilder: widget.diagnostics == null
                          ? null
                          : (context, workspace, actions) => HelpBrowser(
                              controller: _diagnostics,
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
                          widget.deployments == null && widget.migration == null
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
                      gameContextBuilder: (context, workspace) =>
                          GameContextBrowser(
                            controller: _game,
                            steamDiscovery: widget.steamDiscovery,
                            protonContexts: widget.protonContexts,
                            chooseDirectory: widget.chooseGameDirectory,
                            footer:
                                widget.skyrimSetup == null ||
                                    workspace.selectedProfile == null
                                ? null
                                : Padding(
                                    padding: const EdgeInsets.only(
                                      top: McSpacing.large,
                                    ),
                                    child: SkyrimSetupSection(
                                      client: widget.skyrimSetup!,
                                      chooseArchive: widget.chooseArchive,
                                      workspaceId: workspace.id,
                                      profileId: workspace.selectedProfile!.id,
                                    ),
                                  ),
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
                                    onOpenDeployment: widget.deployments == null
                                        ? null
                                        : () => showDialog<void>(
                                            context: context,
                                            builder: (_) => DeploymentDialog(
                                              controller: _deployments,
                                            ),
                                          ),
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
                                        _game.state?.definition.unavailable(
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
                                    onOpenDeployment: widget.deployments == null
                                        ? null
                                        : () => showDialog<void>(
                                            context: context,
                                            builder: (_) => DeploymentDialog(
                                              controller: _deployments,
                                            ),
                                          ),
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
                                        _game.state?.definition.unavailable(
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
                    inheritsApplication: _workspaceInheritsDraft,
                    inheritsApplicationApplied: _workspaceInheritsApplied,
                    onInheritsApplication: (value) => setState(() {
                      _workspaceInheritsDraft = value;
                      _workspaceDraft = value || _workspaceInheritsApplied
                          ? _applicationApplied
                          : _workspaceApplied;
                    }),
                    applied: _selectedApplied,
                    draft: _selectedDraft,
                    busy: _settingsBusy,
                    problem: _settingsProblem,
                    savedAt: _settingsSavedAt,
                    detailsFocus: _detailsFocus,
                    onDraft: _changePreferenceDraft,
                    onSave: () => unawaited(_savePreferences()),
                    onCancel: _cancelPreferences,
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
