import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_collections/mc_ui_collections.dart';

String categoryLabel(String label) {
  if (label.trim().isEmpty) {
    return '${label.replaceAll(' ', '·').replaceAll('\t', '⇥').replaceAll('\n', '↵')} (spaces)';
  }
  return label != label.trim()
      ? '“${label.replaceAll('\t', '⇥').replaceAll('\n', '↵')}”'
      : label;
}

class CategoryController extends ChangeNotifier {
  CategoryController(
    this.client,
    this.workspace, {
    List<CategoryReference> initial = const [],
    this.multiple = false,
  }) {
    _draftIds.addAll(initial.map((value) => value.id));
    model.sort((a, b) => a.label.compareTo(b.label));
    model.apply(
      upserts: initial.map(
        (value) => ModCategory(
          value.id,
          workspace,
          null,
          value.label,
          value.missing,
          0,
          false,
        ),
      ),
    );
    for (final value in initial) {
      model.select(value.id, toggle: true);
    }
    model.addListener(_changed);
    unawaited(_initialize(initial));
  }
  final ModOrganizationClient client;
  final String workspace;
  final bool multiple;
  final model = McCollectionModel<String, ModCategory>(
    idOf: (row) => row.id,
    labelOf: (row) => row.label,
    parentOf: (row) => row.parentId,
    isBranch: (row) => row.hasChildren,
  );
  final Map<String?, String?> _pages = {};
  final Set<String> _draftIds = {};
  final List<String?> _initialPages = [];
  ({String? parent, bool more})? _retry;
  int? revision;
  int _epoch = 0;
  bool loading = false, stale = false, _disposed = false, _initializing = false;
  String? problem;
  List<CategoryReference> get selected => model.selectedIds
      .map((id) => model[id]?.reference)
      .whereType<CategoryReference>()
      .toList();
  bool get canLoad => _pages.values.any((value) => value != null);
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _changed() {
    _notify();
    _loadExpanded();
  }

  void _loadExpanded() {
    if (!_disposed && !_initializing && !loading && !stale && problem == null) {
      if (_initialPages.isNotEmpty) {
        unawaited(_loadInitialPages());
        return;
      }
      for (final id in model.ids) {
        if (model.expanded(id) && !_pages.containsKey(id)) {
          unawaited(load(parent: id));
          break;
        }
      }
    }
  }

  Future<void> _initialize(
    List<CategoryReference> initial, {
    String? revealId,
  }) {
    _initialPages
      ..clear()
      ..add(null)
      ..addAll(
        initial.where((value) => !value.missing).map((value) => value.id),
      );
    if (revealId != null) _initialPages.add(revealId);
    return _loadInitialPages();
  }

  Future<void> _loadInitialPages() async {
    final epoch = _epoch;
    _initializing = true;
    try {
      while (_initialPages.isNotEmpty) {
        if (_disposed || stale || epoch != _epoch) return;
        final parent = _initialPages.first;
        if (!_pages.containsKey(parent) && !await load(parent: parent)) return;
        if (_disposed || epoch != _epoch) return;
        _initialPages.removeAt(0);
      }
    } finally {
      if (!_disposed && epoch == _epoch) {
        _initializing = false;
        _loadExpanded();
      }
    }
  }

  Future<bool> load({String? parent, bool more = false}) async {
    if (_disposed || loading) return false;
    final epoch = _epoch;
    _retry = (parent: parent, more: more);
    loading = true;
    problem = null;
    _notify();
    try {
      final page = await client.categories(
        workspace,
        parentId: parent,
        afterId: more ? _pages[parent] : null,
        expectedRevision: revision,
      );
      if (_disposed || epoch != _epoch) return false;
      if (revision != null && page.revision != revision) {
        throw const FormatException('The categories changed.');
      }
      _retry = null;
      revision = page.revision;
      _pages[parent] = page.nextId;
      model.apply(upserts: [...page.ancestors, ...page.entries]);
      for (final ancestor in page.ancestors) {
        if (ancestor.hasChildren && !model.expanded(ancestor.id)) {
          model.toggle(ancestor.id);
        }
      }
      return true;
    } on Exception catch (error) {
      if (!_disposed &&
          epoch == _epoch &&
          error is LibraryException &&
          error.fault == LibraryFault.notFound &&
          parent != null &&
          _draftIds.contains(parent)) {
        final old = model[parent]!;
        model.apply(
          upserts: [
            ModCategory(
              old.id,
              old.workspaceId,
              null,
              old.label,
              true,
              0,
              false,
            ),
          ],
        );
        _retry = null;
        _pages[parent] = null;
        return true;
      }
      if (!_disposed && epoch == _epoch) {
        stale =
            error is FormatException ||
            (error is LibraryException &&
                error.fault == LibraryFault.staleRevision);
        problem = error is LibraryException
            ? error.detail
            : 'Could not load categories.';
      }
      return false;
    } finally {
      if (!_disposed && epoch == _epoch) {
        loading = false;
        _notify();
        _loadExpanded();
      }
    }
  }

  Future<void> more() async {
    final retry = _retry;
    if (retry != null) {
      await load(parent: retry.parent, more: retry.more);
      return;
    }
    for (final page in _pages.entries) {
      if (page.value != null) {
        await load(parent: page.key, more: true);
        return;
      }
    }
  }

  Future<void> reload({String? revealId}) async {
    final references = selected;
    ++_epoch;
    loading = false;
    revision = null;
    stale = false;
    _pages.clear();
    _retry = null;
    model.apply(
      evicted: model.ids
          .where((id) => !model.selectedIds.contains(id))
          .toList(),
    );
    await _initialize(references, revealId: revealId);
  }

  void cancel() {
    ++_epoch;
    _initializing = false;
    loading = false;
    _notify();
  }

  Future<bool> change(
    Future<int> Function(int) action, {
    String? removedId,
    String? revealId,
  }) async {
    if (revision == null || loading || stale) return false;
    final epoch = _epoch;
    loading = true;
    problem = null;
    _notify();
    try {
      await action(revision!);
      if (_disposed || epoch != _epoch) return false;
      loading = false;
      if (removedId != null) model.apply(removed: [removedId]);
      await reload(revealId: revealId);
      if (problem != null) {
        problem = 'The category change was saved. Could not reload categories.';
      }
      return true;
    } on Exception catch (error) {
      if (!_disposed && epoch == _epoch) {
        stale =
            error is! LibraryException ||
            error.fault == LibraryFault.staleRevision;
        problem = error is LibraryException
            ? error.detail
            : 'Could not confirm the category change. Reload categories.';
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
    model.removeListener(_changed);
    model.dispose();
    super.dispose();
  }
}
