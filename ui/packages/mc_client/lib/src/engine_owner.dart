import 'diagnostics_client.dart';
import 'plugin_order_client.dart';
import 'loot_client.dart';
import 'archive_policy_client.dart';
import 'bethesda_client.dart';
import 'link_setup_client.dart';
import 'nxm_client.dart';
import 'desktop_client.dart';
import 'nexus_client.dart';
import 'nexus_metadata_client.dart';
import 'credential_client.dart';
import 'fomod_client.dart';
import 'bain_client.dart';
import 'bundle_client.dart';
import 'maintenance_client.dart';
import 'installation_client.dart';
import 'artifact_client.dart';
import 'profile_data_client.dart';
import 'game_launch_client.dart';
import 'executable_client.dart';
import 'output_client.dart';
import 'deployment_client.dart';
import 'file_plan_client.dart';
import 'proton_context_client.dart';
import 'inventory_export_client.dart';
import 'migration_client.dart';
import 'settings_client.dart';
import 'skse_client.dart';

import 'dart:async';
import 'dart:io';

import 'engine_session.dart';
import 'operations_client.dart';
import 'workspaces_client.dart';
import 'mod_library_client.dart';
import 'profile_mod_client.dart';
import 'mod_organization_client.dart';
import 'game_context_client.dart';
import 'steam_discovery_client.dart';

sealed class EngineState {
  const EngineState();
}

final class EngineIdle extends EngineState {
  const EngineIdle();
}

final class EngineConnecting extends EngineState {
  const EngineConnecting();
}

final class EngineConnected extends EngineState {
  const EngineConnected(this.report);
  final ConnectionReport report;
}

enum EngineFailureReason { start, protocol, connection, crash, shutdown }

final class EngineFailure extends EngineState {
  const EngineFailure(this.reason, {required this.canRetry});
  final EngineFailureReason reason;
  final bool canRetry;
}

typedef EngineLauncher = Future<Process> Function(String executable);

Future<Process> _launch(String executable) =>
    Process.start(executable, const []);

class EngineOwner {
  EngineOwner(this.executable, {EngineLauncher launch = _launch})
    : _launchChild = launch;

  final String executable;
  final EngineLauncher _launchChild;
  final _changes = StreamController<EngineState>.broadcast();
  EngineState _state = const EngineIdle();
  EngineSession? _session;
  Future<void>? _connecting;
  Future<bool>? _closing;
  bool _stopping = false;
  int _attempt = 0;

