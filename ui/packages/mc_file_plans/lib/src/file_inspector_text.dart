part of 'file_inspector_controller.dart';

extension _FileInspectorText on FileInspectorController {
  void _closeTextEditor() {
    ++_textEpoch;
    textDocument = null;
    openingText = false;
    savingText = false;
    textProblem = null;
    _textActionId = null;
    if (!_disposed) _notifyInspector();
  }

  void _bindTextNavigationGuard(
    Future<bool> Function(FutureOr<void> Function())? guard,
  ) {
    _textNavigationGuard = guard;
  }

  Future<bool> _guardTextNavigation(FutureOr<void> Function() navigate) async {
    final guard = _textNavigationGuard;
    if (guard != null) return guard(navigate);
    await navigate();
    return true;
  }

  bool get _canEditText =>
      !archiveMode &&
      selected?.source is ManagedPreviewSource &&
      selected?.historical == false &&
      selected?.copy != null;

  Future<void> _openTextEditor() async {
    final client = _client, snapshot = _snapshot, selected = this.selected;
    if (_disposed ||
        openingText ||
        client == null ||
        snapshot == null ||
        selected == null ||
        !canEditText) {
      return;
    }
    final epoch = ++_textEpoch;
    openingText = true;
    textProblem = null;
    _notifyInspector();
    try {
      final document = await client.openManagedText(
        snapshot,
        selected.source as ManagedPreviewSource,
      );
      if (_disposed ||
          epoch != _textEpoch ||
          FileInspectorController.key(selected) != _selected) {
        return;
      }
      textDocument = document;
      _textActionId = null;
    } on Exception catch (error) {
      if (!_disposed && epoch == _textEpoch) {
        textProblem = error is FilePlanException
            ? error.detail
            : 'This text file could not be opened for editing.';
      }
    } finally {
      if (!_disposed && epoch == _textEpoch) {
        openingText = false;
        _notifyInspector();
      }
    }
  }

  Future<bool> _saveText(String content) async {
    final client = _client, snapshot = _snapshot, opened = textDocument;
    if (_disposed ||
        savingText ||
        client == null ||
        snapshot == null ||
        opened == null) {
      return false;
    }
    final epoch = _textEpoch;
    savingText = true;
    textProblem = null;
    _notifyInspector();
    try {
      final action = _textActionId ??= newOperationId();
      await client.saveManagedText(snapshot, action, opened.source, content);
      if (_disposed || epoch != _textEpoch) return false;
      _textActionId = null;
      return true;
    } on Exception catch (error) {
      if (!_disposed && epoch == _textEpoch) {
        textProblem = error is FilePlanException
            ? error.detail
            : 'The new version could not be saved.';
        if (error is FilePlanException &&
            error.failure == FilePlanFailure.cancelled) {
          _textActionId = null;
        }
      }
      return false;
    } finally {
      if (!_disposed && epoch == _textEpoch) {
        savingText = false;
        _notifyInspector();
      }
    }
  }

  Future<bool> _abandonPendingText() async {
    final action = _textActionId, client = _client;
    if (action == null) return true;
    if (_disposed || client == null || savingText) return false;
    savingText = true;
    textProblem = null;
    _notifyInspector();
    try {
      await client.abandonManagedText(action);
      if (_disposed) return false;
      _textActionId = null;
      return true;
    } on Exception catch (error) {
      if (!_disposed) {
        textProblem = error is FilePlanException
            ? error.detail
            : 'The interrupted edit could not be abandoned.';
      }
      return false;
    } finally {
      if (!_disposed) {
        savingText = false;
        _notifyInspector();
      }
    }
  }
}
