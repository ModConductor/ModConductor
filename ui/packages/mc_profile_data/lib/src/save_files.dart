import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_collections/mc_ui_collections.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

class ProfileSaveFiles extends StatefulWidget {
  const ProfileSaveFiles({
    super.key,
    required this.client,
    required this.workspace,
    required this.profile,
    required this.expected,
    required this.onChanged,
    this.headersId,
  });
  final ProfileDataClient client;
  final String workspace;
  final ProfileInfo profile;
  final ProfileDataRef expected;
  final String? headersId;
  final VoidCallback onChanged;
  @override
  State<ProfileSaveFiles> createState() => _ProfileSaveFilesState();
}

class _ProfileSaveFilesState extends State<ProfileSaveFiles> {
  final model = McCollectionModel<String, ProfileSaveGroupEntry>(
    idOf: (entry) => entry.id,
    labelOf: (entry) => entry.name,
  );
  ProfileSaveSource source = ProfileSaveSource.profile;
  ProfileSavePath? path;
  ProfileSaveInspection? inspection;
  ProfileDataRef? current;
  StreamSubscription<ProfileDataEvent>? action;
  Completer<void>? actionDone;
  String? next, problem;
  bool busy = false;
  int request = 0;

  @override
  void initState() {
    super.initState();
    current = widget.expected;
    model.addListener(_modelChanged);
    unawaited(read());
  }

  void _modelChanged() {
    if (mounted) setState(() {});
  }

  String describe(Object error, String fallback) => error is ProfileDataProblem
      ? error.detail
      : error is FormatException
      ? error.message
      : fallback;

  Future<void> read({bool more = false}) async {
    if (busy) return;
    final epoch = ++request;
    setState(() {
      busy = true;
      problem = null;
      if (!more) inspection = null;
    });
    try {
      final page = await widget.client.saveGroups(
        widget.workspace,
        widget.profile.id,
        source,
        after: more ? next : null,
      );
      if (!mounted || epoch != request) return;
      if (!more) model.clear();
      model.apply(upserts: page.entries);
      path = page.path;
      next = page.next;
    } on Exception catch (error) {
      if (mounted && epoch == request) {
        problem = describe(error, 'The save groups could not be read.');
      }
    } finally {
      if (mounted && epoch == request) setState(() => busy = false);
    }
  }

  void chooseSource(ProfileSaveSource value) {
    if (busy || value == source) return;
    source = value;
    model.clear();
    path = null;
    next = null;
    inspection = null;
    unawaited(read());
  }

  Future<void> inspect(ProfileSaveGroupEntry entry) async {
    inspection = null;
    problem = null;
    if (entry.kind != ProfileSaveEntryKind.save) {
      setState(() {});
      return;
    }
    final epoch = ++request;
    setState(() => busy = true);
    try {
      final value = await widget.client.inspectSave(
        widget.workspace,
        widget.profile.id,
        source,
        entry.name,
        headersId: widget.headersId,
      );
      if (mounted && epoch == request) inspection = value;
    } on Exception catch (error) {
      if (mounted && epoch == request) {
        problem = describe(error, 'The save could not be inspected.');
      }
    } finally {
      if (mounted && epoch == request) setState(() => busy = false);
    }
  }

  List<String> get selected {
    if (model.selectedIds.isEmpty ||
        model.selectedIds.any((id) => model[id]?.actionable != true)) {
      return const [];
    }
    return model.selectedIds.toList(growable: false);
  }

