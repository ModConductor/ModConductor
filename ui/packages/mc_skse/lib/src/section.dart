import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mc_artifacts/mc_artifacts.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

class SkyrimSetupSection extends StatefulWidget {
  const SkyrimSetupSection({
    super.key,
    required this.client,
    required this.chooseArchive,
    required this.workspaceId,
    required this.profileId,
  });

  final SkyrimSetupClient client;
  final ArchiveChooser chooseArchive;
  final String workspaceId, profileId;

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
    if (old.workspaceId != widget.workspaceId ||
        old.profileId != widget.profileId ||
        old.client != widget.client) {
      ++_epoch;
      _watchReconnect?.cancel();
      unawaited(_watch?.cancel() ?? Future.value());
      status = null;
      _updateEvidenceFresh = false;
      selection = const SkyrimSetupSelection();
      userEdited = false;
      busy = false;
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

  SkyrimSetupAction actionFor(String id) => switch (id) {
    'skse' => selection.skse,
    'enb' => selection.enb,
    'fnis' => selection.fnis,
    _ => SkyrimSetupAction.unchanged,
  };

  @override
  Widget build(BuildContext context) {
    final value = status;
    final locked =
        value?.active == true ||
        (value?.canCancel == true &&
            value?.phase != SkyrimSetupStatusPhase.failed);
    final components =
        value?.components
            .where((item) => const ['skse', 'enb', 'fnis'].contains(item.id))
            .toList() ??
        [];
    final failed =
        value != null &&
        (value.phase == SkyrimSetupStatusPhase.failed ||
            value.phase == SkyrimSetupStatusPhase.recoveryRequired);
    final canApply =
        !busy &&
        !locked &&
        (value?.canStart == true ||
            value?.phase == SkyrimSetupStatusPhase.failed) &&
        selection.canApply;
    final actions = Wrap(
      spacing: McSpacing.medium,
      runSpacing: McSpacing.medium,
      children: [
        McAction(
          key: const ValueKey('apply-skyrim-setup'),
          label: 'Apply',
          emphasis: McActionEmphasis.primary,
          onPressed: canApply ? apply : null,
        ),
        if (selection.hasChange && !locked)
          McAction(
            label: 'Clear choices',
            onPressed: busy
                ? null
                : () {
                    setState(() {
                      selection = const SkyrimSetupSelection();
                      userEdited = true;
                    });
                    unawaited(load());
                  },
          ),
        McAction(
          key: const ValueKey('refresh-skyrim-setup'),
          label: 'Refresh',
          icon: Icons.refresh,
          onPressed: busy ? null : load,
        ),
        if (value?.canCancel == true)
          McAction(label: 'Cancel setup', onPressed: busy ? null : cancelSetup),
        if (failed && value.canContinue)
          McAction(
            label: value.phase == SkyrimSetupStatusPhase.recoveryRequired
                ? 'Continue recovery'
                : 'Try again',
            onPressed: busy
                ? null
                : () => change(
                    () => value.phase == SkyrimSetupStatusPhase.recoveryRequired
                        ? widget.client.continueSetup(
                            widget.workspaceId,
                            widget.profileId,
                          )
                        : widget.client.start(
                            widget.workspaceId,
                            widget.profileId,
                            selection: selection,
                          ),
                  ),
          ),
      ],
    );
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (problem != null) ...[
          McStatus(title: problem!, tone: McStatusTone.error),
          const SizedBox(height: McSpacing.medium),
        ],
        if (value != null &&
            value.status.isNotEmpty &&
            !(value.phase == SkyrimSetupStatusPhase.cancelled &&
                selection.hasChange) &&
            value.status != 'Choose an ENBSeries archive') ...[
          McStatus(
            title: value.status,
            detail: value.detail.isEmpty ? null : value.detail,
            tone: failed ? McStatusTone.error : McStatusTone.neutral,
          ),
          const SizedBox(height: McSpacing.medium),
        ],
        actions,
        if (components.isNotEmpty) ...[
          const SizedBox(height: McSpacing.medium),
          LayoutBuilder(
            builder: (_, bounds) => bounds.maxWidth < 680
                ? const SizedBox.shrink()
                : const Padding(
                    padding: EdgeInsets.symmetric(vertical: McSpacing.small),
                    child: Row(
                      children: [
                        Expanded(flex: 33, child: Text('Component')),
                        Expanded(flex: 24, child: Text('Current')),
                        Expanded(flex: 43, child: Text('Install')),
                      ],
                    ),
                  ),
          ),
          for (final item in components) _component(item, locked),
        ],
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) => McSection(
        title: 'Skyrim setup',
        children: [
          if (constraints.hasBoundedHeight)
            Flexible(child: SingleChildScrollView(child: content))
          else
            content,
        ],
      ),
    );
  }

  Widget _component(SkyrimSetupComponent item, bool locked) {
    final action = actionFor(item.id);
    final updateVersion = _updateEvidenceFresh ? item.updateVersion : null;
    final selected = switch (action) {
      SkyrimSetupAction.install => true,
      SkyrimSetupAction.remove => false,
      _ => item.installed,
    };
    const skseIcon =
        'https://shared.fastly.steamstatic.com/community_assets/images/apps/365720/48eaa1815ac4beddc4d7c9fec6c2517f6f0b718e.jpg';
    const enbIcon = 'http://enbdev.com/header_logo.gif';
    const fnisIcon = 'https://images.nexusmods.com/mod-headers/1704/3038.jpg';
    final kind = switch (item.id) {
      'skse' => 'Script extender',
      'enb' => 'Graphics injector',
      _ => 'Animation tool',
    };
    return McComponentChoiceRow(
      key: ValueKey('setup-${item.id}'),
      name: item.name,
      kind: kind,
      current: item.installed ? 'Installed' : 'Not installed',
      installed: item.installed,
      selected: selected,
      updating: action == SkyrimSetupAction.update && updateVersion != null,
      updateVersion: updateVersion,
      iconUrl: switch (item.id) {
        'skse' => skseIcon,
        'enb' => enbIcon,
        'fnis' => fnisIcon,
        _ => null,
      },
      iconHeaders: item.id == 'enb'
          ? const {'Referer': 'http://enbdev.com/'}
          : null,
      iconFit: item.id == 'fnis' ? BoxFit.cover : BoxFit.contain,
      enabled: !busy && !locked,
      onToggle: () => selectAction(
        item.id,
        selected
            ? (item.installed
                  ? SkyrimSetupAction.remove
                  : SkyrimSetupAction.unchanged)
            : (item.installed
                  ? SkyrimSetupAction.unchanged
                  : SkyrimSetupAction.install),
      ),
      onOpenPage: () => unawaited(widget.client.openProjectPage(item.id)),
      onUpdate: item.installed && updateVersion != null
          ? () => selectAction(
              item.id,
              action == SkyrimSetupAction.update
                  ? SkyrimSetupAction.unchanged
                  : SkyrimSetupAction.update,
            )
          : null,
      onChooseArchive: item.id == 'enb' ? chooseEnbArchive : null,
      onClearArchive: item.id == 'enb'
          ? () {
              setState(() {
                selection = selection.withEnbArchive(null);
                userEdited = true;
              });
              unawaited(load());
            }
          : null,
      archiveName: selection.enbArchivePath?.split(RegExp(r'[/\\]')).last,
      archiveRequired: item.id == 'enb' && selection.needsEnbArchive,
    );
  }
}
