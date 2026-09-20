part of 'app.dart';

class _DesktopShell extends StatelessWidget {
  const _DesktopShell({
    required this.destination,
    required this.connectionStatus,
    required this.onNavigate,
    required this.onQuit,
    required this.workspacesFocus,
    required this.preferencesFocus,
    required this.quitFocus,
    required this.onToggleTheme,
    required this.labels,
    required this.child,
    this.requests,
    this.onRequests,
  });
  final DesktopStatus connectionStatus;
  final _Destination destination;
  final ValueChanged<_Destination> onNavigate;
  final VoidCallback onQuit;
  final FocusNode workspacesFocus;
  final FocusNode preferencesFocus;
  final FocusNode quitFocus;
  final VoidCallback onToggleTheme;
  final AppLocalizations labels;
  final Widget child;
  final DesktopRequests? requests;
  final VoidCallback? onRequests;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        Container(
          padding: const EdgeInsetsDirectional.fromSTEB(24, 12, 24, 8),
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
                      labels.appTitle,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontSize: 17),
                    ),
                  ),
                  McIconAction(
                    key: const ValueKey('quick-theme'),
                    label: labels.changeAppearance,
                    onPressed: onToggleTheme,
                    icon: const Icon(Icons.brightness_6_outlined),
                  ),
                  McAction(
                    key: const ValueKey('quit'),
                    label: labels.quit,
                    icon: Icons.close,
                    focusNode: quitFocus,
                    onPressed: onQuit,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Wrap(
                  spacing: 8,
                  children: [
                    for (final item in _Destination.values)
                      Semantics(
                        selected: destination == item,
                        child: TextButton.icon(
                          key: ValueKey(
                            item == _Destination.workspaces
                                ? 'nav-workspaces'
                                : 'nav-preferences',
                          ),
                          autofocus: item == _Destination.workspaces,
                          focusNode: item == _Destination.workspaces
                              ? workspacesFocus
                              : preferencesFocus,
                          style: TextButton.styleFrom(
                            backgroundColor: destination == item
                                ? Theme.of(context).colorScheme.primary
                                      .withValues(alpha: .12)
                                : null,
                          ),
                          onPressed: () => onNavigate(item),
                          icon: Icon(
                            item == _Destination.workspaces
                                ? Icons.home_outlined
                                : Icons.tune,
                            size: 18,
                          ),
                          label: Text(
                            item == _Destination.workspaces
                                ? labels.workspaces
                                : labels.preferences,
                          ),
                        ),
                      ),
                    if (requests case final requests?)
                      ListenableBuilder(
                        listenable: requests,
                        builder: (context, _) => TextButton.icon(
                          onPressed: onRequests,
                          icon: const Icon(
                            Icons.move_to_inbox_outlined,
                            size: 18,
                          ),
                          label: Text(labels.openRequests(requests.count)),
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
          child: Row(
            children: [
              Expanded(
                child: Text(switch (connectionStatus) {
                  DesktopConnected() => labels.connected,
                  DesktopConnecting() => labels.connecting,
                  DesktopDisconnected() ||
                  DesktopFailure() => labels.notConnected,
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
        ),
      ],
    ),
  );
}
