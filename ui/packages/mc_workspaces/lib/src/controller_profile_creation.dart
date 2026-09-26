part of 'controller.dart';

Future<ProfileChange> _createProfileWithRecovery(
  WorkspacesClient client,
  WorkspaceInfo current,
  ProfileInfo profile,
) async {
  try {
    return await client.createProfile(current.id, current.revision, profile);
  } on WorkspaceException {
    rethrow;
  } on Exception {
    var refreshed = await client.read(current.id);
    while (true) {
      final committed = refreshed.profiles
          .where((candidate) => candidate.id == profile.id)
          .firstOrNull;
      if (committed != null) {
        return ProfileChange(refreshed.workspace, committed, null);
      }
      final next = refreshed.nextProfile;
      if (next == null) break;
      refreshed = await client.read(current.id, after: next);
    }
    return client.createProfile(
      current.id,
      refreshed.workspace.revision,
      profile,
    );
  }
}
