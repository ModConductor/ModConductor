import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mc_client/mc_client.dart';

import 'output_tree.dart';

class OutputController extends ChangeNotifier {
  final tools = OutputTree(OutputLocationKind.toolFolder),
      writable = OutputTree(OutputLocationKind.writableFile);
  GeneratedOutputsClient? client;
  String? workspaceId;
  String? profileId;
  bool _available = false, _disposed = false;
  int _epoch = 0;
  int _readEpoch = 0, _observationEpoch = 0;
  Completer<void>? _read;
  StreamSubscription<OutputLoadEvent>? _observation;
  Completer<void>? _observed;
  OutputScope? scope;
  OutputSnapshot? snapshot;
  OutputLoadProgress? progress;
  OutputFile? inspected;
  OutputActionResult? result;
  String? pendingAction, problem;
  bool loading = false, reading = false, changing = false, needsRead = false;
  VoidCallback? onChanged;
  bool get connected =>
      client != null && workspaceId != null && profileId != null && _available;
  bool get canAct =>
      connected &&
      !changing &&
      !loading &&
      !reading &&
      !needsRead &&
      problem == null &&
      snapshot != null;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void attach(
    GeneratedOutputsClient? value,
    String? workspace, {
    required String? profile,
    required bool available,
  }) {
    final newlyAvailable = !_available && available;
    _available = available;
    if (identical(client, value) &&
        workspace == workspaceId &&
        profile == profileId) {
      if (newlyAvailable && scope == null && connected) unawaited(read());
      return;
    }
    ++_epoch;
    ++_readEpoch;
    ++_observationEpoch;
    if (!(_read?.isCompleted ?? true)) _read!.complete();
    _read = null;
    unawaited(_observation?.cancel());
    _observation = null;
    if (!(_observed?.isCompleted ?? true)) _observed!.complete();
    client = value;
    workspaceId = workspace;
    profileId = profile;
    scope = null;
    snapshot = null;
    inspected = null;
    result = null;
    pendingAction = null;
    loading = reading = changing = needsRead = false;
    problem = null;
    progress = null;
    tools.attach(client, null);
    writable.attach(client, null);
    if (connected) unawaited(read());
    _notify();
  }

  void invalidate() {
    ++_readEpoch;
    if (scope != null || reading) {
      needsRead = true;
      _notify();
    }
  }

  Future<void> read({String? contextId}) async {
    if (reading) return _read?.future;
    final api = client, workspace = workspaceId, profile = profileId;
    if (!connected ||
        api == null ||
        workspace == null ||
        profile == null ||
        reading ||
        changing) {
      return;
    }
    final epoch = _epoch, readEpoch = _readEpoch;
    final done = Completer<void>();
    _read = done;
    reading = true;
    problem = null;
    _notify();
    try {
      final value = await api.read(workspace, profile, contextId: contextId);
      if (_disposed || epoch != _epoch || readEpoch != _readEpoch) return;
      if (scope?.reference.contextId != value.reference.contextId ||
          scope?.reference.revision != value.reference.revision ||
          scope?.reference.contextRevision != value.reference.contextRevision) {
        snapshot = null;
        inspected = null;
        tools.attach(api, null);
        writable.attach(api, null);
      }
      scope = value;
      needsRead = false;
    } on Exception catch (error) {
      if (!_disposed && epoch == _epoch && readEpoch == _readEpoch) {
        problem = _message(error);
        needsRead = true;
      }
    } finally {
      if (!done.isCompleted) done.complete();
      if (!_disposed && epoch == _epoch) {
        _read = null;
        reading = false;
        _notify();
      }
    }
  }

  Future<void> refresh() async {
    if (!connected || changing || loading) return;
    final epoch = _epoch;
    await read(contextId: scope?.reference.contextId);
    final api = client, reference = scope?.reference;
    if (api == null ||
        reference == null ||
        needsRead ||
        _disposed ||
        epoch != _epoch) {
      return;
    }
    final observationEpoch = ++_observationEpoch;
    loading = true;
    problem = null;
    progress = null;
    _notify();
    final done = Completer<void>();
    _observed = done;
    var finished = false;
    _observation = api
        .observe(reference)
        .listen(
          (event) {
            if (_disposed ||
                epoch != _epoch ||
                observationEpoch != _observationEpoch) {
              return;
            }
            switch (event) {
              case OutputLoadProgress():
                progress = event;
              case OutputsObserved():
                finished = true;
                snapshot = event.snapshot;
                scope = event.snapshot.scope;
                inspected = null;
                tools.attach(api, snapshot);
                writable.attach(api, snapshot);
            }
            _notify();
          },
          cancelOnError: true,
          onError: (Object error) {
            if (!_disposed &&
                epoch == _epoch &&
                observationEpoch == _observationEpoch) {
              problem = _message(error);
              needsRead = true;
            }
            if (!done.isCompleted) done.complete();
          },
          onDone: () {
            if (!_disposed &&
                epoch == _epoch &&
                observationEpoch == _observationEpoch &&
                !finished &&
                problem == null) {
              problem = 'The output observation did not finish.';
            }
            if (!done.isCompleted) done.complete();
          },
        );
    await done.future;
    if (!_disposed &&
        epoch == _epoch &&
        observationEpoch == _observationEpoch) {
      loading = false;
      _observation = null;
      _observed = null;
      _notify();
    }
  }

