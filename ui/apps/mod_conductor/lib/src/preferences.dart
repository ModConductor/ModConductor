part of 'app.dart';

class _PreferencesPage extends StatelessWidget {
  const _PreferencesPage({
    required this.credentials,
    required this.nexus,
    required this.applied,
    required this.draft,
    required this.onDraft,
    required this.onSave,
    required this.onCancel,
    required this.detailsFocus,
  });
  final CredentialsClient? credentials;
  final NexusClient? nexus;
  final _Preferences applied;
  final _Preferences draft;
  final ValueChanged<_Preferences> onDraft;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final FocusNode detailsFocus;
  @override
  Widget build(BuildContext context) => McPage(
    key: const PageStorageKey('preferences'),
    title: 'Preferences',
    children: [
      McSection(
        title: 'Display',
        children: [
          const McStatus(title: 'The app does not save preferences.'),
          const SizedBox(height: McSpacing.large),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                McChoice<ThemeMode>(
                  key: const ValueKey('preferences-theme'),
                  label: 'Appearance',
                  value: draft.theme,
                  choices: ThemeMode.values,
                  describe: _themeLabel,
                  onChanged: (value) =>
                      onDraft((theme: value, scale: draft.scale)),
                ),
                const SizedBox(height: McSpacing.large),
                McChoice<double>(
                  key: const ValueKey('preferences-scale'),
                  label: 'Text size',
                  value: draft.scale,
                  choices: const [1, 1.25, 1.5],
                  describe: (value) => '${(value * 100).round()}%',
                  onChanged: (value) =>
                      onDraft((theme: draft.theme, scale: value)),
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
                label: 'Apply',
                emphasis: McActionEmphasis.primary,
                icon: Icons.check,
                onPressed: draft == applied ? null : onSave,
              ),
              McAction(
                key: const ValueKey('cancel-preferences'),
                label: 'Cancel',
                onPressed: draft == applied ? null : onCancel,
              ),
              McAction(
                key: const ValueKey('session-details'),
                label: 'Active preferences',
                focusNode: detailsFocus,
                onPressed: draft == applied
                    ? null
                    : () => _showActivePreferences(context, applied),
              ),
            ],
          ),
        ],
      ),
      const SizedBox(height: McSpacing.medium),
      CredentialPreferences(client: credentials, nexus: nexus),
    ],
  );
}

Future<void> _showActivePreferences(
  BuildContext context,
  _Preferences applied,
) async {
  final previous = FocusManager.instance.primaryFocus;
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Active preferences'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Appearance', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: McSpacing.small),
              Text(_themeLabel(applied.theme)),
              const SizedBox(height: McSpacing.large),
              Text('Text size', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: McSpacing.small),
              Text('${(applied.scale * 100).round()}%'),
            ],
          ),
        ),
      ),
      actions: [
        McAction(label: 'Close', onPressed: () => Navigator.pop(context)),
      ],
    ),
  );
  if (previous?.context != null) previous!.requestFocus();
}
