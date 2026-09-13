import 'plugin_order_client.dart';
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

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:grpc/grpc.dart';

import 'generated/modconductor/v1/bootstrap.pb.dart' as wire;
import 'operations_client.dart';
import 'workspaces_client.dart';
import 'mod_library_client.dart';
import 'profile_mod_client.dart';
import 'mod_organization_client.dart';
import 'game_context_client.dart';
import 'steam_discovery_client.dart';

class EngineSession {
  EngineSession(this._process) : _errors = _process.stderr.listen((_) {});

  final Process _process;
  final StreamSubscription<List<int>> _errors;
  ClientChannel? _channel;
  OperationsClient? _operations;
  OperationsClient get operations => _operations!;
  ProtonContextsClient? _protonContexts;
  ProtonContextsClient get protonContexts => _protonContexts!;
  SteamDiscoveryClient? _steamDiscovery;
  SteamDiscoveryClient get steamDiscovery => _steamDiscovery!;
  LinkSetupClient? _linkSetup;
  LinkSetupClient get linkSetup => _linkSetup!;
  NxmClient? _nxm;
  NxmClient get nxm => _nxm!;
  DesktopClient? _desktop;
  DesktopClient get desktop => _desktop!;
  NexusMetadataClient? _nexusMetadata;
  NexusMetadataClient get nexusMetadata => _nexusMetadata!;
  NexusClient? _nexus;
  NexusClient get nexus => _nexus!;
  CredentialsClient? _credentials;
  CredentialsClient get credentials => _credentials!;
  BundlesClient? _bundles;
  BundlesClient get bundles => _bundles!;
  BainClient? _bain;
  BainClient get bain => _bain!;
  FomodClient? _fomod;
  FomodClient get fomod => _fomod!;
  MaintenanceClient? _maintenance;
  MaintenanceClient get maintenance => _maintenance!;
  InstallationsClient? _installations;
  InstallationsClient get installations => _installations!;
  ArtifactsClient? _artifacts;
  ArtifactsClient get artifacts => _artifacts!;
  ProfileDataClient? _profileData;
  ProfileDataClient get profileData => _profileData!;
  GameLaunchingClient? _gameLaunching;
  GameLaunchingClient get gameLaunching => _gameLaunching!;
  ExecutablesClient? _executables;
  ExecutablesClient get executables => _executables!;
  GeneratedOutputsClient? _outputs;
  GeneratedOutputsClient get outputs => _outputs!;
  DeploymentsClient? _deployments;
  DeploymentsClient get deployments => _deployments!;
  PluginOrderClient? _pluginOrders;
  PluginOrderClient get pluginOrders => _pluginOrders!;
  BethesdaClient? _bethesda;
  BethesdaClient get bethesda => _bethesda!;
  FilePlansClient? _filePlans;
  FilePlansClient get filePlans => _filePlans!;
  GameContextsClient? _gameContexts;
  GameContextsClient get gameContexts => _gameContexts!;
  ModOrganizationClient? _modOrganization;
  ModOrganizationClient get modOrganization => _modOrganization!;
  ProfileModsClient? _profileMods;
  ProfileModsClient get profileMods => _profileMods!;
  ModLibraryClient? _modLibrary;
  ModLibraryClient get modLibrary => _modLibrary!;
  WorkspacesClient? _workspaces;
  WorkspacesClient get workspaces => _workspaces!;
  Future<void>? _closing;

  Future<int> get exited => _process.exitCode;

