part of 'workspace_browser.dart';

extension _WorkspaceProfileActions on _WorkspaceBrowserState {
  void _inspectProfile() {
    _change(() => _inspected = true);
    if (_compactProfile) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _profilePane.currentState?.openEndDrawer();
      });
    }
  }

  void _bindProfileNavigation(String profileId, ProfileNavigationGuard? guard) {
    if (!mounted || _inspectedProfileId != profileId) return;
    if (identical(_profileNavigationGuard, guard) ||
        (_profileNavigationGuard != null && guard != null)) {
      return;
    }
    _change(() => _profileNavigationGuard = guard);
  }

  void _selectProfile(ProfileInfo profile, [VoidCallback? after]) {
    final guard = _profileNavigationGuard;
    final prior = _inspectedProfileId;
    void select() {
      _profiles.select((profileId: profile.id));
      after?.call();
    }

    if (!_inspected || guard == null || prior == null || prior == profile.id) {
      select();
      return;
    }

    _profiles.select((profileId: prior));
    unawaited(guard(select));
  }

  void _finishProfileDrawerClose() {
    if (mounted) {
      _change(() {
        _inspected = false;
        _profileNavigationGuard = null;
        _inspectedProfileId = null;
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _profilesGrid.currentState?.focusSelected();
    });
  }

  void _closeProfileInspector() {
    if (_profilePane.currentState?.isEndDrawerOpen ?? false) {
      _allowProfileDrawerClose = true;
      _profilePane.currentState?.closeEndDrawer();
    } else {
      _finishProfileDrawerClose();
    }
  }

  void _guardProfileDrawerClose() {
    final guard = _profileNavigationGuard;
    if (guard == null || _guardingProfileDrawerClose) return;
    _guardingProfileDrawerClose = true;
    unawaited(
      guard(() {
        _allowProfileDrawerClose = true;
        _profilePane.currentState?.closeEndDrawer();
      }).whenComplete(() => _guardingProfileDrawerClose = false),
    );
  }

  void _profileDrawerChanged(bool open) {
    if (open) return;
    if (_allowProfileDrawerClose) {
      _allowProfileDrawerClose = false;
      _finishProfileDrawerClose();
      return;
    }
    if (_profileNavigationGuard == null) {
      _finishProfileDrawerClose();
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _profilePane.currentState?.openEndDrawer();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _guardProfileDrawerClose();
      });
    });
  }

  Future<void> _profileDialog(
    BuildContext context, {
    ProfileInfo? profile,
    bool rename = false,
  }) async {
    if (profile == null && !rename && widget.profileCreator != null) {
      final workspace = controller.workspace;
      if (workspace != null) {
        _createProfileFocus.requestFocus();
        await widget.profileCreator!(context, workspace);
        if (mounted) _createProfileFocus.requestFocus();
      }
      return;
    }
    final value = await showDialog<String>(
      context: context,
      builder: (_) => McNameDialog(
        title: rename
            ? 'Rename profile'
            : profile == null
            ? 'Create profile'
            : 'Clone profile',
        action: rename
            ? 'Save'
            : profile == null
            ? 'Create'
            : 'Clone',
        initial: profile == null
            ? ''
            : rename
            ? profile.name
            : '${profile.name} copy',
      ),
    );
    if (value == null) return;
    if (rename) {
      await controller.rename(profile!, value);
    } else if (profile == null) {
      await controller.createProfile(value);
    } else {
      await controller.clone(profile, value);
    }
  }

  Future<void> _delete(BuildContext context, ProfileInfo profile) async {
    final selected = controller.workspace?.selectedProfile?.id == profile.id;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => McFormDialog(
        title: 'Delete ${profile.name}?',
        action: 'Delete profile',
        onSubmit: selected ? null : () => Navigator.pop(context, true),
        children: [
          const Text(
            'This permanently removes this profile and its private settings and saves. Installed mods and other profiles stay unchanged.',
          ),
          if (selected) ...[
            const SizedBox(height: McSpacing.large),
            const McStatus(title: 'Select another profile before deletion.'),
          ],
        ],
      ),
    );
    if (confirmed == true) {
      await controller.delete(profile);
      if (mounted &&
          controller.currentProblem == null &&
          !controller.page!.profiles.any((row) => row.id == profile.id)) {
        _profiles.apply(removed: [(profileId: profile.id)]);
      }
    }
  }
}
