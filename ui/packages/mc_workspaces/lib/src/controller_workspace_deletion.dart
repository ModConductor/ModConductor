part of 'controller.dart';

extension WorkspaceDeletion on WorkspaceController {
  Future<WorkspaceDeletionInfo> deletionInfo(String workspace) {
    final client = _client;
    if (client == null) {
      throw const WorkspaceException(
        WorkspaceFault.busy,
        'The engine is not connected.',
      );
    }
    return client.deletionInfo(workspace);
  }

  Future<bool> deleteWorkspace(
    WorkspaceInfo target, {
    bool moveSaves = false,
  }) async {
    final epoch = _epoch;
    final result = await _run(
      target.id,
      'Delete workspace',
      (client) async {
        await client.deleteWorkspace(
          target.id,
          target.revision,
          moveSaves: moveSaves,
        );
        return true;
      },
      (_) {
        recent = recent.where((item) => item.id != target.id).toList();
        if (page?.workspace.id == target.id) {
          page = null;
          showingWorkspace = false;
          ++_navigation;
        }
      },
    );
    if (result != true || epoch != _epoch || _disposed) return false;
    unawaited(loadRecent());
    return true;
  }

  String? deletionProblem(String workspace) =>
      _problemWorkspace == workspace ? problem : null;
}
