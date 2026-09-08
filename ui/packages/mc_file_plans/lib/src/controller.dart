import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mc_client/mc_client.dart';

import 'file_inspector_controller.dart';
import 'planned_files_controller.dart';

class FilePlansController extends ChangeNotifier {
  final tree = PlannedFilesController();
  final inspector = FileInspectorController();
  FilePlansClient? _client;
  String? _profile;
  int _epoch = 0;
  bool _disposed = false, _available = true, _validating = false;
  StreamSubscription<FilePlanLoadEvent>? _acquisition;
  Completer<void>? _acquireDone;
  FilePlanState? state;
  FilePlanProgress? progress;
  bool loading = false, reading = false, changing = false, needsRead = false;
  String? problem;
  bool get connected => _client != null && _profile != null && _available;
  FilePlansController() {
    tree.addListener(_notify);
    inspector.addListener(_notify);
  }
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void attach(
    FilePlansClient? client,
    String? profileId, {
    bool available = true,
  }) {
    final becameAvailable = !_available && available;
    _available = available;
    if (identical(client, _client) && profileId == _profile) {
      if (becameAvailable && state == null && connected) unawaited(read());
      _notify();
      return;
    }
    ++_epoch;
    unawaited(_acquisition?.cancel());
    if (!(_acquireDone?.isCompleted ?? true)) _acquireDone!.complete();
    _acquireDone = null;
    _acquisition = null;
    _client = client;
    _profile = profileId;
    state = null;
    loading = reading = changing = needsRead = false;
    problem = null;
    progress = null;
    tree.attach(null, null);
    inspector.attach(client, null, clear: true);
    if (connected) unawaited(read());
    _notify();
  }

  void invalidate() {
    if (state == null) return;
    needsRead = true;
    unawaited(_validateRetained());
    _notify();
  }

  Future<void> _validateRetained() async {
    final client = _client, retained = state;
    if (_validating || client == null || retained == null) return;
    final epoch = _epoch;
    _validating = true;
    try {
      final value = await client.read(retained.id);
      if (!_disposed && epoch == _epoch && state?.id == retained.id) {
        state = value;
      }
    } on Exception {
      // The retained view stays guarded until an explicit Reload succeeds.
    } finally {
      _validating = false;
      if (!_disposed && epoch == _epoch) _notify();
    }
  }

  void _accept(
    FilePlanState value, {
    bool preserve = false,
    PlannedFileNode? changed,
  }) {
    state = value;
    needsRead = false;
    tree.attach(
      _client,
      value.loaded ? value : null,
      preserve: preserve,
      changed: changed,
    );
    inspector.attach(_client, value);
  }

  Future<FilePlanProblems> problems(FilePlanCursor? cursor) {
    final client = _client, snapshot = state;
    if (client == null || snapshot == null) {
      throw const FilePlanException(
        FilePlanFailure.expired,
        'The file view is unavailable.',
      );
    }
    return client.problems(snapshot.id, cursor: cursor);
  }

  Future<void> read() async {
    final client = _client, profile = _profile;
    if (!connected || reading || loading || changing) return;
    final epoch = _epoch;
    reading = true;
    problem = null;
    _notify();
    try {
      final value = await client!.open(profile!);
      if (_disposed || epoch != _epoch) return;
      _accept(value);
      if (inspector.visible) await inspector.reload();
    } on Exception catch (error) {
      if (!_disposed && epoch == _epoch) {
        needsRead = true;
        problem = error is FilePlanException
            ? error.detail
            : 'Could not read the file view.';
      }
    } finally {
      if (!_disposed && epoch == _epoch) {
        reading = false;
        _notify();
      }
    }
  }

  Future<void> acquire({required bool refresh}) async {
    final client = _client, profile = _profile;
    if (!connected || loading || reading || changing) return;
    final epoch = _epoch;
    loading = true;
    progress = null;
    problem = null;
    _notify();
    final done = Completer<void>();
    _acquireDone = done;
    var finished = false;
    _acquisition = client!
        .acquire(profile!, refresh: refresh)
        .listen(
          (event) {
            if (_disposed || epoch != _epoch) return;
            switch (event) {
              case FilePlanProgress():
                progress = event;
                _notify();
              case FilePlanLoaded(:final state):
                finished = true;
                _accept(state);
                if (inspector.visible) unawaited(inspector.reload());
            }
          },
          onError: (Object error) {
            if (!_disposed && epoch == _epoch) {
              problem = error is FilePlanException
                  ? error.detail
                  : 'Could not load game files.';
            }
            if (!done.isCompleted) done.complete();
          },
          onDone: () {
            if (!_disposed && epoch == _epoch && !finished && problem == null) {
              problem = 'The file check ended before it completed.';
            }
            if (!done.isCompleted) done.complete();
          },
        );
    await done.future;
    if (!_disposed && epoch == _epoch) {
      _acquisition = null;
      loading = false;
      _notify();
    }
  }

  Future<void> cancel() async {
    final current = _acquisition;
    _acquisition = null;
    ++_epoch;
    await current?.cancel();
    if (!(_acquireDone?.isCompleted ?? true)) _acquireDone!.complete();
    _acquireDone = null;
    loading = false;
    progress = null;
    _notify();
  }

  Future<bool> change({required bool hidden}) async {
    final client = _client, current = state, copy = inspector.selected?.copy;
    if (!connected ||
        client == null ||
        current == null ||
        copy == null ||
        changing ||
        loading ||
        reading ||
        needsRead) {
      return false;
    }
    final selected = inspector.selected!;
    if (hidden ? !selected.canHide : !selected.canUnhide) return false;
    final epoch = _epoch;
    changing = true;
    problem = null;
    _notify();
    try {
      final changed = await client.change(current.id, copy, hidden: hidden);
      if (_disposed || epoch != _epoch) return true;
      _accept(changed.state, preserve: true, changed: changed.changed);
      await inspector.reload();
      return true;
    } on Exception catch (error) {
      if (!_disposed && epoch == _epoch) {
        needsRead = true;
        problem = error is FilePlanException ? error.detail : 'The file change could not be confirmed. Reload before you try again.';
      }
      return false;
    } finally {
      if (!_disposed && epoch == _epoch) {
        changing = false;
        _notify();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    ++_epoch;
    unawaited(_acquisition?.cancel());
    if (!(_acquireDone?.isCompleted ?? true)) _acquireDone!.complete();
    tree.removeListener(_notify);
    inspector.removeListener(_notify);
    tree.dispose();
    inspector.dispose();
    super.dispose();
  }
}
