import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_collections/mc_ui_collections.dart';

class ExecutablesController extends ChangeNotifier {
  final presets = McCollectionModel<String, ExecutablePreset>(
    idOf: (v) => v.id,
    labelOf: (v) => v.name,
  );
  final latest = <String, ExecutableRun>{};
  final history = <ExecutableRun>[];
  ExecutablesClient? client;
  WorkspaceInfo? workspace;
  bool _available = false,
      _disposed = false,
      _loaded = false,
      _historyLoaded = false;
  int _epoch = 0;
  bool reading = false,
      changing = false,
      needsRead = false,
      readingHistory = false;
  String? problem, _next, _historyNext;
  String? selectedId;
  ExecutableRunRequest? pendingLaunch;
  String? pendingStop;
  StreamSubscription<ExecutableRun>? _watch;
  String? _watchId;
  ExecutablePreset? get selected =>
      selectedId == null ? null : presets[selectedId!];
  ExecutableRun? get selectedRun =>
      selectedId == null ? null : latest[selectedId!];
  bool get connected => client != null && workspace != null && _available;
  bool get canLoad => connected && !reading && (!_loaded || _next != null);
  bool get canLoadHistory =>
      connected && !readingHistory && (!_historyLoaded || _historyNext != null);
  bool get uncertain => pendingLaunch != null || pendingStop != null;
  bool get canChange => connected && !changing && !needsRead;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void attach(
    ExecutablesClient? api,
    WorkspaceInfo? value, {
    required bool available,
  }) {
    final same = identical(client, api) && workspace?.id == value?.id;
    final becameAvailable = !_available && available;
    workspace = value;
    _available = available;
    if (same) {
      if (becameAvailable && !_loaded) unawaited(load());
      return;
    }
    ++_epoch;
    unawaited(_watch?.cancel());
    _watch = null;
    _watchId = null;
    client = api;
    presets.clear();
    latest.clear();
    history.clear();
    selectedId = null;
    pendingLaunch = null;
    pendingStop = null;
    problem = null;
    _next = null;
    _historyNext = null;
    reading = changing = needsRead = readingHistory = _loaded = _historyLoaded =
        false;
    if (connected) unawaited(load());
    _notify();
  }

  void select(ExecutablePreset value) {
    selectedId = value.id;
    presets.select(value.id);
    _observeSelected();
    _notify();
  }

  void _applyRun(ExecutableRun value) {
    if (value.preset == null) return;
    final previous = latest[value.preset!.id];
    if (previous == null ||
        (previous.id == value.id && value.revision >= previous.revision) ||
        (previous.id != value.id &&
            value.requestedAt.isAfter(previous.requestedAt))) {
      latest[value.preset!.id] = value;
    }
    final index = history.indexWhere((row) => row.id == value.id);
    if (index >= 0 && value.revision >= history[index].revision) {
      history[index] = value;
    }
  }

  void _observeSelected() {
    final run = selectedRun, api = client;
    if (run == null || run.terminal || api == null) {
      unawaited(_watch?.cancel());
      _watch = null;
      _watchId = null;
      return;
    }
    if (_watchId == run.id) return;
    unawaited(_watch?.cancel());
    _watchId = run.id;
    final epoch = _epoch, id = run.id;
    _watch = api
        .observe(run.workspaceId, id)
        .listen(
          (value) {
            if (epoch != _epoch || _watchId != id) return;
            _applyRun(value);
            _notify();
          },
          onError: (Object error) {
            if (epoch != _epoch || _watchId != id) return;
            unawaited(_watch?.cancel());
            _watch = null;
            _watchId = null;
            needsRead = true;
            problem =
                'The run status is unavailable. Read it again to reconnect.';
            _notify();
          },
          onDone: () {
            if (epoch == _epoch && _watchId == id) {
              _watch = null;
              _watchId = null;
              if (selectedRun?.terminal == false) {
                needsRead = true;
                problem = "The run status ended before completion was confirmed. Read it again.";
                _notify();
              }
            }
          },
        );
  }