  Future<void> cancel() async {
    ++_observationEpoch;
    final old = _observation;
    _observation = null;
    if (!(_observed?.isCompleted ?? true)) _observed!.complete();
    loading = false;
    progress = null;
    _notify();
    await old?.cancel();
  }

  void inspect(OutputFile file) {
    inspected = file;
    _notify();
  }

  void closeInspector() {
    inspected = null;
    _notify();
  }

  void dismissResult() {
    result = null;
    _notify();
  }

  String _message(Object error) => error is OutputException
      ? error.detail
      : 'The engine response is unavailable. Read the current result before retrying.';
  Future<OutputLocation?> add(
    String id,
    String name,
    OutputLocationKind kind, {
    List<String>? target,
  }) async {
    final api = client, reference = scope?.reference;
    if (api == null || reference == null || changing || needsRead) return null;
    changing = true;
    problem = null;
    final epoch = _epoch;
    _notify();
    OutputLocation? value;
    try {
      value = await api.add(id, reference, name, kind, target: target);
      if (!_disposed && epoch == _epoch) {
        needsRead = true;
        onChanged?.call();
      }
    } on Exception catch (error) {
      if (!_disposed && epoch == _epoch) {
        problem = _message(error);
        needsRead = true;
      }
    } finally {
      if (!_disposed && epoch == _epoch) {
        changing = false;
        _notify();
      }
    }
    if (value != null) await read();
    return value;
  }

  Future<bool> stop(OutputLocation location) async {
    final api = client;
    if (api == null || changing) return false;
    changing = true;
    problem = null;
    final epoch = _epoch;
    _notify();
    var success = false;
    try {
      await api.stopUsing(location.id, location.revision);
      success = true;
      if (!_disposed && epoch == _epoch) {
        needsRead = true;
        onChanged?.call();
      }
    } on Exception catch (error) {
      if (!_disposed && epoch == _epoch) {
        problem = _message(error);
        needsRead = true;
      }
    } finally {
      if (!_disposed && epoch == _epoch) {
        changing = false;
        _notify();
      }
    }
    if (success) await read();
    return success;
  }

  Future<OutputPromotionPreview> preview(
    List<OutputSelection> files,
    OutputAction action,
  ) {
    final api = client, id = snapshot?.id;
    if (api == null || id == null || !canAct) {
      throw const OutputException(
        OutputFailure.stale,
        'Refresh the output files.',
      );
    }
    return api.preview(id, files, action);
  }

  Future<bool> apply(List<OutputSelection> files, OutputAction action) async {
    final api = client, id = snapshot?.id;
    if (api == null || id == null || !canAct) return false;
    final operation = newOperationId();
    pendingAction = operation;
    return _action(() => api.apply(operation, id, files, action));
  }

  Future<bool> resume(String id) async {
    final api = client;
    if (api == null || changing) return false;
    pendingAction = id;
    return _action(() => api.resume(id));
  }

  Future<void> checkResult() async {
    final api = client, id = pendingAction;
    if (api == null || id == null || changing) return;
    await _action(() => api.action(id), readOnly: true);
  }

  Future<bool> _action(
    Future<OutputActionResult> Function() action, {
    bool readOnly = false,
  }) async {
    final epoch = _epoch;
    changing = true;
    problem = null;
    result = null;
    _notify();
    var success = false;
    try {
      final value = await action();
      if (!_disposed && epoch == _epoch) {
        result = value;
        needsRead = true;
        pendingAction = value.complete ? null : value.id;
        onChanged?.call();
        success = true;
      }
    } on Exception catch (error) {
      if (!_disposed && epoch == _epoch) {
        problem = _message(error);
        needsRead = true;
        if (readOnly &&
            error is OutputException &&
            error.failure == OutputFailure.notFound) {
          pendingAction = null;
        }
      }
    } finally {
      if (!_disposed && epoch == _epoch) {
        changing = false;
        _notify();
      }
    }
    return success;
  }

  @override
  void dispose() {
    _disposed = true;
    ++_epoch;
    if (!(_read?.isCompleted ?? true)) _read!.complete();
    unawaited(_observation?.cancel());
    if (!(_observed?.isCompleted ?? true)) _observed!.complete();
    tools.dispose();
    writable.dispose();
    super.dispose();
  }
}
