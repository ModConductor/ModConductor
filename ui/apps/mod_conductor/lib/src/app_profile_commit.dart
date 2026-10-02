part of 'app.dart';

mixin _ProfileCommit on _AppStateBase {
  Future<GameContextState> _saveCreatedProfileContext(
    WorkspaceInfo workspace,
    ProfileInfo profile,
    GameContextsClient client,
    ProfileSetupSelection selection,
    _ProfileCreationAttempt attempt,
  ) async {
    var saved = attempt.committedContext;
    if (saved != null &&
        identical(attempt.committedClient, client) &&
        _sameProfileSetup(attempt.committedSelection, selection)) {
      return saved;
    }
    final loaded = await client.read(workspace.id, profile.id);
    if (_sameProfileSetup(attempt.attemptedSelection, selection) &&
        _profileSetupIsReady(loaded, selection)) {
      saved = loaded;
    } else {
      attempt.attemptedSelection = selection;
      attempt.committedContext = null;
      attempt.committedClient = null;
      attempt.committedSelection = null;
      saved = await client.save(
        workspace.id,
        profile.id,
        selection.gameId,
        loaded.revision,
        selection.installation,
        proton: selection.proton,
        wine: selection.wine,
      );
    }
    attempt.committedContext = saved;
    attempt.committedClient = client;
    attempt.committedSelection = selection;
    return saved;
  }

  Future<String?> _selectCreatedProfile(
    WorkspaceInfo workspace,
    ProfileInfo profile,
    _ProfileCreationAttempt attempt,
  ) async {
    if (attempt.selectionAttempted) {
      await _workspaces.refresh();
      if (_workspaces.currentProblem != null) {
        return _workspaces.currentProblem;
      }
    }
    if (_workspaces.workspace?.id != workspace.id) {
      return 'The workspace changed. Start profile setup again.';
    }
    if (_workspaces.workspace?.selectedProfile?.id != profile.id) {
      attempt.selectionAttempted = true;
      await _workspaces.select(profile);
    }
    if (_workspaces.workspace?.selectedProfile?.id != profile.id) {
      return _workspaces.currentProblem ??
          'The profile was created but did not open.';
    }
    attempt.selectionAttempted = false;
    return null;
  }

  bool _sameProfileSetup(
    ProfileSetupSelection? previous,
    ProfileSetupSelection current,
  ) =>
      previous?.gameId == current.gameId &&
      previous?.wine == current.wine &&
      previous?.installation == current.installation &&
      _sameProton(previous?.proton, current.proton);

  bool _sameProton(ProtonSelection? left, ProtonSelection? right) {
    if (left == null || right == null) return left == null && right == null;
    final association = switch ((left.association, right.association)) {
      (ManualProtonAssociation(), ManualProtonAssociation()) => true,
      (
        SteamProtonAssociation(
          steamRoot: final leftRoot,
          library: final leftLibrary,
        ),
        SteamProtonAssociation(
          steamRoot: final rightRoot,
          library: final rightLibrary,
        ),
      ) =>
        leftRoot == rightRoot && leftLibrary == rightLibrary,
      _ => false,
    };
    return association &&
        left.appId == right.appId &&
        left.compatData == right.compatData &&
        left.runtimeDirectory == right.runtimeDirectory &&
        left.toolId == right.toolId;
  }

  bool _profileSetupIsReady(
    GameContextState state,
    ProfileSetupSelection selection,
  ) {
    final binding = state.binding;
    return state.definition?.id == selection.gameId &&
        binding != null &&
        binding.path == selection.installation &&
        binding.wine == selection.wine &&
        _sameProton(binding.proton, selection.proton) &&
        !binding.needsCheck &&
        binding.failure == null &&
        binding.evidence.problems.isEmpty;
  }
}
