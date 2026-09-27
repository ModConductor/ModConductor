part of 'profile_setup.dart';

extension _ProfileSetupView on _ProfileSetupSurfaceState {
  Widget gameChoice(BuildContext context, ProfileSetupGame option) =>
      _ProfileSetupChoiceTile<ProfileSetupGame>(
        radioKey: ValueKey(('profile-game', option.id)),
        value: option,
        selected: game == option,
        enabled: !busy,
        title: Text(option.name),
        subtitle: Text(option.storefront),
        selectedFillOpacity: .08,
        secondary: game == option
            ? Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
              )
            : null,
      );

  Widget _profileSetupView(BuildContext context) => PopScope(
    canPop: widget.canCancel && !submitting,
    child: Form(
      key: form,
      child: LayoutBuilder(
        builder: (context, constraints) =>
            _setupLayout(context, constraints.maxWidth < 600),
      ),
    ),
  );

  Widget _setupLayout(BuildContext context, bool narrow) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 680),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(13),
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(
                  narrow ? McSpacing.large : McSpacing.page,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _setupFields(context, narrow),
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: EdgeInsets.all(
                narrow ? McSpacing.large : McSpacing.page,
              ),
              child: searched ? _submitActions(narrow) : _searchActions(narrow),
            ),
          ],
        ),
      ),
    ),
  );

  List<Widget> _setupFields(BuildContext context, bool narrow) => [
    _heading(context),
    const SizedBox(height: McSpacing.large),
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
    Text('Game', style: Theme.of(context).textTheme.titleMedium),
    const SizedBox(height: McSpacing.small),
    RadioGroup<ProfileSetupGame>(
      groupValue: game,
      onChanged: selectGame,
      child: Column(
        children: [
          for (final option in widget.games) gameChoice(context, option),
        ],
      ),
    ),
    if (searched) ...[
      const SizedBox(height: McSpacing.large),
      const Divider(height: 1),
      const SizedBox(height: McSpacing.large),
      installationSection(context),
      if (Platform.isLinux && selectedInstallation != null) ...[
        const SizedBox(height: McSpacing.large),
        ProtonSelectionField(
          selection: proton,
          onSelect: busy || widget.protonContexts == null ? null : selectProton,
        ),
      ],
    ],
    if (problem case final message?) ...[
      const SizedBox(height: McSpacing.medium),
      McActionFeedback(kind: McActionFeedbackKind.failure, message: message),
      if (!searching && selectedInstallation == null)
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: McAction(
            label: 'Try search again',
            icon: Icons.refresh,
            onPressed: busy ? null : findInstallations,
          ),
        ),
    ],
  ];

  Widget _heading(BuildContext context) => Row(
    children: [
      Icon(
        Icons.person_add_alt_1_outlined,
        color: Theme.of(context).colorScheme.primary,
        size: 30,
      ),
      const SizedBox(width: McSpacing.medium),
      Expanded(
        child: Text(
          'Set up profile',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    ],
  );

  McAction _cancelAction() => McAction(
    key: const ValueKey('cancel-profile-setup'),
    label: 'Cancel',
    onPressed: busy ? null : widget.onCancel,
  );

  McAction _findAction() => McAction(
    key: const ValueKey('find-profile-installation'),
    label: 'Find installation',
    icon: Icons.search,
    emphasis: McActionEmphasis.primary,
    onPressed: busy || game == null ? null : findInstallations,
  );

  McAction _submitAction() => McAction(
    key: const ValueKey('submit-profile-setup'),
    label: submitting ? '${widget.actionLabel}…' : widget.actionLabel,
    icon: Icons.arrow_forward,
    emphasis: McActionEmphasis.primary,
    onPressed: canSubmit ? submit : null,
  );

  Widget _searchActions(bool narrow) => narrow
      ? Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.canCancel) _cancelAction(),
            const SizedBox(height: McSpacing.small),
            _findAction(),
          ],
        )
      : Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (widget.canCancel) ...[
              _cancelAction(),
              const SizedBox(width: McSpacing.small),
            ],
            _findAction(),
          ],
        );

  Widget _submitActions(bool narrow) {
    final controls = <Widget>[
      if (widget.canCancel) _cancelAction(),
      _submitAction(),
    ];
    return narrow
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final control in controls)
                Padding(
                  padding: const EdgeInsets.only(top: McSpacing.small),
                  child: control,
                ),
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              for (final control in controls)
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: McSpacing.small,
                  ),
                  child: control,
                ),
            ],
          );
  }
}