  Future<void> preview() async {
    final names = selected;
    if (busy || names.isEmpty || current == null) return;
    final kind = source == ProfileSaveSource.global
        ? ProfileSaveAction.copyToProfile
        : ProfileSaveAction.deleteFromProfile;
    setState(() {
      busy = true;
      problem = null;
    });
    ProfileSaveActionPreview value;
    try {
      value = await widget.client.previewSaveAction(current!, kind, names);
    } on Exception catch (error) {
      if (mounted) {
        setState(() {
          busy = false;
          problem = describe(error, 'The save action could not be previewed.');
        });
      }
      return;
    }
    if (!mounted) return;
    setState(() => busy = false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => McDialog(
        title: kind == ProfileSaveAction.copyToProfile
            ? 'Copy save to ${widget.profile.name}?'
            : 'Permanently delete save?',
        actions: [
          McAction(label: 'Cancel', onPressed: () => Navigator.pop(context)),
          McAction(
            label: kind == ProfileSaveAction.copyToProfile
                ? 'Copy to profile'
                : 'Delete permanently',
            emphasis: McActionEmphasis.primary,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
        children: [
          _fact(context, 'Source', _displayPath(value.source)),
          if (value.destination case final destination?)
            _fact(context, 'Destination', _displayPath(destination)),
          _fact(
            context,
            'Files',
            value.files.map((file) => file.name).join('\n'),
          ),
          if (kind == ProfileSaveAction.deleteFromProfile) ...[
            const McStatus(
              title: 'This deletion is permanent.',
              detail: 'Global saves will not be changed.',
            ),
            const SizedBox(height: 12),
          ],
          const Text(
            'If a selected file changes before this action starts, nothing will be changed.',
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) await apply(value);
  }

  Future<void> apply(ProfileSaveActionPreview preview) async {
    final done = Completer<void>();
    actionDone = done;
    setState(() {
      busy = true;
      problem = null;
    });
    var received = false;
    void finish() {
      if (!done.isCompleted) done.complete();
    }

    action = widget.client
        .applySaveAction(newOperationId(), preview.id, preview.expected)
        .listen(
          (event) {
            if (!mounted) return;
            if (event case ProfileDataResult()) {
              received = true;
              current = event.state.reference;
              problem = event.problem;
            }
            setState(() {});
          },
          onError: (Object error) {
            if (mounted) {
              problem = describe(
                error,
                'The save action could not be completed.',
              );
            }
            finish();
          },
          onDone: finish,
          cancelOnError: true,
        );
    if (mounted) setState(() {});
    await done.future;
    action = null;
    actionDone = null;
    if (!mounted) return;
    if (!received && problem == null) {
      problem =
          'The action result is unavailable. Read again before continuing.';
    }
    widget.onChanged();
    setState(() => busy = false);
    if (received && problem == null) await read();
  }

  Future<void> cancel() async {
    ++request;
    widget.onChanged();
    await action?.cancel();
    action = null;
    if (actionDone case final done? when !done.isCompleted) done.complete();
    if (mounted) {
      setState(() {
        busy = false;
        problem = 'The action was cancelled. Read again before continuing.';
      });
    }
  }

  @override
  void dispose() {
    ++request;
    unawaited(action?.cancel());
    if (actionDone case final done? when !done.isCompleted) done.complete();
    model.removeListener(_modelChanged);
    model.dispose();
    super.dispose();
  }

  String _displayPath(ProfileSavePath value) => value.windowsPath == null
      ? value.hostPath
      : '${value.windowsPath}\n${value.hostPath}';

  String size(int value) {
    if (value >= 1024 * 1024) {
      return '${(value / (1024 * 1024)).toStringAsFixed(1)} MiB';
    }
    if (value >= 1024) return '${(value / 1024).toStringAsFixed(1)} KiB';
    return '$value B';
  }

  Widget collection() => McCollection<String, ProfileSaveGroupEntry>(
    model: model,
    title: 'Save groups',
    showTitle: false,
    filterLabel: 'Filter loaded saves',
    countLabel:
        '${model.length} ${model.length == 1 ? 'entry' : 'entries'}${next != null ? ' loaded' : ''}',
    empty: busy ? 'Reading save groups…' : 'No save groups.',
    loading: busy,
    problem: problem,
    onRefresh: busy ? null : () => unawaited(read()),
    onLoad: busy || next == null ? null : () => unawaited(read(more: true)),
    onSelect: (entry) => unawaited(inspect(entry)),
    multiSelect: true,
    columns: [
      McColumn(
        'Save',
        (entry) => Row(
          children: [
            Icon(
              entry.kind == ProfileSaveEntryKind.save
                  ? Icons.save_outlined
                  : entry.kind == ProfileSaveEntryKind.directory
                  ? Icons.folder_outlined
                  : Icons.insert_drive_file_outlined,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(entry.name, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
      McColumn(
        'Files',
        (entry) => Text(entry.companion == null ? '1' : '2'),
        width: 56,
      ),
      McColumn(
        'Size',
        (entry) => Text(size(entry.bytes + entry.companionBytes)),
        width: 90,
      ),
    ],
    toolbar: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        SegmentedButton<ProfileSaveSource>(
          segments: const [
            ButtonSegment(
              value: ProfileSaveSource.profile,
              label: Text('Profile'),
            ),
            ButtonSegment(
              value: ProfileSaveSource.global,
              label: Text('Global'),
            ),
          ],
          selected: {source},
          onSelectionChanged: busy
              ? null
              : (value) => chooseSource(value.single),
        ),
        if (action != null)
          McAction(label: 'Cancel', onPressed: () => unawaited(cancel()))
        else
          McAction(
            label: source == ProfileSaveSource.global
                ? 'Copy to profile'
                : 'Delete',
            icon: source == ProfileSaveSource.global
                ? Icons.content_copy
                : Icons.delete_outline,
            onPressed: !busy && selected.isNotEmpty ? preview : null,
          ),
      ],
    ),
  );

  static Widget _fact(BuildContext context, String label, String value) =>
      Padding(
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

  Widget details(VoidCallback close, {bool actionInFooter = false}) {
    final value = inspection;
    final entry = value?.entry ?? model.selected;
    return McInspector(
      title: entry?.name ?? 'Save details',
      onClose: close,
      footer: actionInFooter
          ? action != null
                ? McAction(
                    label: 'Cancel',
                    onPressed: () => unawaited(cancel()),
                  )
                : McAction(
                    label: source == ProfileSaveSource.global
                        ? 'Copy to profile'
                        : 'Delete',
                    icon: source == ProfileSaveSource.global
                        ? Icons.content_copy
                        : Icons.delete_outline,
                    onPressed: !busy && selected.isNotEmpty ? preview : null,
                  )
          : null,
      children: [
        if (entry == null)
          const Text('Select a save to view its details.')
        else ...[
          _fact(context, 'Files', [entry.name, ?entry.companion].join('\n')),
          _fact(context, 'Size', size(entry.bytes + entry.companionBytes)),
          if (entry.problem case final detail?)
            McStatus(title: detail, tone: McStatusTone.error),
          if (value?.metadataProblem case final detail?)
            McStatus(title: 'Metadata unavailable', detail: detail),
          if (value?.metadata case final metadata?) ...[
            _fact(
              context,
              'Character',
              '${metadata.character} · Level ${metadata.level}',
            ),
            _fact(context, 'Location', metadata.location),
            _fact(context, 'Game time', metadata.gameTime),
            _fact(context, 'Save number', '${metadata.saveNumber}'),
            _fact(
              context,
              'Format',
              'Skyrim save ${metadata.headerVersion} · form ${metadata.formVersion} · ${metadata.compression.name.toUpperCase()}',
            ),
          ],
          if (value?.pluginCheckProblem case final detail?)
            McStatus(title: 'Plugin check unavailable', detail: detail)
          else if (value != null &&
              value.pluginIssues.isEmpty &&
              value.metadata != null)
            const McStatus(title: 'No missing or inactive plugins found.')
          else if (value != null && value.pluginIssues.isNotEmpty) ...[
            Text(
              'Plugin issues',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            for (final issue in value.pluginIssues)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(issue.name),
                subtitle: issue.source == null ? null : Text(issue.source!),
                trailing: Text(
                  issue.state == SavePluginState.missing
                      ? 'Missing'
                      : 'Inactive',
                ),
              ),
          ],
          const SizedBox(height: 16),
          const McStatus(
            title: 'Steam Cloud is not managed here.',
            detail: 'Cloud copies and remote state will not be changed.',
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: McDialog(
      title: '${widget.profile.name} saves',
      contentWidth: 1040,
      actions: [
        McAction(
          label: 'Close',
          onPressed: busy ? null : () => Navigator.pop(context),
        ),
      ],
      children: [
        if (path case final value?) ...[
          Text(
            _displayPath(value),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          height: 590,
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 760) {
                return inspection == null && model.selected == null
                    ? collection()
                    : details(() {
                        inspection = null;
                        model.clearSelection();
                      }, actionInFooter: true);
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: collection()),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 360,
                    child: details(() {
                      inspection = null;
                      model.clearSelection();
                    }),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    ),
  );
}
