import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'package:mc_ui_collections/mc_ui_collections.dart';

import 'controller.dart';
import 'workspace_dialog.dart';

part 'workspace_entry.dart';
part 'workspace_shell.dart';
part 'workspace_workbench.dart';
part 'workspace_profile_actions.dart';
part 'workspace_profile_view.dart';

typedef ProfileRowId = ({String profileId});
typedef WorkspaceFolderOpener = Future<bool> Function(String path);
typedef ProfileNavigationGuard = Future<bool> Function(
  FutureOr<void> Function() navigate,
);
typedef ProfileInspectorBuilder = Widget Function(
  BuildContext,
  WorkspaceInfo,
  ProfileInfo,
  VoidCallback,
  ValueChanged<ProfileNavigationGuard?>,
);
typedef ProfileCreator = Future<void> Function(
  BuildContext context,
  WorkspaceInfo workspace,
);
typedef ProfileSetupBuilder = Widget Function(
  BuildContext context,
  WorkspaceInfo workspace,
  ProfileInfo profile,
);

class WorkspaceHelpActions {
  const WorkspaceHelpActions({
    required this.createWorkspace,
    required this.openWorkspace,
    this.createProfile,
  });

  final VoidCallback? createWorkspace;
  final VoidCallback? openWorkspace;
  final VoidCallback? createProfile;
}

typedef WorkspaceHelpBuilder = Widget Function(
  BuildContext,
  WorkspaceInfo?,
  WorkspaceHelpActions,
);

enum _WorkspaceMode { profiles, mods, game, tools, archives, help }

enum _ProfileAction { export, clone, rename, delete }

class WorkspaceBrowser extends StatefulWidget {
  const WorkspaceBrowser({
    super.key,
    required this.controller,
    this.chooseDirectory = chooseWorkspaceDirectory,
    this.modLibraryBuilder,
    this.gameContextBuilder,
    this.executableBuilder,
    this.artifactBuilder,
    this.entryHelpBuilder,
    this.helpBuilder,
    this.headerActions,
    this.profileInspectorBuilder,
    this.profileCreator,
    this.onImportProfile,
    this.onExportProfile,
    this.profileSetupBuilder,
    this.imageClient,
    this.gameName,
    this.gameImage,
    this.workbenchReady = true,
    this.compactCloseAction = false,
    this.openFolder,
  });
  final WorkspaceController controller;
  final DirectoryChooser chooseDirectory;
  final Widget Function(BuildContext, WorkspaceInfo, bool visible)?
  modLibraryBuilder;
  final Widget Function(BuildContext, WorkspaceInfo)? gameContextBuilder;
  final Widget Function(BuildContext, WorkspaceInfo)? executableBuilder;
  final Widget Function(BuildContext, WorkspaceInfo, VoidCallback)?
  artifactBuilder;
  final WorkspaceHelpBuilder? entryHelpBuilder;
  final WorkspaceHelpBuilder? helpBuilder;
  final List<Widget> Function(BuildContext, WorkspaceInfo)? headerActions;
  final bool compactCloseAction;
  final WorkspaceFolderOpener? openFolder;
  final ProfileInspectorBuilder? profileInspectorBuilder;
  final ProfileCreator? profileCreator;
  final Future<void> Function(BuildContext context)? onImportProfile;
  final Future<void> Function(
    BuildContext context,
    WorkspaceInfo workspace,
    ProfileInfo profile,
  )?
  onExportProfile;
  final ProfileSetupBuilder? profileSetupBuilder;
  final ProfileImagesClient? imageClient;
  final String? gameName;
  final Uri? gameImage;
  final bool workbenchReady;

  @override
  State<WorkspaceBrowser> createState() => _WorkspaceBrowserState();
}

