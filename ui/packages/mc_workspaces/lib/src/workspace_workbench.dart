part of 'workspace_browser.dart';

extension _WorkspaceWorkbench on _WorkspaceBrowserState {
  List<Widget> _workspaceBody(
    BuildContext context,
    WorkspaceInfo workspace,
    ProfileInfo? current,
    bool ready,
    _WorkspaceMode mode,
  ) => [
    if (mode == _WorkspaceMode.mods &&
        MediaQuery.sizeOf(context).width >= 1050 &&
        widget.workbenchActions != null) ...[
      Align(
        alignment: AlignmentDirectional.centerEnd,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: widget.workbenchActions!(context, workspace),
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
