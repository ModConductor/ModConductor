part of 'app.dart';

class _PreferencesDisplayControls extends StatelessWidget {
  const _PreferencesDisplayControls({
    required this.labels,
    required this.scope,
    required this.onScope,
    required this.workspaceAvailable,
    required this.inheritsApplication,
    required this.onInheritsApplication,
    required this.draft,
    required this.loaded,
    required this.busy,
    required this.onDraft,
  });

  final AppLocalizations labels;
  final _PreferenceScope scope;
  final ValueChanged<_PreferenceScope> onScope;
  final bool workspaceAvailable;
  final bool inheritsApplication;
  final ValueChanged<bool> onInheritsApplication;
  final _Preferences draft;
  final bool loaded;
  final bool busy;
  final ValueChanged<_Preferences> onDraft;

  @override
  Widget build(BuildContext context) {
    final workspaceScope = scope == _PreferenceScope.workspace;
    final enabled = loaded && !busy && !(workspaceScope && inheritsApplication);
    return ConstrainedBox(
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
          if (!workspaceAvailable)
            Padding(
              padding: const EdgeInsets.only(top: McSpacing.small),
              child: Text(labels.workspaceSettingsUnavailable),
            ),
          if (loaded && workspaceScope) ...[
            const SizedBox(height: McSpacing.large),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(labels.useApplicationSettings),
              value: inheritsApplication,
              onChanged: busy ? null : onInheritsApplication,
            ),
          ],
          if (loaded) ...[
            const SizedBox(height: McSpacing.large),
            McChoice<AppearancePreference>(
              key: const ValueKey('preferences-theme'),
              label: labels.appearance,
              value: draft.appearance,
              choices: AppearancePreference.values,
              describe: (value) => _appearanceLabel(labels, value),
              enabled: enabled,
              onChanged: (value) => onDraft((
                appearance: value,
                textScale: draft.textScale,
                interfaceScale: draft.interfaceScale,
                contrast: draft.contrast,
              )),
            ),
            const SizedBox(height: McSpacing.large),
            McChoice<double>(
              key: const ValueKey('preferences-interface-scale'),
              label: labels.interfaceSize,
              value: draft.interfaceScale,
              choices: const [0.9, 1],
              describe: (value) =>
                  labels.textScalePercent((value * 100).round()),
              enabled: enabled,
              onChanged: (value) => onDraft((
                appearance: draft.appearance,
                textScale: draft.textScale,
                interfaceScale: value,
                contrast: draft.contrast,
              )),
            ),
            const SizedBox(height: McSpacing.large),
            McChoice<double>(
              key: const ValueKey('preferences-scale'),
              label: labels.textSize,
              value: draft.textScale,
              choices: const [1, 1.25, 1.5],
              describe: (value) =>
                  labels.textScalePercent((value * 100).round()),
              enabled: enabled,
              onChanged: (value) => onDraft((
                appearance: draft.appearance,
                textScale: value,
                interfaceScale: draft.interfaceScale,
                contrast: draft.contrast,
              )),
            ),
            const SizedBox(height: McSpacing.large),
            McChoice<ContrastPreference>(
              key: const ValueKey('preferences-contrast'),
              label: labels.contrast,
              value: draft.contrast,
              choices: ContrastPreference.values,
              describe: (value) => _contrastLabel(labels, value),
              enabled: enabled,
              onChanged: (value) => onDraft((
                appearance: draft.appearance,
                textScale: draft.textScale,
                interfaceScale: draft.interfaceScale,
                contrast: value,
              )),
            ),
          ],
        ],
      ),
    );
  }
}
