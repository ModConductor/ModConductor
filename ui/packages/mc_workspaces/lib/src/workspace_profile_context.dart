part of 'workspace_browser.dart';

extension _WorkspaceProfileContext on _WorkspaceBrowserState {
  Widget _withProfileContext(
    ProfileInfo profile,
    Widget Function(GameContextState?) builder,
  ) {
    final workspace = controller.workspace!.id;
    final current = widget.gameContext;
    final matching =
        current?.workspaceId == workspace && current?.profileId == profile.id
        ? current
        : null;
    final client = widget.gameContexts;
    final future = matching != null || client == null
        ? null
        : _contexts.putIfAbsent(
            profile.id,
            () => client
                .read(workspace, profile.id)
                .then<GameContextState?>((value) => value)
                .catchError((_) => null),
          );
    return FutureBuilder<GameContextState?>(
      key: ValueKey((workspace, profile.id)),
      future: future,
      builder: (context, snapshot) =>
          builder(matching ?? (client == null ? null : snapshot.data)),
    );
  }
}
