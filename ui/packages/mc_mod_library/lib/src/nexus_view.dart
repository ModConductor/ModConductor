import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_collections/mc_ui_collections.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'nexus_controller.dart';
import 'nexus_forms.dart';
part 'nexus_details.dart';
part 'nexus_files.dart';

class ModNexusView extends StatefulWidget {
  const ModNexusView({
    super.key,
    required this.controller,
    required this.onDownloaded,
    this.organization,
    this.onMapped,
    this.onLinked,
    this.onTrackingChanged,
    this.onRefreshed,
    this.localCategories = const [],
  });
  final ModNexusController controller;
  final Future<void> Function(Artifact, ModNexusDetails, String) onDownloaded;
  final ModOrganizationClient? organization;
  final Future<void> Function()? onMapped;
  final Future<void> Function()? onLinked;
  final VoidCallback? onTrackingChanged;
  final VoidCallback? onRefreshed;
  final List<CategoryReference> localCategories;
  @override
  State<ModNexusView> createState() => _ModNexusViewState();
}

class _ModNexusViewState extends State<ModNexusView> {
  ModNexusController get controller => widget.controller;
  final pane = GlobalKey<ScaffoldState>();
  bool inspected = false;
  void changeView(VoidCallback action) => setState(action);
  Widget gap([double height = 16]) => SizedBox(height: height);
  Widget fact(BuildContext c, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(c).textTheme.bodySmall),
        gap(4),
        Text(value),
      ],
    ),
  );
  String date(DateTime? value) => value == null
      ? 'Not checked'
      : MaterialLocalizations.of(context).formatMediumDate(value.toLocal());
  String size(int? value) => value == null
      ? 'Unknown size'
      : value >= 1048576
      ? '${(value / 1048576).toStringAsFixed(1)} MB'
      : '${(value / 1024).toStringAsFixed(1)} KB';
  Future<void> download() async {
    final original = controller.details;
    final version = controller.model.selected?.file.version ?? '';
    final artifact = await controller.download();
    if (artifact != null && original != null) {
      await widget.onDownloaded(artifact, original, version);
    }
  }

  Future<void> linkForm() async {
    final original = controller.details, nexus = controller.nexus;
    final profile = controller.profile;
    if (original == null || nexus == null || profile == null) return;
    final result = await showDialog<({int mod, int? file})>(
      context: context,
      builder: (_) =>
          NexusLinkForm(details: original, client: nexus, profile: profile),
    );
    if (result != null && mounted) {
      await link(result.mod, result.file);
    }
  }

  Future<void> link(int? mod, int? file) async {
    final before = controller.details?.reference.linkRevision;
    await controller.link(mod, file);
    if (controller.problem == null &&
        before != controller.details?.reference.linkRevision) {
      await widget.onLinked?.call();
    }
  }

  Future<void> refresh() async {
    final before = controller.details;
    await controller.refresh();
    if (controller.problem == null && !identical(before, controller.details)) {
      widget.onRefreshed?.call();
    }
  }

  Future<void> categoryForm() async {
    final original = controller.details, organization = widget.organization;
    if (original == null || organization == null) return;
    final result = await showDialog<String>(
      context: context,
      builder: (_) => NexusCategoryForm(
        details: original,
        client: organization,
        categories: widget.localCategories,
      ),
    );
    if (result != null && mounted) {
      await controller.map(result);
      if (controller.problem == null) await widget.onMapped?.call();
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([controller, controller.model]),
    builder: (c, _) => LayoutBuilder(
      builder: (c, box) {
        final compact = box.maxWidth < 1050;
        final value = controller.details;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                McIconAction(
                  label: controller.files
                      ? 'Back to mod details'
                      : 'Back to mods',
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => controller.files
                      ? controller.showFiles(false)
                      : controller.close(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value?.name ?? 'Nexus Mods',
                    style: Theme.of(c).textTheme.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!compact)
                  SizedBox(
                    width: 200,
                    child: McChoice<bool>(
                      label: 'View',
                      value: controller.files,
                      choices: const [false, true],
                      describe: (v) => v ? 'Files' : 'Details',
                      onChanged: controller.showFiles,
                    ),
                  ),
                McIconAction(
                  label: 'Refresh',
                  icon: const Icon(Icons.refresh),
                  onPressed: controller.busy ? null : refresh,
                ),
                if (compact)
                  McIconAction(
                    label: controller.files ? 'Mod details' : 'Nexus files',
                    icon: Icon(
                      controller.files ? Icons.info_outline : Icons.folder_open,
                    ),
                    onPressed: () => controller.showFiles(!controller.files),
                  ),
              ],
            ),
            gap(12),
            if (controller.busy) const LinearProgressIndicator(),
            if (controller.problem != null) ...[
              McStatus(
                title: controller.problem!.message,
                tone: McStatusTone.error,
              ),
              gap(8),
            ],
            Expanded(
              child: value == null
                  ? const SizedBox.shrink()
                  : controller.files
                  ? filesView(c, compact)
                  : detailsView(c, compact, value),
            ),
          ],
        );
      },
    ),
  );
}
