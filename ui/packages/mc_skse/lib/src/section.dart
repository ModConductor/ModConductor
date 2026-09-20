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
  bool includeFnis = false;
  bool busy = false;
  bool cancelling = false;
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
      status = null;
      includeFnis = false;
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

  Future<void> change(
    Future<SkyrimSetupStatus> Function() action, {
    bool preserveFnisChoice = false,
  }) async {
    if (busy) return;
    setState(() => busy = true);
    SkyrimSetupStatus? next;
    try {
      final value = await action();
      if (!mounted) return;
      setState(() {
        status = value;
        if (!preserveFnisChoice) includeFnis = value.includeFnis;
      });
      next = value;
    } on Exception {
      if (mounted) {
        setState(() => status = null);
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
    if (next != null && mounted) schedule(next);
  }

  Future<void> load({bool preserveFnisChoice = false}) => change(
    () => widget.client.read(
      widget.workspaceId,
      widget.profileId,
      includeFnis: includeFnis,
    ),
    preserveFnisChoice: preserveFnisChoice,
  );

  Future<void> confirm() async {
    final current = status;
    if (current == null) return;
    final agreed = await showDialog<bool>(
      context: context,
      builder: (context) => McDialog(
        title: 'Apply Skyrim setup changes?',
        actions: [
          McAction(
            label: 'Cancel',
            onPressed: () => Navigator.pop(context, false),
          ),
          McAction(
            label: 'Apply changes',
            emphasis: McActionEmphasis.primary,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
        children: [
          const Text(
            'Review the complete change plan. Mod Conductor will preserve the selected installation, other profiles, foreign files and saves.',
          ),
          const SizedBox(height: McSpacing.medium),
          for (final change in current.changes)
            Material(
              type: MaterialType.transparency,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(change.title),
                subtitle: Text(change.detail),
              ),
            ),
        ],
      ),
    );
    if (agreed != true || !mounted) return;
    await change(
      () => widget.client.start(
        widget.workspaceId,
        widget.profileId,
        includeFnis: includeFnis,
        planToken: current.planToken,
      ),
    );
  }

  Future<void> cancelSetup() async {
    if (cancelling) return;
    setState(() => cancelling = true);
    SkyrimSetupStatus? next;
    try {
      final value = await widget.client.cancel(
        widget.workspaceId,
        widget.profileId,
      );
      if (!mounted) return;
      setState(() {
        status = value;
        includeFnis = value.includeFnis;
      });
      next = value;
    } on Exception {
      if (mounted) setState(() => status = null);
    } finally {
      if (mounted) setState(() => cancelling = false);
    }
    if (next != null && mounted) schedule(next);
  }

  Future<void> selectArchive() async {
    final selected = await widget.chooseArchive();
    if (selected == null || !mounted) return;
    await change(
      () => widget.client.selectEnbArchive(
        widget.workspaceId,
        widget.profileId,
        newOperationId(),
        selected.path,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final value = status;
    final failed =
        value == null ||
        value.phase == SkyrimSetupStatusPhase.unavailable ||
        value.phase == SkyrimSetupStatusPhase.recoveryRequired ||
        value.phase == SkyrimSetupStatusPhase.failed;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        McStatus(
          title:
              value?.status ??
              (busy ? 'Checking Skyrim setup' : 'Skyrim setup is unavailable'),
          detail: value?.detail.isEmpty == false
              ? value!.detail
              : 'Check the engine connection.',
          tone: failed ? McStatusTone.error : McStatusTone.neutral,
        ),
        if (busy || value?.active == true) ...[
          const SizedBox(height: McSpacing.medium),
          const LinearProgressIndicator(),
        ],
        if (value != null && value.components.isNotEmpty) ...[
          const SizedBox(height: McSpacing.large),
          for (final item in value.components) ...[
            McStatus(
              title: '${item.name}: ${item.status}',
              detail: item.detail.isEmpty ? null : item.detail,
              tone: item.blocked ? McStatusTone.error : McStatusTone.neutral,
            ),
            const SizedBox(height: McSpacing.medium),
          ],
        ],
        if (value?.consentRecorded != true) ...[
          Material(
            type: MaterialType.transparency,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Include FNIS'),
              subtitle: const Text(
                'Install FNIS and keep its active animation output current for this profile.',
              ),
              value: includeFnis,
              onChanged: busy
                  ? null
                  : (selected) {
                      setState(() => includeFnis = selected);
                      unawaited(load(preserveFnisChoice: true));
                    },
            ),
          ),
        ],
        const SizedBox(height: McSpacing.medium),
        Wrap(
          spacing: McSpacing.medium,
          runSpacing: McSpacing.medium,
          children: [
            McAction(
              label: 'Refresh',
              icon: Icons.refresh,
              onPressed: busy ? null : load,
            ),
            if (value?.canStart == true)
              McAction(
                label: 'Review and apply setup',
                icon: Icons.fact_check_outlined,
                emphasis: McActionEmphasis.primary,
                onPressed: busy ? null : confirm,
              ),
            if (value?.canSelectEnbArchive == true)
              McAction(
                label: 'Choose downloaded ENBSeries archive',
                icon: Icons.folder_open,
                emphasis: McActionEmphasis.primary,
                onPressed: busy ? null : selectArchive,
              ),
            if (value?.canCancel == true)
              McAction(
                label: 'Cancel setup',
                icon: Icons.cancel_outlined,
                onPressed: cancelling ? null : cancelSetup,
              ),
            if (value?.canContinue == true &&
                value?.phase == SkyrimSetupStatusPhase.failed)
              McAction(
                label: 'Try setup again',
                icon: Icons.refresh,
                emphasis: McActionEmphasis.primary,
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
}
