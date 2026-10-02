import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_file_plans/mc_file_plans.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'controller.dart';

class UnrealLoaderSection extends StatefulWidget {
  const UnrealLoaderSection({
    super.key,
    required this.client,
    required this.workspace,
    required this.profile,
    required this.changes,
    required this.onChanged,
    required this.chooseArchive,
  });
  final UnrealClient client;
  final String workspace, profile;
  final Listenable changes;
  final VoidCallback onChanged;
  final Future<String?> Function()? chooseArchive;
  @override
  State<UnrealLoaderSection> createState() => _UnrealLoaderSectionState();
}

class _UnrealLoaderSectionState extends State<UnrealLoaderSection> {
  late final controller = UnrealLoaderController(
    widget.client,
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
  void didUpdateWidget(UnrealLoaderSection old) {
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

  Future<void> tools(UnrealLoaderState state) => showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => LoaderFilesDialog(
      name: state.name,
      settingsFiles: state.settingsFiles,
      logAvailable: state.logAvailable,
      details: ExpansionTile(
        title: const Text('Package details'),
        children: [
          McFactGroup(
            title: state.name,
            rows: [
              McFact(state.declaredVersionLabel, state.declaredVersion),
              if (state.upstreamCommit case final commit?)
                McFact('Upstream commit', commit),
              McFact('Declared source', state.declaredSource),
              McFact('Upstream license', state.upstreamLicense),
            ],
          ),
        ],
      ),
      readSettings: (name) => widget.client.settings(state, name),
      saveSettings: (name, original, content) =>
          widget.client.save(state, name, original, content),
      readLog: () => widget.client.log(state),
    ),
  );
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final state = controller.state;
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
                      name: state.name,
                      kind: state.subtitle,
                      current: state.mod == null
                          ? 'Not installed'
                          : '${state.version} · Installed',
                      installed: state.mod != null,
                      selected: state.enabled || controller.needsArchive,
                      iconUrl: state.iconUrl,
                      iconHeaders: state.iconHeaders,
                      enabled: !controller.busy,
                      onToggle: () => unawaited(controller.toggle()),
                      onOpenPage: () => unawaited(controller.openPage()),
                      onChooseArchive: widget.chooseArchive == null
                          ? null
                          : () => unawaited(
                              controller.chooseArchive(widget.chooseArchive!),
                            ),
                      archiveName: controller.archive
                          ?.split(RegExp(r'[/\\]'))
                          .last,
                      archiveRequired: controller.needsArchive,
                      archiveRequiredText: 'Choose the ${state.name} archive.',
                    ),
                  ),
                  const SizedBox(width: McSpacing.medium),
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: McAction(
                      label: 'Tools',
                      icon: Icons.build_outlined,
                      onPressed: state.mod != null && !controller.busy
                          ? () => tools(state)
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
