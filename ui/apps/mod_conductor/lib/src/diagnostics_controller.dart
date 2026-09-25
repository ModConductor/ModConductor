part of 'app.dart';

class DiagnosticsController extends ChangeNotifier {
  DiagnosticsClient? _client;
  String? _workspaceId,
      _profileId,
      _fileSnapshotId,
      _pluginSnapshotId,
      _deploymentId;
  int? _deploymentRevision;
  int _epoch = 0;
  bool _disposed = false;
  DiagnosticSnapshot? snapshot;
  DiagnosticPreview? preview;
  DiagnosticApplyResult? result;
  bool busy = false;
  String? problem;

  void attach(
    DiagnosticsClient? client,
    String? workspaceId,
    String? profileId, {
    String? fileSnapshotId,
    String? pluginSnapshotId,
    String? deploymentId,
    int? deploymentRevision,
  }) {
    if (identical(client, _client) &&
        workspaceId == _workspaceId &&
        profileId == _profileId &&
        fileSnapshotId == _fileSnapshotId &&
        pluginSnapshotId == _pluginSnapshotId &&
        deploymentId == _deploymentId &&
        deploymentRevision == _deploymentRevision) {
      return;
    }
    _client = client;
    _workspaceId = workspaceId;
    _profileId = profileId;
    _fileSnapshotId = fileSnapshotId;
    _pluginSnapshotId = pluginSnapshotId;
    _deploymentId = deploymentId;
    _deploymentRevision = deploymentRevision;
    ++_epoch;
    snapshot = null;
    preview = null;
    result = null;
    problem = null;
    busy = false;
    if (client != null && workspaceId != null && profileId != null) {
      unawaited(refresh());
    }
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  String _message(Object error) {
    if (error is! DiagnosticsException) {
      return 'Diagnostics did not return a result.';
    }
    return switch (error.fault) {
      DiagnosticFault.expired || DiagnosticFault.stale =>
        'The selected information changed. Run Diagnostics again.',
      DiagnosticFault.foreign || DiagnosticFault.notOwned => 'This change belongs to another workspace. Mod Conductor changed no files.',
      DiagnosticFault.busy =>
        'Another action is active. After the action finishes, try again.',
      DiagnosticFault.oversized =>
        'This change affects too many paths. Mod Conductor changed no files.',
      DiagnosticFault.cancelled =>
        'The action was canceled. Mod Conductor changed no files.',
      DiagnosticFault.notFound =>
        'The selected information is no longer available.',
      DiagnosticFault.unsupported => 'Mod Conductor cannot make this change.',
    };
  }

  Future<void> refresh() async {
    final client = _client, workspace = _workspaceId, profile = _profileId;
    if (client == null || workspace == null || profile == null || busy) return;
    final epoch = ++_epoch;
    busy = true;
    problem = null;
    preview = null;
    result = null;
    _notify();
    try {
      final value = await client.check(
        workspaceId: workspace,
        profileId: profile,
        fileSnapshotId: _fileSnapshotId,
        pluginSnapshotId: _pluginSnapshotId,
        deploymentId: _deploymentId,
        deploymentRevision: _deploymentRevision,
      );
      if (!_disposed && epoch == _epoch) snapshot = value;
    } on Exception catch (error) {
      if (!_disposed && epoch == _epoch) problem = _message(error);
    } finally {
      if (!_disposed && epoch == _epoch) {
        busy = false;
        _notify();
      }
    }
  }

  Future<DiagnosticPreview?> previewChange(DiagnosticFinding finding) async {
    final client = _client, current = snapshot;
    if (client == null || current == null || busy) return null;
    final epoch = ++_epoch;
    busy = true;
    preview = null;
    result = null;
    problem = null;
    _notify();
    try {
      final value = await client.preview(current.id, finding.id);
      if (!_disposed && epoch == _epoch) preview = value;
      return !_disposed && epoch == _epoch ? value : null;
    } on Exception catch (error) {
      if (!_disposed && epoch == _epoch) problem = _message(error);
      return null;
    } finally {
      if (!_disposed && epoch == _epoch) {
        busy = false;
        _notify();
      }
    }
  }

  Future<bool> applyChange() async {
    final client = _client, value = preview;
    if (client == null || value == null || busy) return false;
    final epoch = ++_epoch;
    busy = true;
    problem = null;
    _notify();
    try {
      final applied = await client.apply(value.id);
      if (!_disposed && epoch == _epoch) {
        result = applied;
        preview = null;
      }
      return !_disposed && epoch == _epoch && applied.complete;
    } on Exception catch (error) {
      if (!_disposed && epoch == _epoch) {
        problem = _message(error);
        preview = null;
      }
      return false;
    } finally {
      if (!_disposed && epoch == _epoch) {
        busy = false;
        _notify();
      }
    }
  }

  Future<bool> exportReport() async {
    final client = _client, current = snapshot;
    if (client == null || current == null || busy) return false;
    final epoch = ++_epoch;
    busy = true;
    problem = null;
    _notify();
    try {
      final report = await client.export(current.id);
      final saved = await saveSupportReport(report.fileName, report.content);
      return !_disposed && epoch == _epoch && saved;
    } on Exception catch (error) {
      if (!_disposed && epoch == _epoch) problem = _message(error);
      return false;
    } finally {
      if (!_disposed && epoch == _epoch) {
        busy = false;
        _notify();
      }
    }
  }

  void clearResult() {
    if (result == null) return;
    result = null;
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    ++_epoch;
    super.dispose();
  }
}
