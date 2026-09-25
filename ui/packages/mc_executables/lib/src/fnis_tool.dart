import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

class FnisTool extends StatefulWidget {
  const FnisTool({
    super.key,
    required this.client,
    required this.workspaceId,
    required this.profileId,
  });

  final FnisClient client;
  final String workspaceId, profileId;

  @override
  State<FnisTool> createState() => _FnisToolState();
}

class _FnisToolState extends State<FnisTool> {
  FnisStatus? status;
  String? problem;
  bool busy = false;
  int epoch = 0;
  StreamSubscription<FnisStatus>? runSubscription;

  @override
  void initState() {
    super.initState();
    unawaited(_read());
  }

  @override
  void didUpdateWidget(FnisTool oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.client == widget.client &&
        oldWidget.workspaceId == widget.workspaceId &&
        oldWidget.profileId == widget.profileId) {
      return;
    }
    epoch++;
    final previous = runSubscription;
    if (previous != null) unawaited(previous.cancel());
    runSubscription = null;
    status = null;
    problem = null;
    busy = false;
    unawaited(_read());
  }

  Future<void> _read() =>
      _request(() => widget.client.read(widget.workspaceId, widget.profileId));

  Future<void> _run() async {
    final id = newOperationId();
    await _request(
      () => widget.client.run(widget.workspaceId, widget.profileId, id),
      onResult: (value) {
        if (value.outputPhase != FnisOutputStatusPhase.running ||
            value.runId != id) {
          return;
        }
        final current = epoch;
        runSubscription = widget.client
            .observeRun(widget.workspaceId, widget.profileId, id)
            .listen(
              (event) {
                if (!mounted || current != epoch || event.runId != id) return;
                setState(() => status = event);
              },
              onError: (Object _) {
                if (mounted && current == epoch) {
                  setState(() => problem = 'FNIS run result is unavailable.');
                }
              },
            );
      },
    );
  }

  Future<void> _request(
    Future<FnisStatus> Function() action, {
    void Function(FnisStatus)? onResult,
  }) async {
    if (busy) return;
    final current = epoch;
    setState(() {
      busy = true;
      problem = null;
    });
    try {
      final value = await action();
      if (mounted && current == epoch) {
        setState(() => status = value);
        onResult?.call(value);
      }
    } on Object {
      if (mounted && current == epoch && status != null) {
        setState(
          () => problem = 'The FNIS request failed. Refresh its status.',
        );
      }
    } finally {
      if (mounted && current == epoch) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    final previous = runSubscription;
    if (previous != null) unawaited(previous.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = status;
    if (value == null && problem == null) return const SizedBox.shrink();
    if (value != null &&
        value.phase != FnisStatusPhase.ready &&
        value.phase != FnisStatusPhase.updateAvailable &&
        value.phase != FnisStatusPhase.sourceUnavailable &&
        value.outputPhase != FnisOutputStatusPhase.running) {
      return const SizedBox.shrink();
    }
    final warning = value?.exitCode != null && value!.exitCode != 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: McSection(
        title: 'FNIS',
        children: [
          if (value != null)
            McStatus(
              title: value.outputStatus,
              detail: value.outputDetail.isEmpty ? null : value.outputDetail,
              tone: warning || value.outputPhase == FnisOutputStatusPhase.failed
                  ? McStatusTone.error
                  : McStatusTone.neutral,
            ),
          if (problem != null)
            McStatus(title: problem!, tone: McStatusTone.error),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              McAction(
                label: 'Run FNIS',
                icon: Icons.play_arrow,
                emphasis: McActionEmphasis.primary,
                onPressed: busy || value?.canRun != true
                    ? null
                    : () => unawaited(_run()),
              ),
              if (value?.canCancelRun == true)
                McAction(
                  label: 'Cancel',
                  onPressed: busy
                      ? null
                      : () => unawaited(
                          _request(
                            () => widget.client.cancelRun(
                              widget.workspaceId,
                              widget.profileId,
                            ),
                          ),
                        ),
                ),
              McIconAction(
                label: 'Refresh FNIS status',
                icon: const Icon(Icons.refresh),
                onPressed: busy ? null : () => unawaited(_read()),
              ),
            ],
          ),
          if (value?.runId != null) _runDetails(value!),
        ],
      ),
    );
  }

  Widget _runDetails(FnisStatus value) => Material(
    type: MaterialType.transparency,
    child: ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: const Text('Last run'),
      subtitle: value.exitCode == null
          ? null
          : Text('Exit code ${value.exitCode}'),
      children: [
        if (value.standardOutput.isNotEmpty)
          _log('Output', value.standardOutput),
        if (value.standardError.isNotEmpty) _log('Errors', value.standardError),
        if (value.runLog.isNotEmpty) _log('FNIS log', value.runLog),
      ],
    ),
  );

  Widget _log(String title, String content) =>
      ListTile(title: Text(title), subtitle: SelectableText(content));
}
