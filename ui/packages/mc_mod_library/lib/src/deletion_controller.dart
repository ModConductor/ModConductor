import 'package:flutter/foundation.dart';
import 'package:mc_client/mc_client.dart';

class DeletionController extends ChangeNotifier {
  DeletionController(this.onChanged);
  final Future<void> Function() onChanged;
  MaintenanceClient? client;
  String? workspaceId;
  ModEntry? target;
  bool busy = false, viewing = false, complete = false, _disposed = false;
  String? problem;
  int _epoch = 0;

  void notify() {
    if (!_disposed) notifyListeners();
  }

  String message(Object error) =>
      error is ArtifactProblem ? error.detail : 'The mod was not deleted.';

  void attach(MaintenanceClient? value, String? workspace) {
    if (identical(client, value) && workspaceId == workspace) return;
    ++_epoch;
    client = value;
    workspaceId = workspace;
    target = null;
    problem = null;
    busy = false;
    viewing = false;
    complete = false;
  }

  Future<void> open(ModEntry value) async {
    if (client == null || busy) return;
    ++_epoch;
    target = value;
    viewing = true;
    complete = false;
    await run();
  }

  Future<void> run() async {
    final owner = client, value = target;
    final epoch = _epoch;
    if (owner == null || value == null || busy) return;
    busy = true;
    problem = null;
    notify();
    try {
      await owner.deleteMod(value);
      if (_disposed || epoch != _epoch) return;
      complete = true;
      await onChanged();
    } on Exception catch (error) {
      if (!_disposed && epoch == _epoch) {
        problem = message(error);
      }
    } finally {
      if (!_disposed && epoch == _epoch) {
        busy = false;
        notify();
      }
    }
  }

  void back() {
    if (busy) return;
    ++_epoch;
    target = null;
    problem = null;
    viewing = false;
    complete = false;
    notify();
  }

  @override
  void dispose() {
    _disposed = true;
    ++_epoch;
    super.dispose();
  }
}
