part of 'app.dart';

class _DesktopShell extends StatelessWidget {
  const _DesktopShell({
    super.key,
    required this.destination,
    required this.updateAvailable,
    required this.connectionStatus,
    required this.onNavigate,
    required this.onQuit,
    required this.workspacesFocus,
    required this.preferencesFocus,
    required this.gamesFocus,
    required this.quitFocus,
    required this.onToggleTheme,
    required this.labels,
    required this.child,
    this.requests,
    this.onRequests,
    this.workspace,
  });
  final DesktopStatus connectionStatus;
  final _Destination destination;
  final bool updateAvailable;
  final ValueChanged<_Destination> onNavigate;
  final VoidCallback onQuit;
  final FocusNode workspacesFocus;
  final FocusNode preferencesFocus;
  final FocusNode gamesFocus;
  final FocusNode quitFocus;
  final VoidCallback? onToggleTheme;
  final AppLocalizations labels;
  final Widget child;
  final DesktopRequests? requests;
  final VoidCallback? onRequests;
  final WorkspaceChrome? workspace;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        McAppHeader(
          appName: labels.appTitle,
          workspaceName: workspace?.name,
          workspacePath: workspace?.path,
          actions: [
            ...?workspace?.actions,
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
          navigation: _navigation(context),
          workspaceNavigation: workspace?.navigation,
        ),
        Expanded(child: child),
        _status(context),
      ],
    ),
  );
}
