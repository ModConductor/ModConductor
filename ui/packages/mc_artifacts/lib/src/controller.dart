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
  String? next, problem, activity, progressProblem;
  bool loaded = false, needsRead = false;
  int _epoch = 0;
  bool _disposed = false;
  StreamSubscription<Artifact>? _watch;
  Timer? _reconnect;
  int _watchEpoch = 0;
  void _cancelObservation() {
    final previous = _watch;
    _watch = null;
    if (previous != null) {
      unawaited(previous.cancel().onError<ArtifactProblem>((_, _) {}));
    }
  }

  void observe() {
    _reconnect?.cancel();
    _cancelObservation();
    final watchEpoch = ++_watchEpoch, epoch = _epoch;
    final client = this.client, workspace = workspaceId;
    if (_disposed || client == null || workspace == null) return;
    final ids = <String>{
      if (model.selectedId != null && selected?.download != null)
        model.selectedId!,
      for (final id in model.ids)
        if (model[id]?.download?.active == true) id,
      for (final id in model.ids)
        if (model[id]?.download != null) id,
    }.take(64).toList();
    if (ids.isEmpty) return;
    void reconnect() {
      if (_disposed || epoch != _epoch || watchEpoch != _watchEpoch) return;
      _reconnect?.cancel();
      _reconnect = Timer(const Duration(seconds: 1), observe);
    }

    _watch = client
        .watchDownloads(workspace, ids)
        .listen(
          (artifact) {
            if (_disposed ||
                epoch != _epoch ||
                watchEpoch != _watchEpoch ||
                artifact.workspaceId != workspace)
              return;
            final previous = model[artifact.id];
            final recovered = progressProblem != null;
            progressProblem = null;
            if (previous == null || previous.revision >= artifact.revision) {
              if (recovered) _notify();
              return;
            }
            model.apply(upserts: [artifact]);
            _notify();
          },
          onError: (Object _) {
            if (!_disposed && epoch == _epoch && watchEpoch == _watchEpoch) {
              progressProblem =
                  'Download progress is unavailable. Reconnecting.';
              _notify();
            }
            reconnect();
          },
          onDone: reconnect,
          cancelOnError: true,
        );
  }

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
    ++_watchEpoch;
    _reconnect?.cancel();
    _cancelObservation();
    this.client = client;
    this.workspaceId = workspaceId;
    model.clear();
    next = null;
    problem = null;
    progressProblem = null;
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
        observe();
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
        observe();
        _notify();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    ++_watchEpoch;
    _reconnect?.cancel();
    _cancelObservation();
    ++_epoch;
    model.dispose();
    super.dispose();
  }
}
