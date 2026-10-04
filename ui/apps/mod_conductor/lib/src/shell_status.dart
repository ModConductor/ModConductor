part of 'app.dart';

extension _DesktopConnectionStatus on _DesktopShell {
  Widget _status(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    decoration: BoxDecoration(
      border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(switch (connectionStatus) {
            DesktopConnected() => labels.connected,
            DesktopConnecting() => labels.connecting,
            DesktopDisconnected() || DesktopFailure() => labels.notConnected,
          }, style: Theme.of(context).textTheme.bodySmall),
        ),
        if (requests case final requests?)
          ListenableBuilder(
            listenable: requests,
            builder: (context, _) => requests.available
                ? const SizedBox.shrink()
                : TextButton(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => McDialog(
                        title: labels.cannotOpenFromOtherApps,
                        children: [Text(labels.openFromThisWindow)],
                      ),
                    ),
                    child: Text(labels.cannotOpenFromOtherApps),
                  ),
          ),
      ],
    ),
  );
}
