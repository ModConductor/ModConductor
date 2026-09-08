import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_collections/mc_ui_collections.dart';

String filePathId(List<String> path) => jsonEncode(path);

class PlannedFilesController extends ChangeNotifier {
  final model = McCollectionModel<String, PlannedFileNode>(
    idOf: (row) => filePathId(row.path),
    labelOf: (row) => row.path.join('/'),
    parentOf: (row) => row.path.length == 1
        ? null
        : filePathId(row.path.sublist(0, row.path.length - 1)),
    isBranch: (row) => row.directory,
  );
  FilePlansClient? _client;
  String? _snapshot;
  final _pages = <String?, FilePlanCursor?>{};
  final _pending = <String?>[];
  final _visible = <String>{};
  int _epoch = 0;
  bool _disposed = false, _applying = false;
  bool loading = false;
  String? problem;
  String filter = '';
  Timer? _debounce;
  PlannedFilesController() {
    model.sort((a, b) {
      final kind = (a.directory ? 0 : 1).compareTo(b.directory ? 0 : 1);
      return kind != 0 ? kind : a.path.last.compareTo(b.path.last);
    });
    model.addListener(_expanded);
  }
  bool get canLoad =>
      _snapshot != null &&
      (_pending.isNotEmpty ||
          !(_pages.containsKey(null)) ||
          _pages.values.any((cursor) => cursor != null));
  void attach(
    FilePlansClient? client,
    FilePlanState? state, {
    bool preserve = false,
    PlannedFileNode? changed,
  }) {
    _client = client;
    _snapshot = state?.id;
    ++_epoch;
    loading = false;
    _pending.clear();
    problem = null;
    if (!preserve) {
      _pages.clear();
      _visible.clear();
      _applying = true;
      model.apply(evicted: model.ids.toList(), visibleIds: {});
      _applying = false;
      if (state != null) unawaited(load());
    } else {
      if (changed != null && model[filePathId(changed.path)] != null) {
        _applying = true;
        model.apply(upserts: [changed]);
        _applying = false;
      }
      _expanded();
    }
    notifyListeners();
  }

  void search(String value) {
    if (filter == value) return;
    filter = value;
    ++_epoch;
    loading = false;
    _pending.clear();
    _pages.clear();
    _visible.clear();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      _applying = true;
      model.apply(visibleIds: {});
      _applying = false;
      unawaited(load());
    });
    notifyListeners();
  }

  void _expanded() {
    if (_applying || _disposed || _snapshot == null) return;
    notifyListeners();
    for (final id in model.visible) {
      if (model.expanded(id) &&
          !_pages.containsKey(id) &&
          !_pending.contains(id)) {
        _pending.add(id);
      }
    }
    if (!loading && problem == null && _pending.isNotEmpty) {
      unawaited(load(parent: _pending.removeAt(0)));
    }
  }

  Future<void> load({String? parent}) async {
    final client = _client, snapshot = _snapshot;
    if (_disposed || loading || client == null || snapshot == null) return;
    if (_pages.containsKey(parent) && _pages[parent] == null) return;
    final epoch = _epoch;
    loading = true;
    problem = null;
    notifyListeners();
    try {
      final page = await client.children(
        snapshot,
        parent: parent == null ? null : model[parent]?.path,
        filter: filter,
        cursor: _pages[parent],
      );
      if (_disposed || epoch != _epoch || snapshot != _snapshot) return;
      if (page.state.id != snapshot) {
        throw const FormatException(
          'The file page belongs to a different snapshot.',
        );
      }
      _pages[parent] = page.next;
      _visible.addAll(page.nodes.map((row) => filePathId(row.path)));
      _applying = true;
      model.apply(upserts: page.nodes, visibleIds: _visible);
      _applying = false;
    } on Exception catch (error) {
      if (!_disposed && epoch == _epoch) {
        problem = error is FilePlanException
            ? error.detail
            : 'Could not load planned files.';
        if (!_pending.contains(parent)) _pending.insert(0, parent);
      }
    } finally {
      if (!_disposed && epoch == _epoch) {
        loading = false;
        notifyListeners();
        _expanded();
      }
    }
  }

  Future<void> loadMore() async {
    if (_pending.isNotEmpty) return load(parent: _pending.removeAt(0));
    if (!_pages.containsKey(null)) return load();
    for (final parent in _pages.keys) {
      if (_pages[parent] != null &&
          (parent == null || model.expanded(parent))) {
        return load(parent: parent);
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    ++_epoch;
    _debounce?.cancel();
    model.removeListener(_expanded);
    model.dispose();
    super.dispose();
  }
}
