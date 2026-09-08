import 'package:flutter/foundation.dart';
import 'package:mc_client/mc_client.dart';

import 'planned_files_controller.dart';

class FileInspectorController extends ChangeNotifier {
  FilePlansClient? _client;
  String? _snapshot;
  List<String>? target;
  ManagedFileCopy? requestedCopy;
  final _copies = <Object, InspectedFileCopy>{};
  List<InspectedFileCopy> get copies => List.unmodifiable(_copies.values);
  InspectedFileCopy? focusedCopy;
  InspectedFileCopy? get selected =>
      _copies[_selected] ??
      (focusedCopy != null && key(focusedCopy!) == _selected
          ? focusedCopy
          : null);
  Object? _selected;
  FilePlanCursor? _next;
  final history = <FileVisibilityAudit>[];
  int? _before;
  bool writable = false;
  bool historyLoaded = false;
  bool loading = false, loadingHistory = false;
  String? problem, historyProblem;
  int _epoch = 0, _historyEpoch = 0;
  bool _disposed = false;
  bool get visible => target != null || requestedCopy != null;
  bool get canLoad => _next != null;
  bool get canLoadHistory =>
      selected?.copy != null && (!historyLoaded || _before != null);
  static Object key(InspectedFileCopy copy) =>
      copy.copy ?? 'game:${filePathId(copy.sourcePath)}';
  void attach(
    FilePlansClient? client,
    FilePlanState? state, {
    bool clear = false,
  }) {
    _client = client;
    _snapshot = state?.id;
    ++_epoch;
    loading = false;
    if (clear) close();
  }

  void close() {
    ++_epoch;
    ++_historyEpoch;
    target = null;
    requestedCopy = null;
    focusedCopy = null;
    writable = false;
    _copies.clear();
    _selected = null;
    _next = null;
    loading = false;
    problem = null;
    _clearHistory();
    if (!_disposed) notifyListeners();
  }

  Future<void> showTarget(List<String> path) {
    close();
    target = List.unmodifiable(path);
    return reload();
  }

  Future<void> showCopy(ManagedFileCopy copy) {
    close();
    requestedCopy = copy;
    _selected = copy;
    return reload();
  }

  void select(InspectedFileCopy copy) {
    _selected = key(copy);
    _clearHistory();
    notifyListeners();
  }

  void _clearHistory() {
    ++_historyEpoch;
    history.clear();
    _before = null;
    historyLoaded = false;
    loadingHistory = false;
    historyProblem = null;
  }

  Future<void> reload() async {
    ++_epoch;
    _next = null;
    _copies.clear();
    focusedCopy = null;
    writable = false;
    _clearHistory();
    final chosen =
        selected?.copy ??
        (_selected is ManagedFileCopy
            ? _selected as ManagedFileCopy
            : requestedCopy);
    if (chosen != null) requestedCopy = chosen;
    await load(first: true);
  }

  Future<void> load({bool first = false}) async {
    final client = _client, snapshot = _snapshot;
    if (_disposed ||
        loading ||
        client == null ||
        snapshot == null ||
        !visible ||
        (!first && _next == null)) {
      return;
    }
    final epoch = _epoch;
    loading = true;
    problem = null;
    notifyListeners();
    try {
      final result = first && requestedCopy != null
          ? await client.inspectCopy(snapshot, requestedCopy!)
          : await client.inspect(
              snapshot,
              target!,
              cursor: first ? null : _next,
            );
      if (_disposed || epoch != _epoch || snapshot != _snapshot) return;
      if (result.state.id != snapshot) {
        throw const FormatException(
          'The inspection belongs to a different snapshot.',
        );
      }
      target = result.target;
      writable = result.writable;
      _next = result.next;
      focusedCopy = result.focusedCopy ?? focusedCopy;
      for (final copy in result.copies) {
        _copies[key(copy)] = copy;
      }
      _selected ??=
          result.copies.where((copy) => copy.winner).firstOrNull == null
          ? (result.copies.isEmpty ? null : key(result.copies.first))
          : key(result.copies.firstWhere((copy) => copy.winner));
    } on Exception catch (error) {
      if (!_disposed && epoch == _epoch) {
        problem = error is FilePlanException
            ? error.detail
            : 'Could not inspect this file.';
      }
    } finally {
      if (!_disposed && epoch == _epoch) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadHistory() async {
    final client = _client, snapshot = _snapshot, copy = selected?.copy;
    if (_disposed ||
        loadingHistory ||
        client == null ||
        snapshot == null ||
        copy == null ||
        !canLoadHistory) {
      return;
    }
    final epoch = _historyEpoch;
    loadingHistory = true;
    historyProblem = null;
    notifyListeners();
    try {
      final page = await client.history(snapshot, copy, beforeId: _before);
      if (_disposed || epoch != _historyEpoch) return;
      history.addAll(page.changes);
      _before = page.nextBeforeId;
      historyLoaded = true;
    } on Exception catch (error) {
      if (!_disposed && epoch == _historyEpoch) {
        historyProblem = error is FilePlanException
            ? error.detail
            : 'Could not load file history.';
      }
    } finally {
      if (!_disposed && epoch == _historyEpoch) {
        loadingHistory = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    ++_epoch;
    ++_historyEpoch;
    super.dispose();
  }
}
