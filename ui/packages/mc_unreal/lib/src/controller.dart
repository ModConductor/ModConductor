import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mc_client/mc_client.dart';

class UnrealLoaderController extends ChangeNotifier {
  UnrealLoaderController(
    this.client,
    this.workspace,
    this.profile,
    this.onChanged,
  );
  final UnrealClient client;
  final String workspace, profile;
  final VoidCallback onChanged;
  UnrealLoaderState? state;
  UnrealProgress? progress;
  String? problem, archive;
  bool busy = false,
      needsArchive = false,
      _closed = false,
      _reading = false,
      _readAgain = false;
  StreamSubscription<UnrealProgress>? _acquisition;
  Completer<void>? _completion;

  bool _sameTarget(UnrealLoaderState? previous, UnrealLoaderState? current) =>
      previous != null &&
      current != null &&
      previous.id == current.id &&
      previous.contextRevision == current.contextRevision;

  void _setState(UnrealLoaderState current) {
    if (!_sameTarget(state, current)) {
      archive = null;
      needsArchive = false;
    }
    if (current.mod != null) needsArchive = false;
    state = current;
  }

  Future<void> read() async {
    if (_closed) return;
    if (_reading || busy) {
      _readAgain = true;
      return;
    }
    _reading = true;
    final reply = await client.read(workspace, profile);
    _reading = false;
    if (_closed) return;
    switch (reply) {
      case LoaderValue(:final value):
        _setState(value);
        problem = null;
      case LoaderProblem(:final message):
        problem = message;
    }
    notifyListeners();
    if (_readAgain) {
      _readAgain = false;
      unawaited(read());
    }
  }

  Future<void> chooseArchive(Future<String?> Function() choose) async {
    final target = state;
    if (busy || target == null) return;
    final path = await choose();
    if (_closed || path == null || !_sameTarget(target, state)) return;
    archive = path;
    notifyListeners();
    if (needsArchive) await toggle();
  }

  Future<void> _acquire(UnrealLoaderState target) async {
    final completed = _completion = Completer<void>();
    _acquisition = client
        .acquire(target, archive)
        .listen(
          (value) {
            if (_closed) return;
            progress = value;
            problem = value.problem;
            if (value.state case final current?) {
              _setState(current);
              needsArchive = false;
            }
            if (value.mod != null || value.state != null) onChanged();
            notifyListeners();
          },
          onError: (Object error) {
            if (!_closed) problem = 'The loader acquisition stopped. Completed files remain in the library.';
            if (!completed.isCompleted) completed.complete();
          },
          onDone: () {
            if (!completed.isCompleted) completed.complete();
          },
        );
    await completed.future;
    _acquisition = null;
    _completion = null;
  }

  Future<void> toggle() async {
    final target = state;
    if (busy || target == null) return;
    if (needsArchive && archive == null) {
      needsArchive = false;
      notifyListeners();
      return;
    }
    if (target.mod == null && target.archiveRequired && archive == null) {
      needsArchive = true;
      notifyListeners();
      return;
    }
    busy = true;
    problem = null;
    notifyListeners();
    try {
      if (target.mod == null || needsArchive) {
        await _acquire(target);
      } else {
        final reply = await client.change(target, !target.enabled);
        if (_closed) return;
        switch (reply) {
          case LoaderValue(:final value):
            _setState(value);
            onChanged();
          case LoaderProblem(:final message):
            problem = message;
        }
      }
    } finally {
      busy = false;
      progress = null;
      if (!_closed) {
        notifyListeners();
        if (_readAgain) {
          _readAgain = false;
          unawaited(read());
        }
      }
    }
  }

  Future<void> openPage() async {
    final current = state;
    if (current == null) return;
    final result = await client.openPage(current);
    if (_closed) return;
    problem = result;
    notifyListeners();
  }

  @override
  void dispose() {
    _closed = true;
    unawaited(_acquisition?.cancel());
    if (_completion?.isCompleted == false) _completion!.complete();
    super.dispose();
  }
}
