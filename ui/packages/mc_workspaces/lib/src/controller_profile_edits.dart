part of 'controller.dart';

extension _WorkspaceProfileEdits on WorkspaceController {
  Future<ProfileChange?> _edit(
    String label,
    Future<ProfileChange> Function(WorkspacesClient, WorkspaceInfo) action,
  ) async {
    final current = workspace;
    if (current == null || !canEdit) return null;
    return _run(
      current.id,
      label,
      (client) => action(client, current),
      (value) => _applyProfileChange(current, value),
    );
  }

  Future<void> _editObserved(
    String label,
    Future<_ProfileChangeOutcome> Function(WorkspacesClient, WorkspaceInfo)
    action,
  ) async {
    final current = workspace;
    if (current == null || !canEdit) return;
    await _run(current.id, label, (client) => action(client, current), (
      outcome,
    ) {
      switch (outcome) {
        case _ProfileChangeDone(:final change):
          _applyProfileChange(current, change);
        case _ProfileChangeProblem(:final detail):
          problem = detail;
          _problemWorkspace = current.id;
      }
    });
  }

  void _applyProfileChange(WorkspaceInfo current, ProfileChange value) {
    _remember(value.workspace);
    if (page?.workspace.id != current.id ||
        page!.workspace.revision > value.workspace.revision) {
      return;
    }
    final changed = value.changed;
    final profiles = page!.profiles
        .where(
          (profile) => profile.id != value.deleted && profile.id != changed?.id,
        )
        .toList();
    if (changed != null) profiles.add(changed);
    profiles.sort((a, b) => a.id.compareTo(b.id));
    page = WorkspacePage(value.workspace, profiles, page!.nextProfile);
  }
}
