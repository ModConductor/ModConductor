part of 'app.dart';

extension _DesktopFrame on _ModConductorAppState {
  Widget _buildDesktopFrame(
    BuildContext context,
    WorkspaceChrome? chrome,
    Widget workspaceBody,
  ) => _DesktopShell(
    key: _requestShellKey,
    requests: widget.desktopRequests,
    onRequests: () => unawaited(_presentRequests(context)),
    connectionStatus: widget.status,
    destination: _destination,
    updateAvailable: widget.updates?.updateAvailable ?? false,
    onNavigate: _navigate,
    onQuit: _quitDesktop,
    workspacesFocus: _workspacesFocus,
    preferencesFocus: _preferencesFocus,
    gamesFocus: _gamesFocus,
    quitFocus: _quitFocus,
    labels: AppLocalizations.of(context),
    onToggleTheme: !_applicationSettings.loaded
        ? null
        : () => unawaited(
            _quickTheme(
              Theme.of(context).brightness == Brightness.dark
                  ? AppearancePreference.light
                  : AppearancePreference.dark,
            ),
          ),
    workspace:
        _destination == _Destination.workspaces &&
            widget.status is! DesktopFailure
        ? chrome
        : null,
    child: IndexedStack(
      index: _destination.index,
      children: [
        ExcludeFocus(
          excluding: _destination != _Destination.workspaces,
          child: switch (widget.status) {
            DesktopFailure(:final reason) => _FailurePage(
              labels: AppLocalizations.of(context),
              reason: reason,
              onRetry: widget.onRetry,
              onPreferences: () => _navigate(_Destination.preferences),
            ),
            DesktopDisconnected() ||
            DesktopConnecting() ||
            DesktopConnected() => workspaceBody,
          },
        ),
        ExcludeFocus(
          excluding: _destination != _Destination.games,
          child: GamesPage(
            catalogue: _gameCatalogue,
            client: widget.gameCatalogue is GameRegistrationClient
                ? widget.gameCatalogue as GameRegistrationClient
                : null,
            chooseDirectory: widget.chooseGameDirectory,
          ),
        ),
        ExcludeFocus(
          excluding: _destination != _Destination.preferences,
          child: _buildPreferencesPage(context),
        ),
      ],
    ),
  );
}
