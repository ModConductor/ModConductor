import 'dart:async';
import 'dart:io';

import 'engine_session.dart';
import 'operations_client.dart';
import 'workspaces_client.dart';
import 'mod_library_client.dart';
import 'profile_mod_client.dart';
import 'mod_organization_client.dart';
import 'game_context_client.dart';

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
  GameContextsClient? get gameContexts =>
      _state is EngineConnected ? _session?.gameContexts : null;
  ModOrganizationClient? get modOrganization =>
      _state is EngineConnected ? _session?.modOrganization : null;
  ProfileModsClient? get profileMods =>
      _state is EngineConnected ? _session?.profileMods : null;
  ModLibraryClient? get modLibrary =>
      _state is EngineConnected ? _session?.modLibrary : null;
  WorkspacesClient? get workspaces =>
      _state is EngineConnected ? _session?.workspaces : null;
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
