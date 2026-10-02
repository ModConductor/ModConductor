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

mixin _ProfileCreation on _AppStateBase, _ProfileCommit {
  Future<RegisteredGame?> _addGame() async {
    final client = widget.gameCatalogue;
    if (client is! GameRegistrationClient) return null;
    return showGameEditor(
      context,
      client as GameRegistrationClient,
      _gameCatalogue,
      widget.chooseGameDirectory,
    );
  }

  List<ProfileSetupGame> get _profileSetupGames =>
      ProfileSetupGame.fromCatalogue(_gameCatalogue.games);

  Widget _gameListWaiting() => McDialog(
    title: 'Set up profile',
    contentWidth: 640,
    actions: [
      if (!_gameCatalogue.loading)
        McAction(label: 'Try again', onPressed: _gameCatalogue.load),
    ],
    children: [
      McActionFeedback(
        kind: _gameCatalogue.loading
            ? McActionFeedbackKind.pending
            : McActionFeedbackKind.failure,
        message:
            _gameCatalogue.problem ??
            (_gameCatalogue.loading
                ? 'Loading games'
                : 'The game list is not available.'),
      ),
    ],
  );

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
        selection.gameId,
        state.revision,
        selection.installation,
        proton: selection.proton,
        wine: selection.wine,
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
    if (_profileSetupGames.isEmpty) return _gameListWaiting();
    return ProfileSetupSurface(
      key: ValueKey(('profile-setup', profile.id)),
      initialName: profile.name,
      initialGameId: state.definition?.id,
      nameEditable: false,
      games: _profileSetupGames,
      onAddGame: _addGame,
      discovery: widget.steamDiscovery,
      chooseDirectory: widget.chooseGameDirectory,
      protonContexts: widget.protonContexts,
      initialInstallation: binding?.path,
      initialProton: binding?.proton,
      initialSource: state.definition == null
          ? GameInstallationSource.steam
          : GameInstallationSource.fromDefinition(state.definition!),
      initialWine: binding?.wine,
      chooseExecutable: widget.chooseExecutable,
      initialProblem: _game.problem ?? binding?.failure,
      actionLabel: 'Save profile',
      onSubmit: (selection) => _saveProfileSetup(workspace, profile, selection),
    );
  }

  Future<void> _createProfile(
    BuildContext context,
    WorkspaceInfo workspace, {
    ProfileTransportPreview? portable,
  }) async {
    final attempt = _ProfileCreationAttempt();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => ListenableBuilder(
        listenable: _gameCatalogue,
        builder: (_, _) {
          final declaration = portable?.registrationGame;
          final games = ProfileSetupGame.fromCatalogue(
            _gameCatalogue.games,
            pending: declaration,
          );
          return games.isEmpty
              ? _gameListWaiting()
              : ProfileSetupSurface(
                  initialName: '',
                  initialGameId: portable?.game,
                  initialSource: declaration == null
                      ? GameInstallationSource.steam
                      : GameInstallationSource.fromDefinition(declaration),
                  games: games,
                  onAddGame: _addGame,
                  discovery: widget.steamDiscovery,
                  chooseDirectory: widget.chooseGameDirectory,
                  chooseExecutable: widget.chooseExecutable,
                  protonContexts: widget.protonContexts,
                  actionLabel: 'Create profile',
                  canCancel: true,
                  onCancel: () => Navigator.pop(dialogContext),
                  onComplete: () => Navigator.pop(dialogContext),
                  onSubmit: (selection) => _submitProfileCreation(
                    workspace,
                    attempt,
                    selection,
                    portable?.gameDefinition,
                  ),
                );
        },
      ),
    );
  }

  Future<String?> _submitProfileCreation(
    WorkspaceInfo workspace,
    _ProfileCreationAttempt attempt,
    ProfileSetupSelection selection, [
    CustomGameDraft? portable,
  ]) async {
    if (_workspaces.workspace?.id != workspace.id) {
      return 'The workspace changed. Start profile setup again.';
    }
    final client = widget.gameContexts;
    if (client == null) {
      return 'The profile setup is not available.';
    }
    if (portable != null && selection.gameId == portable.id) {
      final failure = await _gameCatalogue.registerPortable(
        widget.gameCatalogue,
        portable,
      );
      if (failure != null) return failure;
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
}
