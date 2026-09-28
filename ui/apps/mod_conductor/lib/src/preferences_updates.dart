part of 'app.dart';

class _UpdatePreferencesSection extends StatelessWidget {
  const _UpdatePreferencesSection({
    required this.controller,
    required this.checkOnStartup,
    required this.canChangeCheckOnStartup,
    required this.onCheckOnStartup,
    required this.onQuitAndUpdate,
  });

  final AppUpdatesController controller;
  final bool checkOnStartup;
  final bool canChangeCheckOnStartup;
  final ValueChanged<bool> onCheckOnStartup;
  final Future<void> Function(AppUpdateManager)? onQuitAndUpdate;

  @override
  Widget build(BuildContext context) {
    final installed = controller.installedVersion;
    final release = controller.release;
    final available = controller.updateAvailable;
    final manager = controller.manager;
    final error = controller.problem;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      sortKey: const OrdinalSortKey(0, name: 'preferences-sections'),
      child: McSection(
        title: 'App updates',
        children: [
          if (controller.windows)
            Wrap(
              spacing: 56,
              runSpacing: McSpacing.medium,
              children: [
                _UpdateVersion(
                  label: 'Installed version',
                  value: installed ?? 'Unknown',
                ),
                _UpdateVersion(
                  label: 'Available version',
                  value: controller.checking
                      ? 'Checking'
                      : release?.version ??
                            (controller.checked
                                ? 'Not published'
                                : 'Not checked'),
                ),
              ],
            )
          else
            _UpdateVersion(
              label: 'Installed version',
              value: installed ?? 'Unknown',
            ),
          const SizedBox(height: McSpacing.medium),
          if (!controller.windows)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (error != null) ...[
                  McActionFeedback(
                    kind: McActionFeedbackKind.failure,
                    message: error,
                  ),
                  const SizedBox(height: McSpacing.medium),
                ],
                const Text('Update Mod Conductor with your Nix configuration.'),
              ],
            )
          else ...[
            if (controller.checking)
              const McActionFeedback(
                kind: McActionFeedbackKind.pending,
                message: 'Checking for updates',
              )
            else if (error != null)
              McActionFeedback(
                kind: McActionFeedbackKind.failure,
                message: error,
              )
            else if (release != null && !available)
              McActionFeedback(
                kind: McActionFeedbackKind.success,
                message: release.compatible
                    ? 'Up to date'
                    : 'No compatible Windows release is available.',
              ),
            const SizedBox(height: McSpacing.medium),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (available)
                  McAction(
                    key: const ValueKey('app-update-action'),
                    label: manager == null
                        ? 'Open release page'
                        : 'Quit and update with ${manager.label}',
                    icon: manager == null
                        ? Icons.open_in_new
                        : Icons.power_settings_new,
                    emphasis: McActionEmphasis.primary,
                    onPressed: controller.checking
                        ? null
                        : manager == null
                        ? () => unawaited(controller.openReleasePage())
                        : onQuitAndUpdate == null
                        ? null
                        : () => unawaited(onQuitAndUpdate!(manager)),
                  ),
                McAction(
                  key: const ValueKey('check-app-updates'),
                  label: 'Check now',
                  icon: Icons.refresh,
                  onPressed: controller.checking || installed == null
                      ? null
                      : () => unawaited(controller.check()),
                ),
              ],
            ),
            const SizedBox(height: McSpacing.medium),
            const Divider(height: 1),
            Row(
              children: [
                const Expanded(child: Text('Check on startup')),
                Switch(
                  key: const ValueKey('check-updates-on-startup'),
                  value: checkOnStartup,
                  onChanged: canChangeCheckOnStartup ? onCheckOnStartup : null,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _UpdateVersion extends StatelessWidget {
  const _UpdateVersion({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 150,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    ),
  );
}
