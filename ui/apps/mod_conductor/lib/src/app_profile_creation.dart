part of 'app.dart';

class _ProfileCreationAttempt {
  final profileId = newOperationId();
  ProfileInfo? created;
  GameContextState? committedContext;
  GameContextsClient? committedClient;
  ProfileSetupSelection? committedSelection;
  ProfileSetupSelection? attemptedSelection;
  bool selectionAttempted = false;
}

const _profileSetupGames = [
  ProfileSetupGame(
    id: 'skyrim-se-steam',
    name: 'Skyrim Special Edition',
    storefront: 'Steam',
  ),
];

mixin _ProfileCreation on _AppStateBase {
  String _profileSetupFailure(Object failure) {
    if (failure case GameContextException(:final detail, :final candidate)) {
      final problems = candidate?.problems.map((item) => item.detail).toList();
      return problems == null || problems.isEmpty
          ? detail
          : problems.join('\n');
    }
    if (failure case WorkspaceException(:final detail)) return detail;
    return 'Profile setup did not return a result. Try again.';
  }

  Future<String?> _saveProfileSetup(
    WorkspaceInfo workspace,
    ProfileInfo profile,
    ProfileSetupSelection selection,
  ) async {
    final client = widget.gameContexts;
    final state = _game.state;
    if (client == null ||
        state == null ||
        state.workspaceId != workspace.id ||
        state.profileId != profile.id) {
      return 'The profile setup is not ready. Try again.';
    }
    try {
      final saved = await client.save(
        workspace.id,
        profile.id,
        selection.game.id,
        state.revision,
        selection.installation,
      );
      _game.accept(saved, client);
      return null;
    } on Exception catch (failure) {
      return _profileSetupFailure(failure);
    }
  }

  Widget _profileSetupGate(
    BuildContext context,
    WorkspaceInfo workspace,
    ProfileInfo profile,
  ) {
    final state = _game.state;
    final binding = state?.binding;
    if (_game.loading && (state == null || binding?.needsCheck == true)) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: const McActionFeedback(
            kind: McActionFeedbackKind.pending,
            message: 'Checking profile setup',
          ),
        ),
      );
    }
    if (state == null) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              McActionFeedback(
                kind: McActionFeedbackKind.failure,
                message: _game.problem ?? 'The profile setup is not available.',
              ),
              const SizedBox(height: McSpacing.medium),
              McAction(
                label: 'Try again',
                icon: Icons.refresh,
                onPressed: _game.client == null
                    ? null
                    : () => unawaited(_game.load()),
              ),
            ],
          ),
        ),
      );
    }
    return ProfileSetupSurface(
      key: ValueKey(('profile-setup', profile.id)),
      initialName: profile.name,
      nameEditable: false,
      games: _profileSetupGames,
      discovery: widget.steamDiscovery,
      chooseDirectory: widget.chooseGameDirectory,
      initialInstallation: binding?.path,
      initialProblem: _game.problem ?? binding?.failure,
      actionLabel: 'Save profile',
      onSubmit: (selection) => _saveProfileSetup(workspace, profile, selection),
    );
  }

  Future<void> _createProfile(
    BuildContext context,
    WorkspaceInfo workspace,
  ) async {
    final attempt = _ProfileCreationAttempt();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760, maxHeight: 760),
          child: ProfileSetupSurface(
            initialName: '',
            games: _profileSetupGames,
            discovery: widget.steamDiscovery,
            chooseDirectory: widget.chooseGameDirectory,
            actionLabel: 'Create profile',
            canCancel: true,
            onCancel: () => Navigator.pop(dialogContext),
            onComplete: () => Navigator.pop(dialogContext),
            onSubmit: (selection) =>
                _submitProfileCreation(workspace, attempt, selection),
          ),
        ),
      ),
    );
  }

  Future<String?> _submitProfileCreation(
    WorkspaceInfo workspace,
    _ProfileCreationAttempt attempt,
    ProfileSetupSelection selection,
  ) async {
    if (_workspaces.workspace?.id != workspace.id) {
      return 'The workspace changed. Start profile setup again.';
    }
    final client = widget.gameContexts;
    if (client == null) {
      return 'The profile setup is not available.';
    }
    attempt.created ??= await _workspaces.createProfile(
      selection.name,
      profileId: attempt.profileId,
    );
    final profile = attempt.created;
    if (profile == null) {
      return _workspaces.currentProblem ?? 'The profile could not be created.';
    }
    try {
      final saved = await _saveCreatedProfileContext(
        workspace,
        profile,
        client,
        selection,
        attempt,
      );
      final problem = await _selectCreatedProfile(workspace, profile, attempt);
      if (problem != null) {
        return problem;
      }
      _game.accept(saved, client);
      return null;
    } on Exception catch (failure) {
      return _profileSetupFailure(failure);
    }
  }

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
        selection.game.id,
        loaded.revision,
        selection.installation,
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
      previous?.game.id == current.game.id &&
      previous?.installation == current.installation;

  bool _profileSetupIsReady(
    GameContextState state,
    ProfileSetupSelection selection,
  ) {
    final binding = state.binding;
    return state.definition?.id == selection.game.id &&
        binding != null &&
        !binding.needsCheck &&
        binding.failure == null &&
        binding.evidence.problems.isEmpty;
  }
}
