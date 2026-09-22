import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'workspace_dialog.dart' show DirectoryChooser;

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

  Widget gameChoice(BuildContext context, ProfileSetupGame option) => Padding(
    padding: const EdgeInsets.only(bottom: McSpacing.small),
    child: Material(
      color: game == option
          ? Theme.of(context).colorScheme.primary.withValues(alpha: .08)
          : Colors.transparent,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: game == option
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: RadioListTile<ProfileSetupGame>(
        key: ValueKey(('profile-game', option.id)),
        value: option,
        enabled: !busy,
        title: Text(option.name),
        subtitle: Text(option.storefront),
        secondary: game == option
            ? Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
              )
            : null,
      ),
    ),
  );

  Widget installationChoice(
    BuildContext context,
    String path, {
    required String title,
    String? note,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: McSpacing.small),
    child: Material(
      color: selectedInstallation == path
          ? Theme.of(context).colorScheme.primary.withValues(alpha: .07)
          : Colors.transparent,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: selectedInstallation == path
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: RadioListTile<String>(
        key: ValueKey(('profile-installation', path)),
        value: path,
        enabled: !busy,
        title: Text(title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(path, maxLines: 2, overflow: TextOverflow.ellipsis),
            if (note != null)
              Text(
                note,
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
          ],
        ),
      ),
    ),
  );

  Widget folderOverride({required bool primary}) => primary
      ? McAction(
          key: const ValueKey('choose-profile-game-folder'),
          label: 'Choose folder…',
          icon: Icons.folder_open,
          focusNode: folderFocus,
          onPressed: busy ? null : chooseFolder,
        )
      : TextButton.icon(
          key: const ValueKey('choose-another-profile-game-folder'),
          focusNode: folderFocus,
          onPressed: busy ? null : chooseFolder,
          icon: const Icon(Icons.folder_open, size: 18),
          label: const Text('Choose another folder…'),
        );

  Widget installationSection(BuildContext context) {
    if (!searched) return const SizedBox.shrink();
    if (searching) {
      return const McActionFeedback(
        kind: McActionFeedbackKind.pending,
        message: 'Finding installations',
        detail: 'Steam folders',
      );
    }
    final manualPath = manualSelection ? selectedInstallation : null;
    if (manualPath != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Installation', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: McSpacing.small),
          RadioGroup<String>(
            groupValue: manualPath,
            onChanged: (_) {},
            child: installationChoice(
              context,
              manualPath,
              title: 'Selected folder',
              note: 'Selected manually',
            ),
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: folderOverride(primary: false),
          ),
        ],
      );
    }
    if (candidates.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const McStatus(
            title: 'No installation found',
            detail: 'Select the folder that contains SkyrimSE.exe.',
          ),
          const SizedBox(height: McSpacing.small),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: folderOverride(primary: true),
          ),
        ],
      );
    }
    final one = candidates.length == 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          one ? 'Installation' : 'Choose an installation',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: McSpacing.small),
        RadioGroup<String>(
          groupValue: selectedInstallation,
          onChanged: busy
              ? (_) {}
              : (value) => setState(() => selectedInstallation = value),
          child: Column(
            children: [
              for (final candidate in candidates)
                installationChoice(
                  context,
                  candidate.directory.canonicalPath,
                  title: one ? 'Steam installation' : 'Steam library',
                  note: one ? 'Selected automatically' : null,
                ),
            ],
          ),
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: folderOverride(primary: false),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: widget.canCancel && !submitting,
    child: Form(
      key: form,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 600;
          final controls = <Widget>[
            if (widget.canCancel)
              McAction(
                key: const ValueKey('cancel-profile-setup'),
                label: 'Cancel',
                onPressed: busy ? null : widget.onCancel,
              ),
            McAction(
              key: const ValueKey('submit-profile-setup'),
              label: submitting ? '${widget.actionLabel}…' : widget.actionLabel,
              icon: Icons.arrow_forward,
              emphasis: McActionEmphasis.primary,
              onPressed: canSubmit ? submit : null,
            ),
          ];
          return SingleChildScrollView(
            padding: EdgeInsets.all(
              narrow ? McSpacing.medium : McSpacing.large,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Material(
                  color: Theme.of(context).colorScheme.surface,
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(
                      narrow ? McSpacing.large : McSpacing.page,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.person_add_alt_1_outlined,
                              color: Theme.of(context).colorScheme.primary,
                              size: 30,
                            ),
                            const SizedBox(width: McSpacing.medium),
                            Expanded(
                              child: Text(
                                'Set up profile',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: McSpacing.large),
                        TextFormField(
                          key: const ValueKey('profile-setup-name'),
                          controller: name,
                          autofocus: widget.nameEditable,
                          readOnly: !widget.nameEditable,
                          enabled: !busy,
                          decoration: const InputDecoration(
                            labelText: 'Profile name',
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Enter a name.'
                              : null,
                        ),
                        const SizedBox(height: McSpacing.large),
                        Text(
                          'Game',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: McSpacing.small),
                        RadioGroup<ProfileSetupGame>(
                          groupValue: game,
                          onChanged: selectGame,
                          child: Column(
                            children: [
                              for (final option in widget.games)
                                gameChoice(context, option),
                            ],
                          ),
                        ),
                        if (!searched) ...[
                          const SizedBox(height: McSpacing.medium),
                          if (narrow)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (widget.canCancel)
                                  McAction(
                                    key: const ValueKey('cancel-profile-setup'),
                                    label: 'Cancel',
                                    onPressed: busy ? null : widget.onCancel,
                                  ),
                                const SizedBox(height: McSpacing.small),
                                McAction(
                                  key: const ValueKey(
                                    'find-profile-installation',
                                  ),
                                  label: 'Find installation',
                                  icon: Icons.search,
                                  emphasis: McActionEmphasis.primary,
                                  onPressed: busy || game == null
                                      ? null
                                      : findInstallations,
                                ),
                              ],
                            )
                          else
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (widget.canCancel) ...[
                                  McAction(
                                    key: const ValueKey('cancel-profile-setup'),
                                    label: 'Cancel',
                                    onPressed: busy ? null : widget.onCancel,
                                  ),
                                  const SizedBox(width: McSpacing.small),
                                ],
                                McAction(
                                  key: const ValueKey(
                                    'find-profile-installation',
                                  ),
                                  label: 'Find installation',
                                  icon: Icons.search,
                                  emphasis: McActionEmphasis.primary,
                                  onPressed: busy || game == null
                                      ? null
                                      : findInstallations,
                                ),
                              ],
                            ),
                        ] else ...[
                          const SizedBox(height: McSpacing.large),
                          const Divider(height: 1),
                          const SizedBox(height: McSpacing.large),
                          installationSection(context),
                        ],
                        if (problem case final message?) ...[
                          const SizedBox(height: McSpacing.medium),
                          McActionFeedback(
                            kind: McActionFeedbackKind.failure,
                            message: message,
                          ),
                          if (!searching && selectedInstallation == null)
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: McAction(
                                label: 'Try search again',
                                icon: Icons.refresh,
                                onPressed: busy ? null : findInstallations,
                              ),
                            ),
                        ],
                        if (searched) ...[
                          const SizedBox(height: McSpacing.large),
                          if (narrow)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                for (final control in controls)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: McSpacing.small,
                                    ),
                                    child: control,
                                  ),
                              ],
                            )
                          else
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                for (final control in controls)
                                  Padding(
                                    padding: const EdgeInsetsDirectional.only(
                                      start: McSpacing.small,
                                    ),
                                    child: control,
                                  ),
                              ],
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}
