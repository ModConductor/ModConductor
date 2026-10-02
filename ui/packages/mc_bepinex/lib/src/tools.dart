import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_file_plans/mc_file_plans.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

class LoaderTools extends StatefulWidget {
  const LoaderTools({super.key, required this.client, required this.state});
  final BepInExClient client;
  final BepInExState state;
  @override
  State<LoaderTools> createState() => _LoaderToolsState();
}

class _LoaderToolsState extends State<LoaderTools> {
  final editor = GlobalKey<TextEditorToolboxState>();
  LoaderText? settings, log;
  String? problem;
  bool loading = false, saving = false;
  void close() => Navigator.pop(context);
  Future<void> requestClose() async {
    final current = editor.currentState;
    if (current == null)
      close();
    else
      await current.requestClose();
  }

  Future<void> read(bool edit) async {
    setState(() {
      loading = true;
      problem = null;
    });
    final state = widget.state;
    final reply = edit
        ? await widget.client.settings(state.workspace, state.profile)
        : await widget.client.log(state.workspace, state.profile);
    if (!mounted) return;
    setState(() {
      loading = false;
      switch (reply) {
        case LoaderValue(:final value):
          if (edit) {
            settings = value;
          } else {
            log = value;
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
    final state = widget.state;
    final reply = await widget.client.saveSettings(
      state.workspace,
      state.profile,
      settings!,
      content,
    );
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
  Widget build(BuildContext context) {
    final state = widget.state;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (popped, _) {
        if (!popped) unawaited(requestClose());
      },
      child: Dialog(
        child: SizedBox(
          width: 820,
          height: settings != null || log != null ? 620 : 300,
          child: McInspector(
            title: 'BepInEx',
            onClose: requestClose,
            children: [
              if (settings != null)
                TextEditorToolbox(
                  key: editor,
                  document: settings!.document,
                  name: 'BepInEx.cfg',
                  source: 'BepInEx',
                  saveLabel: 'Save settings',
                  problem: problem,
                  saving: saving,
                  onSave: save,
                  onClose: close,
                )
              else if (log != null)
                SingleChildScrollView(
                  child: SelectableText(log!.document.content),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: McSpacing.small,
                      runSpacing: McSpacing.small,
                      children: [
                        McAction(
                          label: 'Edit loader settings',
                          icon: Icons.settings_outlined,
                          onPressed: state.settingsAvailable && !loading
                              ? () => read(true)
                              : null,
                        ),
                        McAction(
                          label: 'Open loader log',
                          icon: Icons.article_outlined,
                          onPressed: state.logAvailable && !loading
                              ? () => read(false)
                              : null,
                        ),
                      ],
                    ),
                    if (loading) const LinearProgressIndicator(),
                    if (problem case final problem?)
                      McStatus(title: problem, tone: McStatusTone.error),
                    ExpansionTile(
                      title: const Text('Package details'),
                      children: [
                        McFactGroup(
                          title: 'Package',
                          rows: [
                            McFact(
                              'Package',
                              '${state.package.package.namespace}-${state.package.package.name}-${state.package.version}',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
