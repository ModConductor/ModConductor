part of 'app.dart';

class _PreferencesActions extends StatelessWidget {
  const _PreferencesActions({
    required this.labels,
    required this.scope,
    required this.inheritsApplication,
    required this.inheritsApplicationApplied,
    required this.applied,
    required this.draft,
    required this.loaded,
    required this.busy,
    required this.problem,
    required this.onSave,
    required this.onCancel,
    required this.onRetry,
    required this.detailsFocus,
  });

  final AppLocalizations labels;
  final _PreferenceScope scope;
  final bool inheritsApplication;
  final bool inheritsApplicationApplied;
  final _Preferences applied;
  final _Preferences draft;
  final bool loaded;
  final bool busy;
  final String? problem;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final VoidCallback onRetry;
  final FocusNode detailsFocus;

  @override
  Widget build(BuildContext context) {
    final changed =
        draft != applied ||
        (scope == _PreferenceScope.workspace &&
            inheritsApplication != inheritsApplicationApplied);
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        if (problem == 'load')
          McAction(
            key: const ValueKey('retry-preferences'),
            label: labels.retry,
            icon: Icons.refresh,
            onPressed: onRetry,
          ),
        McAction(
          key: const ValueKey('apply-preferences'),
          label: labels.apply,
          emphasis: McActionEmphasis.primary,
          icon: Icons.check,
          onPressed: loaded && changed && !busy ? onSave : null,
        ),
        McAction(
          key: const ValueKey('cancel-preferences'),
          label: labels.cancel,
          onPressed: loaded && changed && !busy ? onCancel : null,
        ),
        McAction(
          key: const ValueKey('session-details'),
          label: labels.activePreferences,
          focusNode: detailsFocus,
          onPressed: !loaded
              ? null
              : () => _showActivePreferences(
                  context,
                  labels,
                  applied,
                  (value) => _appearanceLabel(labels, value),
                  (value) => _contrastLabel(labels, value),
                ),
        ),
      ],
    );
  }
}
