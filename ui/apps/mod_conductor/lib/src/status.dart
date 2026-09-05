part of 'app.dart';

sealed class DesktopStatus {
  const DesktopStatus();
}

final class DesktopDisconnected extends DesktopStatus {
  const DesktopDisconnected();
}

final class DesktopFailure extends DesktopStatus {
  const DesktopFailure(this.reason);
  final String reason;
}

class _FailurePage extends StatelessWidget {
  const _FailurePage({required this.reason, required this.onPreferences});
  final String reason;
  final VoidCallback onPreferences;
  @override
  Widget build(BuildContext context) => McPage(
    title: 'Workspace error',
    children: [
      McSection(
        title: 'Workspace',
        children: [
          McStatus(
            title: 'The app cannot open the workspace.',
            detail: reason,
            tone: McStatusTone.error,
          ),
          const SizedBox(height: McSpacing.large),
          McAction(label: 'Preferences', onPressed: onPreferences),
        ],
      ),
    ],
  );
}
