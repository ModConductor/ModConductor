import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mc_client/mc_client.dart';

class InstallationController extends ChangeNotifier {
  InstallationController(this.client, this.artifact, this.onCommitted);
  final InstallationsClient client;
  final Artifact artifact;
  final VoidCallback onCommitted;
  InstallationDraft? draft;
  InstallationStatus? status;
  String? problem, startId;
  bool busy = false, _disposed = false;
  int _epoch = 0;
  StreamSubscription<InstallationStatus>? _watch;
  InstallationPreparation? _preparation;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  String _message(Object error) => error is ArtifactProblem
      ? error.detail
      : 'The installation operation failed.';
  bool get canEdit => !busy && status == null && startId == null;
  Future<void> open() async {
    final epoch = ++_epoch;
    busy = true;
    problem = null;
    _notify();
    try {
      final recent = await client.recent(artifact.workspaceId);
      if (_disposed || epoch != _epoch) return;
      for (final entry in recent) {
        if (entry.artifactId == artifact.id &&
            (entry.phase == InstallationPhase.running ||
                entry.phase == InstallationPhase.stopped)) {
          _accept(entry);
          return;
        }
      }
      final preparation = client.prepare(artifact);
      _preparation = preparation;
      final value = await preparation.result;
      if (_disposed || epoch != _epoch) {
        unawaited(client.closeDraft(value).onError<Exception>((_, _) {}));
        return;
      }
      draft = value;
    } on Exception catch (error) {
      if (!_disposed && epoch == _epoch) problem = _message(error);
    } finally {
      if (!_disposed && epoch == _epoch) {
        busy = false;
        _preparation = null;
        _notify();
      }
    }
  }

  Future<bool> change(InstallationLayoutChange change) async {
    final current = draft;
    if (!canEdit || current == null) return false;
    busy = true;
    problem = null;
    _notify();
    try {
      final value = await client.change(current, change);
      if (_disposed) return false;
      draft = value;
      return true;
    } on Exception catch (error) {
      if (!_disposed) problem = _message(error);
      return false;
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> install() async {
    final current = draft;
    if (busy || current == null || !current.canInstall || status != null)
      return;
    busy = true;
    problem = null;
    startId ??= newOperationId();
    _notify();
    try {
      final value = await client.start(current, startId!);
      if (_disposed) {
        await client.closeDraft(current);
      } else {
        _accept(value);
      }
    } on Exception catch (error) {
      if (!_disposed) problem = _message(error);
    } finally {
      busy = false;
      _notify();
    }
  }

  void _accept(InstallationStatus value) {
    if (_disposed) return;
    final before = status;
    if (before?.id == value.id &&
        before?.phase != InstallationPhase.running &&
        value.phase == InstallationPhase.running)
      return;
    status = value;
    if (value.phase == InstallationPhase.complete &&
        before?.phase != InstallationPhase.complete)
      onCommitted();
    if (value.phase == InstallationPhase.running && _watch == null) observe();
    _notify();
  }

  void observe() {
    final current = status;
    if (_disposed || current == null) return;
    final previous = _watch;
    _watch = null;
    if (previous != null) unawaited(previous.cancel());
    problem = null;
    _watch = client
        .watch(current)
        .listen(
          _accept,
          onError: (Object error) {
            if (!_disposed) {
              problem = _message(error);
              _watch = null;
              _notify();
            }
          },
          onDone: () {
            _watch = null;
          },
          cancelOnError: true,
        );
  }

  Future<void> control({required bool discard}) async {
    final current = status;
    if (busy || current == null) return;
    busy = true;
    problem = null;
    _notify();
    try {
      final value = discard
          ? await client.deleteTemporaryFiles(current)
          : await client.cancel(current);
      _accept(value);
    } on Exception catch (error) {
      if (!_disposed) problem = _message(error);
    } finally {
      busy = false;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    ++_epoch;
    final watch = _watch;
    if (watch != null) unawaited(watch.cancel());
    final preparation = _preparation;
    if (preparation != null)
      unawaited(preparation.cancel().onError<Exception>((_, _) {}));
    final current = draft;
    if (current != null && (startId == null || status != null))
      unawaited(client.closeDraft(current).onError<Exception>((_, _) {}));
    super.dispose();
  }
}
