import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mc_artifacts/mc_artifacts.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

part 'setup_view.dart';
part 'setup_actions.dart';
part 'setup_component.dart';

SkyrimSetupAction _actionFor(SkyrimSetupSelection selection, String id) =>
    switch (id) {
      'skse' => selection.skse,
      'enb' => selection.enb,
      'fnis' => selection.fnis,
      _ => SkyrimSetupAction.unchanged,
    };

class SkyrimSetupSection extends StatefulWidget {
  const SkyrimSetupSection({
    super.key,
    required this.client,
    required this.chooseArchive,
    required this.workspaceId,
    required this.profileId,
    this.contextRevision,
  });

  final SkyrimSetupClient client;
  final ArchiveChooser chooseArchive;
  final String workspaceId, profileId;
  final int? contextRevision;

  @override
  State<SkyrimSetupSection> createState() => _SkyrimSetupSectionState();
}

class _SkyrimSetupSectionState extends State<SkyrimSetupSection> {
  SkyrimSetupStatus? status;
  SkyrimSetupSelection selection = const SkyrimSetupSelection();
  bool userEdited = false;
  bool busy = false;
  String? problem;
  StreamSubscription<SkyrimSetupStatus>? _watch;
  Timer? _watchReconnect;
  int _epoch = 0;
  int _watchAttempt = 0;
  bool _updateEvidenceFresh = false;

  @override
  void initState() {
    super.initState();
    _observe();
  }

  @override
  void didUpdateWidget(covariant SkyrimSetupSection old) {
    super.didUpdateWidget(old);
    final scopeChanged =
        old.workspaceId != widget.workspaceId ||
        old.profileId != widget.profileId ||
        old.client != widget.client;
    if (scopeChanged || old.contextRevision != widget.contextRevision) {
      ++_epoch;
      _watchReconnect?.cancel();
      unawaited(_watch?.cancel() ?? Future.value());
      _updateEvidenceFresh = false;
      problem = null;
      busy = false;
      if (scopeChanged) {
        status = null;
        selection = const SkyrimSetupSelection();
        userEdited = false;
      }
      _observe();
    }
  }

  @override
  void dispose() {
    ++_epoch;
    _watchReconnect?.cancel();
    unawaited(_watch?.cancel() ?? Future.value());
    super.dispose();
  }

  void _observe() {
    final epoch = _epoch;
    final attempt = ++_watchAttempt;
    _watchReconnect?.cancel();
    _watchReconnect = null;
    unawaited(_watch?.cancel() ?? Future.value());
    void reconnect() {
      if (!mounted || epoch != _epoch || attempt != _watchAttempt) return;
      setState(() {
        _updateEvidenceFresh = false;
        _clearUpdateChoices();
      });
      _watchReconnect?.cancel();
      _watchReconnect = Timer(const Duration(seconds: 1), () {
        if (mounted && epoch == _epoch && attempt == _watchAttempt) _observe();
      });
    }

    _watch = widget.client
        .watch(widget.workspaceId, widget.profileId, selection: selection)
        .listen(
          (next) {
            if (!mounted || epoch != _epoch || attempt != _watchAttempt) return;
            _accept(next);
          },
          onError: (Object _) {
            if (mounted && epoch == _epoch && attempt == _watchAttempt) {
              setState(() => problem = 'Skyrim setup updates are unavailable.');
              reconnect();
            }
          },
          onDone: reconnect,
          cancelOnError: true,
        );
  }

  void _accept(SkyrimSetupStatus next) {
    setState(() {
      final wasCancelled = status?.phase == SkyrimSetupStatusPhase.cancelled;
      status = next;
      _updateEvidenceFresh = true;
      if (next.canCancel && next.phase != SkyrimSetupStatusPhase.failed) {
        selection = next.selection;
        userEdited = false;
      } else if (next.ready ||
          (next.phase == SkyrimSetupStatusPhase.cancelled && !wasCancelled)) {
        selection = const SkyrimSetupSelection();
        userEdited = false;
      } else if (!userEdited) {
        selection = next.selection;
      }
      for (final id in const ['skse', 'enb', 'fnis']) {
        if (actionFor(id) == SkyrimSetupAction.update &&
            !next.components.any(
              (item) =>
                  item.id == id && item.installed && item.updateVersion != null,
            )) {
          selection = selection.withAction(id, SkyrimSetupAction.unchanged);
        }
      }
      problem = null;
    });
  }

