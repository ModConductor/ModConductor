import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'installation_files_review.dart';
import 'fomod_controller.dart';
import 'fomod_options.dart';

class FomodView extends StatefulWidget {
  const FomodView({
    super.key,
    required this.client,
    required this.initial,
    required this.profileId,
    required this.available,
    required this.onReviewed,
    required this.onManual,
    required this.onInstall,
    required this.onBack,
    this.onUpdate,
    this.packages,
    this.operationProblem,
  });
  final FomodClient client;
  final BainClient? packages;
  final InstallationDraft initial;
  final String? profileId, operationProblem;
  final bool available;
  final ValueChanged<InstallationDraft> onReviewed, onManual;
  final VoidCallback onInstall, onBack;
  final VoidCallback? onUpdate;
  @override
  State<FomodView> createState() => _FomodViewState();
}

class _FomodViewState extends State<FomodView> {
  late final controller = FomodController(widget.client, widget.initial);
  final pane = GlobalKey<ScaffoldState>();
  InstallationReviewedFile? selectedFile;
  FomodChoices? rendered;
  InstallationDraft? adopted;
  FomodOption? selectedOption;
  bool inspected = false;
  bool get available => widget.available && !controller.busy;
  @override
  void initState() {
    super.initState();
    controller.addListener(changed);
    unawaited(controller.open(widget.profileId));
  }

  void changed() {
    if (!mounted) return;
    final value = controller.value;
    if (value != null && !identical(value, rendered)) {
      rendered = value;
      if (selectedFile != null) {
        selectedFile = value.files
            .where(
              (file) =>
                  file.destination.join('/') ==
                  selectedFile!.destination.join('/'),
            )
            .firstOrNull;
        if (selectedFile == null && selectedOption == null) inspected = false;
      }
      if (selectedOption != null) {
        selectedOption = value.groups
            .expand((g) => g.options)
            .where((o) => o.id == selectedOption!.id)
            .firstOrNull;
        if (selectedOption == null && !value.reviewReady) inspected = false;
      }
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
    super.dispose();
  }

  Future<void> manual() async {
    if (!available) return;
    if (controller.value?.hasStep == true ||
        controller.value?.reviewReady == true) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (c) => McFormDialog(
          title: 'Switch to manual installation?',
          action: 'Use manual layout',
          onSubmit: () => Navigator.pop(c, true),
          children: const [Text('Your installer choices will be cleared.')],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    final draft = await controller.manual();
    if (mounted && draft != null) widget.onManual(draft);
  }

  Future<void> usePackages() async {
    if (!available || widget.packages == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => McFormDialog(
        title: 'Switch to package folders?',
        action: 'Use package folders',
        onSubmit: () => Navigator.pop(c, true),
        children: const [Text('Your installer choices will be cleared.')],
      ),
    );
    if (confirmed != true || !mounted) return;
    final draft = await controller.packages(widget.packages!);
    if (mounted && draft != null) widget.onManual(draft);
  }

  Future<void> image(FomodOption option) async {
    try {
      final bytes = await widget.client.image(
        controller.reference,
        option.image,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (c) => McDialog(
          title: option.name,
          actions: [
            McAction(label: 'Close', onPressed: () => Navigator.pop(c)),
          ],
          children: [
            Image.memory(
              bytes,
              errorBuilder: (_, _, _) =>
                  const Text('This installer image cannot be displayed.'),
            ),
          ],
        ),
      );
    } on Exception catch (error) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (c) => McDialog(
          title: 'Image unavailable',
          actions: [
            McAction(label: 'Close', onPressed: () => Navigator.pop(c)),
          ],
          children: [
            Text(
              error is ArtifactProblem
                  ? error.detail
                  : 'The installer image cannot be read.',
            ),
          ],
        ),
      );
    }
  }

