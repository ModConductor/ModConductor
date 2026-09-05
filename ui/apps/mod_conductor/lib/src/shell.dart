part of 'app.dart';

class _DesktopShell extends StatelessWidget {
  const _DesktopShell({
    required this.destination,
    required this.connectionStatus,
    required this.onNavigate,
    required this.onQuit,
    required this.welcomeFocus,
    required this.preferencesFocus,
    required this.quitFocus,
    required this.child,
  });
  final DesktopStatus connectionStatus;
  final _Destination destination;
  final ValueChanged<_Destination> onNavigate;
  final VoidCallback onQuit;
  final FocusNode welcomeFocus;
  final FocusNode preferencesFocus;
  final FocusNode quitFocus;
  final Widget child;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      Icons.layers_rounded,
                      size: 22,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Mod Conductor',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontSize: 17),
                    ),
                  ),
                  McAction(
                    key: const ValueKey('quit'),
                    label: 'Quit',
                    icon: Icons.close,
                    focusNode: quitFocus,
                    onPressed: onQuit,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  children: [
                    for (final item in _Destination.values)
                      Semantics(
                        selected: destination == item,
                        child: TextButton.icon(
                          key: ValueKey(
                            item == _Destination.welcome
                                ? 'nav-welcome'
                                : 'nav-preferences',
                          ),
                          autofocus: item == _Destination.welcome,
                          focusNode: item == _Destination.welcome
                              ? welcomeFocus
                              : preferencesFocus,
                          style: TextButton.styleFrom(
                            backgroundColor: destination == item
                                ? Theme.of(context).colorScheme.primary
                                      .withValues(alpha: .12)
                                : null,
                          ),
                          onPressed: () => onNavigate(item),
                          icon: Icon(
                            item == _Destination.welcome
                                ? Icons.home_outlined
                                : Icons.tune,
                            size: 18,
                          ),
                          label: Text(
                            item == _Destination.welcome
                                ? 'Welcome'
                                : 'Preferences',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(child: child),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: Text(switch (connectionStatus) {
            DesktopConnected() => 'Connected',
            DesktopConnecting() => 'Connecting',
            DesktopDisconnected() || DesktopFailure() => 'Not connected',
          }, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    ),
  );
}
