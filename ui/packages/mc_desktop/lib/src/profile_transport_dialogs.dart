import 'dart:async';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_workspaces/mc_workspaces.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

typedef CreatedProfileWorkspace = ({
  WorkspaceInfo workspace,
  ProfileInfo gameProfile,
});
typedef CreateProfileWorkspace = Future<CreatedProfileWorkspace?> Function(
  BuildContext context,
);

Future<String?> chooseProfileFile() async => (await openFile(
  acceptedTypeGroups: const [
    XTypeGroup(label: 'Mod Conductor profile', extensions: ['mcprof']),
  ],
))?.path;

Future<String?> chooseProfileDestination(String name) async =>
    (await getSaveLocation(
      suggestedName: name,
      acceptedTypeGroups: const [
        XTypeGroup(label: 'Mod Conductor profile', extensions: ['mcprof']),
      ],
    ))?.path;

class ProfileImportResult {
  const ProfileImportResult(this.workspace, this.profile);
  final WorkspaceInfo workspace;
  final String profile;
}

class ProfileImportDialog extends StatefulWidget {
  const ProfileImportDialog({
    super.key,
    required this.path,
    required this.client,
    required this.workspaces,
    required this.workspaceClient,
    required this.gameContexts,
    required this.createWorkspace,
  });

  final String path;
  final ProfileTransportClient client;
  final WorkspaceController workspaces;
  final WorkspacesClient workspaceClient;
  final GameContextsClient gameContexts;
  final CreateProfileWorkspace createWorkspace;

  @override
  State<ProfileImportDialog> createState() => _ProfileImportDialogState();
}

