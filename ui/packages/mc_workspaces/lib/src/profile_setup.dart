import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'workspace_dialog.dart' show DirectoryChooser;

part 'profile_setup_choice_tile.dart';
part 'profile_setup_installation.dart';
part 'profile_setup_view.dart';

class ProfileSetupGame {
  const ProfileSetupGame({
    required this.id,
    required this.name,
    required this.storefront,
  });

  final String id;
  final String name;
  final String storefront;
}

class ProfileSetupSelection {
  const ProfileSetupSelection({
    required this.name,
    required this.game,
    required this.installation,
  });

  final String name;
  final ProfileSetupGame game;
  final String installation;
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
    this.initialProblem,
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
  final String? initialProblem;

  @override
  State<ProfileSetupSurface> createState() => _ProfileSetupSurfaceState();
}

class _ProfileSetupSurfaceState extends State<ProfileSetupSurface> {
  final form = GlobalKey<FormState>();
  final folderFocus = FocusNode(debugLabel: 'Choose profile game folder');
  late final TextEditingController name;
  late ProfileSetupGame? game;
  SteamSearch? pendingSearch;
  List<SteamInstallationCandidate> candidates = const [];
  String? selectedInstallation;
  String? problem;
  bool searched = false;
  bool searching = false;
  bool choosingFolder = false;
  bool submitting = false;
  bool manualSelection = false;

  bool get busy => searching || choosingFolder || submitting;
  bool get canSubmit => !busy && game != null && selectedInstallation != null;

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.initialName);
    game = widget.games.length == 1 ? widget.games.single : null;
    selectedInstallation = widget.initialInstallation;
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
    if (oldWidget.initialInstallation != widget.initialInstallation &&
        widget.initialInstallation != null &&
        !busy) {
      selectedInstallation = widget.initialInstallation;
      manualSelection = true;
      searched = true;
    }
  }

  @override
  void dispose() {
    final search = pendingSearch;
    if (search != null) unawaited(search.cancel());
    folderFocus.dispose();
    name.dispose();
    super.dispose();
  }

  void selectGame(ProfileSetupGame? value) {
    if (value == null || value == game || busy) return;
    final search = pendingSearch;
    if (search != null) unawaited(search.cancel());
    setState(() {
      game = value;
      pendingSearch = null;
      candidates = const [];
      selectedInstallation = null;
      manualSelection = false;
      searched = false;
      searching = false;
      problem = null;
    });
  }

  Future<void> findInstallations() async {
    final selectedGame = game;
    if (busy || selectedGame == null) return;
    final client = widget.discovery;
    if (client == null) {
      setState(() {
        searched = true;
        candidates = const [];
        selectedInstallation = null;
        manualSelection = false;
        problem = null;
      });
      return;
    }
    setState(() {
      searching = true;
      problem = null;
      searched = true;
      candidates = const [];
      selectedInstallation = null;
      manualSelection = false;
    });
    final search = client.search(selectedGame.id, const []);
    pendingSearch = search;
    try {
      final result = await search.result;
      if (!mounted ||
          !identical(pendingSearch, search) ||
          game != selectedGame) {
        return;
      }
      setState(() {
        candidates = result.candidates;
        selectedInstallation = result.candidates.length == 1
            ? result.candidates.single.directory.canonicalPath
            : null;
      });
    } on Exception {
      if (mounted && identical(pendingSearch, search)) {
        setState(() => problem = 'The Steam search did not finish. Try again.');
      }
    } finally {
      if (mounted && identical(pendingSearch, search)) {
        setState(() {
          pendingSearch = null;
          searching = false;
        });
      }
    }
  }

  Future<void> chooseFolder() async {
    if (busy) return;
    folderFocus.requestFocus();
    setState(() {
      choosingFolder = true;
      problem = null;
    });
    try {
      final selected = await widget.chooseDirectory(selectedInstallation);
      if (mounted && selected != null) {
        setState(() {
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
        folderFocus.requestFocus();
      }
    }
  }

  Future<void> submit() async {
    final selectedGame = game;
    final installation = selectedInstallation;
    if (!canSubmit ||
        selectedGame == null ||
        installation == null ||
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
