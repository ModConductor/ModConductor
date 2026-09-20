import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_artifacts/mc_artifacts.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

class SkseSection extends StatefulWidget {
  const SkseSection({
    super.key,
    required this.client,
    required this.workspaceId,
    required this.profileId,
    this.embedded = false,
  });
  final SkseClient client;
  final String workspaceId, profileId;
  final bool embedded;
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
        value?.phase == SkseStatusPhase.unavailable ||
        value?.phase == SkseStatusPhase.incompatible ||
        value?.phase == SkseStatusPhase.sourceUnavailable;
    final children = <Widget>[
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
          if (value?.phase == SkseStatusPhase.available ||
              value?.phase == SkseStatusPhase.updateAvailable ||
              value?.phase == SkseStatusPhase.failed)
            McAction(
              label: 'Set up SKSE',
              icon: Icons.download,
              emphasis: McActionEmphasis.primary,
              onPressed: busy ? null : () => load(start: true),
            ),
        ],
      ),
    ];
    if (widget.embedded) return Column(children: children);
    return McSection(title: 'Skyrim Script Extender', children: children);
  }
}

class SkyrimSetupSection extends StatelessWidget {
  const SkyrimSetupSection({
    super.key,
    required this.skse,
    required this.enb,
    required this.fnis,
    required this.chooseArchive,
    required this.workspaceId,
    required this.profileId,
  });

  final SkseClient skse;
  final EnbClient enb;
  final FnisClient fnis;
  final ArchiveChooser chooseArchive;
  final String workspaceId, profileId;

