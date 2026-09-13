import 'package:flutter/material.dart';

import 'archive_facts.dart';

import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

class ArchiveFile {
  const ArchiveFile(this.path, this.length);
  final String path;
  final int length;
}

typedef ArchiveChooser = Future<ArchiveFile?> Function();

class ArchiveFileForm extends StatefulWidget {
  const ArchiveFileForm({
    super.key,
    required this.chooseFile,
    required this.workspacePath,
    this.original,
    this.initialFile,
  });
  final ArchiveFile? initialFile;
  final ArchiveChooser chooseFile;
  final String workspacePath;
  final Artifact? original;
  @override
  State<ArchiveFileForm> createState() => _ArchiveFileFormState();
}

class _ArchiveFileFormState extends State<ArchiveFileForm> {
  late ArchiveFile? file = widget.initialFile;
  ArtifactStorage storage = ArtifactStorage.reference;
  String? problem;
  bool choosing = false;
  Future<void> choose() async {
    setState(() {
      choosing = true;
      problem = null;
    });
    try {
      final chosen = await widget.chooseFile();
      if (mounted && chosen != null) setState(() => file = chosen);
    } on Exception {
      if (mounted) setState(() => problem = 'The file could not be read.');
    } finally {
      if (mounted) setState(() => choosing = false);
    }
  }

  @override
  Widget build(BuildContext context) => McFormDialog(
    title: widget.original == null ? 'Add archive' : 'Locate archive',
    action: widget.original == null ? 'Add archive' : 'Use file',
    onSubmit: file == null || choosing
        ? null
        : () => Navigator.pop(context, (file: file!, storage: storage)),
    children: [
      if (widget.original != null) ...[
        Text(widget.original!.originalName),
        const SizedBox(height: 16),
      ],
      if (file != null) ...[
        SelectableText(file!.path),
        const SizedBox(height: 12),
      ],
      McAction(
        label: 'Choose file',
        icon: Icons.folder_open,
        onPressed: choosing ? null : choose,
      ),
      const SizedBox(height: 16),
      if (widget.original == null) ...[
        McChoice<ArtifactStorage>(
          label: 'Storage',
          value: storage,
          choices: ArtifactStorage.values,
          describe: (v) => v == ArtifactStorage.reference
              ? 'Keep in current folder'
              : 'Copy to library',
          onChanged: (v) => setState(() => storage = v),
        ),
        const SizedBox(height: 12),
        Text(
          storage == ArtifactStorage.copy
              ? 'Copies ${file == null ? 'the archive' : archiveSize(file!.length)} to this workspace. The original file stays unchanged.'
              : 'Uses the file at its current location. The original file stays unchanged.',
        ),
        if (storage == ArtifactStorage.copy) ...[
          const SizedBox(height: 16),
          Text('Workspace', style: Theme.of(context).textTheme.bodySmall),
          SelectableText(widget.workspacePath),
        ],
      ] else
        const Text(
          'The file must match the saved archive. Its name and location can differ.',
        ),
      if (problem != null) ...[
        const SizedBox(height: 16),
        McStatus(title: problem!, tone: McStatusTone.error),
      ],
    ],
  );
}

class ArchiveLinkForm extends StatefulWidget {
  const ArchiveLinkForm({
    super.key,
    required this.client,
    required this.artifact,
  });
  final ArtifactsClient client;
  final Artifact artifact;
  @override
  State<ArchiveLinkForm> createState() => _ArchiveLinkFormState();
}

class _ArchiveLinkFormState extends State<ArchiveLinkForm> {
  final Map<String, ArtifactLink> links = {};
  String? next, chosen, problem;
  bool loading = false, loaded = false;
  Future<void> load() async {
    setState(() {
      loading = true;
      problem = null;
    });
    try {
      final page = await widget.client.linkOptions(
        widget.artifact.workspaceId,
        after: next,
      );
      if (!mounted) return;
      setState(() {
        for (final link in page.entries) {
          links[link.modId] = link;
        }
        next = page.next;
        loaded = true;
        chosen ??= links.keys.firstOrNull;
      });
    } on Exception catch (error) {
      if (mounted)
        setState(
          () => problem = error is ArtifactProblem
              ? error.detail
              : 'The installed mods could not be read.',
        );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  Widget build(BuildContext context) => McFormDialog(
    title: 'Link installed mod',
    action: 'Link mod',
    onSubmit: chosen == null || loading
        ? null
        : () => Navigator.pop(context, links[chosen]),
    children: [
      Text(widget.artifact.originalName),
      const SizedBox(height: 16),
      if (chosen != null) ...[
        McChoice<String>(
          label: 'Installed mod',
          value: chosen!,
          choices: links.keys.toList(),
          describe: (id) => links[id]!.modName,
          onChanged: (id) => setState(() => chosen = id),
        ),
        const SizedBox(height: 16),
        Text('Saved version', style: Theme.of(context).textTheme.bodySmall),
        SelectableText(links[chosen]!.versionLabel),
        const SizedBox(height: 16),
      ] else if (loaded)
        const Text('No installed mods have a saved version.'),
      if (next != null || problem != null)
        McAction(
          label: problem != null ? 'Retry' : 'Load more mods',
          onPressed: loading ? null : load,
        ),
      if (loading) const LinearProgressIndicator(),
      if (problem != null) McStatus(title: problem!, tone: McStatusTone.error),
      const SizedBox(height: 12),
      const Text(
        'Records that this archive supplied the selected version. This does not install or check the mod.',
      ),
    ],
  );
}
