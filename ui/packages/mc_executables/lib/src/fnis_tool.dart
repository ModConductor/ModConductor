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
    this.changes,
  });

  final FnisClient client;
  final String workspaceId, profileId;
  final Listenable? changes;

  @override
  State<FnisTool> createState() => _FnisToolState();
}

class _FnisToolState extends State<FnisTool> {
  FnisStatus? status;
  String? problem;
  bool busy = false;
  int epoch = 0;
  bool readPending = false;
  StreamSubscription<FnisStatus>? runSubscription;
  String? observedRun;
  int observation = 0;
  int statusRevision = 0;
  bool recoveringRun = false;

  @override
  void initState() {
    super.initState();
    widget.changes?.addListener(_changed);
    unawaited(_read());
  }

  void _changed() {
    if (busy) {
      readPending = true;
    } else {
      unawaited(_read());
    }
  }

  @override
  void didUpdateWidget(FnisTool oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.changes != widget.changes) {
      oldWidget.changes?.removeListener(_changed);
      widget.changes?.addListener(_changed);
    }
    if (oldWidget.client == widget.client &&
        oldWidget.workspaceId == widget.workspaceId &&
        oldWidget.profileId == widget.profileId) {
      return;
    }
    epoch++;
    _stopObserving();
    status = null;
    problem = null;
    busy = false;
    readPending = false;
    unawaited(_read());
  }

  Future<void> _read() => _request(
    () => widget.client.read(widget.workspaceId, widget.profileId),
    reading: true,
  );

  Future<void> _run() => _request(
    () => widget.client.run(
      widget.workspaceId,
      widget.profileId,
      newOperationId(),
    ),
  );

  void _stopObserving() {
    observation++;
    final previous = runSubscription;
    runSubscription = null;
    observedRun = null;
    recoveringRun = false;
    if (previous != null) unawaited(previous.cancel());
  }

  void _accept(FnisStatus value) {
    statusRevision++;
    setState(() => status = value);
    final id = value.outputPhase == FnisOutputStatusPhase.running
        ? value.runId
        : null;
    if (id == observedRun) return;
    _stopObserving();
    if (id == null) return;
    observedRun = id;
    final current = epoch;
    final watching = observation;
    runSubscription = widget.client
        .observeRun(widget.workspaceId, widget.profileId, id)
        .listen(
          (event) {
            if (!_awaitingRun(current, watching, id) || event.runId != id) {
              return;
            }
            _accept(event);
          },
          onError: (Object _) {
            unawaited(_recoverRun(current, watching, id));
          },
          onDone: () {
            unawaited(_recoverRun(current, watching, id));
          },
          cancelOnError: true,
        );
  }

  bool _awaitingRun(int current, int watching, String id) =>
      mounted &&
      current == epoch &&
      watching == observation &&
      observedRun == id &&
      status?.runId == id &&
      status?.outputPhase == FnisOutputStatusPhase.running;

  Future<void> _recoverRun(int current, int watching, String id) async {
    if (!_awaitingRun(current, watching, id) || recoveringRun) return;
    recoveringRun = true;
    try {
      final recovered = await widget.client.read(
        widget.workspaceId,
        widget.profileId,
      );
      if (!_awaitingRun(current, watching, id)) return;
      if (recovered.runId != id ||
          recovered.outputPhase != FnisOutputStatusPhase.running) {
        _accept(recovered);
        setState(() => problem = null);
        return;
      }
    } on Object {
      if (!_awaitingRun(current, watching, id)) return;
    }
    _stopObserving();
    statusRevision++;
    setState(() {
      status = null;
      problem = 'FNIS run status is unavailable.';
    });
  }

  Future<void> _request(
    Future<FnisStatus> Function() action, {
    bool reading = false,
  }) async {
    if (busy) return;
    final current = epoch;
    final revision = statusRevision;
    setState(() {
      busy = true;
      problem = null;
    });
    try {
      final value = await action();
      if (mounted && current == epoch) {
        if (!reading || revision == statusRevision) _accept(value);
      }
    } on Object {
      if (mounted && current == epoch && status != null) {
        setState(
          () => problem = 'The FNIS request failed. Refresh its status.',
        );
      }
    } finally {
      if (mounted && current == epoch) {
        setState(() => busy = false);
        if (readPending) {
          readPending = false;
          unawaited(_read());
        }
      }
    }
  }

  @override
  void dispose() {
    widget.changes?.removeListener(_changed);
    _stopObserving();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = status;
    if (value == null && problem == null) return const SizedBox.shrink();
    if (value != null && value.outputStatus.isEmpty) {
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