  void _clearUpdateChoices() {
    for (final id in const ['skse', 'enb', 'fnis']) {
      if (actionFor(id) == SkyrimSetupAction.update) {
        selection = selection.withAction(id, SkyrimSetupAction.unchanged);
      }
    }
  }

  Future<void> change(Future<SkyrimSetupStatus> Function() action) async {
    if (busy) return;
    final epoch = ++_epoch;
    _watchReconnect?.cancel();
    unawaited(_watch?.cancel() ?? Future.value());
    setState(() {
      busy = true;
      problem = null;
      _updateEvidenceFresh = false;
    });
    try {
      final next = await action();
      if (!mounted || epoch != _epoch) return;
      _accept(next);
    } on Exception {
      if (mounted && epoch == _epoch) {
        setState(() {
          problem = 'Skyrim setup could not be updated.';
          _clearUpdateChoices();
        });
      }
    } finally {
      if (mounted && epoch == _epoch) {
        setState(() => busy = false);
        _observe();
      }
    }
  }

  Future<void> load() => change(
    () => widget.client.read(
      widget.workspaceId,
      widget.profileId,
      selection: selection,
    ),
  );

  void selectAction(String id, SkyrimSetupAction action) {
    if (busy ||
        status?.active == true ||
        (status?.canCancel == true &&
            status?.phase != SkyrimSetupStatusPhase.failed))
      return;
    setState(() {
      selection = selection.withAction(id, action);
      userEdited = true;
      if (id == 'enb' &&
          action != SkyrimSetupAction.install &&
          action != SkyrimSetupAction.update) {
        selection = selection.withEnbArchive(null);
      }
    });
    unawaited(load());
  }

  Future<void> chooseEnbArchive() async {
    if (busy) return;
    final file = await widget.chooseArchive();
    if (!mounted || file == null) return;
    setState(() {
      selection = selection.withEnbArchive(file.path);
      userEdited = true;
    });
    await load();
  }

  Future<void> apply() async {
    final current = status;
    if (busy || current == null || !selection.canApply) return;
    await change(
      () => widget.client.start(
        widget.workspaceId,
        widget.profileId,
        selection: selection,
      ),
    );
  }

  Future<void> cancelSetup() =>
      change(() => widget.client.cancel(widget.workspaceId, widget.profileId));

  SkyrimSetupAction actionFor(String id) => _actionFor(selection, id);

  void clearChoices() {
    setState(() {
      selection = const SkyrimSetupSelection();
      userEdited = true;
    });
    unawaited(load());
  }

  void clearEnbArchive() {
    setState(() {
      selection = selection.withEnbArchive(null);
      userEdited = true;
    });
    unawaited(load());
  }

  Future<void> retryOrContinue(SkyrimSetupStatus value) => change(
    () => value.phase == SkyrimSetupStatusPhase.recoveryRequired
        ? widget.client.continueSetup(widget.workspaceId, widget.profileId)
        : widget.client.start(
            widget.workspaceId,
            widget.profileId,
            selection: selection,
          ),
  );

  @override
  Widget build(BuildContext context) => _SkyrimSetupView(
    status: status,
    selection: selection,
    busy: busy,
    problem: problem,
    updateEvidenceFresh: _updateEvidenceFresh,
    onApply: apply,
    onClearChoices: clearChoices,
    onRefresh: load,
    onCancel: cancelSetup,
    onRetryOrContinue: retryOrContinue,
    onSelectAction: selectAction,
    onChooseEnbArchive: chooseEnbArchive,
    onClearEnbArchive: clearEnbArchive,
    onOpenProjectPage: (id) => unawaited(widget.client.openProjectPage(id)),
  );
}
