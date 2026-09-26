part of 'output_controller.dart';

extension _OutputMutations on OutputController {
  Future<OutputLocation?> _add(
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

  Future<bool> _stop(OutputLocation location) async {
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

  Future<OutputPromotionPreview> _preview(
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

  Future<bool> _apply(List<OutputSelection> files, OutputAction action) async {
    final api = client, id = snapshot?.id;
    if (api == null || id == null || !canAct) return false;
    final operation = newOperationId();
    pendingAction = operation;
    return _action(() => api.apply(operation, id, files, action));
  }

  Future<bool> _resume(String id) async {
    final api = client;
    if (api == null || changing) return false;
    pendingAction = id;
    return _action(() => api.resume(id));
  }

  Future<void> _checkResult() async {
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
}
