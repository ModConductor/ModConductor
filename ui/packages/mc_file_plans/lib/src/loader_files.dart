import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'text_editor.dart';

class LoaderFilesDialog extends StatefulWidget {
  const LoaderFilesDialog({
    super.key,
    required this.name,
    required this.settingsFiles,
    required this.readSettings,
    required this.saveSettings,
    required this.readLog,
    required this.logAvailable,
    this.settingsLabel = 'Edit settings',
    this.logLabel = 'View log',
    this.details,
  });
  final String name;
  final List<String> settingsFiles;
  final Future<LoaderReply<LoaderText>> Function(String) readSettings;
  final Future<LoaderReply<LoaderText>> Function(String, LoaderText, String)
  saveSettings;
  final Future<LoaderReply<LoaderText>> Function() readLog;
  final bool logAvailable;
  final String settingsLabel, logLabel;
  final Widget? details;
  @override
  State<LoaderFilesDialog> createState() => _LoaderFilesDialogState();
}

class _LoaderFilesDialogState extends State<LoaderFilesDialog> {
  final editor = GlobalKey<TextEditorToolboxState>();
  LoaderText? settings, log;
  String? filename, problem;
  bool loading = false, saving = false;
  void close() => Navigator.pop(context);
  Future<void> requestClose() async {
    final current = editor.currentState;
    if (current == null) {
      close();
    } else {
      await current.requestClose();
    }
  }

  Future<void> read(String? name) async {
    setState(() {
      loading = true;
      problem = null;
    });
    final reply = name == null
        ? await widget.readLog()
        : await widget.readSettings(name);
    if (!mounted) return;
    setState(() {
      loading = false;
      switch (reply) {
        case LoaderValue(:final value):
          if (name == null) {
            log = value;
          } else {
            filename = name;
            settings = value;
          }
        case LoaderProblem(:final message):
          problem = message;
      }
    });
  }

  Future<bool> save(String content) async {
    setState(() {
      saving = true;
      problem = null;
    });
    final reply = await widget.saveSettings(filename!, settings!, content);
    if (!mounted) return false;
    bool saved = false;
    setState(() {
      saving = false;
      switch (reply) {
        case LoaderValue(:final value):
          settings = value;
          saved = true;
        case LoaderProblem(:final message):
          problem = message;
      }
    });
    return saved;
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (popped, _) {
      if (!popped) unawaited(requestClose());
    },
    child: Dialog(
      child: SizedBox(
        width: 820,
        height: settings != null || log != null ? 620 : 300,
        child: McInspector(
          title: widget.name,
          onClose: requestClose,
          children: [
            if (settings != null)
              TextEditorToolbox(
                key: editor,
                document: settings!.document,
                name: filename!,
                source: widget.name,
                saveLabel: 'Save settings',
                problem: problem,
                saving: saving,
                onSave: save,
                onClose: () async {
                  if (widget.settingsFiles.length == 1) {
                    close();
                    return;
                  }
                  setState(() {
                    settings = null;
                    problem = null;
                  });
                },
              ),
            if (log != null)
              SingleChildScrollView(
                child: SelectableText(log!.document.content),
              ),
            if (settings == null && log == null) ...[
              Wrap(
                spacing: McSpacing.medium,
                runSpacing: McSpacing.small,
                children: [
                  for (final name in widget.settingsFiles)
                    McAction(
                      label: widget.settingsFiles.length == 1
                          ? widget.settingsLabel
                          : name,
                      icon: Icons.edit_outlined,
                      onPressed: loading ? null : () => read(name),
                    ),
                  McAction(
                    label: widget.logLabel,
                    icon: Icons.subject_outlined,
                    onPressed: loading || !widget.logAvailable
                        ? null
                        : () => read(null),
                  ),
                ],
              ),
              if (loading) const LinearProgressIndicator(),
              if (problem != null)
                McStatus(title: problem!, tone: McStatusTone.error),
              ?widget.details,
            ],
          ],
        ),
      ),
    ),
  );
}
