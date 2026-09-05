part of 'app.dart';

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({
    required this.theme,
    required this.onTheme,
    required this.onPreferences,
  });
  final ThemeMode theme;
  final ValueChanged<ThemeMode> onTheme;
  final VoidCallback onPreferences;
  @override
  Widget build(BuildContext context) => McPage(
    key: const PageStorageKey('welcome'),
    title: 'Welcome',
    children: [
      McSection(
        title: 'Workspace',
        children: [
          const McStatus(title: 'This version cannot open a workspace.'),
          const SizedBox(height: McSpacing.large),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              McAction(
                key: const ValueKey('open-preferences'),
                label: 'Preferences',
                icon: Icons.tune,
                emphasis: McActionEmphasis.primary,
                onPressed: onPreferences,
              ),
            ],
          ),
        ],
      ),
      const SizedBox(height: McSpacing.medium),
      McSection(
        title: 'Appearance',
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: McChoice<ThemeMode>(
              key: const ValueKey('welcome-theme'),
              label: 'Appearance',
              value: theme,
              choices: ThemeMode.values,
              describe: _themeLabel,
              onChanged: onTheme,
            ),
          ),
          const SizedBox(height: McSpacing.medium),
          const McStatus(title: 'The app does not save preferences.'),
        ],
      ),
    ],
  );
}
