import 'dart:collection';

import 'package:flutter/foundation.dart';

/// IDs belong to the consumer. Rows and tree ancestry are immutable values.
class McCollectionModel<I extends Object, T extends Object>
    extends ChangeNotifier {
  McCollectionModel({
    required this.idOf,
    required this.labelOf,
    this.parentOf,
    this.isBranch,
  });
  final I Function(T) idOf;
  final String Function(T) labelOf;
  final I? Function(T)? parentOf;
  final bool Function(T)? isBranch;
  final Map<I, T> _rows = {};
  final Map<I?, List<I>> _children = {};
  final Map<I, String> _search = {};
  final Set<I> _expanded = {};
  List<I> _visible = [];
  Map<I, int> _positions = {};
  I? _selected, _focused;
  String _query = '';
  Comparator<T>? _compare;
  bool _descending = false;

  I? get selectedId => _selected;
  I? get focusedId => _focused;
  T? get selected => _rows[_selected];
  T? operator [](I? id) => _rows[id];
  Iterable<I> get ids => _rows.keys;
  int get length => _rows.length;
  List<I> get visible => UnmodifiableListView(_visible);
  int? position(I? id) => _positions[id];
  String get query => _query;
  bool get descending => _descending;
  bool expanded(I id) => _expanded.contains(id);
  bool branch(I id) =>
      _rows[id] != null && (isBranch?.call(_rows[id]!) ?? false);
  I? parent(I id) => _rows[id] == null ? null : parentOf?.call(_rows[id]!);
  int depth(I id) {
    var depth = 0;
    for (var next = parent(id); next != null; next = parent(next)) {
      depth++;
    }
    return depth;
  }

  void apply({
    Iterable<T> upserts = const [],
    Iterable<I> removed = const [],
    Iterable<I> evicted = const [],
  }) {
    final affected = <I?>{};
    var changed = false;
    var projectionChanged = false;
    final deleted = removed.toSet();
    for (final id in {...deleted, ...evicted}) {
      final old = _rows.remove(id);
      if (old != null) {
        _children[parentOf?.call(old)]?.remove(id);
        _search.remove(id);
        projectionChanged = true;
        changed = true;
      }
      if (deleted.contains(id)) {
        _expanded.remove(id);
        if (_selected == id) {
          _selected = null;
          changed = true;
        }
        if (_focused == id) {
          _focused = null;
          changed = true;
        }
      }
    }
    for (final row in upserts) {
      final id = idOf(row), old = _rows[id];
      if (identical(old, row)) continue;
      final parent = parentOf?.call(row);
      final oldParent = old == null ? null : parentOf?.call(old);
      if (old == null || oldParent != parent) {
        if (old != null) _children[oldParent]?.remove(id);
        (_children[parent] ??= []).add(id);
        projectionChanged = true;
      }
      final search = labelOf(row).toLowerCase();
      if (_query.trim().isNotEmpty && _search[id] != search) {
        projectionChanged = true;
      }
      if (_compare != null &&
          (old == null || oldParent != parent || _compare!(old, row) != 0)) {
        affected.add(parent);
        projectionChanged = true;
      }
      _rows[id] = row;
      _search[id] = search;
      changed = true;
    }
    if (!changed) return;
    if (_compare != null) {
      for (final parent in affected) {
        _sortChildren(_children[parent]!);
      }
    }
    if (projectionChanged) _project();
    notifyListeners();
  }

  void _sortChildren(List<I> children) {
    children.sort((a, b) {
      final result = _compare!(_rows[a]!, _rows[b]!);
      return _descending ? -result : result;
    });
  }

  void sort(Comparator<T> compare, {bool descending = false}) {
    _compare = compare;
    _descending = descending;
    for (final children in _children.values) {
      _sortChildren(children);
    }
    _project();
    notifyListeners();
  }

  void filter(String query) {
    if (_query == query) return;
    _query = query;
    _project();
    notifyListeners();
  }

  void _project() {
    final needle = _query.toLowerCase().trim();
    Set<I>? matches;
    if (needle.isNotEmpty) {
      matches = {};
      for (final entry in _search.entries) {
        if (!entry.value.contains(needle)) continue;
        I? id = entry.key;
        while (id != null && matches.add(id)) {
          id = parent(id);
        }
      }
    }
    final visible = <I>[];
    void visit(I? parent) {
      for (final id in _children[parent] ?? <I>[]) {
        if (matches != null && !matches.contains(id)) continue;
        visible.add(id);
        if (matches != null || expanded(id)) visit(id);
      }
    }

    visit(null);
    _visible = visible;
    _positions = {for (var i = 0; i < visible.length; i++) visible[i]: i};
  }

  void select(I id) {
    if (_selected == id && _focused == id) return;
    _selected = id;
    _focused = id;
    notifyListeners();
  }

  void toggle(I id) {
    if (!branch(id)) return;
    if (!_expanded.remove(id)) _expanded.add(id);
    _project();
    notifyListeners();
  }

  void clear() {
    _rows.clear();
    _children.clear();
    _search.clear();
    _expanded.clear();
    _visible = [];
    _positions = {};
    _selected = _focused = null;
    _query = '';
    notifyListeners();
  }
}
