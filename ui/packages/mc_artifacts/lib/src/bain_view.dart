import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_collections/mc_ui_collections.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'archive_facts.dart';
import 'bain_controller.dart';
import 'installation_files_review.dart';

class BainView extends StatefulWidget {
  const BainView({
    super.key,
    required this.client,
    required this.initial,
    required this.available,
    required this.onReviewed,
    required this.onModeChanged,
    required this.onInstall,
    required this.onBack,
    this.onUpdate,
    this.backLabel = 'Back to archives',
    this.operationProblem,
  });
  final BainClient client;
  final InstallationDraft initial;
  final bool available;
  final ValueChanged<InstallationDraft> onReviewed, onModeChanged;
  final VoidCallback onInstall, onBack;
  final String backLabel;
  final VoidCallback? onUpdate;
  final String? operationProblem;
  @override
  State<BainView> createState() => _BainViewState();
}

class _BainViewState extends State<BainView> {
  late final controller = BainController(widget.client, widget.initial);
  final pane = GlobalKey<ScaffoldState>();
  final packages = McCollectionModel<int, BainPackage>(
    idOf: (p) => p.index,
    labelOf: (p) => p.name,
  );
  BainChoices? rendered;
  InstallationDraft? adopted;
  BainPackage? selectedPackage;
  List<InstallationReviewedFile>? folderFiles;
  InstallationReviewedFile? selectedFile;
  String? folderProblem;
  bool inspected = false;
  bool get available => widget.available && !controller.busy;
  @override
  void initState() {
    super.initState();
    controller.addListener(changed);
    unawaited(controller.open());
  }

  void changed() {
    if (!mounted) return;
    final value = controller.value;
    if (value != null && !identical(value, rendered)) {
      if (rendered?.reviewing != value.reviewing) {
        inspected = false;
        selectedPackage = null;
        selectedFile = null;
      }
      rendered = value;
      final ids = value.packages.map((p) => p.index).toSet();
      packages.apply(
        upserts: value.packages,
        evicted: packages.ids.where((id) => !ids.contains(id)).toList(),
      );
      if (selectedPackage != null) {
        selectedPackage = value.packages
            .where((p) => p.index == selectedPackage!.index)
            .firstOrNull;
        if (selectedPackage != null) unawaited(readFolder(selectedPackage!));
      }
      if (selectedFile != null)
        selectedFile = value.files
            .where(
              (f) =>
                  f.destination.join('/') ==
                  selectedFile!.destination.join('/'),
            )
            .firstOrNull;
      final draft = value.reviewedDraft;
      if (draft != null && !identical(draft, adopted)) {
        adopted = draft;
        widget.onReviewed(draft);
      }
    }
    setState(() {});
  }

  @override
  void dispose() {
    controller.removeListener(changed);
    controller.dispose();
    packages.dispose();
    super.dispose();
  }