  EngineState get state => _state;
  ProtonContextsClient? get protonContexts =>
      _state is EngineConnected ? _session?.protonContexts : null;
  SteamDiscoveryClient? get steamDiscovery =>
      _state is EngineConnected ? _session?.steamDiscovery : null;
  BainClient? get bain => _session?.bain;
  LinkSetupClient? get linkSetup =>
      _state is EngineConnected ? _session?.linkSetup : null;
  NxmClient? get nxm => _state is EngineConnected ? _session?.nxm : null;
  DesktopClient? get desktop =>
      _state is EngineConnected ? _session?.desktop : null;
  NexusMetadataClient? get nexusMetadata =>
      _state is EngineConnected ? _session?.nexusMetadata : null;
  NexusClient? get nexus => _state is EngineConnected ? _session?.nexus : null;
  CredentialsClient? get credentials =>
      _state is EngineConnected ? _session?.credentials : null;
  BundlesClient? get bundles =>
      _state is EngineConnected ? _session?.bundles : null;
  FomodClient? get fomod => _state is EngineConnected ? _session?.fomod : null;
  MaintenanceClient? get maintenance =>
      _state is EngineConnected ? _session?.maintenance : null;
  InstallationsClient? get installations =>
      _state is EngineConnected ? _session?.installations : null;
  ArtifactsClient? get artifacts =>
      _state is EngineConnected ? _session?.artifacts : null;
  ProfileDataClient? get profileData =>
      _state is EngineConnected ? _session?.profileData : null;
  GameLaunchingClient? get gameLaunching =>
      _state is EngineConnected ? _session?.gameLaunching : null;
  ExecutablesClient? get executables =>
      _state is EngineConnected ? _session?.executables : null;
  GeneratedOutputsClient? get outputs =>
      _state is EngineConnected ? _session?.outputs : null;
  DeploymentsClient? get deployments =>
      _state is EngineConnected ? _session?.deployments : null;
  PluginOrderClient? get pluginOrders =>
      _state is EngineConnected ? _session?.pluginOrders : null;
  LootClient? get loot => _state is EngineConnected ? _session?.loot : null;
  ArchivePolicyClient? get archivePolicies =>
      _state is EngineConnected ? _session?.archivePolicies : null;
  BethesdaClient? get bethesda =>
      _state is EngineConnected ? _session?.bethesda : null;
  FilePlansClient? get filePlans =>
      _state is EngineConnected ? _session?.filePlans : null;
  GameContextsClient? get gameContexts =>
      _state is EngineConnected ? _session?.gameContexts : null;
  ModOrganizationClient? get modOrganization =>
      _state is EngineConnected ? _session?.modOrganization : null;
  InventoryExportClient? get inventoryExports =>
      _state is EngineConnected ? _session?.inventoryExports : null;
  ProfileModsClient? get profileMods =>
      _state is EngineConnected ? _session?.profileMods : null;
  ModLibraryClient? get modLibrary =>
      _state is EngineConnected ? _session?.modLibrary : null;
  DiagnosticsClient? get diagnostics =>
      _state is EngineConnected ? _session?.diagnostics : null;
  WorkspacesClient? get workspaces =>
      _state is EngineConnected ? _session?.workspaces : null;
  MigrationClient? get migration =>
      _state is EngineConnected ? _session?.migration : null;
  SettingsClient? get settings =>
      _state is EngineConnected ? _session?.settings : null;
  SkseClient? get skse => _state is EngineConnected ? _session?.skse : null;
  Stream<EngineState> get changes => _changes.stream;

  void _set(EngineState state) {
    _state = state;
    _changes.add(state);
  }

  Future<void> connect() {
    if (_stopping || _session != null) return _connecting ?? Future.value();
    return _connecting ??= _connect(++_attempt)
        .whenComplete(() => _connecting = null);
  }

  Future<void> _connect(int attempt) async {
    _set(const EngineConnecting());
    var reason = EngineFailureReason.start;
    try {
      final session = EngineSession(await _launchChild(executable));
      _session = session;
      unawaited(
        session.exited.then((_) async {
          if (_session == session) {
            _session = null;
            if (!_stopping && attempt == _attempt) {
              _set(
                const EngineFailure(EngineFailureReason.crash, canRetry: true),
              );
            }
          }
          await session.close();
        }),
      );
      if (_stopping || attempt != _attempt) return;
      reason = EngineFailureReason.connection;
      await session.connect();
      final report = await session.check();
      if (!_stopping && attempt == _attempt && _session == session) {
        _set(EngineConnected(report));
      }
    } on Exception catch (error) {
      if (_stopping || attempt != _attempt) return;
      if (error is EngineProtocolMismatch) {
        reason = EngineFailureReason.protocol;
      }
      final session = _session;
      if (session != null) {
        try {
          await session.close();
          if (_session == session) _session = null;
        } on Exception {
          _set(
            const EngineFailure(EngineFailureReason.shutdown, canRetry: false),
          );
          return;
        }
      }
      _set(EngineFailure(reason, canRetry: true));
    }
  }

  Future<bool> close() =>
      _closing ??= _close().whenComplete(() => _closing = null);

  Future<bool> _close() async {
    _stopping = true;
    ++_attempt;
    try {
      await _connecting;
      final session = _session;
      await session?.close();
      _session = null;
      _set(const EngineIdle());
      return true;
    } on Exception {
      _set(const EngineFailure(EngineFailureReason.shutdown, canRetry: false));
      return false;
    } finally {
      _stopping = false;
    }
  }
}
