import 'package:flutter/foundation.dart';
import 'package:mc_client/mc_client.dart';

class DeletionController extends ChangeNotifier {
  DeletionController(this.onChanged);
  final Future<void> Function() onChanged;
  MaintenanceClient? client;
  String? workspaceId;
  DeletionPreview? preview;
  bool busy = false, viewing = false, complete = false, _disposed = false;
  String? problem;
  int _epoch = 0;

  void notify() {
    if (!_disposed) notifyListeners();
  }

  String message(Object error) => error is ArtifactProblem
      ? error.detail
      : 'The deletion operation failed.';

  void attach(MaintenanceClient? value, String? workspace) {
    if (identical(client, value) && workspaceId == workspace) return;
    ++_epoch;
    client = value;
    workspaceId = workspace;
    preview = null;
    problem = null;
    busy = false;
    viewing = false;
    complete = false;
  }

  Future<void> open(ModEntry target) async {
    if (client == null || busy) return;
    final epoch = ++_epoch;
    viewing = true;
    busy = true;
    preview = null;
    problem = null;
    complete = false;
    notify();
    try {
      final value = await client!.prepareDeletion(target);
      if (!_disposed && epoch == _epoch) preview = value;
    } on Exception catch (error) {
      if (!_disposed && epoch == _epoch) problem = message(error);
    } finally {
      if (!_disposed && epoch == _epoch) {
        busy = false;
        notify();
      }
    }
  }

  Future<void> run() async {
    final owner = client, value = preview;
    final epoch = _epoch;
    if (owner == null || value == null || busy || value.blocked != null) return;
    busy = true;
    problem = null;
    notify();
    try {
      await owner.deleteMod(value);
      if (_disposed || epoch != _epoch) return;
      complete = true;
      await onChanged();
    } on Exception catch (error) {
      if (!_disposed && epoch == _epoch) problem = message(error);
    } finally {
      if (!_disposed && epoch == _epoch) {
        busy = false;
        notify();
      }
    }
  }

  void back() {
    ++_epoch;
    preview = null;
    problem = null;
    busy = false;
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
