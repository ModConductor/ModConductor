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
        onUnknownSave: () => c.unknownSave(client, initial.workspaceId),
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
                              McPropertyRow(
                                label: 'Executable',
                                value: evidence.executable!.path,
                              ),
                              McPropertyRow(
                                label: 'File version',
                                value:
                                    '${evidence.executable!.fileVersion} · x64',
                              ),
                              McPropertyRow(
                                label: 'Data folder',
                                value: evidence.dataPath!,
                              ),
                              McPropertyRow(
                                label: 'Launcher',
                                value:
                                    evidence.launcherPath ??
                                    'Not found or unavailable',
                              ),
                              McPropertyRow(
                                label: 'Steam installation',
                                value:
                                    evidence.proton?.selection.association
                                        is SteamProtonAssociation
                                    ? 'AppID ${evidence.proton!.selection.appId} · Manifest checked'
                                    : 'Not verified',
                              ),
                              const McPropertyRow(
                                label: 'Steam build',
                                value: 'Not available',
                              ),
                              if (evidence.proton case final proton?) ...[
                                McPropertyRow(
                                  label: 'Proton',
                                  value: proton.runtimeName,
                                ),
                                McPropertyRow(
                                  label: 'Proton version',
                                  value: proton.runtimeVersion,
                                ),
                                McPropertyRow(
                                  label: 'Proton data folder',
                                  value: proton.selection.compatData,
                                ),
                                McPropertyRow(
                                  label: 'Prefix folder',
                                  value: proton.prefixPath,
                                ),
                                McPropertyRow(
                                  label: 'Proton folder',
                                  value: proton.selection.runtimeDirectory,
                                ),
                                McPropertyRow(
                                  label: 'Prefix version',
                                  value:
                                      proton.prefixVersion ?? 'Not available',
                                ),
                                if (proton.mappingProblem case final problem?)
                                  McPropertyRow(
                                    label: 'Steam setting',
                                    value: problem,
                                  )
                                else ...[
                                  McPropertyRow(
                                    label: 'Steam game-specific setting',
                                    value: proton.perGameTool ?? 'Not set',
                                  ),
                                  McPropertyRow(
                                    label: 'Steam default',
                                    value: proton.globalTool ?? 'Not set',
                                  ),
                                ],
                                for (final path in proton.paths) ...[
                                  McPropertyRow(
                                    label: path.name,
                                    value: location(path.location),
                                  ),
                                  if (path.windowsPath case final windows?)
                                    McPropertyRow(
                                      label: 'Windows path',
                                      value: windows,
                                    ),
                                ],
                              ] else ...[
                                McPropertyRow(
                                  label: 'Documents',
                                  value: location(evidence.documents),
                                ),
                                McPropertyRow(
                                  label: 'Saves',
                                  value: location(evidence.saves),
                                ),
                                McPropertyRow(
                                  label: 'Local AppData',
                                  value: location(evidence.localAppData),
                                ),
                              ],
                            ],
                          ),
                        ),
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
                        for (final capability in state.definition.capabilities)
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