  Widget inspector(BuildContext c, VoidCallback close) {
    final option = selectedOption, file = selectedFile;
    return McInspector(
      title: option?.name ?? file?.destination.last ?? 'File',
      onClose: close,
      children: option != null
          ? [
              if (option.description.isNotEmpty) Text(option.description),
              if (option.problem != null) ...[
                const SizedBox(height: 16),
                Text(option.problem!),
              ],
              if (option.image.isNotEmpty) ...[
                const SizedBox(height: 16),
                McAction(
                  label: 'View image',
                  icon: Icons.image_outlined,
                  onPressed: () => unawaited(image(option)),
                ),
              ],
            ]
          : file == null
          ? []
          : installationReviewedFacts(c, file),
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (c, box) {
      final value = controller.value,
          narrow = box.maxWidth < 1100 * MediaQuery.textScalerOf(c).scale(1),
          review = value?.reviewReady == true;
      final profileChanged =
          value != null && widget.profileId != value.profileId;
      final editable = available && !profileChanged;
      final problem = profileChanged
          ? 'The selected profile changed. Reload the installer.'
          : widget.operationProblem ?? controller.problem ?? value?.problem;
      void inspect() {
        setState(() => inspected = true);
        if (narrow) pane.currentState?.openEndDrawer();
      }

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
                  label: value?.canBack == true
                      ? 'Previous step'
                      : 'Back to archives',
                  icon: const Icon(Icons.arrow_back),
                  onPressed: value?.canBack == true
                      ? (available ? () => unawaited(controller.back()) : null)
                      : widget.onBack,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${review ? 'Review ' : ''}${value?.name ?? widget.initial.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(c).textTheme.titleMedium,
                  ),
                ),
                McIconMenu<String>(
                  label: 'Installer actions',
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'manual',
                      enabled: available,
                      child: const Text('Use manual layout'),
                    ),
                    if (widget.packages != null &&
                        widget.initial.availableInstallers.contains(
                          InstallationMode.bain,
                        ))
                      PopupMenuItem(
                        value: 'packages',
                        enabled: available,
                        child: const Text('Use package folders'),
                      ),
                    if (review && widget.onUpdate != null)
                      PopupMenuItem(
                        value: 'update',
                        enabled: editable,
                        child: const Text('Update installed mod'),
                      ),
                  ],
                  onSelected: (value) {
                    if (value == 'manual') {
                      unawaited(manual());
                    } else if (value == 'packages') {
                      unawaited(usePackages());
                    } else {
                      widget.onUpdate?.call();
                    }
                  },
                ),
                if (value?.hasStep == true || review) ...[
                  const SizedBox(width: 8),
                  McAction(
                    label: review
                        ? 'Install'
                        : value!.stepNumber == value.visibleSteps
                        ? 'Review files'
                        : 'Next',
                    emphasis: McActionEmphasis.primary,
                    onPressed: editable
                        ? (review
                              ? widget.onInstall
                              : () => unawaited(controller.next()))
                        : null,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            if (controller.busy) const LinearProgressIndicator(),
            if (widget.initial.wizardScripts.isNotEmpty) ...[
              Text(
                'Wizard script not supported',
                style: Theme.of(c).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
            ],
            if (problem != null) ...[
              McStatus(title: problem, tone: McStatusTone.error),
              const SizedBox(height: 8),
            ],
            if (profileChanged) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: McAction(
                  label: 'Reload installer',
                  onPressed: available
                      ? () => unawaited(controller.open(widget.profileId))
                      : null,
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (review) ...[
              Text(
                '${adopted!.version.isEmpty ? '' : 'Version ${adopted!.version} · '}Mod starts disabled',
                style: Theme.of(c).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
            ],
            if (value?.hasStep == true) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      value!.stepName,
                      style: Theme.of(c).textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    '${value.stepNumber} of ${value.visibleSteps}',
                    style: Theme.of(c).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Expanded(
              child: value == null || (!value.hasStep && !review)
                  ? Align(
                      alignment: Alignment.topLeft,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          McAction(
                            label: 'Use manual layout',
                            onPressed: available
                                ? () => unawaited(manual())
                                : null,
                          ),
                          McAction(
                            label: 'Reload installer',
                            onPressed: available
                                ? () => unawaited(
                                    controller.open(widget.profileId),
                                  )
                                : null,
                          ),
                        ],
                      ),
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: review
                              ? InstallationFilesReview(
                                  files: value.files,
                                  narrow: narrow,
                                  onSelect: (file) {
                                    selectedFile = file;
                                    selectedOption = null;
                                    inspect();
                                  },
                                )
                              : FomodOptionGroups(
                                  key: ValueKey((
                                    value.stepName,
                                    value.stepNumber,
                                  )),
                                  groups: value.groups,
                                  available: editable,
                                  choose: (option, selected) => unawaited(
                                    controller.choose(option, selected),
                                  ),
                                  inspect: (option) {
                                    selectedOption = option;
                                    inspect();
                                  },
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
