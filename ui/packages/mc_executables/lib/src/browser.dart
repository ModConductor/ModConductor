import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_collections/mc_ui_collections.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'controller.dart';
import 'editor.dart';
import 'fnis_tool.dart';
import 'run_details.dart';
import 'run_presentation.dart';
export 'run_presentation.dart' show executableRunLabel;

class ExecutablesBrowser extends StatefulWidget {
  const ExecutablesBrowser({
    super.key,
    required this.controller,
    required this.chooseExecutable,
    required this.chooseDirectory,
    this.fnis,
    this.workspace,
  });
  final ExecutablesController controller;
  final ExecutablePathChooser chooseExecutable, chooseDirectory;
  final FnisClient? fnis;
  final WorkspaceInfo? workspace;
  @override
  State<ExecutablesBrowser> createState() => _ExecutablesBrowserState();
}

class _ExecutablesBrowserState extends State<ExecutablesBrowser> {
  final _scaffold = GlobalKey<ScaffoldState>();
  bool _inspection = false;
  ExecutablesController get c => widget.controller;
  void _edit(ExecutablePreset? value) => showDialog<void>(
    context: context,
    builder: (_) => ExecutableEditor(
      controller: c,
      initial: value,
      chooseExecutable: widget.chooseExecutable,
      chooseDirectory: widget.chooseDirectory,
    ),
  );
  Future<void> _remove(ExecutablePreset value) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => McDialog(
        title: 'Remove ${value.name}?',
        actions: [
          McAction(
            label: 'Cancel',
            onPressed: () => Navigator.pop(context, false),
          ),
          McAction(
            label: 'Remove',
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
        children: const [
          Text('Saved run records remain. This does not stop a running tool.'),
        ],
      ),
    );
    if (result == true && mounted) await c.remove(value);
  }

  void _details(bool compact) {
    if (compact) {
      _scaffold.currentState?.openEndDrawer();
    } else {
      setState(() => _inspection = true);
    }
  }

  void _history() {
    unawaited(c.loadHistory());
    showDialog<void>(
      context: context,
      builder: (context) => ListenableBuilder(
        listenable: c,
        builder: (context, _) => McDialog(
          title: 'Recent runs',
          children: [
            if (c.history.isEmpty)
              Text(c.readingHistory ? 'Reading…' : 'No runs recorded.'),
            for (final run in c.history)
              ListTile(
                title: Text(run.name),
                subtitle: Text(
                  '${executableRunLabel(run)} · ${run.requestedAt.toLocal()}',
                ),
                onTap: () => showExecutableRunDetails(context, run),
              ),
            if (c.canLoadHistory || c.readingHistory)
              McAction(
                label: c.readingHistory ? 'Reading…' : 'Load more',
                onPressed: c.readingHistory
                    ? null
                    : () => unawaited(c.loadHistory()),
              ),
            if (c.problem != null)
              McStatus(title: c.problem!, tone: McStatusTone.error),
          ],
        ),
      ),
    );
  }

  Widget _runAction() {
    final run = c.selectedRun;
    return McAction(
      label: c.changing
          ? 'Working…'
          : run != null && !run.terminal
          ? 'Stop waiting'
          : 'Run',
      icon: run != null && !run.terminal ? Icons.link_off : Icons.play_arrow,
      emphasis: McActionEmphasis.primary,
      onPressed: c.canChange && c.selected != null && !c.uncertain
          ? () => unawaited(
              run != null && !run.terminal ? c.stopWaiting() : c.run(),
            )
          : null,
    );
  }

