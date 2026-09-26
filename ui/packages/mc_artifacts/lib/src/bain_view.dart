import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_collections/mc_ui_collections.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'archive_facts.dart';
import 'bain_controller.dart';
import 'bain_package_collection.dart';
import 'bain_toolbar.dart';
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

  void packageMenuAction(String action) {
    if (action == 'notes') {
      unawaited(notes());
      return;
    }
    unawaited(controller.chooseAll(action == 'all'));
  }

  void selectPackage(BainPackage package, bool narrow) {
    selectedPackage = package;
    selectedFile = null;
    unawaited(readFolder(package));
    inspect(narrow);
  }

  void toolbarAction(String action) {
    switch (action) {
      case 'notes':
        unawaited(notes());
      case 'fomod':
        unawaited(useInstaller(InstallationMode.fomod));
      case 'manual':
        unawaited(useInstaller(InstallationMode.manual));
      case 'update':
        widget.onUpdate?.call();
    }
  }

  void advance(bool review) {
    if (review) {
      widget.onInstall();
    } else {
      unawaited(controller.review());
    }
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
            BainToolbar(
              name: widget.initial.name,
              backLabel: widget.backLabel,
              review: review,
              available: available,
              canAdvance: canAdvance,
              supported: supported,
              hasNotes: value?.hasNotes == true,
              canUseFomod: widget.initial.availableInstallers.contains(
                InstallationMode.fomod,
              ),
              canUpdate: widget.onUpdate != null,
              onBack: () {
                if (review) {
                  unawaited(controller.back());
                } else {
                  widget.onBack();
                }
              },
              onAction: toolbarAction,
              onAdvance: () => advance(review),
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
                              : BainPackageCollection(
                                  model: packages,
                                  value: value,
                                  narrow: narrow,
                                  available: available,
                                  hasWizardScripts:
                                      widget.initial.wizardScripts.isNotEmpty,
                                  onOrder: () => unawaited(order()),
                                  onMenuAction: packageMenuAction,
                                  onSelect: (package) =>
                                      selectPackage(package, narrow),
                                  onChoose: (package, selected) => unawaited(
                                    controller.choose(package, selected),
                                  ),
                                ),
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