  Future<void> connect() async {
    final random = Random.secure();
    final capability = List.generate(
      32,
      (_) => random.nextInt(256),
    ).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    _process.stdin.writeln(capability);
    await _process.stdin.flush();
    final ready = await _readReady(_process.stdout)
        .timeout(const Duration(seconds: 10));
    if (ready.protocolMajor != 1) {
      throw const EngineProtocolMismatch();
    }
    if (ready.port < 1 || ready.port > 65535 || ready.certificatePem.isEmpty) {
      throw const FormatException('Invalid engine descriptor.');
    }
    final channel = ClientChannel(
      '127.0.0.1',
      port: ready.port,
      options: ChannelOptions(
        credentials: ChannelCredentials.secure(
          certificates: ready.certificatePem,
          authority: 'localhost',
        ),
        connectTimeout: const Duration(seconds: 2),
      ),
    );
    _channel = channel;
    final options = CallOptions(
      timeout: const Duration(seconds: 5),
      metadata: {'mc-session': capability},
    );
    _operations = OperationsClient(channel, options);
    _workspaces = GrpcWorkspacesClient(channel, options);
    _modLibrary = ModLibraryClient(channel, options);
    _profileMods = ProfileModsClient(channel, options);
    _modOrganization = ModOrganizationClient(channel, options);
    _pluginOrders = GrpcPluginOrderClient(
      channel,
      CallOptions(metadata: options.metadata),
    );
    _bethesda = GrpcBethesdaClient(
      channel,
      CallOptions(metadata: options.metadata),
    );

    _filePlans = GrpcFilePlansClient(
      channel,
      CallOptions(metadata: options.metadata),
    );
    _executables = GrpcExecutablesClient(
      channel,
      CallOptions(metadata: options.metadata),
    );
    _gameLaunching = GrpcGameLaunchingClient(
      channel,
      CallOptions(metadata: options.metadata),
    );
    _bain = GrpcBainClient(channel, CallOptions(metadata: options.metadata));
    _desktop = GrpcDesktopClient(channel, options);
    _nxm = NxmClient(channel, options);
    _linkSetup = LinkSetupClient(channel, options);
    _nexusMetadata = GrpcNexusMetadataClient(
      channel,
      CallOptions(metadata: options.metadata),
    );
    _nexus = GrpcNexusClient(channel, CallOptions(metadata: options.metadata));
    _credentials = GrpcCredentialsClient(
      channel,
      CallOptions(
        metadata: options.metadata,
        timeout: const Duration(seconds: 20),
      ),
    );
    _bundles = GrpcBundlesClient(
      channel,
      CallOptions(metadata: options.metadata),
    );
    _fomod = GrpcFomodClient(channel, CallOptions(metadata: options.metadata));
    _maintenance = GrpcMaintenanceClient(
      channel,
      CallOptions(metadata: options.metadata),
    );
    _installations = GrpcInstallationsClient(
      channel,
      CallOptions(metadata: options.metadata),
    );
    _artifacts = GrpcArtifactsClient(
      channel,
      CallOptions(metadata: options.metadata),
    );
    _profileData = GrpcProfileDataClient(
      channel,
      CallOptions(metadata: options.metadata),
    );
    _outputs = GrpcGeneratedOutputsClient(
      channel,
      CallOptions(metadata: options.metadata),
    );
    _deployments = GrpcDeploymentsClient(
      channel,
      CallOptions(metadata: options.metadata),
    );
    _gameContexts = GrpcGameContextsClient(channel, options);
    _steamDiscovery = GrpcSteamDiscoveryClient(channel, options);
    _protonContexts = GrpcProtonContextsClient(channel, options);
  }

  Future<ConnectionReport> check() => operations.check();

  Future<void> close() =>
      _closing ??= _close().whenComplete(() => _closing = null);

  Future<void> _close() async {
    await _channel?.terminate();
    try {
      await _process.stdin.close();
    } on IOException {
      // An exited child can close its pipe before the owner does.
    }
    await _process.exitCode.timeout(const Duration(seconds: 3));
    await _errors.cancel();
  }
}

class EngineProtocolMismatch implements Exception {
  const EngineProtocolMismatch();
}

Future<wire.EngineReady> _readReady(Stream<List<int>> output) async {
  final bytes = <int>[];
  await for (final chunk in output) {
    for (final byte in chunk) {
      if (byte == 10) {
        return wire.EngineReady.fromBuffer(
          base64.decode(ascii.decode(bytes).trim()),
        );
      }
      if (bytes.length == 4096) {
        throw const FormatException('Engine descriptor is too long.');
      }
      bytes.add(byte);
    }
  }
  throw const FormatException('The engine stopped before it was ready.');
}
