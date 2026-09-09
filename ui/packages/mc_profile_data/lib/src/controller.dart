import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mc_client/mc_client.dart';

class ProfileDataController extends ChangeNotifier {
  ProfileDataClient? _client;
  String? _workspace, _profile;
  int _epoch = 0;
  bool _disposed = false;
  StreamSubscription<ProfileDataEvent>? _action;
  Completer<void>? _done;
  ProfileDataState? state;
  ProfileDataResult? result;
  ProfileDataProgress? progress;
  String? problem, activity;
  bool available = false;
  bool needsRead = false;
  VoidCallback? onChanged;
  bool get busy => activity != null;
  bool get canEdit =>
      available &&
      !busy &&
      !needsRead &&
      state != null &&
      state!.pendingActionId == null &&
      state!.problem == null;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void attach(
    ProfileDataClient? client,
    String? workspace,
    String? profile, {
    required bool available,
  }) {
    final changed =
        !identical(client, _client) ||
        workspace != _workspace ||
        profile != _profile;
    final becameAvailable = available && !this.available;
    this.available = available;
    if (changed) {
      ++_epoch;
      unawaited(_action?.cancel());
      _action = null;
      if (_done != null && !_done!.isCompleted) _done!.complete();
      _done = null;
      _client = client;
      _workspace = workspace;
      _profile = profile;
      state = null;
      result = null;
      progress = null;
      problem = null;
      activity = null;
      needsRead = true;
    }
    if ((changed || becameAvailable) &&
        available &&
        client != null &&
        workspace != null &&
        profile != null) {
      unawaited(read());
    }
  }

  void invalidate() {
    needsRead = true;
    _notify();
  }

  Future<void> read() async {
    final client = _client, workspace = _workspace, profile = _profile;
    if (client == null || workspace == null || profile == null || busy) return;
    final epoch = _epoch;
    activity = 'Reading settings and saves';
    problem = null;
    _notify();
    try {
      final value = await client.read(workspace, profile);
      if (_disposed || epoch != _epoch) return;
      state = value;
      needsRead = false;
    } on Exception catch (error) {
      if (!_disposed && epoch == _epoch) {
        problem = error is ProfileDataProblem
            ? error.detail
            : 'Settings and saves could not be read.';
        needsRead = true;
      }
    } finally {
      if (!_disposed && epoch == _epoch) {
        activity = null;
        _notify();
      }
    }
  }

  Future<void> _run(String label, Stream<ProfileDataEvent> events) async {
    final epoch = _epoch;
    final done = Completer<void>();
    _done = done;
    activity = label;
    progress = null;
    problem = null;
    result = null;
    _notify();
    var finished = false;
    void finish() {
      if (finished) return;
      finished = true;
      if (!done.isCompleted) done.complete();
      if (_disposed || epoch != _epoch) return;
      _action = null;
      _done = null;
      activity = null;
      if (result == null) {
        needsRead = true;
        problem ??= 'The action did not return a complete result. Read again before continuing.';
      }
      _notify();
      onChanged?.call();
    }

    _action = events.listen(
      (event) {
        if (_disposed || epoch != _epoch) return;
        switch (event) {
          case ProfileDataProgress():
            progress = event;
          case ProfileDataResult():
            result = event;
            state = event.state;
            problem = event.problem;
            needsRead = false;
        }
        _notify();
      },
      onError: (Object error) {
        if (!_disposed && epoch == _epoch) {
          problem = error is ProfileDataProblem
              ? error.detail
              : 'The action result is unavailable.';
        }
        finish();
      },
      onDone: finish,
      cancelOnError: true,
    );
    await done.future;
  }

  Future<void> edit(
    ProfileDataOptions options,
    InitialProfileSaves initial,
    DisabledProfileFiles disabled,
  ) async {
    if (!canEdit || _client == null) return;
    await _run(
      'Saving profile options',
      _client!.edit(
        newOperationId(),
        state!.reference,
        options,
        initialSaves: initial,
        disabledFiles: disabled,
      ),
    );
  }

  Future<void> restore() async {
    if (!canEdit || _client == null || state!.inUseProfileId == null) return;
    await _run(
      'Restoring global settings and saves',
      _client!.restore(newOperationId(), state!.reference),
    );
  }

  Future<void> resume() async {
    final current = state;
    if (busy ||
        _client == null ||
        current?.pendingActionId == null ||
        current!.pendingProfileChange) {
      return;
    }
    await _run(
      'Continuing settings and saves',
      _client!.resume(current.reference.workspaceId, current.pendingActionId!),
    );
  }

  Future<void> cancel() async {
    final action = _action;
    final epoch = _epoch;
    final done = _done;
    if (action == null) return;
    await action.cancel();
    if (_disposed || epoch != _epoch) return;
    _action = null;
    activity = null;
    needsRead = true;
    problem =
        'The action was cancelled. Read again to see any completed changes.';
    _done = null;
    if (done != null && !done.isCompleted) done.complete();
    _notify();
    onChanged?.call();
  }

  @override
  void dispose() {
    _disposed = true;
    ++_epoch;
    unawaited(_action?.cancel());
    if (_done != null && !_done!.isCompleted) _done!.complete();
    super.dispose();
  }
}
