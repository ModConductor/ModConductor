import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_game_contexts/mc_game_contexts.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'workspace_dialog.dart' show DirectoryChooser;

part 'profile_setup_view.dart';
part 'profile_setup_discovery.dart';

class ProfileSetupGame {
  const ProfileSetupGame({
    required this.id,
    required this.name,
    required this.storefront,
    required this.steamAppId,
  });

  final String id;
  final String name;
  final String storefront;
  final int steamAppId;
}

class ProfileSetupSelection {
  const ProfileSetupSelection({
    required this.name,
    required this.game,
    required this.installation,
    this.proton,
    this.wine,
    this.source = GameInstallationSource.steam,
  });

  final String name;
  final ProfileSetupGame game;
  final String installation;
  final ProtonSelection? proton;
  final WineSelection? wine;
  final GameInstallationSource source;
  String get gameId => source.gameId;
}

typedef ProfileSetupSubmit = Future<String?> Function(
  ProfileSetupSelection selection,
);

class ProfileSetupSurface extends StatefulWidget {
  const ProfileSetupSurface({
    super.key,
    required this.initialName,
    required this.games,
    required this.discovery,
    required this.chooseDirectory,
    required this.onSubmit,
    required this.actionLabel,
    this.nameEditable = true,
    this.canCancel = false,
    this.onCancel,
    this.onComplete,
    this.initialInstallation,
    this.initialProton,
    this.initialWine,
    this.initialSource = GameInstallationSource.steam,
    this.chooseExecutable,
    this.initialProblem,
    this.protonContexts,
  });

  final String initialName;
  final List<ProfileSetupGame> games;
  final SteamDiscoveryClient? discovery;
  final DirectoryChooser chooseDirectory;
  final ProfileSetupSubmit onSubmit;
  final String actionLabel;
  final bool nameEditable;
  final bool canCancel;
  final VoidCallback? onCancel;
  final VoidCallback? onComplete;
  final String? initialInstallation;
  final ProtonSelection? initialProton;
  final WineSelection? initialWine;
  final GameInstallationSource initialSource;
  final GameDirectoryChooser? chooseExecutable;
  final String? initialProblem;
  final ProtonContextsClient? protonContexts;

  @override
  State<ProfileSetupSurface> createState() => _ProfileSetupSurfaceState();
}

class _ProfileSetupSurfaceState extends State<ProfileSetupSurface> {
  final form = GlobalKey<FormState>();
  final folder = TextEditingController();
  final wineExecutable = TextEditingController();
  final winePrefix = TextEditingController();
  late GameInstallationSource source;
  late final TextEditingController name;
  late ProfileSetupGame? game;
  SteamSearch? pendingSearch;
  List<SteamInstallationCandidate> candidates = const [];
  String? selectedInstallation;
  ProtonSelection? proton;
  List<String> steamRoots = const [];
  String? problem;
  bool searched = false;
  bool searching = false;
  bool choosingFolder = false;
  bool submitting = false;
  bool manualSelection = false;

  bool get busy => searching || choosingFolder || submitting;
  bool get canSubmit => !busy && game != null && folder.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.initialName);
    game = widget.games.length == 1 ? widget.games.single : null;
    selectedInstallation = widget.initialInstallation;
    folder.text = widget.initialInstallation ?? '';
    source = widget.initialSource;
    wineExecutable.text = widget.initialWine?.executable ?? '';
    winePrefix.text = widget.initialWine?.prefix ?? '';
    folder.addListener(folderChanged);
    proton = widget.initialProton;
    manualSelection = selectedInstallation != null;
    searched = selectedInstallation != null;
    problem = widget.initialProblem;
  }

  @override
  void didUpdateWidget(ProfileSetupSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialName != widget.initialName && !widget.nameEditable) {
      name.text = widget.initialName;
    }
    if ((oldWidget.initialInstallation != widget.initialInstallation ||
            oldWidget.initialSource != widget.initialSource ||
            oldWidget.initialProton != widget.initialProton ||
            oldWidget.initialWine != widget.initialWine) &&
        widget.initialInstallation != null &&
        !busy) {
      folder.text = widget.initialInstallation!;
      source = widget.initialSource;
      wineExecutable.text = widget.initialWine?.executable ?? '';
      winePrefix.text = widget.initialWine?.prefix ?? '';
      selectedInstallation = widget.initialInstallation;
      proton = widget.initialProton;
      manualSelection = true;
      searched = true;
    }
  }

  @override
  void dispose() {
    final search = pendingSearch;
    if (search != null) unawaited(search.cancel());
    folder.removeListener(folderChanged);
    folder.dispose();
    wineExecutable.dispose();
    winePrefix.dispose();
    name.dispose();
    super.dispose();
  }

  void folderChanged() {
    if (selectedInstallation != folder.text) proton = null;
    selectedInstallation = folder.text.isEmpty ? null : folder.text;
    if (mounted) setState(() {});
  }

  void selectSource(GameInstallationSource value) {
    if (busy || source == value) return;
    setState(() {
      source = value;
      proton = null;
      wineExecutable.clear();
      winePrefix.clear();
      candidates = const [];
      problem = null;
    });
  }

  void selectGame(ProfileSetupGame? value) {
    if (value == null || value == game || busy) return;
    final search = pendingSearch;
    if (search != null) unawaited(search.cancel());
    setState(() {
      game = value;
      pendingSearch = null;
      candidates = const [];
      folder.clear();
      selectedInstallation = null;
      proton = null;
      steamRoots = const [];
      manualSelection = false;
      searched = false;
      searching = false;
      problem = null;
    });
  }

  Future<void> chooseFolder() async {
    if (busy) return;
    setState(() {
      choosingFolder = true;
      problem = null;
    });
    try {
      final selected = await widget.chooseDirectory(selectedInstallation);
      if (mounted && selected != null) {
        setState(() {
          if (selectedInstallation != selected) proton = null;
          folder.text = selected;
          selectedInstallation = selected;
          manualSelection = true;
          searched = true;
        });
      }
    } on Exception {
      if (mounted) {
        setState(() => problem = 'The folder selector could not open.');
      }
    } finally {
      if (mounted) {
        setState(() => choosingFolder = false);
      }
    }
  }

  Future<void> submit() async {
    final selectedGame = game;
    final installation = folder.text.trim();
    if (!canSubmit ||
        selectedGame == null ||
        installation.isEmpty ||
        !form.currentState!.validate()) {
      return;
    }
    setState(() {
      submitting = true;
      problem = null;
    });
    try {
      final failure = await widget.onSubmit(
        ProfileSetupSelection(
          name: name.text.trim(),
          game: selectedGame,
          installation: installation,
          proton: source == GameInstallationSource.steam ? proton : null,
          source: source,
          wine: Platform.isLinux && source != GameInstallationSource.steam
              ? WineSelection(
                  executable: wineExecutable.text.trim(),
                  prefix: winePrefix.text.trim(),
                )
              : null,
        ),
      );
      if (!mounted) return;
      if (failure == null) {
        widget.onComplete?.call();
      } else {
        setState(() => problem = failure);
      }
    } on Exception {
      if (mounted) {
        setState(() => problem = 'Profile setup did not finish. Try again.');
      }
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  void _change(VoidCallback action) => setState(action);

  @override
  Widget build(BuildContext context) => _profileSetupView(context);
}
