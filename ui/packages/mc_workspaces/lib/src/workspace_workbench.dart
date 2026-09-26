part of 'workspace_browser.dart';

extension _WorkspaceWorkbench on _WorkspaceBrowserState {
  List<Widget> _workspaceBody(
    BuildContext context,
    WorkspaceInfo workspace,
    ProfileInfo? current,
    bool ready,
    _WorkspaceMode mode,
  ) => [
    if (!ready && widget.profileSetupBuilder != null)
      Expanded(child: widget.profileSetupBuilder!(context, workspace, current!))
    else ...[
      if (widget.modLibraryBuilder != null ||
          widget.gameContextBuilder != null ||
          widget.executableBuilder != null ||
          widget.artifactBuilder != null ||
          widget.helpBuilder != null) ...[
        Align(
          alignment: Alignment.centerLeft,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<_WorkspaceMode>(
              segments: [
                ButtonSegment(
                  value: _WorkspaceMode.profiles,
                  label: Text(
                    'Profiles',
                    key: ValueKey('workspace-profiles-tab'),
                  ),
                  icon: Icon(Icons.people_outline),
                ),
                if (widget.modLibraryBuilder != null)
                  ButtonSegment(
                    value: _WorkspaceMode.mods,
                    label: Text('Mods', key: ValueKey('workspace-mods-tab')),
                    icon: Icon(Icons.layers_outlined),
                  ),
                if (widget.gameContextBuilder != null)
                  ButtonSegment(
                    value: _WorkspaceMode.game,
                    label: Text('Game', key: ValueKey('workspace-game-tab')),
                    icon: Icon(Icons.videogame_asset_outlined),
                  ),
                if (widget.executableBuilder != null)
                  ButtonSegment(
                    value: _WorkspaceMode.tools,
                    label: Text('Tools', key: ValueKey('workspace-tools-tab')),
                    icon: Icon(Icons.terminal),
                  ),
                if (widget.artifactBuilder != null)
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
        const SizedBox(height: 16),
      ],
      Expanded(
        child: IndexedStack(
          index: mode.index,
          children: [
            ExcludeFocus(
              excluding: mode != _WorkspaceMode.profiles,
              child: _profilesSurface(context),
            ),
            if (widget.modLibraryBuilder != null)
              ExcludeFocus(
                excluding: mode != _WorkspaceMode.mods,
                child: widget.modLibraryBuilder!(context, workspace),
              )
            else
              const SizedBox.shrink(),
            if (widget.gameContextBuilder != null)
              ExcludeFocus(
                excluding: mode != _WorkspaceMode.game,
                child: widget.gameContextBuilder!(context, workspace),
              )
            else
              const SizedBox.shrink(),
            if (widget.executableBuilder != null)
              ExcludeFocus(
                excluding: mode != _WorkspaceMode.tools,
                child: widget.executableBuilder!(context, workspace),
              )
            else
              const SizedBox.shrink(),
            if (widget.artifactBuilder != null)
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
    ],
  ];
}
