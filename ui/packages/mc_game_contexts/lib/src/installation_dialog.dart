import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'steam_search_controller.dart';
import 'steam_chooser.dart';
import 'proton_dialog.dart';
import 'installation_setup_fields.dart';

typedef GameDirectoryChooser = Future<String?> Function(String? initialPath);

class InstallationDialog extends StatefulWidget {
  const InstallationDialog({
    super.key,
    required this.initial,
    required this.client,
    required this.chooseDirectory,
    required this.onSaved,
    required this.onUnknownSave,
    this.steamDiscovery,
    this.protonContexts,
    this.chooseExecutable,
    this.catalogue = const [],
  });
  final GameContextState initial;
  final List<GameDefinitionInfo> catalogue;
  final GameContextsClient client;
  final SteamDiscoveryClient? steamDiscovery;
  final ProtonContextsClient? protonContexts;
  final GameDirectoryChooser chooseDirectory;
  final GameDirectoryChooser? chooseExecutable;
  final ValueChanged<GameContextState> onSaved;
  final VoidCallback onUnknownSave;
  @override
  State<InstallationDialog> createState() => _InstallationDialogState();
}

class _InstallationDialogState extends State<InstallationDialog> {
  late final folder = TextEditingController(
    text: widget.initial.binding?.path ?? '',
  );
  late GameContextState current = widget.initial;
  late GameDefinitionInfo selectedGame =
      widget.initial.definition ?? widget.catalogue.first;
  List<GameDefinitionInfo> get variants => widget.catalogue
      .where((game) => game.variantGroupId == selectedGame.variantGroupId)
      .toList();
  List<GameDefinitionInfo> get gameChoices {
    final groups = <String, GameDefinitionInfo>{};
    for (final game in widget.catalogue) {
      groups.putIfAbsent(game.variantGroupId, () => game);
    }
    return groups.values.toList();
  }

  String get gameChoice =>
      gameChoices
          .where((game) => game.variantGroupId == selectedGame.variantGroupId)
          .firstOrNull
          ?.id ??
      selectedGame.id;
  List<GameInstallationSource> get sources => variants.isEmpty
      ? [GameInstallationSource.fromDefinition(selectedGame)]
      : variants
            .map((game) => GameInstallationSource.fromDefinition(game))
            .toList();
  late GameInstallationSource source = GameInstallationSource.fromDefinition(
    selectedGame,
  );
  late final wineExecutable = TextEditingController(
    text: widget.initial.binding?.wine?.executable ?? '',
  );
  late final winePrefix = TextEditingController(
    text: widget.initial.binding?.wine?.prefix ?? '',
  );
  SteamSearchController? steamSearch;
  late ProtonSelection? proton = widget.initial.binding?.proton;
  bool busy = false;
  bool submitting = false;
  bool needsReload = false;
  bool reloaded = false;
  String? error;
  late String protonGamePath;
  @override
  void initState() {
    super.initState();
    protonGamePath = folder.text;
    folder.addListener(gamePathChanged);
  }

  void gamePathChanged() {
    if (folder.text == protonGamePath) return;
    setState(() {
      protonGamePath = folder.text;
      proton = null;
    });
  }

  @override
  void dispose() {
    steamSearch?.dispose();
    folder.removeListener(gamePathChanged);
    folder.dispose();
    wineExecutable.dispose();
    winePrefix.dispose();
    super.dispose();
  }

  Future<void> findInSteam() async {
    final discovery = widget.steamDiscovery;
    if (busy || discovery == null) return;
    final search = steamSearch ??= SteamSearchController(
      discovery,
      selectedGame.id,
    );
    final path = await showDialog<String>(
      context: context,
      builder: (_) => SteamInstallationChooser(
        controller: search,
        gameName: selectedGame.name,
        chooseDirectory: widget.chooseDirectory,
      ),
    );
    if (mounted && path != null) {
      setState(() {
        folder.text = path;
        error = null;
      });
    }
  }

  Future<void> chooseProton() async {
    final client = widget.protonContexts;
    if (busy || client == null || folder.text.isEmpty) return;
    final gamePath = folder.text;
    final selected = await showDialog<ProtonSelection>(
      context: context,
      builder: (_) => ProtonDialog(
        gameId: selectedGame.id,
        gameName: selectedGame.name,
        steamAppId: selectedGame.declaredSteamAppId,
        gamePath: gamePath,
        client: client,
        chooseDirectory: widget.chooseDirectory,
        roots: steamSearch?.additionalRoots ?? const [],
        initial: proton,
      ),
    );
    if (mounted && selected != null && folder.text == gamePath) {
      setState(() {
        proton = selected;
        error = null;
      });
    }
  }

