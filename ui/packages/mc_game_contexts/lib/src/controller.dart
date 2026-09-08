import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mc_client/mc_client.dart';

class GameContextController extends ChangeNotifier {
  GameContextsClient? _client;
  final _startupChecks = <String>{};
  String? _workspace;
  int _epoch = 0;
  bool _disposed = false;
  bool editable = false;
  bool loading = false;
  bool needsRead = false;
  String? problem;
  GameContextState? state;
  GameContextsClient? get client => _client;
  bool get canChange =>
      !needsRead && editable && !loading && state != null && _client != null;

  bool get canRefresh =>
      editable && !loading && state != null && _client != null;

  void unknownSave(GameContextsClient source, String workspace) {
    if (_disposed || source != _client || workspace != _workspace) return;
    ++_epoch;
    loading = false;
    needsRead = true;
    problem = 'Save did not return a result. Reload the saved installation.';
    _notify();
  }

  void attach(
    GameContextsClient? client, {
    required String? workspaceId,
    required bool editable,
  }) {
    final changed = client != _client || workspaceId != _workspace;
    if (client != _client) _startupChecks.clear();
    _client = client;
    _workspace = workspaceId;
    this.editable = editable;
    if (changed) {
      ++_epoch;
      state = null;
      needsRead = false;
      problem = null;
      loading = false;
      if (client != null && workspaceId != null) {
        unawaited(_load(initialize: true));
      }
    }
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void accept(GameContextState result, GameContextsClient source) {
    if (_disposed ||
        source != _client ||
        result.workspaceId != _workspace ||
        (state?.revision ?? -1) > result.revision) {
      return;
    }
    ++_epoch;
    loading = false;
    state = result;
    _startupChecks.add(result.workspaceId);
    needsRead = false;
    problem = null;
    _notify();
  }

  Future<bool> load({bool refresh = false}) => _load(refresh: refresh);

  Future<bool> _load({bool refresh = false, bool initialize = false}) async {
    final client = _client;
    final workspace = _workspace;
    if (client == null || workspace == null || loading) return false;
    var checking = refresh && state?.binding != null;
    if (checking) _startupChecks.add(workspace);
    final epoch = ++_epoch;
    loading = true;
    problem = null;
    _notify();
    try {
      var result = checking
          ? await client.refresh(workspace, state!.revision)
          : await client.read(workspace);
      if (_disposed || epoch != _epoch) return false;
      state = result;
      if (initialize &&
          (result.binding?.needsCheck ?? false) &&
          _startupChecks.add(workspace)) {
        checking = true;
        _notify();
        result = await client.refresh(workspace, result.revision);
        if (_disposed || epoch != _epoch) return false;
      }
      state = result;
      needsRead = false;
      return true;
    } on Exception catch (error) {
      if (!_disposed && epoch == _epoch) {
        if (checking && error is! GameContextException) needsRead = true;
        problem = error is GameContextException
            ? error.detail
            : 'The installation check did not return a result.';
      }
      return false;
    } finally {
      if (!_disposed && epoch == _epoch) {
        loading = false;
        _notify();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    ++_epoch;
    super.dispose();
  }
}
