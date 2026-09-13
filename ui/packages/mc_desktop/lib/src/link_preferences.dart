import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

class NexusLinkPreferences extends StatefulWidget {
  const NexusLinkPreferences({super.key, required this.client});
  final LinkSetupClient? client;
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
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => McFormDialog(
        title: windows
            ? 'Remove MC from Windows Settings?'
            : 'Remove Nexus link setup?',
        action: windows ? 'Remove from Windows Settings' : 'Remove link setup',
        onSubmit: () => Navigator.pop(c, true),
        children: [
          Text(
            windows ? 'Choose another default app in Windows Settings.' : 'The previous default app will be restored only if Mod Conductor is still the default.',
          ),
        ],
      ),
    );
    if (yes == true && mounted && widget.client != null)
      await run(widget.client!.remove);
  }

  @override
  Widget build(BuildContext context) {
    final value = status, client = widget.client;
    final windows = value?.windows ?? Platform.isWindows;
    final enabled = client != null && !busy;
    return McSection(
      title: 'Nexus download links',
      children: [
        const Text('Open Mod Manager Download links with Mod Conductor.'),
        const SizedBox(height: 16),
        Text(switch (value?.available) {
          true =>
            windows
                ? 'Available in Windows Settings'
                : 'Link setup is available',
          false =>
            windows ? 'Not added to Windows Settings' : 'Link setup is off',
          null => 'Link setup cannot be checked',
        }),
        const SizedBox(height: 4),
        Text(
          'Default app: ${switch (value?.defaultApp) {
            NexusLinkDefault.modConductor => 'Mod Conductor',
            NexusLinkDefault.anotherApp => 'Another app',
            NexusLinkDefault.none => 'Not set',
            _ => 'Cannot check',
          }}',
        ),
        if (windows) ...[
          const SizedBox(height: 16),
          const Text('Choose the default app in Windows Settings.'),
        ],
        if (!windows && value?.changed == true) ...[
          const SizedBox(height: 16),
          const Text(
            'The default app has changed. Removing MC will keep your current choice.',
          ),
        ],
        if (failed || value?.problem != null) ...[
          const SizedBox(height: 16),
          McStatus(
            title: value?.problem ?? 'The Nexus link setup could not be checked. Check the engine connection.',
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
                label: windows
                    ? 'Add to Windows Settings'
                    : 'Use Mod Conductor',
                emphasis: McActionEmphasis.primary,
                onPressed: enabled
                    ? () => run(() => client.add(Platform.resolvedExecutable))
                    : null,
              ),
            if (value?.canRemove == true)
              McAction(
                label: windows
                    ? 'Remove from Windows Settings'
                    : 'Remove link setup',
                onPressed: enabled ? remove : null,
              ),
            if (windows)
              McAction(
                label: 'Open Windows Settings',
                icon: Icons.open_in_new,
                emphasis: value?.available == true
                    ? McActionEmphasis.primary
                    : McActionEmphasis.secondary,
                onPressed: enabled ? () => run(client.openSettings) : null,
              ),
            McAction(
              label: 'Check default app',
              icon: Icons.refresh,
              onPressed: enabled ? refresh : null,
            ),
          ],
        ),
      ],
    );
  }
}
