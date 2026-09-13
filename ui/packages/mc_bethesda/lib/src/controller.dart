import 'package:flutter/foundation.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_collections/mc_ui_collections.dart';

class PluginsController extends ChangeNotifier {
  final rows = McCollectionModel<String, PluginEntry>(
    idOf: (r) => r.name,
    labelOf: (r) => r.name,
  );
  BethesdaClient? _client;
  String? _profile;
  int _epoch = 0, _inputsRevision = 0;
  bool _disposed = false, reading = false, stale = false, inspecting = false;
  PluginSnapshot? state;
  String? problem;
  bool get connected => _client != null && _profile != null;
  void attach(BethesdaClient? client, String? profile) {
    if (identical(client, _client) && profile == _profile) return;
    ++_epoch;
    _client = client;
    _profile = profile;
    rows.clear();
    state = null;
    problem = null;
    reading = false;
    stale = false;
    inspecting = false;
    notifyListeners();
  }

  void invalidate() {
    ++_inputsRevision;
    if (state == null) return;
    stale = true;
    notifyListeners();
  }

  void select(PluginEntry row) {
    rows.select(row.name);
    notifyListeners();
  }

  void inspect() {
    inspecting = true;
    notifyListeners();
  }

  void closeInspector() {
    inspecting = false;
    notifyListeners();
  }

  Future<void> scan() async {
    final client = _client, profile = _profile;
    if (client == null || profile == null || reading) return;
    final epoch = _epoch, inputsRevision = _inputsRevision;
    reading = true;
    problem = null;
    notifyListeners();
    try {
      final value = await client.scan(profile);
      if (_disposed || epoch != _epoch) return;
      state = value;
      stale = value.stale || inputsRevision != _inputsRevision;
      final names = value.entries.map((r) => r.name).toSet();
      rows.apply(
        upserts: value.entries,
        removed: rows.ids.where((id) => !names.contains(id)).toList(),
      );
      if (rows.selected == null && value.entries.isNotEmpty) {
        rows.select(value.entries.first.name);
      }
    } on FilePlanException catch (error) {
      if (!_disposed && epoch == _epoch) {
        stale = state != null;
        problem = error.detail;
      }
    } on Exception {
      if (!_disposed && epoch == _epoch) {
        stale = state != null;
        problem = 'The plugin scan could not finish. Try again.';
      }
    } finally {
      if (!_disposed && epoch == _epoch) {
        reading = false;
        notifyListeners();
      }
    }
  }

  bool _validating = false;
  Future<void> validate() async {
    final client = _client, snapshot = state, epoch = _epoch;
    if (client == null || snapshot == null || _validating || reading) return;
    _validating = true;
    try {
      final current = await client.read(snapshot.id);
      if (!_disposed && epoch == _epoch && state?.id == snapshot.id) {
        stale = stale || current.stale;
        notifyListeners();
      }
    } on FilePlanException catch (error) {
      if (!_disposed && epoch == _epoch) {
        stale = true;
        problem = error.detail;
        notifyListeners();
      }
    } on Exception {
      if (!_disposed && epoch == _epoch) {
        stale = true;
        problem = 'The plugin scan could not be checked. Refresh to try again.';
        notifyListeners();
      }
    } finally {
      _validating = false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    ++_epoch;
    rows.dispose();
    super.dispose();
  }
}