  @override
  Widget build(BuildContext context) => McSection(
    title: 'Skyrim setup',
    children: [
      Flexible(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkseSection(
                client: skse,
                workspaceId: workspaceId,
                profileId: profileId,
                embedded: true,
              ),
              const SizedBox(height: McSpacing.large),
              const Divider(),
              const SizedBox(height: McSpacing.medium),
              _EnbPanel(
                client: enb,
                chooseArchive: chooseArchive,
                workspaceId: workspaceId,
                profileId: profileId,
              ),
              const SizedBox(height: McSpacing.large),
              const Divider(),
              const SizedBox(height: McSpacing.medium),
              _FnisPanel(
                client: fnis,
                workspaceId: workspaceId,
                profileId: profileId,
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class _FnisPanel extends StatefulWidget {
  const _FnisPanel({
    required this.client,
    required this.workspaceId,
    required this.profileId,
  });
  final FnisClient client;
  final String workspaceId, profileId;

  @override
  State<_FnisPanel> createState() => _FnisPanelState();
}

class _FnisPanelState extends State<_FnisPanel> {
  FnisStatus? status;
  bool busy = false;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    unawaited(load());
  }

  @override
  void didUpdateWidget(covariant _FnisPanel old) {
    super.didUpdateWidget(old);
    if (old.workspaceId != widget.workspaceId ||
        old.profileId != widget.profileId) {
      unawaited(load());
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> change(Future<FnisStatus> Function() action) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final value = await action();
      if (!mounted) return;
      setState(() => status = value);
      timer?.cancel();
      if (value.active || value.phase == FnisStatusPhase.waiting) {
        timer = Timer(const Duration(seconds: 1), () => unawaited(load()));
      }
    } on Exception {
      if (mounted) {
        setState(
          () => status = const FnisStatus(
            phase: FnisStatusPhase.failed,
            version: '',
            status: 'FNIS status is unavailable',
            detail: 'Check the engine connection.',
            canInstall: false,
            canCancel: false,
            canUpdate: false,
            canRemove: false,
            canRecover: false,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> load() =>
      change(() => widget.client.read(widget.workspaceId, widget.profileId));

  @override
  Widget build(BuildContext context) {
    final value = status;
    final failed =
        value?.phase == FnisStatusPhase.failed ||
        value?.phase == FnisStatusPhase.unavailable ||
        value?.phase == FnisStatusPhase.recoveryRequired ||
        value?.phase == FnisStatusPhase.sourceUnavailable;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        McStatus(
          title:
              value?.status ??
              (busy ? 'Checking FNIS' : 'FNIS status is unavailable'),
          detail: value?.detail.isEmpty == false ? value!.detail : null,
          tone: failed ? McStatusTone.error : McStatusTone.neutral,
        ),
        if (busy) ...[
          const SizedBox(height: McSpacing.medium),
          const LinearProgressIndicator(),
        ],
        if (value != null && value.version.isNotEmpty) ...[
          const SizedBox(height: McSpacing.medium),
          Text('FNIS Behavior SE ${value.version} · Windows generator'),
        ],
        const SizedBox(height: McSpacing.large),
        Wrap(
          spacing: McSpacing.medium,
          runSpacing: McSpacing.medium,
          children: [
            McAction(
              label: 'Refresh',
              icon: Icons.refresh,
              onPressed: busy ? null : load,
            ),
            if (value?.canInstall == true)
              McAction(
                label: 'Install FNIS',
                icon: Icons.download,
                emphasis: McActionEmphasis.primary,
                onPressed: busy
                    ? null
                    : () => change(
                        () => widget.client.install(
                          widget.workspaceId,
                          widget.profileId,
                        ),
                      ),
              ),
            if (value?.canCancel == true)
              McAction(
                label: 'Cancel',
                onPressed: busy
                    ? null
                    : () => change(
                        () => widget.client.cancel(
                          widget.workspaceId,
                          widget.profileId,
                        ),
                      ),
              ),
            if (value?.canUpdate == true)
              McAction(
                label: 'Update FNIS',
                icon: Icons.update,
                onPressed: busy
                    ? null
                    : () => change(
                        () => widget.client.update(
                          widget.workspaceId,
                          widget.profileId,
                        ),
                      ),
              ),
            if (value?.canRemove == true)
              McAction(
                label: 'Remove FNIS',
                icon: Icons.delete_outline,
                onPressed: busy
                    ? null
                    : () => change(
                        () => widget.client.remove(
                          widget.workspaceId,
                          widget.profileId,
                        ),
                      ),
              ),
            if (value?.canRecover == true)
              McAction(
                label: 'Recover previous setup',
                icon: Icons.restore,
                onPressed: busy
                    ? null
                    : () => change(
                        () => widget.client.recover(
                          widget.workspaceId,
                          widget.profileId,
                        ),
                      ),
              ),
          ],
        ),
      ],
    );
  }
}

class _EnbPanel extends StatefulWidget {
  const _EnbPanel({
    required this.client,
    required this.chooseArchive,
    required this.workspaceId,
    required this.profileId,
  });
  final EnbClient client;
  final ArchiveChooser chooseArchive;
  final String workspaceId, profileId;

  @override
  State<_EnbPanel> createState() => _EnbPanelState();
}

class _EnbPanelState extends State<_EnbPanel> {
  EnbStatus? status;
  bool busy = false;
  Timer? timer;

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    unawaited(load());
  }

  @override
  void didUpdateWidget(covariant _EnbPanel old) {
    super.didUpdateWidget(old);
    if (old.workspaceId != widget.workspaceId ||
        old.profileId != widget.profileId)
      unawaited(load());
  }

  Future<void> change(Future<EnbStatus> Function() action) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final value = await action();
      if (mounted) {
        setState(() => status = value);
        timer?.cancel();
        if (value.active) {
          timer = Timer(const Duration(seconds: 1), () => unawaited(load()));
        }
      }
    } on Exception {
      if (mounted) {
        setState(
          () => status = const EnbStatus(
            phase: EnbStatusPhase.failed,
            status: 'ENB status is unavailable',
            detail: 'Check the engine connection.',
            runtimeVersion: '',
            presetVersion: '',
            canOpenAuthorPage: false,
            canSelectArchive: false,
            canCancel: false,
            canUpdate: false,
            canRemove: false,
            canRecover: false,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> load() =>
      change(() => widget.client.read(widget.workspaceId, widget.profileId));

  Future<void> selectArchive() async {
    final selected = await widget.chooseArchive();
    if (selected == null || !mounted) return;
    await change(
      () => widget.client.selectArchive(
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
        value?.phase == EnbStatusPhase.failed ||
        value?.phase == EnbStatusPhase.blocked ||
        value?.phase == EnbStatusPhase.conflict ||
        value?.phase == EnbStatusPhase.unavailable;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        McStatus(
          title:
              value?.status ??
              (busy ? 'Checking ENB' : 'ENB status is unavailable'),
          detail: value?.detail.isEmpty == false ? value!.detail : null,
          tone: failed ? McStatusTone.error : McStatusTone.neutral,
        ),
        if (busy) ...[
          const SizedBox(height: McSpacing.medium),
          const LinearProgressIndicator(),
        ],
        if (value != null && value.runtimeVersion.isNotEmpty) ...[
          const SizedBox(height: McSpacing.medium),
          Text(
            'ENBSeries ${value.runtimeVersion} · Lean ENB ${value.presetVersion}',
          ),
        ],
        const SizedBox(height: McSpacing.large),
        Wrap(
          spacing: McSpacing.medium,
          runSpacing: McSpacing.medium,
          children: [
            McAction(
              label: 'Refresh',
              icon: Icons.refresh,
              onPressed: busy ? null : load,
            ),
            if (value?.canOpenAuthorPage == true)
              McAction(
                label: 'Open ENBSeries page',
                icon: Icons.open_in_browser,
                emphasis: McActionEmphasis.primary,
                onPressed: busy
                    ? null
                    : () => change(
                        () => widget.client.openAuthorPage(
                          widget.workspaceId,
                          widget.profileId,
                        ),
                      ),
              ),
            if (value?.canSelectArchive == true)
              McAction(
                label: 'Choose downloaded archive',
                icon: Icons.folder_open,
                emphasis: McActionEmphasis.primary,
                onPressed: busy ? null : selectArchive,
              ),
            if (value?.canCancel == true)
              McAction(
                label: 'Cancel',
                onPressed: busy
                    ? null
                    : () => change(
                        () => widget.client.cancel(
                          widget.workspaceId,
                          widget.profileId,
                        ),
                      ),
              ),
            if (value?.canUpdate == true)
              McAction(
                label: 'Update Lean ENB',
                icon: Icons.update,
                onPressed: busy
                    ? null
                    : () => change(
                        () => widget.client.update(
                          widget.workspaceId,
                          widget.profileId,
                        ),
                      ),
              ),
            if (value?.canRemove == true)
              McAction(
                label: 'Remove ENB setup',
                icon: Icons.delete_outline,
                onPressed: busy
                    ? null
                    : () => change(
                        () => widget.client.remove(
                          widget.workspaceId,
                          widget.profileId,
                        ),
                      ),
              ),
            if (value?.canRecover == true)
              McAction(
                label: 'Recover previous setup',
                icon: Icons.restore,
                onPressed: busy
                    ? null
                    : () => change(
                        () => widget.client.recover(
                          widget.workspaceId,
                          widget.profileId,
                        ),
                      ),
              ),
          ],
        ),
      ],
    );
  }
}
