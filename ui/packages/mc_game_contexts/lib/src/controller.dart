import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mc_client/mc_client.dart';

class GameContextController extends ChangeNotifier {
  GameContextsClient? _client;
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
    _client = client;
    _workspace = workspaceId;
    this.editable = editable;
    if (changed) {
      ++_epoch;
      state = null;
      needsRead = false;
      problem = null;
      loading = false;
      if (client != null && workspaceId != null) unawaited(load());
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
    needsRead = false;
    problem = null;
    _notify();
  }

  Future<bool> load({bool refresh = false}) async {
    final client = _client;
    final workspace = _workspace;
    if (client == null || workspace == null || loading) return false;
    final epoch = ++_epoch;
    loading = true;
    problem = null;
    _notify();
    try {
      final result = refresh && state?.binding != null
          ? await client.refresh(workspace, state!.revision)
          : await client.read(workspace);
      if (_disposed || epoch != _epoch) return false;
      state = result;
      needsRead = false;
      return true;
    } on Exception catch (error) {
      if (!_disposed && epoch == _epoch) {
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
