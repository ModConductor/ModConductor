part of 'app.dart';

class DesktopHost extends StatefulWidget {
  const DesktopHost({super.key, this.engineExecutable});
  final String? engineExecutable;

  @override
  State<DesktopHost> createState() => _DesktopHostState();
}

class _DesktopHostState extends State<DesktopHost> with WidgetsBindingObserver {
  DesktopStatus _status = const DesktopConnecting();
  EngineSession? _engine;
  late final Future<void> _startup;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startup = _connect();
  }

  Future<void> _connect() async {
    try {
      final name = Platform.isWindows
          ? 'ModConductor.Engine.exe'
          : 'ModConductor.Engine';
      final executable =
          widget.engineExecutable ??
          File.fromUri(
            File(Platform.resolvedExecutable).parent.uri
                .resolve('engine/$name'),
          ).path;
      final engine = await EngineSession.start(executable);
      _engine = engine;
      if (_closing) {
        await engine.close();
        return;
      }
      final report = await engine.check();
      if (mounted && !_closing) {
        setState(() => _status = DesktopConnected(report));
      }
      unawaited(
        engine.exited.then((_) {
          if (mounted && !_closing) {
            setState(
              () => _status = const DesktopFailure('The engine stopped.'),
            );
          }
        }),
      );
    } on Exception {
      await _engine?.close();
      if (mounted && !_closing) {
        setState(
          () =>
              _status = const DesktopFailure('Check the engine installation.'),
        );
      }
    }
  }

  Future<void> _close() async {
    _closing = true;
    await _startup;
    await _engine?.close();
  }

  @override
  Future<AppExitResponse> didRequestAppExit() async {
    await _close();
    return AppExitResponse.exit;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ModConductorApp(status: _status);
}
