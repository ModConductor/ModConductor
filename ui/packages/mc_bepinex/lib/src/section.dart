import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'controller.dart';
import 'tools.dart';

class BepInExSection extends StatefulWidget {
  const BepInExSection({
    super.key,
    required this.client,
    required this.packages,
    required this.workspace,
    required this.profile,
    required this.changes,
    required this.onChanged,
  });
  final BepInExClient client;
  final ThunderstoreClient packages;
  final String workspace, profile;
  final Listenable changes;
  final VoidCallback onChanged;
  @override
  State<BepInExSection> createState() => _BepInExSectionState();
}

class _BepInExSectionState extends State<BepInExSection> {
  late final controller = LoaderController(
    widget.client,
    widget.packages,
    widget.workspace,
    widget.profile,
    widget.onChanged,
  );
  void read() => unawaited(controller.read());
  @override
  void initState() {
    super.initState();
    widget.changes.addListener(read);
    read();
  }

  @override
  void didUpdateWidget(BepInExSection old) {
    super.didUpdateWidget(old);
    if (old.changes != widget.changes) {
      old.changes.removeListener(read);
      widget.changes.addListener(read);
    }
  }

  @override
  void dispose() {
    widget.changes.removeListener(read);
    controller.dispose();
    super.dispose();
  }

  Future<void> tools() => showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) =>
        LoaderTools(client: widget.client, state: controller.state!),
  );
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final state = controller.state;
      final package = state?.package;
      return Padding(
        padding: const EdgeInsets.only(top: McSpacing.large),
        child: McSection(
          title: 'Mod loader',
          children: [
            if (state == null && controller.problem == null)
              const LinearProgressIndicator(),
            if (state != null)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: McComponentChoiceRow(
                      name: package?.package.name ?? 'BepInEx',
                      kind: 'Mod loader',
                      current: state.mod == null
                          ? 'Not installed'
                          : '${package == null ? 'Archive' : 'Pack ${package.version}'} · ${state.enabled ? 'Enabled' : 'Disabled'}',
                      installed: state.mod != null,
                      selected: state.enabled,
                      iconUrl: package == null
                          ? null
                          : 'https://ccdn.thunderstore.io/live/repository/icons/${package.package.namespace}-${package.package.name}-${package.version}.png',
                      enabled: !controller.busy,
                      onToggle: () => unawaited(controller.toggle()),
                      onOpenPage: package == null
                          ? null
                          : () => unawaited(
                              widget.packages.openPage(package.package),
                            ),
                    ),
                  ),
                  const SizedBox(width: McSpacing.medium),
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: McAction(
                      label: 'Tools',
                      icon: Icons.build_outlined,
                      onPressed: state.mod != null && !controller.busy
                          ? tools
                          : null,
                    ),
                  ),
                ],
              ),
            if (controller.progress case final progress?)
              McStatus(
                title: progress.stage == 'download'
                    ? 'Downloading loader'
                    : 'Installing loader',
              ),
            if (controller.problem case final problem?)
              McStatus(title: problem, tone: McStatusTone.error),
          ],
        ),
      );
    },
  );
}
