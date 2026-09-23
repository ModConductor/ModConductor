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
    this.footer,
  });
  final GameContextController controller;
  final SteamDiscoveryClient? steamDiscovery;
  final ProtonContextsClient? protonContexts;
  final GameDirectoryChooser chooseDirectory;
  final Widget? footer;
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
        onUnknownSave: () =>
            c.unknownSave(client, initial.workspaceId, initial.profileId),
      ),
    );
    if (mounted) changeFocus.requestFocus();
  }

  String location(GameLocation value) => switch (value) {
    LocatedGameFolder(:final path, :final exists) =>
      exists ? path : '$path\nNot found',
    UnavailableGameLocation(:final reason) => reason,
  };
  String checkedAt(DateTime time) =>
      MaterialLocalizations.of(context).formatFullDate(time.toLocal());
  List<McFact> locationFacts(String label, GameLocation value) =>
      switch (value) {
        LocatedGameFolder(:final path, :final exists) => [
          McFact(label, path, path: true),
          if (!exists) McFact('$label status', 'Not found'),
        ],
        UnavailableGameLocation(:final reason) => [McFact(label, reason)],
      };
  McCapabilityDisposition capabilityDisposition(
    GameCapabilityDisposition value,
  ) => switch (value) {
    GameCapabilityDisposition.available => McCapabilityDisposition.available,
    GameCapabilityDisposition.unavailable =>
      McCapabilityDisposition.unavailable,
    GameCapabilityDisposition.unsupported =>
      McCapabilityDisposition.unsupported,
  };
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final c = widget.controller;
      final state = c.state;
      final binding = state?.binding;
      final evidence = binding?.evidence;
      return SingleChildScrollView(
        child: Column(
          children: [
            McSection(
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
                    McAction(
                      label: 'Retry',
                      onPressed: () => unawaited(c.load()),
                    ),
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
                  Row(
                    children: [
                      if (state.definition!.declaredSteamAppId == 489830) ...[
                        const McIdentityIcon(
                          name: 'Skyrim Special Edition',
                          url: 'https://cdn.cloudflare.steamstatic.com/steamcommunity/public/images/apps/489830/0dfe3eed5658f9fbd8b62f8021038c0a4190f21d.jpg',
                          size: 44,
                        ),
                        const SizedBox(width: 12),
                      ],
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              state.definition!.name,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${state.definition!.storefront} · ${evidence!.platform == GameContextPlatform.windows ? 'Windows' : 'Proton'}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  McPathValue(path: binding.path),
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
                        McFactGroup(
                          title: 'Game',
                          rows: [
                            McFact('Game', state.definition!.name),
                            McFact('Store', state.definition!.storefront),
                            McFact(
                              'Platform',
                              evidence.platform == GameContextPlatform.windows
                                  ? 'Windows'
                                  : 'Proton',
                            ),
                            McFact(
                              'Installation folder',
                              binding.path,
                              path: true,
                            ),
                            if (evidence.dataPath case final data?)
                              McFact('Data folder', data, path: true),
                            if (evidence.executable case final executable?) ...[
                              McFact('Executable', executable.path, path: true),
                              McFact(
                                'File version',
                                '${executable.fileVersion} · x64',
                              ),
                            ],
                            if (evidence.launcherPath case final launcher?)
                              McFact('Launcher', launcher, path: true),
                          ],
                        ),
                        if (evidence.proton case final proton?) ...[
                          const SizedBox(height: 20),
                          McFactGroup(
                            title: 'Runtime',
                            rows: [
                              McFact('Name', proton.runtimeName),
                              McFact('Version', proton.runtimeVersion),
                              McFact(
                                'Proton folder',
                                proton.selection.runtimeDirectory,
                                path: true,
                              ),
                              McFact(
                                'Data folder',
                                proton.selection.compatData,
                                path: true,
                              ),
                              McFact(
                                'Prefix folder',
                                proton.prefixPath,
                                path: true,
                              ),
                              if (proton.prefixVersion case final version?)
                                McFact('Prefix version', version),
                            ],
                          ),
                          const SizedBox(height: 20),
                          McFactGroup(
                            title: 'Steam',
                            rows: [
                              McFact('AppID', '${proton.selection.appId}'),
                              if (proton.mappingProblem case final problem?)
                                McFact('Mapping problem', problem)
                              else ...[
                                McFact(
                                  'Game setting',
                                  proton.perGameTool ?? 'Not set',
                                ),
                                McFact(
                                  'Default',
                                  proton.globalTool ?? 'Not set',
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 20),
                          McFactGroup(
                            title: 'Folders',
                            rows: [
                              for (final path in proton.paths) ...[
                                ...locationFacts(path.name, path.location),
                                if (path.windowsPath case final windows?)
                                  McFact('Windows path', windows),
                              ],
                            ],
                          ),
                        ] else ...[
                          const SizedBox(height: 20),
                          McFactGroup(
                            title: 'Folders',
                            rows: [
                              ...locationFacts('Documents', evidence.documents),
                              ...locationFacts('Saves', evidence.saves),
                              ...locationFacts(
                                'Local AppData',
                                evidence.localAppData,
                              ),
                            ],
                          ),
                        ],
                        if (evidence.problems.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          McDiagnosticTable(
                            title: 'Installation problems',
                            diagnostics: [
                              for (
                                var index = 0;
                                index < evidence.problems.length;
                                index++
                              )
                                McDiagnosticItem(
                                  id: '${evidence.problems[index].path}:${evidence.problems[index].detail}:$index',
                                  title: evidence.problems[index].detail,
                                  affected: evidence.problems[index].path,
                                  evidence: [
                                    McFact(
                                      'Problem',
                                      evidence.problems[index].detail,
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: ExpansionTile(
                      key: PageStorageKey(('capabilities', state.workspaceId)),
                      tilePadding: EdgeInsets.zero,
                      title: const Text('Capabilities'),
                      children: [
                        for (final capability in state.definition!.capabilities)
                          McCapabilityState(
                            key: ValueKey(('capability', capability.id.value)),
                            title: capability.name,
                            disposition: capabilityDisposition(
                              capability.disposition,
                            ),
                            reason: capability.reason,
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            ?widget.footer,
          ],
        ),
      );
    },
  );
}
