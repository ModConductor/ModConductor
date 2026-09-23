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
  bool busy = false;
  String? problem;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    unawaited(load());
  }

  @override
  void didUpdateWidget(covariant SkyrimSetupSection old) {
    super.didUpdateWidget(old);
    if (old.workspaceId != widget.workspaceId ||
        old.profileId != widget.profileId) {
      timer?.cancel();
      status = null;
      selection = const SkyrimSetupSelection();
      unawaited(load());
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void schedule(SkyrimSetupStatus value) {
    timer?.cancel();
    if (value.active) {
      timer = Timer(const Duration(seconds: 1), () => unawaited(load()));
    } else if (value.consentRecorded &&
        value.canContinue &&
        value.phase != SkyrimSetupStatusPhase.failed) {
      timer = Timer(
        Duration.zero,
        () => unawaited(
          change(
            () => widget.client.continueSetup(
              widget.workspaceId,
              widget.profileId,
            ),
          ),
        ),
      );
    }
  }

  Future<void> change(Future<SkyrimSetupStatus> Function() action) async {
    if (busy) return;
    setState(() {
      busy = true;
      problem = null;
    });
    SkyrimSetupStatus? next;
    try {
      next = await action();
      if (!mounted) return;
      setState(() {
        final wasCancelled = status?.phase == SkyrimSetupStatusPhase.cancelled;
        status = next;
        if (next!.consentRecorded) {
          selection = next.selection;
        } else if (next.ready ||
            (next.phase == SkyrimSetupStatusPhase.cancelled && !wasCancelled)) {
          selection = const SkyrimSetupSelection();
        }
      });
    } on Exception {
      if (mounted)
        setState(() => problem = 'Skyrim setup could not be updated.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
    if (next != null && mounted) schedule(next);
  }

  Future<void> load() => change(
    () => widget.client.read(
      widget.workspaceId,
      widget.profileId,
      selection: selection,
    ),
  );

  void selectAction(String id, SkyrimSetupAction action) {
    if (busy || status?.consentRecorded == true) return;
    setState(() {
      selection = selection.withAction(id, action);
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
    setState(() => selection = selection.withEnbArchive(file.path));
    await load();
  }

  Future<void> review() async {
    final current = status;
    if (busy || current == null || !current.canStart || !selection.canReview)
      return;
    final primary = current.changes.where((item) => !item.supporting).toList();
    final support = current.changes.where((item) => item.supporting).toList();
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => McDialog(
        title: 'Review Skyrim setup',
        contentWidth: 620,
        children: [
          McChangeSummary(
            changes: [
              for (final item in primary)
                McChangeEntry(item.title, item.detail, item.source),
            ],
          ),
          if (support.isNotEmpty) ...[
            const SizedBox(height: McSpacing.large),
            Text(
              'Also required',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: McSpacing.small),
            for (final item in support)
              Text('${item.detail} ${item.title.toLowerCase()}'),
          ],
        ],
        actions: [
          McAction(
            label: 'Back',
            onPressed: () => Navigator.pop(context, false),
          ),
          McAction(
            key: const ValueKey('apply-skyrim-setup'),
            label: 'Apply changes',
            emphasis: McActionEmphasis.primary,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    if (approved != true || !mounted) return;
    await change(
      () => widget.client.start(
        widget.workspaceId,
        widget.profileId,
        selection: selection,
        planToken: current.planToken,
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
    final locked = value?.consentRecorded == true;
    final components =
        value?.components
            .where((item) => const ['skse', 'enb', 'fnis'].contains(item.id))
            .toList() ??
        [];
    final failed =
        value != null &&
        (value.phase == SkyrimSetupStatusPhase.failed ||
            value.phase == SkyrimSetupStatusPhase.recoveryRequired);
    final canReview =
        !busy && !locked && value?.canStart == true && selection.canReview;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (problem != null) ...[
          McStatus(title: problem!, tone: McStatusTone.error),
          const SizedBox(height: McSpacing.medium),
        ],
        if (value != null &&
            value.status.isNotEmpty &&
            value.status != 'Choose an ENBSeries archive') ...[
          McStatus(
            title: value.status,
            detail: value.detail.isEmpty ? null : value.detail,
            tone: failed ? McStatusTone.error : McStatusTone.neutral,
          ),
          const SizedBox(height: McSpacing.medium),
        ],
        if (components.isNotEmpty) ...[
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
          const SizedBox(height: McSpacing.medium),
        ],
        Wrap(
          spacing: McSpacing.medium,
          runSpacing: McSpacing.medium,
          children: [
            if (selection.hasChange && !locked)
              McAction(
                label: 'Clear choices',
                onPressed: busy
                    ? null
                    : () {
                        setState(
                          () => selection = const SkyrimSetupSelection(),
                        );
                        unawaited(load());
                      },
              ),
            McAction(
              key: const ValueKey('refresh-skyrim-setup'),
              label: 'Refresh',
              icon: Icons.refresh,
              onPressed: busy ? null : load,
            ),
            McAction(
              key: const ValueKey('review-skyrim-setup'),
              label: 'Review changes',
              emphasis: McActionEmphasis.primary,
              onPressed: canReview ? review : null,
            ),
            if (value?.canCancel == true)
              McAction(
                label: 'Cancel setup',
                onPressed: busy ? null : cancelSetup,
              ),
            if (failed && value.canContinue)
              McAction(
                label: 'Try again',
                onPressed: busy
                    ? null
                    : () => change(
                        () => widget.client.continueSetup(
                          widget.workspaceId,
                          widget.profileId,
                        ),
                      ),
              ),
          ],
        ),
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
      updating: action == SkyrimSetupAction.update,
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
      onUpdate: item.installed
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
              setState(() => selection = selection.withEnbArchive(null));
              unawaited(load());
            }
          : null,
      archiveName: selection.enbArchivePath?.split(RegExp(r'[/\\]')).last,
      archiveRequired: item.id == 'enb' && selection.needsEnbArchive,
    );
  }
}