  Future<void> save() async {
    if (busy || needsReload) return;
    setState(() {
      busy = true;
      submitting = true;
      error = null;
    });
    try {
      final result = await widget.client.save(
        current.workspaceId,
        current.profileId,
        selectedGame.id,
        current.revision,
        folder.text,
        proton:
            source == GameInstallationSource.steam && !selectedGame.nativeLinux
            ? proton
            : null,
        wine: Platform.isLinux && source != GameInstallationSource.steam
            ? WineSelection(
                executable: wineExecutable.text.trim(),
                prefix: winePrefix.text.trim(),
              )
            : null,
      );
      widget.onSaved(result);
      if (mounted) Navigator.pop(context);
    } on Exception catch (failure) {
      if (failure is! GameContextException) widget.onUnknownSave();
      if (mounted) {
        setState(() {
          if (failure is GameContextException) {
            needsReload = failure.code == GameContextFailure.stale;
            error = failure.candidate?.problems.map((p) => p.detail).join('\n');
            if (error == null || error!.isEmpty) error = failure.detail;
          } else {
            needsReload = true;
            error = 'Save did not return a result. Reload the saved installation before another change.';
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
          submitting = false;
        });
      }
    }
  }

  Future<void> reload() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final result = await widget.client.read(
        current.workspaceId,
        current.profileId,
      );
      widget.onSaved(result);
      if (mounted) {
        setState(() {
          current = result;
          needsReload = false;
          reloaded = true;
          error = null;
        });
      }
    } on Exception {
      if (mounted) {
        setState(
          () => error = 'The saved installation could not be loaded. Your folder is unchanged.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> browse() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final selected = await widget.chooseDirectory(
        folder.text.isEmpty ? null : folder.text,
      );
      if (mounted && selected != null) {
        setState(() {
          folder.text = selected;
          error = null;
        });
      }
    } on Exception {
      if (mounted) {
        setState(() => error = 'The folder selector could not open.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void selectSource(GameInstallationSource value) {
    if (busy || value == source) return;
    setState(() {
      source = value;
      selectedGame = variants.firstWhere(
        (game) => GameInstallationSource.fromDefinition(game) == value,
      );
      proton = null;
      wineExecutable.clear();
      winePrefix.clear();
      steamSearch?.dispose();
      steamSearch = null;
      error = null;
    });
  }

  void selectGame(String id) {
    if (busy || id == selectedGame.id) return;
    setState(() {
      selectedGame = widget.catalogue.firstWhere((game) => game.id == id);
      source = GameInstallationSource.fromDefinition(selectedGame);
      folder.clear();
      proton = null;
      wineExecutable.clear();
      winePrefix.clear();
      steamSearch?.dispose();
      steamSearch = null;
      error = null;
    });
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !submitting,
    child: McDialog(
      title: 'Game installation',
      contentWidth: 640,
      actions: [
        McAction(
          label: 'Cancel',
          onPressed: submitting ? null : () => Navigator.pop(context),
        ),
        McAction(
          key: const ValueKey('submit'),
          label: submitting ? 'Saving…' : 'Save',
          emphasis: McActionEmphasis.primary,
          onPressed: busy || needsReload || folder.text.trim().isEmpty
              ? null
              : save,
        ),
      ],
      children: [
        InstallationSetupFields(
          gameName: gameChoice,
          gameLabels: {
            for (final game in gameChoices)
              game.id: game.selectionLabel(gameChoices),
          },
          gameChoices: widget.catalogue.isEmpty
              ? [selectedGame.id]
              : gameChoices.map((game) => game.id).toList(),
          onGameChanged: selectGame,
          sourceChoices: sources,
          source: source,
          onSourceChanged: selectSource,
          folder: folder,
          wineExecutable: wineExecutable,
          winePrefix: winePrefix,
          chooseDirectory: widget.chooseDirectory,
          chooseExecutable: widget.chooseExecutable,
          onBrowse: browse,
          onProblem: (value) => setState(() => error = value),
          onFindSteam: widget.steamDiscovery == null ? null : findInSteam,
          nativeClient: selectedGame.nativeLinux,
          onSelectProton: widget.protonContexts == null ? null : chooseProton,
          proton: proton,
          busy: busy,
        ),
        if (error != null) ...[
          const SizedBox(height: McSpacing.medium),
          McStatus(title: error!, tone: McStatusTone.error),
        ],
        if (needsReload) ...[
          const SizedBox(height: McSpacing.medium),
          McAction(
            key: const ValueKey('reload-installation'),
            label: 'Reload saved installation',
            icon: Icons.refresh,
            onPressed: busy ? null : reload,
          ),
        ],
        if (reloaded) ...[
          const SizedBox(height: McSpacing.medium),
          Text(
            'Saved installation',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: McSpacing.small),
          SelectableText(current.binding?.path ?? 'No installation selected'),
        ],
      ],
    ),
  );
}
