import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mc_client/mc_client.dart';

class ProtonSearchController extends ChangeNotifier {
  ProtonSearchController(
    this.client,
    this.definitionId,
    this.gamePath,
    this.roots,
  );
  final ProtonContextsClient client;
  final String definitionId, gamePath;
  final List<String> roots;
  ProtonSearchResult? report;
  bool loading = false;
  String? problem;
  ProtonSearch? _pending;
  int _epoch = 0;
  bool _disposed = false;
  Future<void> search() async {
    if (loading || _disposed) return;
    final epoch = ++_epoch;
    loading = true;
    problem = null;
    notifyListeners();
    try {
      final pending = client.search(definitionId, gamePath, roots);
      _pending = pending;
      final value = await pending.result;
      if (!_disposed && epoch == _epoch) report = value;
    } on Exception {
      if (!_disposed && epoch == _epoch) problem = 'The Proton folders could not be checked. You can select an existing folder or retry.';
    } finally {
      if (!_disposed && epoch == _epoch) {
        loading = false;
        _pending = null;
        notifyListeners();
      }
    }
  }

  void cancel() {
    ++_epoch;
    final pending = _pending;
    _pending = null;
    loading = false;
    if (pending != null) unawaited(pending.cancel());
  }

  @override
  void dispose() {
    _disposed = true;
    cancel();
    super.dispose();
  }
}
