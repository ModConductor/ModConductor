import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_collections/mc_ui_collections.dart';

class ArtifactController extends ChangeNotifier {
  final model = McCollectionModel<String, Artifact>(
    idOf: (a) => a.id,
    labelOf: (a) => a.originalName,
  );
  ArtifactsClient? client;
  String? workspaceId;
  String? next, problem, activity;
  bool loaded = false, needsRead = false;
  int _epoch = 0;
  bool _disposed = false;
  bool get busy => activity != null;
  bool get canEdit =>
      client != null && workspaceId != null && !busy && !needsRead;
  Artifact? get selected => model.selected;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void attach(ArtifactsClient? client, String? workspaceId) {
    if (identical(client, this.client) && workspaceId == this.workspaceId)
      return;
    ++_epoch;
    this.client = client;
    this.workspaceId = workspaceId;
    model.clear();
    next = null;
    problem = null;
    activity = null;
    loaded = false;
    needsRead = false;
    if (client != null && workspaceId != null) unawaited(load());
  }

  Future<void> load({bool more = false}) async {
    final client = this.client, workspace = workspaceId;
    if (client == null || workspace == null || busy || (more && next == null))
      return;
    final epoch = _epoch;
    activity = 'Reading archives';
    problem = null;
    _notify();
    try {
      final page = await client.list(
        workspace,
        after: more ? next : null,
        refresh: !more && loaded,
      );
      if (_disposed || epoch != _epoch) return;
      final entries = [...page.entries], selected = model.selectedId;
      if (!more &&
          page.next != null &&
          selected != null &&
          !entries.any((a) => a.id == selected)) {
        entries.add(await client.read(workspace, selected));
        if (_disposed || epoch != _epoch) return;
      }
      model.apply(
        upserts: entries,
        evicted: more ? const [] : model.ids.toList(),
      );
      next = page.next;
      loaded = true;
      needsRead = false;
    } on Exception catch (error) {
      if (!_disposed && epoch == _epoch)
        problem = error is ArtifactProblem
            ? error.detail
            : 'The archives could not be read.';
    } finally {
      if (!_disposed && epoch == _epoch) {
        activity = null;
        _notify();
      }
    }
  }

  Future<bool> change(
    String label,
    Future<Artifact?> Function(ArtifactsClient, String) action, {
    String? removed,
  }) async {
    final client = this.client, workspace = workspaceId;
    if (client == null || workspace == null || !canEdit) return false;
    final epoch = _epoch;
    activity = label;
    problem = null;
    _notify();
    try {
      final value = await action(client, workspace);
      if (_disposed || epoch != _epoch) return false;
      if (removed != null) model.apply(removed: [removed]);
      if (value != null) {
        model.apply(upserts: [value]);
        model.select(value.id);
      }
      return true;
    } on Exception catch (error) {
      if (!_disposed && epoch == _epoch) {
        needsRead = true;
        problem = error is ArtifactProblem
            ? error.detail
            : 'The result is unavailable. Refresh the list before continuing.';
      }
      return false;
    } finally {
      if (!_disposed && epoch == _epoch) {
        activity = null;
        _notify();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    ++_epoch;
    model.dispose();
    super.dispose();
  }
}
