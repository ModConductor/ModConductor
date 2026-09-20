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
    required this.labels,
    required this.reason,
    required this.onPreferences,
    this.onRetry,
  });
  final AppLocalizations labels;
  final String reason;
  final VoidCallback onPreferences;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => McPage(
    title: labels.connectionError,
    children: [
      McSection(
        title: labels.connection,
        children: [
          McStatus(
            title: labels.connectionFailed,
            detail: reason,
            tone: McStatusTone.error,
          ),
          const SizedBox(height: McSpacing.large),
          Wrap(
            spacing: McSpacing.medium,
            runSpacing: McSpacing.small,
            children: [
              McAction(label: labels.retry, onPressed: onRetry),
              McAction(label: labels.preferences, onPressed: onPreferences),
            ],
          ),
        ],
      ),
    ],
  );
}
