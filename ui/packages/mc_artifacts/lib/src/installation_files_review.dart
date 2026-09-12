import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_collections/mc_ui_collections.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'archive_facts.dart';

class InstallationFilesReview extends StatefulWidget {
  const InstallationFilesReview({
    super.key,
    required this.files,
    required this.narrow,
    required this.onSelect,
    this.onInclude,
    this.enabled = true,
  });
  final List<InstallationReviewedFile> files;
  final bool narrow, enabled;
  final ValueChanged<InstallationReviewedFile> onSelect;
  final void Function(InstallationReviewedFile, bool)? onInclude;
  @override
  State<InstallationFilesReview> createState() =>
      _InstallationFilesReviewState();
}

class _InstallationFilesReviewState extends State<InstallationFilesReview> {
  final rows = McCollectionModel<String, InstallationReviewedFile>(
    idOf: (f) => jsonEncode(f.destination),
    labelOf: (f) => f.destination.join('/'),
  );
  bool replacements = false;
  List<InstallationReviewedFile> get visible => replacements
      ? widget.files.where((f) => f.replaces.isNotEmpty).toList()
      : widget.files;
  void apply() {
    final current = visible,
        ids = current.map((f) => jsonEncode(f.destination)).toSet();
    rows.apply(
      upserts: current,
      evicted: rows.ids.where((id) => !ids.contains(id)).toList(),
    );
  }

  @override
  void initState() {
    super.initState();
    apply();
  }

  @override
  void didUpdateWidget(InstallationFilesReview old) {
    super.didUpdateWidget(old);
    if (!identical(old.files, widget.files)) apply();
  }

  @override
  void dispose() {
    rows.dispose();
    super.dispose();
  }

  String get count {
    final files = visible, selected = files.where((f) => f.included).toList();
    final sizes = {for (final f in selected) f.index: f.bytes};
    final bytes = sizes.values.fold(0, (sum, value) => sum + value);
    return '${widget.onInclude == null ? '${files.length} ${files.length == 1 ? 'file' : 'files'}' : '${selected.length} included'} · ${archiveSize(bytes)}';
  }

  @override
  Widget build(
    BuildContext c,
  ) => McCollection<String, InstallationReviewedFile>(
    model: rows,
    title: 'Files to install',
    showTitle: !widget.narrow,
    showTree: false,
    compactFilter: widget.narrow,
    filterLabel: 'Filter files',
    countLabel: count,
    onSelect: widget.onSelect,
    filterActions: [
      McMenuAction<bool>(
        label: replacements
            ? 'Replacements (${widget.files.where((f) => f.replaces.isNotEmpty).length})'
            : 'All files',
        choices: const [false, true],
        describe: (v) => v
            ? 'Replacements (${widget.files.where((f) => f.replaces.isNotEmpty).length})'
            : 'All files',
        onSelected: (v) => setState(() {
          replacements = v;
          apply();
        }),
      ),
    ],
    columns: [
      if (widget.onInclude != null)
        McColumn(
          '',
          (f) => Checkbox(
            value: f.included,
            onChanged: widget.enabled
                ? (value) => widget.onInclude!(f, value!)
                : null,
          ),
          width: 48,
          interactive: true,
        ),
      McColumn('Destination', (f) => McCollectionName(f.destination.join('/'))),
      if (!widget.narrow) McColumn('From', (f) => Text(f.choice), width: 190),
      if (!widget.narrow)
        McColumn('Size', (f) => Text(archiveSize(f.bytes)), width: 90),
    ],
  );
}

List<Widget> installationReviewedFacts(
  BuildContext c,
  InstallationReviewedFile file,
) => [
  archiveFact(c, 'Selected source', file.source.join('/')),
  archiveFact(c, 'From', file.choice),
  archiveFact(c, 'Size', archiveSize(file.bytes)),
  if (file.replaces.isNotEmpty)
    archiveFact(
      c,
      'Replaces',
      file.replaces.map((p) => p.join('/')).join('\n'),
    ),
];