  Future<void> dialog(String title, String text) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (c) => McDialog(
        title: title,
        actions: [McAction(label: 'Close', onPressed: () => Navigator.pop(c))],
        children: [Text(text)],
      ),
    );
  }

  Future<void> notes() async {
    try {
      final text = await widget.client.notes(controller.reference);
      if (mounted) await dialog('Package notes', text);
    } on Exception catch (error) {
      if (mounted)
        await dialog(
          'Package notes',
          error is ArtifactProblem
              ? error.detail
              : 'The package notes cannot be read.',
        );
    }
  }

  Future<void> order() => dialog(
    'Folder order',
    'Folders are ordered by name, without case differences. Later selected folders replace files from earlier folders at the same destination.\n\nNumbers are part of the name: 02 comes before 10, and 10 comes before 2.',
  );
  Future<void> useInstaller(InstallationMode mode) async {
    if (!available) return;
    final manual = mode == InstallationMode.manual;
    if (controller.value?.packages.isNotEmpty == true) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (c) => McFormDialog(
          title: manual
              ? 'Switch to manual installation?'
              : 'Switch to the XML installer?',
          action: manual ? 'Use manual layout' : 'Use XML installer',
          onSubmit: () => Navigator.pop(c, true),
          children: const [
            Text('Your package and file choices will be cleared.'),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    final draft = await controller.useInstaller(mode);
    if (mounted && draft != null) widget.onModeChanged(draft);
  }

  Future<void> readFolder(BainPackage package) async {
    final reference = controller.reference;
    folderFiles = null;
    folderProblem = null;
    try {
      final files = await widget.client.folder(reference, package.index);
      if (mounted &&
          controller.reference.revision == reference.revision &&
          selectedPackage?.index == package.index)
        setState(() => folderFiles = files);
    } on Exception catch (error) {
      if (mounted &&
          controller.reference.revision == reference.revision &&
          selectedPackage?.index == package.index)
        setState(
          () => folderProblem = error is ArtifactProblem
              ? error.detail
              : 'The folder details cannot be read.',
        );
    }
  }

  void inspect(bool narrow) {
    setState(() => inspected = true);
    if (narrow) pane.currentState?.openEndDrawer();
  }

  Widget inspector(BuildContext c, VoidCallback close) {
    final package = selectedPackage, file = selectedFile;
    return McInspector(
      title: package?.name ?? file?.destination.join('/') ?? 'File',
      onClose: close,
      children: package != null
          ? [
              archiveFact(
                c,
                'Order',
                '${(controller.value?.packages.indexWhere((p) => p.index == package.index) ?? 0) + 1} of ${controller.value?.packages.length ?? 0}',
              ),
              archiveFact(c, 'Size', archiveSize(package.bytes)),
              if (folderProblem != null)
                McStatus(title: folderProblem!, tone: McStatusTone.error),
              if (folderFiles == null && folderProblem == null)
                const LinearProgressIndicator(),
              for (final file
                  in folderFiles ?? const <InstallationReviewedFile>[]) ...[
                archiveFact(c, 'File', file.destination.join('/')),
                if (file.replaces.isNotEmpty)
                  archiveFact(
                    c,
                    'Replaces',
                    file.replaces.map((p) => p.join('/')).join('\n'),
                  ),
              ],
            ]
          : file == null
          ? []
          : installationReviewedFacts(c, file),
    );
  }

  Widget packageList(BuildContext c, bool narrow) {
    final value = controller.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!narrow)
          Text('Package folders', style: Theme.of(c).textTheme.titleMedium),
        Row(
          children: [
            Expanded(
              child: Text(
                'Later folders replace earlier files.',
                style: Theme.of(c).textTheme.bodySmall,
              ),
            ),
            McIconAction(
              label: 'Folder order',
              icon: const Icon(Icons.info_outline),
              onPressed: () => unawaited(order()),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: McCollection<int, BainPackage>(
            model: packages,
            title: 'Package folders',
            showTitle: false,
            showTree: false,
            compactFilter: narrow,
            filterLabel: 'Filter folders',
            countLabel:
                '${value?.packages.where((p) => p.selected).length ?? 0} of ${value?.packages.length ?? 0} folders selected',
            filterActions: [
              if (widget.initial.wizardScripts.isNotEmpty) ...[
                Text(
                  'Wizard script not supported',
                  style: Theme.of(c).textTheme.bodySmall,
                ),
                const SizedBox(width: 8),
              ],
              McIconMenu<String>(
                label: 'Folder selection',
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'all',
                    enabled: available,
                    child: const Text('Select all'),
                  ),
                  PopupMenuItem(
                    value: 'none',
                    enabled: available,
                    child: const Text('Clear selection'),
                  ),
                  if (value?.hasNotes == true)
                    PopupMenuItem(
                      value: 'notes',
                      enabled: available,
                      child: const Text('Package notes'),
                    ),
                ],
                onSelected: (v) {
                  if (v == 'notes') {
                    unawaited(notes());
                  } else {
                    unawaited(controller.chooseAll(v == 'all'));
                  }
                },
              ),
            ],
            onSelect: (package) {
              selectedPackage = package;
              selectedFile = null;
              unawaited(readFolder(package));
              inspect(narrow);
            },
            columns: [
              McColumn(
                '',
                (p) => Checkbox(
                  value: p.selected,
                  onChanged: available
                      ? (v) => unawaited(controller.choose(p, v!))
                      : null,
                ),
                width: 48,
                interactive: true,
              ),
              if (!narrow)
                McColumn(
                  'Order',
                  (p) => Text(
                    '${(value?.packages.indexWhere((r) => r.index == p.index) ?? 0) + 1}',
                  ),
                  width: 65,
                ),
              McColumn('Package folder', (p) => McCollectionName(p.name)),
              if (!narrow)
                McColumn('Files', (p) => Text('${p.files}'), width: 80),
              if (!narrow)
                McColumn('Size', (p) => Text(archiveSize(p.bytes)), width: 100),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (c, box) {
      final narrow = box.maxWidth < 1100 * MediaQuery.textScalerOf(c).scale(1),
          value = controller.value,
          review = value?.reviewing == true;
      final problem =
          controller.problem ?? widget.operationProblem ?? value?.problem;
      final supported = value?.packages.isNotEmpty == true;
      final canAdvance =
          available &&
          (review
              ? value?.reviewedDraft?.canInstall == true
              : value?.packages.any((p) => p.selected) == true);
      return Scaffold(
        key: pane,
        backgroundColor: Colors.transparent,
        endDrawer: Drawer(
          width: 440,
          child: inspector(c, () => pane.currentState?.closeEndDrawer()),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                McIconAction(
                  label: review ? 'Back to package folders' : widget.backLabel,
                  icon: const Icon(Icons.arrow_back),
                  onPressed: review
                      ? (available ? () => unawaited(controller.back()) : null)
                      : widget.onBack,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${review ? 'Review ' : ''}${widget.initial.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(c).textTheme.titleMedium,
                  ),
                ),
                McIconMenu<String>(
                  label: 'Installer actions',
                  itemBuilder: (_) => [
                    if (value?.hasNotes == true)
                      PopupMenuItem(
                        value: 'notes',
                        enabled: available,
                        child: const Text('Package notes'),
                      ),
                    if (widget.initial.availableInstallers.contains(
                      InstallationMode.fomod,
                    ))
                      PopupMenuItem(
                        value: 'fomod',
                        enabled: available,
                        child: const Text('Use XML installer'),
                      ),
                    PopupMenuItem(
                      value: 'manual',
                      enabled: available,
                      child: const Text('Use manual layout'),
                    ),
                    if (review && widget.onUpdate != null)
                      PopupMenuItem(
                        value: 'update',
                        enabled: canAdvance,
                        child: const Text('Update installed mod'),
                      ),
                  ],
                  onSelected: (v) {
                    switch (v) {
                      case 'notes':
                        unawaited(notes());
                      case 'fomod':
                        unawaited(useInstaller(InstallationMode.fomod));
                      case 'manual':
                        unawaited(useInstaller(InstallationMode.manual));
                      case 'update':
                        widget.onUpdate?.call();
                    }
                  },
                ),
                if (supported) ...[
                  const SizedBox(width: 8),
                  McAction(
                    label: review ? 'Install' : 'Review files',
                    emphasis: McActionEmphasis.primary,
                    onPressed: canAdvance
                        ? (review
                              ? widget.onInstall
                              : () => unawaited(controller.review()))
                        : null,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            if (controller.busy) const LinearProgressIndicator(),
            if (problem != null) ...[
              McStatus(title: problem, tone: McStatusTone.error),
              const SizedBox(height: 8),
            ],
            if (review) ...[
              Text(
                '${widget.initial.version.isEmpty ? '' : 'Version ${widget.initial.version} · '}Mod starts disabled',
                style: Theme.of(c).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
            ],
            Expanded(
              child: !supported
                  ? ListView(
                      children: [
                        if (widget.initial.wizardScripts.isNotEmpty) ...[
                          const McStatus(
                            title: 'Wizard script not supported',
                            tone: McStatusTone.neutral,
                          ),
                          const SizedBox(height: 16),
                        ],
                        Align(
                          alignment: Alignment.centerLeft,
                          child: McAction(
                            label: 'Use manual layout',
                            onPressed: available
                                ? () => unawaited(
                                    useInstaller(InstallationMode.manual),
                                  )
                                : null,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: review
                              ? InstallationFilesReview(
                                  files: value!.files,
                                  narrow: narrow,
                                  enabled: available,
                                  onInclude: (file, included) => unawaited(
                                    controller.include(file, included),
                                  ),
                                  onSelect: (file) {
                                    selectedFile = file;
                                    selectedPackage = null;
                                    inspect(narrow);
                                  },
                                )
                              : packageList(c, narrow),
                        ),
                        if (inspected && !narrow) ...[
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 360,
                            child: inspector(
                              c,
                              () => setState(() => inspected = false),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      );
    },
  );
}