  Future<void> load({bool refresh = false}) async {
    final api = client, id = workspace?.id;
    if (!connected ||
        api == null ||
        id == null ||
        reading ||
        changing ||
        uncertain) {
      return;
    }
    if (!refresh && !canLoad) return;
    final epoch = _epoch;
    reading = true;
    problem = null;
    _notify();
    try {
      final page = await api.list(id, after: refresh ? null : _next);
      if (epoch != _epoch) return;
      if (refresh) {
        presets.clear();
        latest.clear();
      }
      presets.apply(upserts: page.presets);
      _next = page.next;
      _loaded = true;
      for (final run in page.latestRuns) {
        _applyRun(run);
      }
      if (selectedId == null || !presets.ids.contains(selectedId)) {
        selectedId = page.presets.firstOrNull?.id;
      }
      if (selectedId != null) presets.select(selectedId!);
      needsRead = false;
      _observeSelected();
    } on Object catch (error) {
      if (epoch == _epoch) problem = errorMessage(error);
    } finally {
      if (epoch == _epoch) {
        reading = false;
        _notify();
      }
    }
  }

  Future<ExecutablePreset> save(ExecutablePreset value) async {
    final api = client;
    if (!canChange || api == null) {
      throw const ExecutableException(
        ExecutableFailure.unavailable,
        'The executable list is unavailable.',
      );
    }
    final epoch = _epoch;
    changing = true;
    _notify();
    try {
      final saved = await api.save(value);
      if (epoch != _epoch) {
        throw const ExecutableException(
          ExecutableFailure.unavailable,
          'The workspace changed. Read the executable again.',
        );
      }
      presets.apply(upserts: [saved]);
      selectedId = saved.id;
      presets.select(saved.id);
      return saved;
    } on ExecutableException {
      rethrow;
    } on Object {
      if (epoch == _epoch) needsRead = true;
      rethrow;
    } finally {
      if (epoch == _epoch) {
        changing = false;
        _notify();
      }
    }
  }

  Future<ExecutablePreset> readPreset(String workspaceId, String id) async {
    final api = client;
    if (api == null || !connected || workspace?.id != workspaceId) {
      throw const ExecutableException(
        ExecutableFailure.unavailable,
        'The workspace is unavailable.',
      );
    }
    final epoch = _epoch;
    try {
      final value = await api.readPreset(workspaceId, id);
      if (epoch != _epoch) {
        throw const ExecutableException(
          ExecutableFailure.unavailable,
          'The workspace changed.',
        );
      }
      presets.apply(upserts: [value]);
      needsRead = false;
      _notify();
      return value;
    } on ExecutableException catch (error) {
      if (epoch == _epoch && error.failure == ExecutableFailure.notFound) {
        needsRead = false;
        _notify();
      }
      rethrow;
    }
  }

  Future<void> remove(ExecutablePreset value) async {
    final api = client;
    if (!canChange || api == null) return;
    final epoch = _epoch;
    changing = true;
    problem = null;
    _notify();
    try {
      await api.delete(value.workspaceId, value.id, value.revision);
      if (epoch != _epoch) return;
      presets.apply(removed: [value.id]);
      latest.remove(value.id);
      selectedId = presets.ids.firstOrNull;
      _observeSelected();
    } on Object catch (error) {
      if (epoch == _epoch) {
        problem = errorMessage(error);
        needsRead = true;
      }
    } finally {
      if (epoch == _epoch) {
        changing = false;
        _notify();
      }
    }
  }

  Future<void> run() async {
    final tool = selected, ws = workspace;
    if (tool == null || ws == null || !canChange || uncertain) return;
    final request = ExecutableRunRequest(
      id: newOperationId(),
      workspaceId: ws.id,
      workspaceRevision: ws.revision,
      presetId: tool.id,
      presetRevision: tool.revision,
    );
    pendingLaunch = request;
    await continueLaunch();
  }

