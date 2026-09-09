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
  });
  final ProfileDataClient client;
  final String workspace;
  final ProfileInfo profile;
  @override
  State<ProfileSaveFiles> createState() => _ProfileSaveFilesState();
}

class _ProfileSaveFilesState extends State<ProfileSaveFiles> {
  final model = McCollectionModel<String, ProfileSaveEntry>(
    idOf: (entry) => entry.name,
    labelOf: (entry) => entry.name,
  );
  List<String> path = [];
  String? next, problem;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    unawaited(read());
  }

  Future<void> read({bool more = false}) async {
    if (busy) return;
    setState(() {
      busy = true;
      problem = null;
    });
    try {
      final page = await widget.client.saveFiles(
        widget.workspace,
        widget.profile.id,
        path,
        after: more ? next : null,
      );
      if (!mounted) return;
      if (!more) model.clear();
      model.apply(upserts: page.entries);
      next = page.next;
    } on Exception catch (error) {
      if (mounted) {
        problem = error is ProfileDataProblem
            ? error.detail
            : 'The save files could not be read.';
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void folder(List<String> value) {
    if (busy) return;
    path = value;
    model.clear();
    next = null;
    unawaited(read());
  }

  @override
  void dispose() {
    model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => McDialog(
    title: '${widget.profile.name} save files',
    children: [
      SizedBox(
        width: 680,
        height: 340,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (path.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: McAction(
                  label: 'Up',
                  icon: Icons.arrow_upward,
                  onPressed: busy
                      ? null
                      : () => folder(path.sublist(0, path.length - 1)),
                ),
              ),
            if (path.isNotEmpty)
              Text(path.join('/'), overflow: TextOverflow.ellipsis),
            if (problem != null)
              McStatus(title: problem!, tone: McStatusTone.error),
            Expanded(
              child: McCollection<String, ProfileSaveEntry>(
                model: model,
                title: 'Save files',
                showTitle: false,
                filterLabel: 'Filter loaded files',
                countLabel:
                    '${model.length} ${model.length == 1 ? 'entry' : 'entries'}${next != null ? ' loaded' : ''}',
                empty: busy ? 'Reading save files…' : 'No save files.',
                onRefresh: busy ? null : () => unawaited(read()),
                onLoad: busy || next == null
                    ? null
                    : () => unawaited(read(more: true)),
                columns: [
                  McColumn(
                    'Name',
                    (entry) => entry.directory
                        ? McAction(
                            label: entry.name,
                            icon: Icons.folder_outlined,
                            onPressed: busy
                                ? null
                                : () => folder([...path, entry.name]),
                          )
                        : Tooltip(
                            message: entry.name,
                            child: Text(
                              entry.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                    interactive: true,
                  ),
                  McColumn(
                    'Size',
                    (entry) =>
                        Text(entry.directory ? 'Folder' : '${entry.bytes} B'),
                    width: 95,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
