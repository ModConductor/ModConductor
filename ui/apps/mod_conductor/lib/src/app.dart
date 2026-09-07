import 'dart:async';
import 'dart:io';

import 'dart:ui' show AppExitType, AppExitResponse;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_selector/file_selector.dart';
import 'package:mc_game_contexts/mc_game_contexts.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';
import 'package:mc_mod_library/mc_mod_library.dart';
import 'package:mc_workspaces/mc_workspaces.dart';

part 'shell.dart';
part 'preferences.dart';
part 'status.dart';
part 'desktop_host.dart';

Future<String?> _chooseGameDirectory(String? initialPath) => getDirectoryPath(
  initialDirectory: initialPath,
  confirmButtonText: 'Choose folder',
  canCreateDirectories: false,
);

void _quitDesktop() {
  ServicesBinding.instance.exitApplication(AppExitType.cancelable);
}

void startDesktop() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DesktopHost());
}

enum _Destination { workspaces, preferences }

typedef _Preferences = ({ThemeMode theme, double scale});

String _themeLabel(ThemeMode mode) => switch (mode) {
  ThemeMode.system => 'Use system appearance',
  ThemeMode.light => 'Light',
  ThemeMode.dark => 'Dark',
};

class ModConductorApp extends StatefulWidget {
  const ModConductorApp({
    super.key,
    this.onQuit,
    this.onRetry,
    this.status = const DesktopDisconnected(),
    this.workspaces,
    this.modLibrary,
    this.profileMods,
    this.modOrganization,
    this.gameContexts,
    this.steamDiscovery,
    this.chooseGameDirectory = _chooseGameDirectory,
    this.chooseDirectory = chooseWorkspaceDirectory,
  });
  final DesktopStatus status;
  final WorkspacesClient? workspaces;
  final ModLibraryClient? modLibrary;
  final ProfileModsClient? profileMods;
  final ModOrganizationClient? modOrganization;
  final GameContextsClient? gameContexts;
  final SteamDiscoveryClient? steamDiscovery;
  final GameDirectoryChooser chooseGameDirectory;
  final DirectoryChooser chooseDirectory;
  final VoidCallback? onQuit;
  final VoidCallback? onRetry;
  @override
  State<ModConductorApp> createState() => _ModConductorAppState();
}

class _ModConductorAppState extends State<ModConductorApp> {
  _Destination _destination = _Destination.workspaces;
  _Preferences _applied = (theme: ThemeMode.system, scale: 1);
  _Preferences _draft = (theme: ThemeMode.system, scale: 1);
  final _workspacesFocus = FocusNode(debugLabel: 'Workspaces navigation');
  final _preferencesFocus = FocusNode(debugLabel: 'Preferences navigation');
  final _detailsFocus = FocusNode(debugLabel: 'Active preferences');
  final _quitFocus = FocusNode(debugLabel: 'Quit');
  final _workspaces = WorkspaceController();
  final _mods = ModLibraryController();
  final _game = GameContextController();

  void _syncWorkspaceConsumers() {
    _game.attach(
      widget.gameContexts,
      workspaceId: _workspaces.workspace?.id,
      editable: _workspaces.canEdit,
    );
    _mods.attach(
      widget.modLibrary,
      widget.profileMods,
      organizationClient: widget.modOrganization,
      workspaceId: _workspaces.workspace?.id,
      profileId: _workspaces.workspace?.selectedProfile?.id,
      editable: _workspaces.canEdit,
    );
  }

  @override
  void initState() {
    super.initState();
    _workspaces.addListener(_syncWorkspaceConsumers);
    _workspaces.attach(widget.workspaces);
    _syncWorkspaceConsumers();
  }

  @override
  void didUpdateWidget(ModConductorApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    _workspaces.attach(widget.workspaces);
    _syncWorkspaceConsumers();
  }

  @override
  void dispose() {
    _workspaces.removeListener(_syncWorkspaceConsumers);
    _mods.dispose();
    _game.dispose();
    _workspaces.dispose();
    for (final node in [
      _workspacesFocus,
      _preferencesFocus,
      _detailsFocus,
      _quitFocus,
    ]) {
      node.dispose();
    }
    super.dispose();
  }

  void _navigate(_Destination value) {
    setState(() => _destination = value);
    (value == _Destination.workspaces ? _workspacesFocus : _preferencesFocus)
        .requestFocus();
  }

  void _quickTheme(ThemeMode value) => setState(() {
    _applied = (theme: value, scale: _applied.scale);
    _draft = (theme: value, scale: _draft.scale);
  });

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Mod Conductor',
    debugShowCheckedModeBanner: false,
    theme: mcTheme(Brightness.light),
    darkTheme: mcTheme(Brightness.dark),
    themeMode: _applied.theme,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(_applied.scale)),
      child: child!,
    ),
    home: Builder(
      builder: (context) => CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.comma, control: true): () =>
              _navigate(_Destination.preferences),
          const SingleActivator(LogicalKeyboardKey.digit1, alt: true): () =>
              _navigate(_Destination.workspaces),
          const SingleActivator(LogicalKeyboardKey.digit2, alt: true): () =>
              _navigate(_Destination.preferences),
          const SingleActivator(LogicalKeyboardKey.keyQ, control: true):
              widget.onQuit ?? _quitDesktop,
        },
        child: _DesktopShell(
          connectionStatus: widget.status,
          destination: _destination,
          onNavigate: _navigate,
          onQuit: widget.onQuit ?? _quitDesktop,
          workspacesFocus: _workspacesFocus,
          preferencesFocus: _preferencesFocus,
          quitFocus: _quitFocus,
          onToggleTheme: () => _quickTheme(
            Theme.of(context).brightness == Brightness.dark
                ? ThemeMode.light
                : ThemeMode.dark,
          ),
          child: IndexedStack(
            index: _destination.index,
            children: [
              ExcludeFocus(
                excluding: _destination != _Destination.workspaces,
                child: switch (widget.status) {
                  DesktopFailure(:final reason) => _FailurePage(
                    reason: reason,
                    onRetry: widget.onRetry,
                    onPreferences: () => _navigate(_Destination.preferences),
                  ),
                  DesktopDisconnected() ||
                  DesktopConnecting() ||
                  DesktopConnected() => WorkspaceBrowser(
                    controller: _workspaces,
                    gameContextBuilder: (context, workspace) =>
                        GameContextBrowser(
                          controller: _game,
                          steamDiscovery: widget.steamDiscovery,
                          chooseDirectory: widget.chooseGameDirectory,
                        ),
                    modLibraryBuilder: (context, workspace) =>
                        ModLibraryBrowser(
                          controller: _mods,
                          workspacePath: workspace.path,
                          chooseDirectory: widget.chooseDirectory,
                        ),
                    chooseDirectory: widget.chooseDirectory,
                  ),
                },
              ),
              ExcludeFocus(
                excluding: _destination != _Destination.preferences,
                child: _PreferencesPage(
                  applied: _applied,
                  draft: _draft,
                  detailsFocus: _detailsFocus,
                  onDraft: (value) => setState(() => _draft = value),
                  onSave: () => setState(() => _applied = _draft),
                  onCancel: () => setState(() => _draft = _applied),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