  Future<void> continueLaunch() async {
    final request = pendingLaunch, api = client;
    if (request == null || api == null || !connected || changing) return;
    final epoch = _epoch;
    changing = true;
    problem = null;
    _notify();
    try {
      final value = await api.begin(request);
      if (epoch != _epoch) return;
      _applyRun(value);
      pendingLaunch = null;
      needsRead = false;
      _historyLoaded = false;
      _observeSelected();
    } on ExecutableException catch (error) {
      if (epoch == _epoch) {
        pendingLaunch = null;
        needsRead = error.failure == ExecutableFailure.staleRevision;
        problem = error.detail;
      }
    } on Object {
      if (epoch == _epoch) {
        needsRead = true;
        problem = 'The launch result is unknown. Read the result before starting another run.';
      }
    } finally {
      if (epoch == _epoch) {
        changing = false;
        _notify();
      }
    }
  }

  Future<void> stopWaiting() async {
    final run = selectedRun, api = client;
    if (run == null ||
        run.terminal ||
        api == null ||
        !connected ||
        changing ||
        uncertain) {
      return;
    }
    final epoch = _epoch;
    changing = true;
    pendingStop = run.id;
    problem = null;
    _notify();
    try {
      final value = await api.stopWaiting(run.workspaceId, run.id);
      if (epoch != _epoch) return;
      _applyRun(value);
      pendingStop = null;
      needsRead = false;
      _observeSelected();
    } on Object {
      if (epoch == _epoch) {
        needsRead = true;
        problem = 'The stop-waiting result is unknown. Read the run status.';
      }
    } finally {
      if (epoch == _epoch) {
        changing = false;
        _notify();
      }
    }
  }

  Future<void> readRun() async {
    final id = pendingLaunch?.id ?? pendingStop ?? selectedRun?.id,
        api = client,
        ws = workspace?.id;
    if (id == null || api == null || ws == null || !connected || changing) {
      return;
    }
    final epoch = _epoch;
    changing = true;
    problem = null;
    _notify();
    try {
      final value = await api.read(ws, id);
      if (epoch != _epoch) return;
      _applyRun(value);
      pendingLaunch = null;
      pendingStop = null;
      needsRead = false;
      _observeSelected();
    } on ExecutableException catch (error) {
      if (epoch == _epoch) {
        problem =
            error.failure == ExecutableFailure.notFound && pendingLaunch != null
            ? 'The launch is not recorded. Continue uses the same request.'
            : error.detail;
        needsRead = true;
      }
    } on Object {
      if (epoch == _epoch) {
        problem = 'The run status is unavailable.';
        needsRead = true;
      }
    } finally {
      if (epoch == _epoch) {
        changing = false;
        _notify();
      }
    }
  }

  Future<void> loadHistory() async {
    final api = client, id = workspace?.id;
    if (!canLoadHistory || api == null || id == null) return;
    final epoch = _epoch;
    readingHistory = true;
    _notify();
    try {
      final page = await api.recent(
        id,
        after: _historyLoaded ? _historyNext : null,
      );
      if (epoch != _epoch) return;
      if (!_historyLoaded) history.clear();
      for (final run in page.runs) {
        if (!history.any((v) => v.id == run.id)) {
          history.add(run);
        }
      }
      _historyNext = page.next;
      _historyLoaded = true;
    } on Object catch (error) {
      if (epoch == _epoch) problem = errorMessage(error);
    } finally {
      if (epoch == _epoch) {
        readingHistory = false;
        _notify();
      }
    }
  }

  static String errorMessage(Object error) => error is ExecutableException
      ? error.detail
      : 'The engine did not return a confirmed result.';
  @override
  void dispose() {
    _disposed = true;
    ++_epoch;
    unawaited(_watch?.cancel());
    presets.dispose();
    super.dispose();
  }
}
