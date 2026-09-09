import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mc_client/mc_client.dart';

class GamePlayController extends ChangeNotifier {
  GameLaunchingClient? client;
  ExecutablesClient? executions;
  WorkspaceInfo? workspace;
  GameLaunchState? state;
  ExecutableRun? run;
  GameRunRequest? pending;
  String? problem;
  bool changing = false, reading = false, uncertain = false, starting = false;
  bool _available = false, _disposed = false;
  int _epoch = 0, _readEpoch = 0;
  StreamSubscription<ExecutableRun>? _watch;
  String? _watchId;
  VoidCallback? onDeploymentChanged;
  bool get connected =>
      client != null &&
      executions != null &&
      workspace?.selectedProfile != null &&
      _available;
  bool get active => run != null && !run!.terminal;
  bool get canPlay => connected && !changing && !uncertain && !active;
  bool get preparing => active && run!.phase == ExecutableRunPhase.starting;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void attach(
    GameLaunchingClient? api,
    ExecutablesClient? runs,
    WorkspaceInfo? value, {
    required bool available,
  }) {
    final same =
        identical(client, api) &&
        identical(executions, runs) &&
        workspace?.id == value?.id;
    final changedProfile =
        workspace?.selectedProfile?.id != value?.selectedProfile?.id;
    final becameAvailable = !_available && available;
    workspace = value;
    _available = available;
    if (same) {
      if ((changedProfile || becameAvailable) && connected) {
        unawaited(readState());
      }
      return;
    }
    ++_epoch;
    ++_readEpoch;
    unawaited(_watch?.cancel());
    _watch = null;
    _watchId = null;
    client = api;
    executions = runs;
    state = null;
    run = null;
    pending = null;
    problem = null;
    changing = reading = uncertain = starting = false;
    if (connected) unawaited(readState());
    _notify();
  }

  void invalidate() {
    if (connected && !changing) unawaited(readState());
  }

  Future<void> readState() async {
    final api = client, ws = workspace, profile = workspace?.selectedProfile;
    if (!connected ||
        api == null ||
        ws == null ||
        profile == null ||
        changing) {
      return;
    }
    final epoch = _epoch, readEpoch = ++_readEpoch;
    reading = true;
    _notify();
    try {
      final value = await api.read(ws.id, profile.id);
      if (epoch != _epoch || readEpoch != _readEpoch) return;
      state = value;
      if (!uncertain) problem = value.problem;
      if (value.latest != null) _accept(value.latest!);
    } on Object catch (error) {
      if (epoch == _epoch && readEpoch == _readEpoch) problem = _message(error);
    } finally {
      if (epoch == _epoch && readEpoch == _readEpoch) {
        reading = false;
        _notify();
      }
    }
  }

  void _accept(ExecutableRun value) {
    final previous = run;
    if (previous != null &&
        (previous.id == value.id
            ? value.revision < previous.revision
            : value.requestedAt.isBefore(previous.requestedAt))) {
      return;
    }
    run = value;
    if (previous?.game?.files?.generationId !=
            value.game?.files?.generationId ||
        previous?.terminal != value.terminal) {
      onDeploymentChanged?.call();
    }
    if (value.terminal) {
      unawaited(_watch?.cancel());
      _watch = null;
      _watchId = null;
    } else if (_watchId != value.id) {
      unawaited(_watch?.cancel());
      _watchId = value.id;
      final epoch = _epoch;
      _watch = executions!
          .observe(value.workspaceId, value.id)
          .listen(
            (next) {
              if (epoch != _epoch) return;
              _accept(next);
              _notify();
            },
            onError: (Object error) {
              if (epoch == _epoch) {
                uncertain = true;
                problem = 'The run status is unknown. Read the result.';
                _watchId = null;
                _notify();
              }
            },
          );
    }
  }

  Future<void> play() async {
    final api = client, ws = workspace, profile = workspace?.selectedProfile;
    if (!canPlay || api == null || ws == null || profile == null) return;
    final epoch = _epoch;
    changing = starting = true;
    problem = null;
    _notify();
    try {
      final latest = await api.read(ws.id, profile.id);
      if (epoch != _epoch) return;
      state = latest;
      if (latest.latest case final current? when !current.terminal) {
        _accept(current);
        return;
      }
      if (latest.problem != null) {
        problem = latest.problem;
        return;
      }
      if (workspace?.revision != ws.revision ||
          workspace?.selectedProfile?.id != profile.id) {
        problem = 'The selected profile changed. Play again when ready.';
        return;
      }
      final request = GameRunRequest(
        id: newOperationId(),
        workspaceId: ws.id,
        workspaceRevision: ws.revision,
        profileId: profile.id,
        contextRevision: latest.contextRevision,
        sourceToken: latest.sourceToken,
      );
      pending = request;
      final value = await api.play(request);
      if (epoch != _epoch) return;
      pending = null;
      uncertain = false;
      _accept(value);
    } on ExecutableException catch (error) {
      if (epoch == _epoch) {
        pending = null;
        problem = error.detail;
      }
    } on Object catch (error) {
      if (epoch == _epoch) {
        uncertain = pending != null;
        problem = uncertain
            ? 'The launch result is unknown. Read the result before starting another run.'
            : _message(error);
      }
    } finally {
      if (epoch == _epoch) {
        changing = starting = false;
        _notify();
      }
    }
  }

  Future<void> readResult() async {
    final api = executions, ws = workspace, id = pending?.id ?? run?.id;
    if (!connected || api == null || ws == null || id == null || changing) {
      return;
    }
    final epoch = _epoch;
    changing = true;
    problem = null;
    _notify();
    try {
      final value = await api.read(ws.id, id);
      if (epoch != _epoch) return;
      pending = null;
      uncertain = false;
      _accept(value);
    } on ExecutableException catch (error) {
      if (epoch == _epoch) {
        if (error.failure == ExecutableFailure.notFound) {
          pending = null;
          uncertain = false;
        }
        problem = error.detail;
      }
    } on Object {
      if (epoch == _epoch) {
        uncertain = true;
        problem = 'The run status could not be read.';
      }
    } finally {
      if (epoch == _epoch) {
        changing = false;
        _notify();
      }
    }
  }

  Future<void> stop() async {
    final value = run, api = client, runs = executions;
    if (!connected ||
        value == null ||
        value.terminal ||
        api == null ||
        runs == null ||
        changing ||
        uncertain) {
      return;
    }
    final epoch = _epoch;
    changing = true;
    problem = null;
    _notify();
    try {
      final next = value.phase == ExecutableRunPhase.starting
          ? await api.cancel(value.workspaceId, value.id)
          : await runs.stopWaiting(value.workspaceId, value.id);
      if (epoch != _epoch) return;
      _accept(next);
    } on Object {
      if (epoch == _epoch) {
        uncertain = true;
        problem = 'The action result is unknown. Read the result.';
      }
    } finally {
      if (epoch == _epoch) {
        changing = false;
        _notify();
      }
    }
  }

  String _message(Object error) => error is ExecutableException
      ? error.detail
      : 'The game launch state could not be read.';
  @override
  void dispose() {
    _disposed = true;
    ++_epoch;
    unawaited(_watch?.cancel());
    super.dispose();
  }
}
