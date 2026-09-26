import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mc_client/mc_client.dart';

import 'output_tree.dart';

part 'output_observation.dart';
part 'output_mutations.dart';

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

  Future<void> read({String? contextId}) => _readScope(contextId: contextId);

  Future<void> refresh() => _refreshObservation();

  Future<void> cancel() => _cancelObservation();

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
  }) => _add(id, name, kind, target: target);

  Future<bool> stop(OutputLocation location) => _stop(location);

  Future<OutputPromotionPreview> preview(
    List<OutputSelection> files,
    OutputAction action,
  ) => _preview(files, action);

  Future<bool> apply(List<OutputSelection> files, OutputAction action) =>
      _apply(files, action);

  Future<bool> resume(String id) => _resume(id);

  Future<void> checkResult() => _checkResult();

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
