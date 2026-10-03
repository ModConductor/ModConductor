part of 'workspace_browser.dart';

extension _WorkspaceWorkbench on _WorkspaceBrowserState {
  List<Widget> _workspaceBody(
    BuildContext context,
    WorkspaceInfo workspace,
    ProfileInfo? current,
    bool ready,
    _WorkspaceMode mode,
  ) => [
    if (widget.discoveryBuilder != null ||
        widget.modLibraryBuilder != null ||
        widget.gameContextBuilder != null ||
        widget.executableBuilder != null ||
        widget.artifactBuilder != null ||
        widget.helpBuilder != null) ...[
      Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: [
          SizedBox(
            width: MediaQuery.sizeOf(context).width < 1050
                ? MediaQuery.sizeOf(context).width - 40
                : 650,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<_WorkspaceMode>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: _WorkspaceMode.profiles,
                    label: Text(
                      'Profiles',
                      key: ValueKey('workspace-profiles-tab'),
                    ),
                    icon: Icon(Icons.people_outline),
                  ),
                  if (widget.discoveryBuilder != null)
                    const ButtonSegment(
                      value: _WorkspaceMode.discover,
                      label: Text(
                        'Discover',
                        key: ValueKey('workspace-discover-tab'),
                      ),
                      icon: Icon(Icons.search),
                    ),
                  if (ready && widget.modLibraryBuilder != null)
                    ButtonSegment(
                      value: _WorkspaceMode.mods,
                      label: Text('Mods', key: ValueKey('workspace-mods-tab')),
                      icon: Icon(Icons.layers_outlined),
                    ),
                  if (ready && widget.gameContextBuilder != null)
                    ButtonSegment(
                      value: _WorkspaceMode.game,
                      label: Text('Game', key: ValueKey('workspace-game-tab')),
                      icon: Icon(Icons.videogame_asset_outlined),
                    ),
                  if (ready && widget.executableBuilder != null)
                    ButtonSegment(
                      value: _WorkspaceMode.tools,
                      label: Text(
                        'Tools',
                        key: ValueKey('workspace-tools-tab'),
                      ),
                      icon: Icon(Icons.terminal),
                    ),
                  if (ready && widget.artifactBuilder != null)
                    ButtonSegment(
                      value: _WorkspaceMode.archives,
                      label: Text(
                        'Archives',
                        key: ValueKey('workspace-archives-tab'),
                      ),
                      icon: Icon(Icons.inventory_2_outlined),
                    ),
                  if (widget.helpBuilder != null)
                    ButtonSegment(
                      value: _WorkspaceMode.help,
                      label: Text('Help', key: ValueKey('workspace-help-tab')),
                      icon: Icon(Icons.help_center_outlined),
                    ),
                ],
                selected: {mode},
                onSelectionChanged: (value) =>
                    _change(() => _mode = value.single),
              ),
            ),
          ),
          if (mode == _WorkspaceMode.mods &&
              MediaQuery.sizeOf(context).width >= 1050)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children:
                  widget.workbenchActions?.call(context, workspace) ?? const [],
            ),
        ],
      ),
      const SizedBox(height: 16),
    ],
    Expanded(
      child: IndexedStack(
        index: mode.index,
        children: [
          ExcludeFocus(
            excluding: mode != _WorkspaceMode.profiles,
            child: !ready && widget.profileSetupBuilder != null
                ? widget.profileSetupBuilder!(context, workspace, current!)
                : _profilesSurface(context),
          ),
          if (widget.discoveryBuilder != null)
            ExcludeFocus(
              excluding: mode != _WorkspaceMode.discover,
              child: widget.discoveryBuilder!(
                context,
                workspace,
                mode == _WorkspaceMode.discover,
              ),
            )
          else
            const SizedBox.shrink(),
          if (ready && widget.modLibraryBuilder != null)
            ExcludeFocus(
              excluding: mode != _WorkspaceMode.mods,
              child: widget.modLibraryBuilder!(
                context,
                workspace,
                mode == _WorkspaceMode.mods,
              ),
            )
          else
            const SizedBox.shrink(),
          if (ready && widget.gameContextBuilder != null)
            ExcludeFocus(
              excluding: mode != _WorkspaceMode.game,
              child: widget.gameContextBuilder!(context, workspace),
            )
          else
            const SizedBox.shrink(),
          if (ready && widget.executableBuilder != null)
            ExcludeFocus(
              excluding: mode != _WorkspaceMode.tools,
              child: widget.executableBuilder!(context, workspace),
            )
          else
            const SizedBox.shrink(),
          if (ready && widget.artifactBuilder != null)
            ExcludeFocus(
              excluding: mode != _WorkspaceMode.archives,
              child: widget.artifactBuilder!(
                context,
                workspace,
                () => _change(() => _mode = _WorkspaceMode.mods),
              ),
            )
          else
            const SizedBox.shrink(),
          if (widget.helpBuilder != null)
            ExcludeFocus(
              excluding: mode != _WorkspaceMode.help,
              child: _help(context, workspace),
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    ),
  ];
}
