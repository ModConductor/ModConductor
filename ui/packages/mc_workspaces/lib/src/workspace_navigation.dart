part of 'workspace_browser.dart';

extension _WorkspaceNavigation on _WorkspaceBrowserState {
  Widget? _workspaceNavigation(_WorkspaceMode mode, bool ready) {
    if (widget.discoveryBuilder == null &&
        widget.modLibraryBuilder == null &&
        widget.gameContextBuilder == null &&
        widget.executableBuilder == null &&
        widget.artifactBuilder == null &&
        widget.helpBuilder == null) {
      return null;
    }
    return McNavigationStrip<_WorkspaceMode>(
      selected: mode,
      onSelected: (value) => _change(() => _mode = value),
      items: [
        const McNavigationItem(
          value: _WorkspaceMode.profiles,
          label: 'Profiles',
          icon: Icons.people_outline,
          key: ValueKey('workspace-profiles-tab'),
        ),
        if (widget.discoveryBuilder != null)
          const McNavigationItem(
            value: _WorkspaceMode.discover,
            label: 'Discover',
            icon: Icons.search,
            key: ValueKey('workspace-discover-tab'),
          ),
        if (ready && widget.modLibraryBuilder != null)
          const McNavigationItem(
            value: _WorkspaceMode.mods,
            label: 'Mods',
            icon: Icons.layers_outlined,
            key: ValueKey('workspace-mods-tab'),
          ),
        if (ready && widget.gameContextBuilder != null)
          const McNavigationItem(
            value: _WorkspaceMode.game,
            label: 'Game',
            icon: Icons.videogame_asset_outlined,
            key: ValueKey('workspace-game-tab'),
          ),
        if (ready && widget.executableBuilder != null)
          const McNavigationItem(
            value: _WorkspaceMode.tools,
            label: 'Tools',
            icon: Icons.terminal,
            key: ValueKey('workspace-tools-tab'),
          ),
        if (ready && widget.artifactBuilder != null)
          const McNavigationItem(
            value: _WorkspaceMode.archives,
            label: 'Archives',
            icon: Icons.inventory_2_outlined,
            key: ValueKey('workspace-archives-tab'),
          ),
        if (widget.helpBuilder != null)
          const McNavigationItem(
            value: _WorkspaceMode.help,
            label: 'Help',
            icon: Icons.help_center_outlined,
            key: ValueKey('workspace-help-tab'),
          ),
      ],
    );
  }
}
