import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_collections/mc_ui_collections.dart';

class SteamSearchController extends ChangeNotifier {
  SteamSearchController(this.client, this.definitionId);
  final SteamDiscoveryClient client;
  final String definitionId;
  final model = McCollectionModel<String, SteamInstallationCandidate>(
    idOf: (row) => row.id,
    labelOf: (row) => row.directory.canonicalPath,
  );
  final List<String> _roots = [];
  List<String> get additionalRoots => List.unmodifiable(_roots);
  SteamSearchResult? report;
  bool loading = false, cancelled = false;
  String? problem;
  SteamSearch? _pending;
  int _epoch = 0;
  bool _disposed = false;
  bool get canAddRoot => !loading && _roots.length < 16;
  Future<void> addRoot(String path) async {
    if (!canAddRoot) return;
    if (!_roots.contains(path)) _roots.add(path);
    await search();
  }

  Future<void> search() async {
    if (loading || _disposed) return;
    final epoch = ++_epoch;
    loading = true;
    cancelled = false;
    problem = null;
    notifyListeners();
    final initial = report == null;
    try {
      final pending = client.search(definitionId, List.unmodifiable(_roots));
      _pending = pending;
      final value = await pending.result;
      if (_disposed || epoch != _epoch) return;
      report = value;
      final ids = value.candidates.map((c) => c.id).toSet();
      model.apply(
        upserts: value.candidates,
        removed: model.ids.where((id) => !ids.contains(id)).toList(),
      );
      if (initial && model.selected == null && model.visible.isNotEmpty) {
        model.select(model.visible.first);
      }
    } on Exception {
      if (!_disposed && epoch == _epoch) {
        problem = 'The Steam search did not finish. Try again.';
      }
    } finally {
      if (!_disposed && epoch == _epoch) {
        _pending = null;
        loading = false;
        notifyListeners();
      }
    }
  }

  void cancel() {
    if (!loading) return;
    ++_epoch;
    final pending = _pending;
    _pending = null;
    loading = false;
    cancelled = true;
    if (pending != null) unawaited(pending.cancel());
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    cancel();
    ++_epoch;
    model.dispose();
    super.dispose();
  }
}
