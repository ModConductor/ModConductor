import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

class NexusLinkPreferencesLabels {
  const NexusLinkPreferencesLabels({
    required this.title,
    required this.description,
    required this.removeWindowsTitle,
    required this.removeTitle,
    required this.removeWindows,
    required this.remove,
    required this.chooseOtherDefault,
    required this.restoreDefault,
    required this.availableWindows,
    required this.available,
    required this.notAddedWindows,
    required this.off,
    required this.cannotCheck,
    required this.defaultApp,
    required this.modConductor,
    required this.anotherApp,
    required this.notSet,
    required this.cannotCheckDefault,
    required this.chooseDefaultWindows,
    required this.defaultChanged,
    required this.checkFailed,
    required this.addWindows,
    required this.useModConductor,
    required this.openWindows,
    required this.checkDefault,
  });

  final String title;
  final String description;
  final String removeWindowsTitle;
  final String removeTitle;
  final String removeWindows;
  final String remove;
  final String chooseOtherDefault;
  final String restoreDefault;
  final String availableWindows;
  final String available;
  final String notAddedWindows;
  final String off;
  final String cannotCheck;
  final String Function(String) defaultApp;
  final String modConductor;
  final String anotherApp;
  final String notSet;
  final String cannotCheckDefault;
  final String chooseDefaultWindows;
  final String defaultChanged;
  final String checkFailed;
  final String addWindows;
  final String useModConductor;
  final String openWindows;
  final String checkDefault;
}

class NexusLinkPreferences extends StatefulWidget {
  const NexusLinkPreferences({
    super.key,
    required this.client,
    required this.labels,
  });
  final LinkSetupClient? client;
  final NexusLinkPreferencesLabels labels;
  @override
  State<NexusLinkPreferences> createState() => _NexusLinkPreferencesState();
}

class _NexusLinkPreferencesState extends State<NexusLinkPreferences> {
  NexusLinkSetupStatus? status;
  bool busy = false, failed = false;
  int generation = 0;
  @override
  void initState() {
    super.initState();
    refresh();
  }

  @override
  void didUpdateWidget(NexusLinkPreferences oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.client, oldWidget.client)) {
      ++generation;
      busy = false;
      status = null;
      refresh();
    }
  }

  void refresh() {
    if (widget.client != null) run(widget.client!.read);
  }

  Future<void> run(Future<NexusLinkSetupStatus> Function() action) async {
    if (busy) return;
    final epoch = generation;
    setState(() {
      busy = true;
      failed = false;
    });
    try {
      final result = await action();
      if (mounted && epoch == generation) setState(() => status = result);
    } on LinkSetupProblem {
      if (mounted && epoch == generation) setState(() => failed = true);
    } finally {
      if (mounted && epoch == generation) setState(() => busy = false);
    }
  }

  Future<void> remove() async {
    final windows = status?.windows == true;
    final labels = widget.labels;
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => McFormDialog(
        title: windows ? labels.removeWindowsTitle : labels.removeTitle,
        action: windows ? labels.removeWindows : labels.remove,
        onSubmit: () => Navigator.pop(c, true),
        children: [
          Text(windows ? labels.chooseOtherDefault : labels.restoreDefault),
        ],
      ),
    );
    if (yes == true && mounted && widget.client != null)
      await run(widget.client!.remove);
  }

  @override
  Widget build(BuildContext context) {
    final labels = widget.labels;
    final value = status, client = widget.client;
    final windows = value?.windows ?? Platform.isWindows;
    final enabled = client != null && !busy;
    return McSection(
      title: labels.title,
      children: [
        Text(labels.description),
        const SizedBox(height: 16),
        Text(switch (value?.available) {
          true => windows ? labels.availableWindows : labels.available,
          false => windows ? labels.notAddedWindows : labels.off,
          null => labels.cannotCheck,
        }),
        const SizedBox(height: 4),
        Text(
          labels.defaultApp(switch (value?.defaultApp) {
            NexusLinkDefault.modConductor => labels.modConductor,
            NexusLinkDefault.anotherApp => labels.anotherApp,
            NexusLinkDefault.none => labels.notSet,
            _ => labels.cannotCheckDefault,
          }),
        ),
        if (windows) ...[
          const SizedBox(height: 16),
          Text(labels.chooseDefaultWindows),
        ],
        if (!windows && value?.changed == true) ...[
          const SizedBox(height: 16),
          Text(labels.defaultChanged),
        ],
        if (failed || value?.problem != null) ...[
          const SizedBox(height: 16),
          McStatus(
            title: value?.problem ?? labels.checkFailed,
            tone: McStatusTone.error,
          ),
        ],
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            if (value?.available == false ||
                (!windows && value?.changed == true))
              McAction(
                label: windows ? labels.addWindows : labels.useModConductor,
                emphasis: McActionEmphasis.primary,
                onPressed: enabled
                    ? () => run(() => client.add(Platform.resolvedExecutable))
                    : null,
              ),
            if (value?.canRemove == true)
              McAction(
                label: windows ? labels.removeWindows : labels.remove,
                onPressed: enabled ? remove : null,
              ),
            if (windows)
              McAction(
                label: labels.openWindows,
                icon: Icons.open_in_new,
                emphasis: value?.available == true
                    ? McActionEmphasis.primary
                    : McActionEmphasis.secondary,
                onPressed: enabled ? () => run(client.openSettings) : null,
              ),
            McAction(
              label: labels.checkDefault,
              icon: Icons.refresh,
              onPressed: enabled ? refresh : null,
            ),
          ],
        ),
      ],
    );
  }
}
