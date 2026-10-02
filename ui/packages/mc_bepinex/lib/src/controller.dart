import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mc_client/mc_client.dart';

class LoaderController extends ChangeNotifier {
  LoaderController(
    this.client,
    this.packages,
    this.workspace,
    this.profile,
    this.onChanged,
  );
  final BepInExClient client;
  final ThunderstoreClient packages;
  final String workspace, profile;
  final VoidCallback onChanged;
  BepInExState? state;
  String? problem;
  ThunderstoreProgress? progress;
  bool busy = false, _closed = false, _reading = false, _readAgain = false;
  ThunderstoreAcquisition? _acquisition;

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
        state = value;
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

  Future<BepInExState?> _current() async {
    final reply = await client.read(workspace, profile);
    switch (reply) {
      case LoaderValue(:final value):
        return value;
      case LoaderProblem(:final message):
        problem = message;
        return null;
    }
  }

  Future<bool> _acquire(BepInExState target) async {
    final package = target.package;
    if (package == null) {
      problem = 'Install a compatible BepInEx loader archive through the mod library first.';
      return false;
    }
    final acquisition = _acquisition = packages.acquire(workspace, package);
    bool complete = false;
    try {
      await for (final value in acquisition.progress) {
        if (_closed) return false;
        progress = value;
        if (value.problem case final failure?) {
          problem = failure.message;
          return false;
        }
        if (value.modId != null) onChanged();
        complete = value.stage == 'complete';
        notifyListeners();
      }
      if (!complete) problem = 'The loader acquisition did not complete.';
      return complete;
    } on Exception {
      problem = 'The loader acquisition did not complete. Completed packages remain in the library.';
      return false;
    } finally {
      _acquisition = null;
    }
  }

  Future<void> toggle() async {
    final target = state;
    if (busy || target == null) return;
    busy = true;
    problem = null;
    notifyListeners();
    try {
      if (target.mod == null && !await _acquire(target)) return;
      if (_closed) return;
      final current = await _current();
      if (_closed || current == null) return;
      if (current.contextRevision != target.contextRevision) {
        problem =
            'The game installation changed. Read the loader selection again.';
        return;
      }
      final reply = await client.change(current, !target.enabled);
      if (_closed) return;
      switch (reply) {
        case LoaderValue(:final value):
          state = value;
          onChanged();
        case LoaderProblem(:final message):
          problem = message;
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

  @override
  void dispose() {
    _closed = true;
    unawaited(_acquisition?.cancel());
    super.dispose();
  }
}
