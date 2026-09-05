part of 'app.dart';

sealed class DesktopStatus {
  const DesktopStatus();
}

final class DesktopDisconnected extends DesktopStatus {
  const DesktopDisconnected();
}

final class DesktopConnecting extends DesktopStatus {
  const DesktopConnecting();
}

final class DesktopConnected extends DesktopStatus {
  const DesktopConnected(this.report);
  final ConnectionReport report;
}

final class DesktopFailure extends DesktopStatus {
  const DesktopFailure(this.reason);
  final String reason;
}

class _FailurePage extends StatelessWidget {
  const _FailurePage({
    required this.reason,
    required this.onPreferences,
    this.onRetry,
  });
  final String reason;
  final VoidCallback onPreferences;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => McPage(
    title: 'Connection error',
    children: [
      McSection(
        title: 'Connection',
        children: [
          McStatus(
            title: 'Connection failed',
            detail: reason,
            tone: McStatusTone.error,
          ),
          const SizedBox(height: McSpacing.large),
          Wrap(
            spacing: McSpacing.medium,
            runSpacing: McSpacing.small,
            children: [
              McAction(label: 'Retry', onPressed: onRetry),
              McAction(label: 'Preferences', onPressed: onPreferences),
            ],
          ),
        ],
      ),
    ],
  );
}