class _WorkspaceBrowserState extends State<WorkspaceBrowser> {
  WorkspaceController get controller => widget.controller;
  DirectoryChooser get chooseDirectory => widget.chooseDirectory;
  final _createWorkspaceFocus = FocusNode(debugLabel: 'Create workspace');
  final _openWorkspaceFocus = FocusNode(debugLabel: 'Open workspace');
  final _createProfileFocus = FocusNode(debugLabel: 'Create profile');
  final _helpFocus = FocusNode(debugLabel: 'Help');
  int _archiveNavigation = 0;
  int _gameNavigation = 0;
  int _helpNavigation = 0;
  bool _entryHelp = false;
  String? _shownId;
  _WorkspaceMode _mode = _WorkspaceMode.profiles;
  final _profilesGrid = GlobalKey<McCardGridState<ProfileRowId, ProfileInfo>>();
  final _profiles = McCollectionModel<ProfileRowId, ProfileInfo>(
    idOf: (row) => (profileId: row.id),
    labelOf: (row) => row.name,
  );
  WorkspacePage? _shownPage;
  final Map<String, Future<String?>> _images = {};
  int _imageEpoch = -1;
  final _profilePane = GlobalKey<ScaffoldState>();
  bool _inspected = false, _compactProfile = false;
  ProfileNavigationGuard? _profileNavigationGuard;
  String? _inspectedProfileId;
  bool _openingFolder = false, _folderProblem = false;
  bool _allowProfileDrawerClose = false, _guardingProfileDrawerClose = false;
  void _change(VoidCallback action) => setState(action);

  @override
  void initState() {
    super.initState();
    controller.addListener(_navigationChanged);
    _profiles.sort((a, b) => a.name.compareTo(b.name));
    _navigationChanged();
  }

  @override
  void didUpdateWidget(WorkspaceBrowser oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, controller)) {
      oldWidget.controller.removeListener(_navigationChanged);
      controller.addListener(_navigationChanged);
      _navigationChanged();
    }
  }

  void _navigationChanged() {
    final id = controller.workspace?.id;
    if (id != _shownId) {
      _images.clear();
      _profiles.clear();
      _mode = _WorkspaceMode.profiles;
      _entryHelp = false;
      _inspected = false;
    }
    if (_imageEpoch != controller.imageEpoch) {
      _imageEpoch = controller.imageEpoch;
      for (final image in _images.values) {
        unawaited(
          image.then(
            (path) => path == null ? false : FileImage(File(path)).evict(),
          ),
        );
      }
      _images.clear();
    }
    if (_archiveNavigation != controller.archiveNavigation) {
      _archiveNavigation = controller.archiveNavigation;
      _mode = _WorkspaceMode.archives;
    }
    if (_gameNavigation != controller.gameNavigation) {
      _gameNavigation = controller.gameNavigation;
      _mode = _WorkspaceMode.game;
    }
    if (_helpNavigation != controller.helpNavigation) {
      _helpNavigation = controller.helpNavigation;
      _mode = _WorkspaceMode.help;
    }
    final page = controller.page;
    if (id != null && page != null && !identical(page, _shownPage)) {
      final selected = page.workspace.selectedProfile;
      final rows = {for (final row in page.profiles) (profileId: row.id): row};
      if (selected != null) rows[(profileId: selected.id)] = selected;
      final removed = _profiles.ids
          .where((id) => !rows.containsKey(id))
          .toList();
      _profiles.apply(
        upserts: rows.values,
        removed: page.nextProfile == null ? removed : const [],
        evicted: page.nextProfile != null ? removed : const [],
      );
      _shownPage = page;
    }
    if (id == _shownId) return;
    _shownId = id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && controller.workspace?.id == id) {
        (id == null ? _createWorkspaceFocus : _createProfileFocus)
            .requestFocus();
      }
    });
  }

  @override
  void dispose() {
    controller.removeListener(_navigationChanged);
    _profiles.dispose();
    _createWorkspaceFocus.dispose();
    _openWorkspaceFocus.dispose();
    _createProfileFocus.dispose();
    _helpFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) =>
        controller.workspace == null ? _entry(context) : _workspace(context),
  );
}
