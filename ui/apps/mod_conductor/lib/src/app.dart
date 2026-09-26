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
part 'help_articles.dart';
part 'diagnostics_controller.dart';
part 'help_browser.dart';
part 'app_settings.dart';
part 'app_workspace_scope.dart';
part 'app_capability_consumers.dart';
part 'app_desktop_requests.dart';
part 'app_profile_creation.dart';
part 'app_state.dart';
part 'app_shell_content.dart';

void _quitDesktop() {
  ServicesBinding.instance.exitApplication(AppExitType.cancelable);
}

void startDesktop() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DesktopHost());
}

enum _Destination { workspaces, preferences }

class _RequestRouteObserver extends NavigatorObserver {
  _RequestRouteObserver(this.onRouteClosed);

  final VoidCallback onRouteClosed;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onRouteClosed();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onRouteClosed();
  }
}

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

class _ModConductorAppState extends _AppStateBase
    with
        _SettingsScope,
        _WorkspaceScope,
        _CapabilityConsumers,
        _DesktopRequests,
        _ProfileCreation,
        _ShellContent {
  late final _RequestRouteObserver _requestRoutes = _RequestRouteObserver(
    _requestRouteClosed,
  );
  @override
  void initState() {
    super.initState();
    widget.desktopRequests?.addListener(_requestsChanged);
    _scheduleIncomingRequest();
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
    if (oldWidget.desktopRequests != widget.desktopRequests) {
      oldWidget.desktopRequests?.removeListener(_requestsChanged);
      widget.desktopRequests?.addListener(_requestsChanged);
      _presentedRequestId = null;
      _scheduleIncomingRequest();
    }
    _workspaces.attach(widget.workspaces);
    _syncWorkspaceConsumers();
    if (oldWidget.settings != widget.settings) {
      unawaited(_loadApplicationSettings());
      unawaited(_loadWorkspaceSettings(_workspaces.workspace?.id, force: true));
    }
  }

  @override
  void dispose() {
    widget.desktopRequests?.removeListener(_requestsChanged);
    _wakeModalSpaceWaiters();
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

  @override
  Widget build(BuildContext context) {
    final preferences = _effectivePreferences;
    final explicitHigh = preferences.contrast == ContrastPreference.high;
    final systemContrast = preferences.contrast == ContrastPreference.system;
    final allowPlatformHighContrast =
        preferences.contrast != ContrastPreference.standard;
    return MaterialApp(
      navigatorObservers: [_requestRoutes],
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
            key: _requestShellKey,
            requests: widget.desktopRequests,
            onRequests: () => unawaited(_presentRequests(context)),
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
                    DesktopConnected() => _buildWorkspaceBrowser(context),
                  },
                ),
                ExcludeFocus(
                  excluding: _destination != _Destination.preferences,
                  child: _buildPreferencesPage(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
