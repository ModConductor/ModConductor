import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

class FileProblemsDialog extends StatefulWidget {
  const FileProblemsDialog({super.key, required this.load});
  final Future<FilePlanProblems> Function(FilePlanCursor?) load;
  @override
  State<FileProblemsDialog> createState() => _FileProblemsDialogState();
}

class _FileProblemsDialogState extends State<FileProblemsDialog> {
  final _problems = <String>[];
  FilePlanCursor? _next;
  bool _loading = false, _loaded = false;
  String? _problem;
  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    if (_loading || (_loaded && _next == null)) return;
    setState(() {
      _loading = true;
      _problem = null;
    });
    try {
      final page = await widget.load(_next);
      if (!mounted) return;
      _problems.addAll(page.problems);
      _next = page.next;
      _loaded = true;
    } on Exception catch (error) {
      if (mounted) {
        _problem = error is FilePlanException
            ? error.detail
            : 'Could not load file problems.';
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => McDialog(
    title: 'File problems',
    children: [
      for (final problem in _problems)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(problem),
        ),
      if (_problem != null)
        McStatus(title: _problem!, tone: McStatusTone.error),
      if (_loading) const LinearProgressIndicator(),
      if (!_loaded || _next != null)
        TextButton(
          onPressed: _loading ? null : () => unawaited(_load()),
          child: Text(_problem == null ? 'Load more' : 'Retry'),
        ),
    ],
  );
}
