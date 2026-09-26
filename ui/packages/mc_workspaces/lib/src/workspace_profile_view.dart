part of 'workspace_browser.dart';

extension _WorkspaceProfileView on _WorkspaceBrowserState {
  Widget _profilesSurface(BuildContext context) => ListenableBuilder(
    listenable: _profiles,
    builder: (context, _) => LayoutBuilder(
      builder: (context, constraints) {
        final selected = _profiles.selected;
        _compactProfileActions =
            constraints.maxHeight <
            420 * MediaQuery.textScalerOf(context).scale(1);
        _compactProfile =
            constraints.maxWidth <
            1100 * MediaQuery.textScalerOf(context).scale(1);
        Widget inspector() {
          final profile = selected!;
          _inspectedProfileId = profile.id;
          return widget.profileInspectorBuilder!(
            context,
            controller.workspace!,
            profile,
            _closeProfileInspector,
            (guard) => _bindProfileNavigation(profile.id, guard),
          );
        }

        return Scaffold(
          key: _profilePane,
          backgroundColor: Colors.transparent,
          endDrawer:
              _compactProfile &&
                  selected != null &&
                  widget.profileInspectorBuilder != null
              ? PopScope(
                  canPop:
                      _allowProfileDrawerClose ||
                      _profileNavigationGuard == null,
                  onPopInvokedWithResult: (didPop, _) {
                    if (!didPop) _guardProfileDrawerClose();
                  },
                  child: Drawer(width: 440, child: inspector()),
                )
              : null,
          onEndDrawerChanged: _profileDrawerChanged,
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _profileCollection(context)),
              if (!_compactProfile &&
                  _inspected &&
                  selected != null &&
                  widget.profileInspectorBuilder != null) ...[
                const SizedBox(width: 16),
                SizedBox(width: 390, child: inspector()),
              ],
            ],
          ),
        );
      },
    ),
  );

  Widget _profileCollection(BuildContext context) => ListenableBuilder(
    listenable: _profiles,
    builder: (context, _) {
      final selected = _profiles.selected;
      final current = controller.workspace?.selectedProfile;
      final incomplete = controller.page!.nextProfile != null;
      return Column(
        children: [
          Expanded(
            child: McCollection<ProfileRowId, ProfileInfo>(
              model: _profiles,
              title: 'Profiles',
              showTitle: !_compactProfileActions,
              filterActions: [
                if (_compactProfileActions)
                  McIconAction(
                    key: const ValueKey('create-profile'),
                    focusNode: _createProfileFocus,
                    label: 'Create profile',
                    icon: const Icon(Icons.add),
                    onPressed: controller.canEdit
                        ? () => _profileDialog(context)
                        : null,
                  ),
              ],
              focusNode: _profilesFocus,
              filterLabel: incomplete
                  ? 'Filter loaded profiles'
                  : 'Filter profiles',
              countLabel:
                  '${_profiles.length} ${_profiles.length == 1 ? 'profile' : 'profiles'}${incomplete ? ' loaded' : ''}',
              empty: 'No profiles.',
              onSelect: _selectProfile,
              onLoad: incomplete && controller.canEdit
                  ? () => unawaited(controller.moreProfiles())
                  : null,
              onRefresh: controller.connected && controller.activity == null
                  ? () => unawaited(controller.refresh())
                  : null,
              semanticLabel: (row) =>
                  '${row.name}${row.id == current?.id ? ', current profile' : ''}',
              actions: [
                if (!_compactProfileActions)
                  McAction(
                    key: const ValueKey('create-profile'),
                    focusNode: _createProfileFocus,
                    label: 'Create profile',
                    icon: Icons.add,
                    emphasis: McActionEmphasis.primary,
                    onPressed: controller.canEdit
                        ? () => _profileDialog(context)
                        : null,
                  ),
              ],
              columns: [
                McColumn(
                  'Name',
                  (row) =>
                      McCollectionName(row.name, icon: Icons.person_outline),
                  compare: (a, b) => a.name.compareTo(b.name),
                ),
                McColumn(
                  'Status',
                  (row) => Text(row.id == current?.id ? 'Current' : ''),
                  width: 120,
                ),
                McColumn(
                  '',
                  (row) => McIconMenu<_ProfileAction>(
                    key: ValueKey('profile-menu-${row.id}'),
                    label: 'Options for ${row.name}',
                    enabled: controller.canEdit,
                    onSelected: (action) {
                      _selectProfile(row, () {
                        switch (action) {
                          case _ProfileAction.clone:
                            unawaited(_profileDialog(context, profile: row));
                          case _ProfileAction.rename:
                            unawaited(
                              _profileDialog(
                                context,
                                profile: row,
                                rename: true,
                              ),
                            );
                          case _ProfileAction.delete:
                            unawaited(_delete(context, row));
                        }
                      });
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: _ProfileAction.clone,
                        child: Text('Clone'),
                      ),
                      PopupMenuItem(
                        value: _ProfileAction.rename,
                        child: Text('Rename'),
                      ),
                      PopupMenuItem(
                        value: _ProfileAction.delete,
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                  width: 42,
                  interactive: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 12,
              children: [
                Text(
                  selected?.name ?? 'No profile selected',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (widget.profileInspectorBuilder != null)
                  McAction(
                    label: 'Settings and saves',
                    icon: Icons.tune,
                    onPressed: selected == null ? null : _inspectProfile,
                  ),
                McAction(
                  key: const ValueKey('use-profile'),
                  label: 'Use profile',
                  icon: Icons.check,
                  emphasis: McActionEmphasis.primary,
                  onPressed:
                      controller.canEdit &&
                          selected != null &&
                          selected.id != current?.id
                      ? () => unawaited(controller.select(selected))
                      : null,
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
}
