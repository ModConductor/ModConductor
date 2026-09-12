import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_collections/mc_ui_collections.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'archive_facts.dart';

class _EntryRow {
  const _EntryRow(this.path, this.parent, this.name, this.entry);
  final String path, name;
  final String? parent;
  final InspectedEntry? entry;
  bool get directory => entry?.directory ?? true;
}

class ArchiveContentsView extends StatefulWidget {
  const ArchiveContentsView({
    super.key,
    required this.artifact,
    required this.client,
    required this.onBack,
  });
  final Artifact artifact;
  final ArtifactsClient client;
  final VoidCallback onBack;
  @override
  State<ArchiveContentsView> createState() => _ArchiveContentsViewState();
}

class _ArchiveContentsViewState extends State<ArchiveContentsView> {
  final pane = GlobalKey<ScaffoldState>();
  final model = McCollectionModel<String, _EntryRow>(
    idOf: (e) => e.path,
    labelOf: (e) => e.name,
    parentOf: (e) => e.parent,
    isBranch: (e) => e.directory,
  );
  ArchiveRead? pending;
  InspectedArchive? manifest;
  String? problem;
  bool loading = false, inspected = false;
  int epoch = 0;
  @override
  void initState() {
    super.initState();
    unawaited(load());
  }

  void cancel() {
    ++epoch;
    final previous = pending;
    pending = null;
    if (previous != null)
      unawaited(previous.cancel().onError<Exception>((_, _) {}));
    if (mounted)
      setState(() {
        loading = false;
        problem = 'Archive reading stopped.';
      });
  }

  @override
  void dispose() {
    ++epoch;
    final previous = pending;
    if (previous != null)
      unawaited(previous.cancel().onError<Exception>((_, _) {}));
    model.dispose();
    super.dispose();
  }

  Future<void> load() async {
    final current = ++epoch;
    setState(() {
      loading = true;
      problem = null;
    });
    final read = widget.client.readContents(widget.artifact);
    pending = read;
    try {
      final result = await read.result;
      if (!mounted || current != epoch) return;
      final rows = <String, _EntryRow>{};
      for (final entry in result.entries) {
        for (var i = 1; i <= entry.components.length; ++i) {
          final path = entry.components.take(i).join('/');
          final value = i == entry.components.length ? entry : null;
          if (!rows.containsKey(path) || value != null) {
            rows[path] = _EntryRow(
              path,
              i == 1 ? null : entry.components.take(i - 1).join('/'),
              entry.components[i - 1],
              value,
            );
          }
        }
      }
      model.apply(upserts: rows.values, evicted: model.ids.toList());
      for (final row in rows.values) {
        if (row.directory && row.parent == null && !model.expanded(row.path))
          model.toggle(row.path);
      }
      setState(() {
        manifest = result;
        loading = false;
        pending = null;
      });
    } on Exception catch (error) {
      if (mounted && current == epoch)
        setState(() {
          loading = false;
          pending = null;
          problem = error is ArtifactProblem ? error.detail : error.toString();
          manifest = null;
          model.clear();
        });
    }
  }

  Widget inspector(BuildContext c, VoidCallback close) {
    final row = model.selected;
    return McInspector(
      title: row?.name ?? 'File',
      onClose: close,
      children: [
        if (row != null) ...[
          archiveFact(c, 'Path', row.path),
          if (!row.directory)
            archiveFact(c, 'Size', archiveSize(row.entry?.size)),
          archiveFact(c, 'Archive', widget.artifact.originalName),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext c) => LayoutBuilder(
    builder: (c, box) {
      final narrow = box.maxWidth < 1100 * MediaQuery.textScalerOf(c).scale(1);
      final files = manifest?.entries.where((e) => !e.directory).length ?? 0;
      return Scaffold(
        key: pane,
        backgroundColor: Colors.transparent,
        endDrawer: Drawer(
          width: 440,
          child: inspector(c, () => pane.currentState?.closeEndDrawer()),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                McIconAction(
                  label: 'Back to archives',
                  icon: const Icon(Icons.arrow_back),
                  onPressed: widget.onBack,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.artifact.originalName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(c).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: McCollection<String, _EntryRow>(
                      model: model,
                      title: 'Contents',
                      showTitle: !narrow,
                      showTree: true,
                      filterLabel: 'Filter contents',
                      filterEnabled: !loading && problem == null,
                      countLabel: manifest == null
                          ? ''
                          : '${manifest!.format} · $files ${files == 1 ? 'file' : 'files'} · ${archiveSize(manifest!.totalSize)}',
                      loading: loading,
                      onCancel: cancel,
                      onRefresh: loading ? null : () => unawaited(load()),
                      empty: loading ? 'Reading contents…' : 'No entries.',
                      emptyContent: problem == null
                          ? null
                          : SingleChildScrollView(
                              child: McStatus(
                                title: 'Cannot read archive',
                                detail: problem,
                              ),
                            ),
                      onSelect: (_) {
                        setState(() => inspected = true);
                        if (narrow) pane.currentState?.openEndDrawer();
                      },
                      columns: [
                        McColumn(
                          'Name',
                          (e) => McCollectionName(
                            e.name,
                            icon: e.directory ? Icons.folder_outlined : null,
                          ),
                        ),
                        if (!narrow)
                          McColumn(
                            'Size',
                            (e) => Text(
                              e.directory ? '' : archiveSize(e.entry?.size),
                            ),
                            width: 100,
                          ),
                      ],
                    ),
                  ),
                  if (!narrow && inspected && model.selected != null) ...[
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 360,
                      child: inspector(
                        c,
                        () => setState(() => inspected = false),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
