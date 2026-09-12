import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mc_client/mc_client.dart';

class DeletionController extends ChangeNotifier {
  DeletionController(this.onChanged);
  final Future<void> Function() onChanged;
  MaintenanceClient? client;
  String? workspaceId;
  DeletionPreview? preview;
  DeletionStatus? status;
  List<DeletionStatus> pending = const [];
  bool busy = false, viewing = false, _disposed = false;
  String? problem, startId;
  int _epoch = 0;
  StreamSubscription<DeletionStatus>? _watch;
  void notify() {
    if (!_disposed) notifyListeners();
  }

  String message(Object error) => error is ArtifactProblem
      ? error.detail
      : 'The deletion operation failed.';
  void attach(MaintenanceClient? value, String? workspace) {
    if (identical(client, value) && workspaceId == workspace) return;
    ++_epoch;
    final oldPreview = preview, oldClient = client;
    if (oldPreview != null && oldClient != null && startId == null) {
      unawaited(
        oldClient.closeDeletion(oldPreview).onError<Exception>((_, _) {}),
      );
    }
    final watch = _watch;
    _watch = null;
    if (watch != null) unawaited(watch.cancel());
    client = value;
    workspaceId = workspace;
    preview = null;
    status = null;
    pending = const [];
    problem = null;
    startId = null;
    busy = false;
    viewing = false;
    if (value != null && workspace != null) unawaited(recent());
  }

  Future<void> recent() async {
    final value = client, workspace = workspaceId, epoch = _epoch;
    if (value == null || workspace == null) return;
    try {
      final entries = await value.recentDeletions(workspace);
      if (_disposed || epoch != _epoch) return;
      pending = entries;
    } on Exception catch (error) {
      if (!_disposed && epoch == _epoch) problem = message(error);
    }
    if (!_disposed && epoch == _epoch) notify();
  }

  Future<void> open(ModEntry target) async {
    if (client == null || busy) return;
    final epoch = ++_epoch;
    final owner = client!;
    viewing = true;
    busy = true;
    preview = null;
    status = null;
    problem = null;
    startId = null;
    notify();
    try {
      final value = await owner.prepareDeletion(target);
      if (_disposed || epoch != _epoch) {
        unawaited(owner.closeDeletion(value).onError<Exception>((_, _) {}));
        return;
      }
      preview = value;
    } on Exception catch (error) {
      if (!_disposed && epoch == _epoch) problem = message(error);
    } finally {
      if (!_disposed && epoch == _epoch) {
        busy = false;
        notify();
      }
    }
  }

  void accept(DeletionStatus value) {
    if (_disposed) return;
    final before = status;
    if (before?.id == value.id && before?.phase == DeletionPhase.complete) {
      return;
    }
    status = value;
    if (value.phase == DeletionPhase.complete) {
      pending = pending.where((entry) => entry.id != value.id).toList();
      unawaited(onChanged());
    }
    if (value.phase == DeletionPhase.running && _watch == null) observe();
    notify();
  }

  void resume(DeletionStatus value) {
    viewing = true;
    preview = null;
    startId = value.id;
    problem = null;
    accept(value);
  }

  Future<void> run() async {
    final value = client, plan = preview, previous = status, epoch = _epoch;
    if (value == null || busy || (plan == null && previous == null)) return;
    busy = true;
    problem = null;
    startId ??= newOperationId();
    notify();
    try {
      final next = previous == null
          ? await value.startDeletion(plan!, startId!)
          : await value.continueDeletion(previous);
      if (_disposed || epoch != _epoch) return;
      accept(next);
      unawaited(onChanged());
    } on Exception catch (error) {
      if (!_disposed && epoch == _epoch) problem = message(error);
    } finally {
      if (!_disposed && epoch == _epoch) {
        busy = false;
        notify();
      }
    }
  }

  void observe() {
    final value = status, current = client, epoch = _epoch;
    if (value == null || current == null || _disposed) return;
    final previous = _watch;
    _watch = null;
    if (previous != null) unawaited(previous.cancel());
    problem = null;
    _watch = current
        .watchDeletion(value)
        .listen(
          (value) {
            if (epoch == _epoch) accept(value);
          },
          onError: (Object error) {
            if (!_disposed && epoch == _epoch) {
              problem = message(error);
              _watch = null;
              notify();
            }
          },
          onDone: () {
            if (epoch == _epoch) _watch = null;
          },
          cancelOnError: true,
        );
  }

  void back() {
    ++_epoch;
    final previous = _watch;
    _watch = null;
    if (previous != null) unawaited(previous.cancel());
    final value = preview;
    if (value != null && startId == null) {
      unawaited(client!.closeDeletion(value).onError<Exception>((_, _) {}));
    }
    preview = null;
    status = null;
    problem = null;
    startId = null;
    busy = false;
    viewing = false;
    unawaited(recent());
    notify();
  }

  @override
  void dispose() {
    _disposed = true;
    ++_epoch;
    if (_watch != null) unawaited(_watch!.cancel());
    final value = preview;
    if (value != null && startId == null) {
      unawaited(client!.closeDeletion(value).onError<Exception>((_, _) {}));
    }
    super.dispose();
  }
}
