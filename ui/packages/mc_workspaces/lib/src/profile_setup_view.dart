part of 'profile_setup.dart';

extension _ProfileSetupView on _ProfileSetupSurfaceState {
  Widget _profileSetupView(BuildContext context) => PopScope(
    canPop: widget.canCancel && !submitting,
    child: Form(
      key: form,
      child: McDialog(
        title: 'Set up profile',
        contentWidth: 640,
        actions: [
          if (widget.canCancel)
            McAction(
              key: const ValueKey('cancel-profile-setup'),
              label: 'Cancel',
              onPressed: busy ? null : widget.onCancel,
            ),
          McAction(
            key: const ValueKey('submit-profile-setup'),
            label: submitting ? '${widget.actionLabel}…' : widget.actionLabel,
            icon: Icons.arrow_forward,
            emphasis: McActionEmphasis.primary,
            onPressed: canSubmit ? submit : null,
          ),
        ],
        children: [
          TextFormField(
            key: const ValueKey('profile-setup-name'),
            controller: name,
            autofocus: widget.nameEditable,
            readOnly: !widget.nameEditable,
            enabled: !busy,
            decoration: const InputDecoration(labelText: 'Profile name'),
            validator: (value) =>
                value == null || value.trim().isEmpty ? 'Enter a name.' : null,
          ),
          const SizedBox(height: McSpacing.large),
          InstallationSetupFields(
            nativeClient: game?.nativeClient ?? false,
            gameName: game?.id ?? 'Select game',
            gameChoices: widget.games.map((option) => option.id).toList(),
            gameLabels: {
              for (final option in widget.games) option.id: option.name,
            },
            onGameChanged: (value) => selectGame(
              widget.games.firstWhere((option) => option.id == value),
            ),
            source: source,
            sourceChoices: game?.sources ?? const [],
            onSourceChanged: selectSource,
            folder: folder,
            wineExecutable: wineExecutable,
            winePrefix: winePrefix,
            chooseDirectory: widget.chooseDirectory,
            chooseExecutable: widget.chooseExecutable,
            onBrowse: chooseFolder,
            onProblem: (value) => _change(() => problem = value),
            onFindSteam: findInstallations,
            onSelectProton: widget.protonContexts == null ? null : selectProton,
            proton: proton,
            busy: busy,
            candidates: candidates
                .map((value) => value.directory.canonicalPath)
                .toList(),
            onCandidateChanged: (value) => folder.text = value,
          ),
          if (widget.onAddGame != null) ...[
            const SizedBox(height: McSpacing.medium),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: McAction(
                label: 'Add game',
                icon: Icons.add,
                onPressed: busy ? null : addGame,
              ),
            ),
          ],
          if (searching) ...[
            const SizedBox(height: McSpacing.medium),
            const McActionFeedback(
              kind: McActionFeedbackKind.pending,
              message: 'Finding installations',
            ),
          ],
          if (problem case final message?) ...[
            const SizedBox(height: McSpacing.medium),
            McActionFeedback(
              kind: McActionFeedbackKind.failure,
              message: message,
            ),
          ],
        ],
      ),
    ),
  );
}