  Widget _inspector(BuildContext context, VoidCallback close) {
    final value = c.selected, run = c.selectedRun;
    return McInspector(
      title: value?.name ?? 'Executable',
      onClose: close,
      footer: value == null
          ? null
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                McAction(
                  label: 'Edit',
                  icon: Icons.edit_outlined,
                  onPressed: c.canChange ? () => _edit(value) : null,
                ),
                _runAction(),
              ],
            ),
      children: [
        if (value == null)
          const Text('Select an executable.')
        else ...[
          if (run != null) ...[
            McStatus(
              title: executableRunLabel(run),
              detail: run.problem,
              tone: run.phase == ExecutableRunPhase.failed
                  ? McStatusTone.error
                  : McStatusTone.neutral,
            ),
            const SizedBox(height: 12),
            McAction(
              label: 'Run details',
              onPressed: () => showExecutableRunDetails(context, run),
            ),
            const SizedBox(height: 16),
          ],
          _detail(context, 'Executable', value.executable),
          _detail(context, 'Working directory', value.workingDirectory),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text('Arguments (${value.arguments.length})'),
            children: [
              for (var i = 0; i < value.arguments.length; i++)
                _detail(
                  context,
                  'Argument ${i + 1}',
                  value.arguments[i].isEmpty ? '(empty)' : value.arguments[i],
                ),
            ],
          ),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('Environment'),
            children: [
              for (final row in value.environment)
                _detail(
                  context,
                  row.name,
                  row.value == null
                      ? 'Remove child variable'
                      : row.value!.isEmpty
                      ? '(empty)'
                      : row.value!,
                ),
            ],
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (context, _) => LayoutBuilder(
      builder: (context, box) {
        final scale = MediaQuery.textScalerOf(context).scale(1),
            compact = box.maxWidth < 1100 * scale,
            narrow = box.maxWidth < 760 * scale;
        return Scaffold(
          key: _scaffold,
          backgroundColor: Colors.transparent,
          endDrawer: Drawer(
            width: 440,
            child: ListenableBuilder(
              listenable: c,
              builder: (context, _) => _inspector(
                context,
                () => _scaffold.currentState?.closeEndDrawer(),
              ),
            ),
          ),
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Column(
                  children: [
                    if (widget.fnis != null &&
                        widget.workspace?.selectedProfile != null)
                      FnisTool(
                        client: widget.fnis!,
                        workspaceId: widget.workspace!.id,
                        profileId: widget.workspace!.selectedProfile!.id,
                      ),
                    Expanded(
                      child: c.needsRead && (c.problem != null || c.uncertain)
                          ? SingleChildScrollView(
                              child: McSection(
                                title: 'Executable result',
                                children: [
                                  if (c.problem != null)
                                    McStatus(
                                      title: c.problem!,
                                      tone: McStatusTone.error,
                                    ),
                                  const SizedBox(height: 16),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      if (c.pendingLaunch != null ||
                                          c.pendingStop != null ||
                                          c.selectedRun != null)
                                        McAction(
                                          label: 'Read result',
                                          onPressed: c.changing
                                              ? null
                                              : () => unawaited(c.readRun()),
                                        ),
                                      if (c.pendingLaunch != null)
                                        McAction(
                                          label: 'Continue',
                                          onPressed: c.changing
                                              ? null
                                              : () => unawaited(
                                                  c.continueLaunch(),
                                                ),
                                        ),
                                      if (!c.uncertain)
                                        McAction(
                                          label: 'Refresh executables',
                                          onPressed: c.changing
                                              ? null
                                              : () => unawaited(
                                                  c.load(refresh: true),
                                                ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            )
                          : McCollection<String, ExecutablePreset>(
                              model: c.presets,
                              title: 'Executables',
                              filterLabel: 'Filter executables',
                              countLabel:
                                  '${c.presets.length} ${c.presets.length == 1 ? 'executable' : 'executables'}',
                              empty: 'No executables.',
                              actions: [
                                McIconAction(
                                  label: 'Add executable',
                                  icon: const Icon(Icons.add),
                                  onPressed: c.canChange
                                      ? () => _edit(null)
                                      : null,
                                ),
                                McIconMenu<String>(
                                  label: 'Executable options',
                                  onSelected: (v) {
                                    switch (v) {
                                      case 'edit':
                                        _edit(c.selected);
                                      case 'remove':
                                        unawaited(_remove(c.selected!));
                                      case 'history':
                                        _history();
                                    }
                                  },
                                  itemBuilder: (_) => [
                                    PopupMenuItem(
                                      value: 'edit',
                                      enabled:
                                          c.canChange && c.selected != null,
                                      child: const Text('Edit'),
                                    ),
                                    PopupMenuItem(
                                      value: 'remove',
                                      enabled:
                                          c.canChange && c.selected != null,
                                      child: const Text('Remove'),
                                    ),
                                    PopupMenuItem(
                                      value: 'history',
                                      enabled: c.connected,
                                      child: const Text('Recent runs'),
                                    ),
                                  ],
                                ),
                              ],
                              toolbar: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _runAction(),
                                  McAction(
                                    label: 'Details',
                                    icon: Icons.info_outline,
                                    onPressed: c.selected == null
                                        ? null
                                        : () => _details(compact),
                                  ),
                                ],
                              ),
                              columns: [
                                McColumn('Name', (v) => Text(v.name)),
                                McColumn(
                                  'Latest run',
                                  (v) =>
                                      Text(executableRunLabel(c.latest[v.id])),
                                ),
                                if (!narrow)
                                  McColumn(
                                    'Executable',
                                    (v) => Text(
                                      v.executable,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                              onSelect: c.select,
                              onActivate: (_) => _details(compact),
                              loading: c.reading,
                              problem: c.problem,
                              onLoad: c.canLoad
                                  ? () => unawaited(c.load())
                                  : null,
                              onRefresh:
                                  c.connected && !c.changing && !c.uncertain
                                  ? () => unawaited(c.load(refresh: true))
                                  : null,
                            ),
                    ),
                  ],
                ),
              ),
              if (!compact && _inspection) ...[
                const SizedBox(width: 16),
                SizedBox(
                  width: 380,
                  child: _inspector(
                    context,
                    () => setState(() => _inspection = false),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    ),
  );
}

Widget _detail(BuildContext context, String label, String value) => Padding(
  padding: const EdgeInsets.only(bottom: 16),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: 4),
      SelectableText(value),
    ],
  ),
);
