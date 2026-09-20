part of 'app.dart';

class DesktopHost extends StatefulWidget {
  const DesktopHost({super.key, this.engineExecutable, this.stateDirectory});
  final String? engineExecutable;
  final String? stateDirectory;

  @override
  State<DesktopHost> createState() => _DesktopHostState();
}

class _DesktopHostState extends State<DesktopHost> with WidgetsBindingObserver {
  late final EngineOwner _owner;
  late final DesktopRequests _requests;
  late final StreamSubscription<EngineState> _changes;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final name = Platform.isWindows
        ? 'ModConductor.Engine.exe'
        : 'ModConductor.Engine';
    final executable =
        widget.engineExecutable ??
        File.fromUri(
          File(Platform.resolvedExecutable).parent.uri.resolve('engine/$name'),
        ).path;
    _owner = EngineOwner(
      executable,
      launch: (path) => Process.start(path, [
        if (widget.stateDirectory != null) ...[
          '--state-directory',
          widget.stateDirectory!,
        ],
      ]),
    );
    _requests = DesktopRequests();
    _changes = _owner.changes.listen((_) {
      _requests.attach(_owner.desktop, nxm: _owner.nxm);
      if (mounted) setState(() {});
    });
    unawaited(_owner.connect());
  }

  @override
  Future<AppExitResponse> didRequestAppExit() async =>
      await _owner.close() ? AppExitResponse.exit : AppExitResponse.cancel;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _requests.dispose();
    unawaited(_changes.cancel());
    unawaited(_owner.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ModConductorApp(
    desktopRequests: _requests,
    workspaces: _owner.workspaces,
    migration: _owner.migration,
    settings: _owner.settings,
    modLibrary: _owner.modLibrary,
    profileMods: _owner.profileMods,
    modOrganization: _owner.modOrganization,
    inventoryExports: _owner.inventoryExports,
    gameContexts: _owner.gameContexts,
    filePlans: _owner.filePlans,
    diagnostics: _owner.diagnostics,
    bethesda: _owner.bethesda,
    pluginOrders: _owner.pluginOrders,
    loot: _owner.loot,
    archivePolicies: _owner.archivePolicies,
    outputs: _owner.outputs,
    deployments: _owner.deployments,
    executables: _owner.executables,
    gameLaunching: _owner.gameLaunching,
    profileData: _owner.profileData,
    artifacts: _owner.artifacts,
    installations: _owner.installations,
    maintenance: _owner.maintenance,
    fomod: _owner.fomod,
    bain: _owner.bain,
    credentials: _owner.credentials,
    nexus: _owner.nexus,
    nexusMetadata: _owner.nexusMetadata,
    linkSetup: _owner.linkSetup,
    bundles: _owner.bundles,
    steamDiscovery: _owner.steamDiscovery,
    protonContexts: _owner.protonContexts,
    skse: _owner.skse,
    enb: _owner.enb,
    fnis: _owner.fnis,
    skyrimSetup: _owner.skyrimSetup,
    status: switch (_owner.state) {
      EngineIdle() => const DesktopDisconnected(),
      EngineConnecting() => const DesktopConnecting(),
      EngineConnected(:final report) => DesktopConnected(report),
      EngineFailure(:final reason) => DesktopFailure(switch (reason) {
        EngineFailureReason.start =>
          'The engine could not start. Check the installation.',
        EngineFailureReason.protocol =>
          'The app and engine versions do not match. Reinstall the app.',
        EngineFailureReason.connection => 'The engine connection failed.',
        EngineFailureReason.crash => 'The engine stopped.',
        EngineFailureReason.shutdown => 'The engine did not stop. The app remains open. Wait, then quit again.',
      }),
    },
    onRetry: switch (_owner.state) {
      EngineFailure(canRetry: true) => () => unawaited(_owner.connect()),
      _ => null,
    },
  );
}
