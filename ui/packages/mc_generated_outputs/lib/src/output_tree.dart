import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_collections/mc_ui_collections.dart';

class OutputNode {
  OutputNode(this.locationId, List<String> path, this.file)
    : path = List.unmodifiable(path),
      id = jsonEncode([locationId, ...path]),
      parent = path.length == 1
          ? null
          : jsonEncode([locationId, ...path.sublist(0, path.length - 1)]);
  final String locationId, id;
  final String? parent;
  final List<String> path;
  final OutputFile? file;
  bool get folder => file == null;
}

class OutputTree extends ChangeNotifier {
  OutputTree(this.kind) {
    model.sort((a, b) {
      final branch = (a.folder ? 0 : 1).compareTo(b.folder ? 0 : 1);
      return branch != 0 ? branch : a.path.last.compareTo(b.path.last);
    });
    model.addListener(_notify);
  }
  final OutputLocationKind kind;
  final model = McCollectionModel<String, OutputNode>(
    idOf: (value) => value.id,
    labelOf: (value) => value.path.join('/'),
    parentOf: (value) => value.parent,
    isBranch: (value) => value.folder,
  );
  GeneratedOutputsClient? _client;
  String? _snapshot, _cursor;
  bool _loaded = false, _disposed = false;
  int _epoch = 0;
  Timer? _debounce;
  bool loading = false;
  String? problem;
  String filter = '';
  int files = 0, unreviewed = 0, matching = 0, loadedFiles = 0;
  bool get canLoad => _snapshot != null && (!_loaded || _cursor != null);
  List<OutputFile> get selected => model.selectedIds
      .map((id) => model[id]?.file)
      .whereType<OutputFile>()
      .where((file) => file.status != OutputFileStatus.absent)
      .toList();
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void attach(GeneratedOutputsClient? client, OutputSnapshot? snapshot) {
    _client = client;
    if (_snapshot == snapshot?.id) return;
    _snapshot = snapshot?.id;
    _reset();
    if (snapshot != null) unawaited(load());
  }

  void _reset() {
    ++_epoch;
    _debounce?.cancel();
    _debounce = null;
    _loaded = false;
    _cursor = null;
    loading = false;
    problem = null;
    files = unreviewed = matching = loadedFiles = 0;
    model.clear();
    _notify();
  }

  void search(String value) {
    if (value == filter) return;
    filter = value;
    _reset();
    _debounce = Timer(
      const Duration(milliseconds: 200),
      () => unawaited(load()),
    );
  }

  Future<void> load() async {
    final client = _client, snapshot = _snapshot;
    if (_disposed ||
        client == null ||
        snapshot == null ||
        loading ||
        !canLoad) {
      return;
    }
    final epoch = _epoch;
    loading = true;
    problem = null;
    _notify();
    try {
      final page = await client.page(
        snapshot,
        kind: kind,
        cursor: _cursor,
        filter: filter,
      );
      if (_disposed || epoch != _epoch || snapshot != _snapshot) return;
      if (page.snapshot.id != snapshot) {
        throw const FormatException(
          'The output page belongs to another observation.',
        );
      }
      final upserts = <String, OutputNode>{};
      for (final file in page.entries) {
        for (var length = 1; length < file.path.length; length++) {
          final folder = OutputNode(
            file.locationId,
            file.path.sublist(0, length),
            null,
          );
          if (model[folder.id] == null) upserts[folder.id] = folder;
        }
        final node = OutputNode(file.locationId, file.path, file);
        if (model[node.id]?.file == null && upserts[node.id]?.file == null) {
          loadedFiles++;
        }
        upserts[node.id] = node;
      }
      model.apply(upserts: upserts.values);
      _loaded = true;
      _cursor = page.nextCursor;
      files = page.files;
      unreviewed = page.unreviewed;
      matching = page.matching;
    } on Exception catch (error) {
      if (!_disposed && epoch == _epoch) {
        problem = error is OutputException
            ? error.detail
            : 'The output page could not be read.';
      }
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
    _debounce?.cancel();
    model.removeListener(_notify);
    model.dispose();
    super.dispose();
  }
}
