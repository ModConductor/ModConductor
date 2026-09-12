import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'controller.dart';
import 'archive_facts.dart';

String downloadLabel(ArtifactDownload d) => switch (d.phase) {
  DownloadPhase.queued => 'Queued',
  DownloadPhase.running => 'Downloading',
  DownloadPhase.waiting => 'Waiting to retry',
  DownloadPhase.paused => 'Paused',
  DownloadPhase.failed => 'Download failed',
  DownloadPhase.complete => 'Available',
};
String downloadSize(ArtifactDownload d) => d.total == null
    ? archiveSize(d.bytes)
    : '${archiveSize(d.bytes)} / ${archiveSize(d.total)}';

class DownloadControls extends StatefulWidget {
  const DownloadControls({
    super.key,
    required this.artifact,
    required this.controller,
  });
  final Artifact artifact;
  final ArtifactController controller;
  @override
  State<DownloadControls> createState() => _DownloadControlsState();
}

class _DownloadControlsState extends State<DownloadControls> {
  Timer? timer;
  void schedule() {
    timer?.cancel();
    final due = widget.artifact.download!.retryAt;
    if (due != null && due.isAfter(DateTime.now())) {
      timer = Timer(
        due.difference(DateTime.now()) + const Duration(milliseconds: 1),
        () {
          if (mounted) setState(() {});
        },
      );
    }
  }

  @override
  void initState() {
    super.initState();
    schedule();
  }

  @override
  void didUpdateWidget(DownloadControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.artifact.download!.retryAt !=
        widget.artifact.download!.retryAt)
      schedule();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> change(DownloadAction action) async {
    if (action == DownloadAction.restart &&
        widget.artifact.download!.bytes > 0) {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (c) => McFormDialog(
          title: 'Restart download?',
          action: 'Restart',
          onSubmit: () => Navigator.pop(c, true),
          children: [
            Text(widget.artifact.originalName),
            const SizedBox(height: 16),
            Text(
              'Restart removes the ${archiveSize(widget.artifact.download!.bytes)} partial copy and downloads the file from the beginning.',
            ),
          ],
        ),
      );
      if (accepted != true || !mounted) return;
    }
    await widget.controller.change(
      'Changing download',
      (client, _) => client.controlDownload(widget.artifact, action),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.artifact.download!;
    if (d.phase == DownloadPhase.complete) return const SizedBox.shrink();
    final action = d.active
        ? DownloadAction.pause
        : d.restartRequired
        ? DownloadAction.restart
        : DownloadAction.resume;
    final enabled =
        widget.controller.canEdit &&
        (action == DownloadAction.pause ||
            d.retryAt == null ||
            !d.retryAt!.isAfter(DateTime.now()));
    return McAction(
      label: switch (action) {
        DownloadAction.pause => 'Pause',
        DownloadAction.restart => 'Restart',
        DownloadAction.resume =>
          d.phase == DownloadPhase.failed ? 'Retry' : 'Resume',
      },
      icon: switch (action) {
        DownloadAction.pause => Icons.pause,
        DownloadAction.restart => Icons.restart_alt,
        DownloadAction.resume => Icons.play_arrow,
      },
      emphasis: action == DownloadAction.resume
          ? McActionEmphasis.primary
          : McActionEmphasis.secondary,
      onPressed: enabled ? () => unawaited(change(action)) : null,
    );
  }
}

class DownloadDetails extends StatelessWidget {
  const DownloadDetails({super.key, required this.download});
  final ArtifactDownload download;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (download.phase != DownloadPhase.complete) ...[
        LinearProgressIndicator(
          value: download.total == null || download.total == 0
              ? null
              : (download.bytes / download.total!).clamp(0, 1),
        ),
        const SizedBox(height: 8),
        Text(downloadSize(download)),
        const SizedBox(height: 24),
        if (download.retryAt != null) ...[
          Text(
            'Retry after ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(download.retryAt!))}.',
          ),
          const SizedBox(height: 16),
        ],
      ],
      archiveFact(context, 'Source', download.source),
    ],
  );
}

String downloadChecksum(ArtifactDownload d) => d.checksumMatched
    ? 'Matched supplied SHA-256'
    : d.expectedSha256 == null
    ? 'No checksum supplied'
    : 'Expected SHA-256 supplied';
