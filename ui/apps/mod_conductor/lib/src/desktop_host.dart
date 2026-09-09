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
    _changes = _owner.changes.listen((_) {
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
    unawaited(_changes.cancel());
    unawaited(_owner.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ModConductorApp(
    workspaces: _owner.workspaces,
    modLibrary: _owner.modLibrary,
    profileMods: _owner.profileMods,
    modOrganization: _owner.modOrganization,
    gameContexts: _owner.gameContexts,
    filePlans: _owner.filePlans,
    outputs: _owner.outputs,
    deployments: _owner.deployments,
    executables: _owner.executables,
    gameLaunching: _owner.gameLaunching,
    steamDiscovery: _owner.steamDiscovery,
    protonContexts: _owner.protonContexts,
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
