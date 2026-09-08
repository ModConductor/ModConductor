import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_collections/mc_ui_collections.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'output_controller.dart';

class UnfinishedOutputReview extends StatefulWidget {
  const UnfinishedOutputReview({super.key, required this.controller});
  final OutputController controller;
  @override
  State<UnfinishedOutputReview> createState() => _UnfinishedOutputReviewState();
}

class _UnfinishedOutputReviewState extends State<UnfinishedOutputReview> {
  final _files = McCollectionModel<String, OutputActionEntry>(
    idOf: (entry) => jsonEncode([entry.file.locationId, ...entry.file.path]),
    labelOf: (entry) => entry.file.path.join('/'),
  );
  late final List<String> _ids;
  String? _selected;
  @override
  void initState() {
    super.initState();
    _ids = widget.controller.scope?.pendingActions.toList() ?? [];
    if (_ids.length == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_read(_ids.single));
      });
    }
  }

  @override
  void dispose() {
    _files.dispose();
    super.dispose();
  }

  void _showResult() {
    if (!mounted) return;
    final result = widget.controller.result;
    _files.clear();
    if (result?.id == _selected) _files.apply(upserts: result!.entries);
    setState(() {});
  }

  Future<void> _read(String id) async {
    setState(() => _selected = id);
    widget.controller.pendingAction = id;
    await widget.controller.checkResult();
    _showResult();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final controller = widget.controller;
      final result = controller.result?.id == _selected
          ? controller.result
          : null;
      return McDialog(
        title: 'Unfinished output review',
        children: [
          if (_ids.length > 1)
            controller.changing
                ? Text('Review ${_ids.indexOf(_selected!) + 1}')
                : McChoice<String?>(
                    label: 'Review',
                    value: _selected,
                    choices: [null, ..._ids],
                    describe: (id) => id == null
                        ? 'Choose a review'
                        : 'Review ${_ids.indexOf(id) + 1}',
                    onChanged: (id) {
                      if (!controller.changing && id != null) {
                        unawaited(_read(id));
                      }
                    },
                  ),
          if (result != null) ...[
            Text(
              result.published
                  ? 'The mod version is saved.'
                  : 'No mod version has been saved.',
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 280,
              child: McCollection<String, OutputActionEntry>(
                model: _files,
                title: 'Selected output files',
                filterLabel: 'Filter selected files',
                countLabel:
                    '${result.entries.length} selected ${result.entries.length == 1 ? 'file' : 'files'}',
                showTitle: false,
                columns: [
                  McColumn('File', (entry) => Text(entry.file.path.join('/'))),
                  McColumn(
                    'Review',
                    (entry) => Text(switch (entry.disposition) {
                      OutputDisposition.pending => 'Not finished',
                      OutputDisposition.changed => 'Changed; kept',
                      OutputDisposition.kept => 'Kept',
                      OutputDisposition.discarded => 'Discarded',
                      OutputDisposition.moved => 'Moved',
                      OutputDisposition.copied => 'Copy saved',
                    }),
                    width: 120,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (controller.problem != null)
            McStatus(title: controller.problem!, tone: McStatusTone.error),
          if (controller.changing) const LinearProgressIndicator(),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              McAction(
                label: 'Read result',
                onPressed: _selected == null || controller.changing
                    ? null
                    : () => _read(_selected!),
              ),
              McAction(
                label: 'Continue review',
                onPressed:
                    result == null || result.complete || controller.changing
                    ? null
                    : () async {
                        await controller.resume(result.id);
                        _showResult();
                      },
              ),
            ],
          ),
        ],
      );
    },
  );
}
