import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'controller.dart';
import 'installation_dialog.dart';
export 'installation_dialog.dart' show GameDirectoryChooser;

class GameContextBrowser extends StatefulWidget {
  const GameContextBrowser({
    super.key,
    required this.controller,
    required this.chooseDirectory,
    this.steamDiscovery,
    this.protonContexts,
  });
  final GameContextController controller;
  final SteamDiscoveryClient? steamDiscovery;
  final ProtonContextsClient? protonContexts;
  final GameDirectoryChooser chooseDirectory;
  @override
  State<GameContextBrowser> createState() => _GameContextBrowserState();
}

class _GameContextBrowserState extends State<GameContextBrowser> {
  final changeFocus = FocusNode(debugLabel: 'Change game installation');
  @override
  void dispose() {
    changeFocus.dispose();
    super.dispose();
  }

  Future<void> change() async {
    final c = widget.controller;
    if (!c.canChange) return;
    final client = c.client!;
    final initial = c.state!;
    changeFocus.requestFocus();
    await showDialog<void>(
      context: context,
      builder: (_) => InstallationDialog(
        initial: initial,
        client: client,
        chooseDirectory: widget.chooseDirectory,
        steamDiscovery: widget.steamDiscovery,
        protonContexts: widget.protonContexts,
        onSaved: (result) => c.accept(result, client),
        onUnknownSave: () => c.unknownSave(client, initial.workspaceId),
      ),
    );
    if (mounted) changeFocus.requestFocus();
  }

  Widget fact(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 3),
        SelectableText(value),
      ],
    ),
  );
  String location(GameLocation value) => switch (value) {
    LocatedGameFolder(:final path, :final exists) =>
      exists ? path : '$path\nNot found',
    UnavailableGameLocation(:final reason) => reason,
  };
  String checkedAt(DateTime time) =>
      MaterialLocalizations.of(context).formatFullDate(time.toLocal());
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final c = widget.controller;
      final state = c.state;
      final binding = state?.binding;
      final evidence = binding?.evidence;
      return SingleChildScrollView(
        child: McSection(
          title: 'Game installation',
          children: [
            if (c.problem != null) ...[
              McStatus(title: c.problem!, tone: McStatusTone.error),
              const SizedBox(height: 16),
            ],
            if (state == null) ...[
              McStatus(
                title: c.loading
                    ? 'Loading installation'
                    : c.problem == null
                    ? 'Not connected'
                    : 'Installation unavailable',
              ),
              if (!c.loading && c.client != null) ...[
                const SizedBox(height: 16),
                McAction(label: 'Retry', onPressed: () => unawaited(c.load())),
              ],
            ] else if (binding == null) ...[
              McStatus(
                title: c.needsRead
                    ? 'Saved installation needs a reload'
                    : 'No game selected',
              ),
              const SizedBox(height: 16),
              McAction(
                key: const ValueKey('select-installation'),
                label: c.needsRead ? 'Reload' : 'Select installation',
                icon: Icons.folder_open,
                emphasis: McActionEmphasis.primary,
                focusNode: changeFocus,
                onPressed: c.needsRead
                    ? (c.canRefresh ? () => unawaited(c.load()) : null)
                    : (c.canChange ? change : null),
              ),
            ] else ...[
              Text(
                state.definition.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                '${state.definition.storefront} · ${evidence!.platform == GameContextPlatform.windows ? 'Windows' : 'Proton'}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              SelectableText(binding.path),
              const SizedBox(height: 16),
              McStatus(
                title: c.needsRead
                    ? 'Saved installation needs a reload'
                    : c.loading
                    ? 'Checking installation'
                    : binding.failure ??
                          (binding.needsCheck
                              ? 'Installation needs a check'
                              : evidence.proton == null
                              ? 'Installation files checked'
                              : 'Installation and Proton files checked'),
                detail: binding.needsCheck || c.needsRead
                    ? 'Last checked: ${checkedAt(evidence.checkedAt)}'
                    : evidence.platform == GameContextPlatform.proton &&
                          evidence.proton == null
                    ? 'Save and settings locations are unavailable.'
                    : 'Game version ${evidence.executable!.fileVersion}',
                tone: binding.failure != null
                    ? McStatusTone.error
                    : McStatusTone.neutral,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  McAction(
                    key: const ValueKey('change-installation'),
                    label: 'Change',
                    icon: Icons.folder_open,
                    focusNode: changeFocus,
                    onPressed: c.canChange ? change : null,
                  ),
                  McAction(
                    key: const ValueKey('refresh-installation'),
                    label: c.needsRead ? 'Reload' : 'Refresh',
                    icon: Icons.refresh,
                    onPressed: c.canRefresh
                        ? () => unawaited(c.load(refresh: !c.needsRead))
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Material(
                color: Colors.transparent,
                child: ExpansionTile(
                  key: PageStorageKey((
                    'installation-details',
                    state.workspaceId,
                  )),
                  tilePadding: EdgeInsets.zero,
                  title: const Text('Installation details'),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (binding.needsCheck || c.needsRead)
                            const McStatus(title: 'Last checked details'),
                          fact('Executable', evidence.executable!.path),
                          fact(
                            'File version',
                            '${evidence.executable!.fileVersion} · x64',
                          ),
                          fact('Data folder', evidence.dataPath!),
                          fact(
                            'Launcher',
                            evidence.launcherPath ?? 'Not found or unavailable',
                          ),
                          fact(
                            'Steam installation',
                            evidence.proton?.selection.association
                                    is SteamProtonAssociation
                                ? 'AppID ${evidence.proton!.selection.appId} · Manifest checked'
                                : 'Not verified',
                          ),
                          fact('Steam build', 'Not available'),
                          if (evidence.proton case final proton?) ...[
                            fact('Proton', proton.runtimeName),
                            fact('Proton version', proton.runtimeVersion),
                            fact(
                              'Proton data folder',
                              proton.selection.compatData,
                            ),
                            fact('Prefix folder', proton.prefixPath),
                            fact(
                              'Proton folder',
                              proton.selection.runtimeDirectory,
                            ),
                            fact(
                              'Prefix version',
                              proton.prefixVersion ?? 'Not available',
                            ),
                            if (proton.mappingProblem case final problem?)
                              fact('Steam setting', problem)
                            else ...[
                              fact(
                                'Steam game-specific setting',
                                proton.perGameTool ?? 'Not set',
                              ),
                              fact(
                                'Steam default',
                                proton.globalTool ?? 'Not set',
                              ),
                            ],
                            for (final path in proton.paths) ...[
                              fact(path.name, location(path.location)),
                              if (path.windowsPath case final windows?)
                                fact('Windows path', windows),
                            ],
                          ] else ...[
                            fact('Documents', location(evidence.documents)),
                            fact('Saves', location(evidence.saves)),
                            fact(
                              'Local AppData',
                              location(evidence.localAppData),
                            ),
                          ],
                          fact(
                            'Unavailable features',
                            state.definition.unavailableCapabilities
                                .map((capability) => capability.name)
                                .join(', '),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    },
  );
}
