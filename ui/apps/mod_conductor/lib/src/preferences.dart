part of 'app.dart';

class _PreferencesPage extends StatelessWidget {
  const _PreferencesPage({
    required this.labels,
    required this.credentials,
    required this.nexus,
    required this.linkSetup,
    required this.scope,
    required this.onScope,
    required this.workspaceAvailable,
    required this.inheritsApplication,
    required this.inheritsApplicationApplied,
    required this.onInheritsApplication,
    required this.applied,
    required this.draft,
    required this.busy,
    required this.problem,
    required this.savedAt,
    required this.onDraft,
    required this.onSave,
    required this.onCancel,
    required this.detailsFocus,
  });
  final AppLocalizations labels;
  final CredentialsClient? credentials;
  final NexusClient? nexus;
  final LinkSetupClient? linkSetup;
  final _PreferenceScope scope;
  final ValueChanged<_PreferenceScope> onScope;
  final bool workspaceAvailable;
  final bool inheritsApplication;
  final bool inheritsApplicationApplied;
  final ValueChanged<bool> onInheritsApplication;
  final _Preferences applied;
  final _Preferences draft;
  final bool busy;
  final String? problem;
  final DateTime? savedAt;
  final ValueChanged<_Preferences> onDraft;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final FocusNode detailsFocus;

  String _appearance(AppearancePreference value) => switch (value) {
    AppearancePreference.system => labels.systemAppearance,
    AppearancePreference.light => labels.light,
    AppearancePreference.dark => labels.dark,
  };

  String _contrast(ContrastPreference value) => switch (value) {
    ContrastPreference.system => labels.systemContrast,
    ContrastPreference.standard => labels.standardContrast,
    ContrastPreference.high => labels.highContrast,
  };

  @override
  Widget build(BuildContext context) {
    final workspaceScope = scope == _PreferenceScope.workspace;
    final changed =
        draft != applied ||
        (workspaceScope && inheritsApplication != inheritsApplicationApplied);
    final enabled = !busy && !(workspaceScope && inheritsApplication);
    return McPage(
      key: const PageStorageKey('preferences'),
      title: labels.preferences,
      children: [
        McSection(
          title: labels.display,
          children: [
            if (problem != null)
              McStatus(
                title: problem == 'load'
                    ? labels.settingsLoadFailed
                    : labels.settingsSaveFailed,
                tone: McStatusTone.error,
              )
            else if (savedAt case final saved?)
              McStatus(title: labels.preferencesSaved(saved)),
            if (problem != null || savedAt != null)
              const SizedBox(height: McSpacing.large),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  McChoice<_PreferenceScope>(
                    key: const ValueKey('preferences-scope'),
                    label: labels.scope,
                    value: scope,
                    choices: workspaceAvailable
                        ? _PreferenceScope.values
                        : const [_PreferenceScope.application],
                    describe: (value) => value == _PreferenceScope.application
                        ? labels.application
                        : labels.currentWorkspace,
                    onChanged: onScope,
                  ),
                  if (workspaceScope) ...[
                    const SizedBox(height: McSpacing.large),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(labels.useApplicationSettings),
                      value: inheritsApplication,
                      onChanged: busy ? null : onInheritsApplication,
                    ),
                  ],
                  const SizedBox(height: McSpacing.large),
                  McChoice<AppearancePreference>(
                    key: const ValueKey('preferences-theme'),
                    label: labels.appearance,
                    value: draft.appearance,
                    choices: AppearancePreference.values,
                    describe: _appearance,
                    enabled: enabled,
                    onChanged: (value) => onDraft((
                      appearance: value,
                      scale: draft.scale,
                      contrast: draft.contrast,
                    )),
                  ),
                  const SizedBox(height: McSpacing.large),
                  McChoice<double>(
                    key: const ValueKey('preferences-scale'),
                    label: labels.textSize,
                    value: draft.scale,
                    choices: const [1, 1.25, 1.5],
                    describe: (value) =>
                        labels.textScalePercent((value * 100).round()),
                    enabled: enabled,
                    onChanged: (value) => onDraft((
                      appearance: draft.appearance,
                      scale: value,
                      contrast: draft.contrast,
                    )),
                  ),
                  const SizedBox(height: McSpacing.large),
                  McChoice<ContrastPreference>(
                    key: const ValueKey('preferences-contrast'),
                    label: labels.contrast,
                    value: draft.contrast,
                    choices: ContrastPreference.values,
                    describe: _contrast,
                    enabled: enabled,
                    onChanged: (value) => onDraft((
                      appearance: draft.appearance,
                      scale: draft.scale,
                      contrast: value,
                    )),
                  ),
                ],
              ),
            ),
            const SizedBox(height: McSpacing.large),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                McAction(
                  key: const ValueKey('apply-preferences'),
                  label: labels.apply,
                  emphasis: McActionEmphasis.primary,
                  icon: Icons.check,
                  onPressed: changed && !busy ? onSave : null,
                ),
                McAction(
                  key: const ValueKey('cancel-preferences'),
                  label: labels.cancel,
                  onPressed: changed && !busy ? onCancel : null,
                ),
                McAction(
                  key: const ValueKey('session-details'),
                  label: labels.activePreferences,
                  focusNode: detailsFocus,
                  onPressed: () => _showActivePreferences(
                    context,
                    labels,
                    applied,
                    _appearance,
                    _contrast,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: McSpacing.medium),
        CredentialPreferences(client: credentials, nexus: nexus),
        const SizedBox(height: McSpacing.medium),
        NexusLinkPreferences(client: linkSetup),
      ],
    );
  }
}

Future<void> _showActivePreferences(
  BuildContext context,
  AppLocalizations labels,
  _Preferences applied,
  String Function(AppearancePreference) appearance,
  String Function(ContrastPreference) contrast,
) async {
  final previous = FocusManager.instance.primaryFocus;
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(labels.activePreferences),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                labels.appearance,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: McSpacing.small),
              Text(appearance(applied.appearance)),
              const SizedBox(height: McSpacing.large),
              Text(
                labels.textSize,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: McSpacing.small),
              Text(labels.textScalePercent((applied.scale * 100).round())),
              const SizedBox(height: McSpacing.large),
              Text(
                labels.contrast,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: McSpacing.small),
              Text(contrast(applied.contrast)),
            ],
          ),
        ),
      ),
      actions: [
        McAction(label: labels.close, onPressed: () => Navigator.pop(context)),
      ],
    ),
  );
  if (previous?.context != null) previous!.requestFocus();
}
