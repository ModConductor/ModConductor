import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_collections/mc_ui_collections.dart';

part 'runs.dart';

class ExecutablesController extends ChangeNotifier {
  final presets = McCollectionModel<String, ExecutablePreset>(
    idOf: (v) => v.id,
    labelOf: (v) => v.name,
  );
  late final _runs = _ExecutableRuns(this);
  Map<String, ExecutableRun> get latest => _runs.latest;
  List<ExecutableRun> get history => _runs.history;
  ExecutablesClient? client;
  WorkspaceInfo? workspace;
  bool _available = false, _disposed = false, _loaded = false;
  int _epoch = 0;
  bool reading = false, changing = false, needsRead = false;
  bool get readingHistory => _runs.readingHistory;
  set readingHistory(bool value) => _runs.readingHistory = value;
  String? problem, _next;
  String? selectedId;
  ExecutableRunRequest? get pendingLaunch => _runs.pendingLaunch;
  set pendingLaunch(ExecutableRunRequest? value) => _runs.pendingLaunch = value;
  String? get pendingStop => _runs.pendingStop;
  set pendingStop(String? value) => _runs.pendingStop = value;
  ExecutablePreset? get selected =>
      selectedId == null ? null : presets[selectedId!];
  ExecutableRun? get selectedRun =>
      selectedId == null ? null : latest[selectedId!];
  bool get connected => client != null && workspace != null && _available;
  bool get canLoad => connected && !reading && (!_loaded || _next != null);
  bool get canLoadHistory =>
      connected && !readingHistory && _runs.hasMoreHistory;
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
    _runs.reset();
    client = api;
    presets.clear();
    selectedId = null;
    problem = null;
    _next = null;
    reading = changing = needsRead = _loaded = false;
    if (connected) unawaited(load());
    _notify();
  }

  void select(ExecutablePreset value) {
    selectedId = value.id;
    presets.select(value.id);
    _runs.observeSelected();
    _notify();
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
        _runs.latest.clear();
      }
      presets.apply(upserts: page.presets);
      _next = page.next;
      _loaded = true;
      for (final run in page.latestRuns) {
        _runs.applyRun(run);
      }
      if (selectedId == null || !presets.ids.contains(selectedId)) {
        selectedId = page.presets.firstOrNull?.id;
      }
      if (selectedId != null) presets.select(selectedId!);
      needsRead = false;
      _runs.observeSelected();
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
      _runs.latest.remove(value.id);
      selectedId = presets.ids.firstOrNull;
      _runs.observeSelected();
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

  Future<void> run() => _runs.run();
  Future<void> continueLaunch() => _runs.continueLaunch();
  Future<void> stopWaiting() => _runs.stopWaiting();
  Future<void> readRun() => _runs.readRun();
  Future<void> loadHistory() => _runs.loadHistory();

  static String errorMessage(Object error) => error is ExecutableException
      ? error.detail
      : 'The engine did not return a confirmed result.';
  @override
  void dispose() {
    _disposed = true;
    ++_epoch;
    _runs.dispose();
    presets.dispose();
    super.dispose();
  }
}
