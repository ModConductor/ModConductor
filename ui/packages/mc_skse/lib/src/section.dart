import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

class SkseSection extends StatefulWidget {
  const SkseSection({
    super.key,
    required this.client,
    required this.workspaceId,
    required this.profileId,
  });
  final SkseClient client;
  final String workspaceId, profileId;
  @override
  State<SkseSection> createState() => _SkseSectionState();
}

class _SkseSectionState extends State<SkseSection> {
  SkseStatus? status;
  bool busy = false;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    unawaited(load());
  }

  @override
  void didUpdateWidget(covariant SkseSection old) {
    super.didUpdateWidget(old);
    if (old.workspaceId != widget.workspaceId ||
        old.profileId != widget.profileId)
      unawaited(load());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> load({bool start = false}) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final value = start
          ? await widget.client.start(widget.workspaceId, widget.profileId)
          : await widget.client.read(widget.workspaceId, widget.profileId);
      if (!mounted) return;
      setState(() => status = value);
      timer?.cancel();
      if (value.active || value.phase == SkseStatusPhase.waiting) {
        timer = Timer(const Duration(seconds: 1), () => unawaited(load()));
      }
    } on Exception {
      if (mounted)
        setState(
          () => status = const SkseStatus(
            SkseStatusPhase.failed,
            '',
            '',
            'SKSE status is unavailable',
            'Check the engine connection.',
          ),
        );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = status;
    final failed =
        value?.phase == SkseStatusPhase.failed ||
        value?.phase == SkseStatusPhase.unavailable;
    return McSection(
      title: 'Skyrim Script Extender',
      children: [
        McStatus(
          title:
              value?.status ??
              (busy ? 'Checking SKSE' : 'SKSE status is unavailable'),
          detail: value?.detail.isEmpty == false ? value!.detail : null,
          tone: failed ? McStatusTone.error : McStatusTone.neutral,
        ),
        if (value != null && value.gameVersion.isNotEmpty) ...[
          const SizedBox(height: McSpacing.medium),
          Text('Skyrim ${value.gameVersion} · SKSE ${value.componentVersion}'),
        ],
        const SizedBox(height: McSpacing.large),
        Wrap(
          spacing: McSpacing.medium,
          children: [
            McAction(
              label: 'Refresh',
              icon: Icons.refresh,
              onPressed: busy ? null : load,
            ),
            if (value?.phase == SkseStatusPhase.available || failed)
              McAction(
                label: 'Set up SKSE',
                icon: Icons.download,
                emphasis: McActionEmphasis.primary,
                onPressed: busy ? null : () => load(start: true),
              ),
          ],
        ),
      ],
    );
  }
}
