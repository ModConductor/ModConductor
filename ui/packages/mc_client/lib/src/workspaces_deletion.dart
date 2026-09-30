part of 'workspaces_client.dart';

class WorkspaceDeletionInfo {
  const WorkspaceDeletionInfo({
    required this.hasPrivateSaves,
    this.saveDestinations = const [],
  });
  final bool hasPrivateSaves;
  final List<String> saveDestinations;
}

Future<WorkspaceDeletionInfo> _deletionInfo(
  wire.WorkspaceOperationsClient client,
  String workspace,
) async {
  final reply = await client.readWorkspaceDeletion(
    wire.ReadWorkspaceDeletionRequest(workspaceId: workspace),
  );
  return switch (reply.whichOutcome()) {
    wire.WorkspaceDeletionInfoReply_Outcome.info => WorkspaceDeletionInfo(
      hasPrivateSaves: reply.info.hasPrivateSaves,
      saveDestinations: List.unmodifiable(reply.info.saveDestinations),
    ),
    wire.WorkspaceDeletionInfoReply_Outcome.fault => _reject(reply.fault),
    wire.WorkspaceDeletionInfoReply_Outcome.notSet =>
      throw const FormatException('Missing workspace deletion information.'),
  };
}

Future<void> _deleteWorkspace(
  wire.WorkspaceOperationsClient client,
  String workspace,
  int revision,
  bool moveSaves,
) async {
  final reply = await client.deleteWorkspace(
    wire.DeleteWorkspaceRequest(
      workspaceId: workspace,
      expectedRevision: Int64(revision),
      moveSaves: moveSaves,
    ),
  );
  switch (reply.whichOutcome()) {
    case wire.WorkspaceDeletionReply_Outcome.deleted:
      if (!reply.deleted) {
        throw const FormatException('Workspace deletion did not complete.');
      }
    case wire.WorkspaceDeletionReply_Outcome.fault:
      _reject(reply.fault);
    case wire.WorkspaceDeletionReply_Outcome.notSet:
      throw const FormatException('Missing workspace deletion result.');
  }
}
