part of 'workspace_browser.dart';

extension _WorkspaceProfileView on _WorkspaceBrowserState {
  Widget _profilesSurface(BuildContext context) => ListenableBuilder(
    listenable: _profiles,
    builder: (context, _) => LayoutBuilder(
      builder: (context, constraints) {
        final selected = _profiles.selected;
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

  Widget _profileCollection(BuildContext context) {
    final current = controller.workspace?.selectedProfile;
    final incomplete = controller.page!.nextProfile != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Profiles', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Expanded(
          child: McCardGrid<ProfileRowId, ProfileInfo>(
            key: _profilesGrid,
            model: _profiles,
            filterLabel: incomplete
                ? 'Filter loaded profiles'
                : 'Filter profiles',
            empty: 'No profiles.',
            cardExtent: 336,
            compactCardExtent: 390,
            compactCardWidth: 480,
            twoColumnWidth: 900,
            countLabel:
                '${_profiles.length} ${_profiles.length == 1 ? 'profile' : 'profiles'}${incomplete ? ' loaded' : ''}',
            onSelect: _selectProfile,
            onLoad: incomplete && controller.canEdit
                ? () => unawaited(controller.moreProfiles())
                : null,
            onRefresh: controller.connected && controller.activity == null
                ? () => unawaited(controller.refresh())
                : null,
            filterActions: [
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
            card: (profile) =>
                _profileCard(context, profile, current?.id, false),
            cardWithFocus: (profile, focused) =>
                _profileCard(context, profile, current?.id, focused),
          ),
        ),
      ],
    );
  }

  Widget _profileCard(
    BuildContext context,
    ProfileInfo profile,
    String? activeId,
    bool focused,
  ) {
    final selected = _profiles.selectedId == (profileId: profile.id);
    final active = profile.id == activeId;
    final imageClient = widget.imageClient;
    final future = imageClient == null
        ? null
        : _images.putIfAbsent(
            profile.id,
            () => imageClient
                .readProfileImage(controller.workspace!.id, profile.id)
                .catchError((_) => null),
          );
    return FutureBuilder<String?>(
      future: future,
      builder: (context, snapshot) => Padding(
        padding: const EdgeInsets.all(3),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: focused
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: McPortraitCard(
            key: ValueKey('profile-card-${profile.id}'),
            name: profile.name,
            category: widget.gameName,
            image: widget.gameImage,
            imagePath: snapshot.data,
            questionFallback: true,
            badge: active
                ? 'Active'
                : selected
                ? 'Selected'
                : null,
            badgeEmphasis: active,
            selected: selected,
            actionsRow: true,
            actions: [
              Expanded(
                flex: 2,
                child: McAction(
                  key: ValueKey('use-profile-${profile.id}'),
                  label: 'Use profile',
                  emphasis: McActionEmphasis.primary,
                  onPressed: controller.canEdit && !active
                      ? () => unawaited(controller.select(profile))
                      : null,
                ),
              ),
              Expanded(
                flex: 3,
                child: McAction(
                  label: 'Settings and saves',
                  icon: Icons.settings_outlined,
                  onPressed: widget.profileInspectorBuilder == null
                      ? null
                      : () => _selectProfile(profile, _inspectProfile),
                ),
              ),
              McIconMenu<_ProfileAction>(
                key: ValueKey('profile-menu-${profile.id}'),
                label: 'Options for ${profile.name}',
                enabled: controller.canEdit,
                onSelected: (action) {
                  _selectProfile(profile, () {
                    switch (action) {
                      case _ProfileAction.clone:
                        unawaited(_profileDialog(context, profile: profile));
                      case _ProfileAction.rename:
                        unawaited(
                          _profileDialog(
                            context,
                            profile: profile,
                            rename: true,
                          ),
                        );
                      case _ProfileAction.delete:
                        unawaited(_delete(context, profile));
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
            ],
          ),
        ),
      ),
    );
  }
}