class _ProfileImportDialogState extends State<ProfileImportDialog> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  ProfileTransportPreview? preview;
  WorkspaceInfo? selectedWorkspace;
  List<ProfileInfo> gameProfiles = const [];
  ProfileInfo? selectedGameProfile;
  List<ProfileInfo> existing = const [];
  final manual = <int, String>{};
  String? problem;
  bool loading = true, busy = false;
  int choiceGeneration = 0;

  @override
  void initState() {
    super.initState();
    unawaited(load());
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> load() async {
    try {
      final read = await widget.client.inspect(widget.path);
      if (!mounted) return;
      final active = widget.workspaces.workspace;
      setState(() {
        preview = read;
        name.text = '${read.name} – Imported';
        loading = false;
      });
      await widget.workspaces.loadRecent();
      if (active != null) await chooseWorkspace(active);
    } on ProfileTransportException catch (error) {
      if (mounted)
        setState(() {
          problem = error.detail;
          loading = false;
        });
    }
  }

  Future<void> chooseWorkspace(WorkspaceInfo workspace) async {
    final generation = ++choiceGeneration;
    setState(() {
      selectedWorkspace = workspace;
      gameProfiles = const [];
      selectedGameProfile = null;
      existing = const [];
      problem = null;
    });
    try {
      final page = await widget.workspaceClient.read(workspace.id);
      if (!mounted || generation != choiceGeneration) return;
      final matches = <ProfileInfo>[];
      for (final profile in page.profiles) {
        final state = await widget.gameContexts.read(workspace.id, profile.id);
        final binding = state.binding;
        if (binding != null &&
            !binding.needsCheck &&
            binding.failure == null &&
            binding.evidence.problems.isEmpty &&
            binding.evidence.definitionId == preview?.game) {
          matches.add(profile);
        }
      }
      if (!mounted || generation != choiceGeneration) return;
      final chosen = matches
          .where((profile) => profile.id == page.workspace.selectedProfile?.id)
          .firstOrNull;
      setState(() {
        selectedWorkspace = page.workspace;
        gameProfiles = matches;
        selectedGameProfile = chosen ?? matches.firstOrNull;
        existing = page.profiles;
      });
    } on Exception {
      if (mounted && generation == choiceGeneration) {
        setState(() => problem = 'The target workspace could not be checked.');
      }
    }
  }

  Future<void> createWorkspace() async {
    final created = await widget.createWorkspace(context);
    if (!mounted || created == null) return;
    await widget.workspaces.loadRecent();
    await chooseWorkspace(created.workspace);
    if (mounted && selectedWorkspace?.id == created.workspace.id) {
      setState(() => selectedGameProfile = created.gameProfile);
    }
  }

  Future<void> chooseSource(ProfileSourceRequirement source) async {
    final path = await openFile();
    if (!mounted || path == null) return;
    setState(() => manual[source.index] = path.path);
  }

  Future<void> submit() async {
    if (busy || !form.currentState!.validate()) return;
    final workspace = selectedWorkspace;
    final game = selectedGameProfile;
    if (workspace == null || game == null) {
      setState(
        () => problem = 'Select a workspace with this game installation.',
      );
      return;
    }
    if (existing.any(
      (profile) => profile.name.toLowerCase() == name.text.trim().toLowerCase(),
    )) {
      setState(() => problem = 'Use a new profile name in this workspace.');
      return;
    }
    setState(() {
      busy = true;
      problem = null;
    });
    try {
      final imported = await widget.client.import(
        widget.path,
        workspace.id,
        game.id,
        name.text.trim(),
        manualSources: manual,
      );
      if (mounted)
        Navigator.pop(context, ProfileImportResult(workspace, imported));
    } on ProfileTransportException catch (error) {
      if (mounted) setState(() => problem = error.detail);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Form(
    key: form,
    child: ListenableBuilder(
      listenable: widget.workspaces,
      builder: (context, _) => McFormDialog(
        title: 'Import profile',
        action: busy ? 'Importing…' : 'Import profile',
        onSubmit: loading || busy || preview == null ? null : submit,
        canCancel: !busy,
        children: [
          if (loading)
            const McActionFeedback(
              kind: McActionFeedbackKind.pending,
              message: 'Reading profile file',
            ),
          if (preview case final value?) ...[
            Text(
              '${File(widget.path).uri.pathSegments.last} · ${value.modCount} mods',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: McSpacing.large),
            McNameField(controller: name, onSubmit: submit),
            const SizedBox(height: McSpacing.medium),
            McChoice<String?>(
              label: 'Workspace',
              value: selectedWorkspace?.id,
              choices: [null, ...widget.workspaces.recent.map((row) => row.id)],
              describe: (id) => id == null
                  ? 'Choose a workspace'
                  : widget.workspaces.recent
                        .firstWhere((row) => row.id == id)
                        .name,
              enabled: !busy,
              onChanged: (id) {
                final workspace = widget.workspaces.recent
                    .where((row) => row.id == id)
                    .firstOrNull;
                if (workspace != null) unawaited(chooseWorkspace(workspace));
              },
            ),
            McAction(
              label: 'Create new workspace',
              icon: Icons.add,
              onPressed: busy ? null : createWorkspace,
            ),
            if (widget.workspaces.nextWorkspace != null)
              McAction(
                label: 'Load more workspaces',
                onPressed: busy
                    ? null
                    : () => widget.workspaces.loadRecent(more: true),
              ),
            if (gameProfiles.length > 1) ...[
              const SizedBox(height: McSpacing.medium),
              McChoice<String?>(
                label: 'Game installation',
                value: selectedGameProfile?.id,
                choices: gameProfiles.map((value) => value.id).toList(),
                describe: (id) =>
                    gameProfiles.firstWhere((row) => row.id == id).name,
                enabled: !busy,
                onChanged: (id) => setState(
                  () => selectedGameProfile = gameProfiles
                      .where((row) => row.id == id)
                      .firstOrNull,
                ),
              ),
            ],
            if (selectedWorkspace != null && gameProfiles.isEmpty)
              const McActionFeedback(
                kind: McActionFeedbackKind.refusal,
                message: 'This workspace has no ready game installation.',
              ),
            for (final source in value.sources) ...[
              const SizedBox(height: McSpacing.small),
              McAction(
                label: manual.containsKey(source.index)
                    ? 'Change ${source.archiveName}'
                    : 'Choose ${source.archiveName}',
                onPressed: busy ? null : () => chooseSource(source),
              ),
            ],
            if (value.sources.isNotEmpty)
              Text(
                'Exact archives are required. Available Nexus files download after you select Import profile.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
          if (problem case final text?) ...[
            const SizedBox(height: McSpacing.medium),
            McActionFeedback(kind: McActionFeedbackKind.failure, message: text),
          ],
        ],
      ),
    ),
  );
}

class ProfileExportDialog extends StatefulWidget {
  const ProfileExportDialog({
    super.key,
    required this.client,
    required this.workspace,
    required this.profile,
    required this.chooseDestination,
  });
  final ProfileTransportClient client;
  final WorkspaceInfo workspace;
  final ProfileInfo profile;
  final Future<String?> Function(String name) chooseDestination;

  @override
  State<ProfileExportDialog> createState() => _ProfileExportDialogState();
}

class _ProfileExportDialogState extends State<ProfileExportDialog> {
  final name = TextEditingController();
  bool includeSaves = false, busy = false;
  String? problem;

  @override
  void initState() {
    super.initState();
    name.text = '${widget.profile.name}.mcprof';
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (busy) return;
    final fileName = name.text.trim();
    if (fileName.isEmpty || !fileName.toLowerCase().endsWith('.mcprof')) {
      setState(() => problem = 'Use a .mcprof file name.');
      return;
    }
    final path = await widget.chooseDestination(fileName);
    if (!mounted || path == null) return;
    setState(() {
      busy = true;
      problem = null;
    });
    try {
      await widget.client.export(
        widget.workspace.id,
        widget.profile.id,
        path,
        includeSaves: includeSaves,
      );
      if (mounted) Navigator.pop(context, path);
    } on ProfileTransportException catch (error) {
      if (mounted) setState(() => problem = error.detail);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => McFormDialog(
    title: 'Export profile',
    action: busy ? 'Exporting…' : 'Export profile',
    onSubmit: busy ? null : submit,
    canCancel: !busy,
    children: [
      Text(widget.profile.name, style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: McSpacing.large),
      TextField(
        controller: name,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'File name'),
        onSubmitted: (_) => submit(),
      ),
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Include save games'),
        value: includeSaves,
        onChanged: busy
            ? null
            : (value) => setState(() => includeSaves = value ?? false),
      ),
      if (busy)
        const McActionFeedback(
          kind: McActionFeedbackKind.pending,
          message: 'Exporting profile',
        ),
      if (problem case final text?)
        McActionFeedback(kind: McActionFeedbackKind.failure, message: text),
    ],
  );
}
