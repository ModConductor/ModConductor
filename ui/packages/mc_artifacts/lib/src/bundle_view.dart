import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'bundle_controller.dart';
import 'bundle_collection.dart';
import 'bundle_toolbar.dart';
import 'bundle_rows.dart';
import 'bundle_prompts.dart';
import 'bundle_inspector.dart';
import 'installation_view.dart';

class ModBundleView extends StatefulWidget {
  const ModBundleView({
    super.key,
    required this.artifact,
    required this.client,
    required this.installations,
    this.fomod,
    this.bain,
    this.profileId,
    required this.onBack,
    required this.onCommitted,
    this.onDetached,
    this.onAttached,
    required this.onOpenMods,
  });
  final Artifact artifact;
  final BundlesClient client;
  final InstallationsClient installations;
  final FomodClient? fomod;
  final BainClient? bain;
  final String? profileId;
  final VoidCallback onBack, onCommitted, onOpenMods;
  final void Function(InstallationStatus)? onDetached;
  final void Function(InstallationStatus)? onAttached;
  @override
  State<ModBundleView> createState() => _ModBundleViewState();
}

class _ModBundleViewState extends State<ModBundleView> {
  late final controller = BundleController(
    widget.client,
    widget.installations,
    widget.artifact,
  );
  final pane = GlobalKey<ScaffoldState>();
  final rows = BundleRows();
  List<BundleRow> get displayed => rows.displayed;
  BundleRow? get current => rows.current;
  Set<int> get chosen => rows.chosen;
  bool inspected = false;
  bool get picking => controller.discovery != null;
  BundleItem? get next {
    for (final item in controller.bundle?.items ?? <BundleItem>[]) {
      if (item.state != BundleItemState.installed) return item;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    controller.addListener(changed);
    unawaited(controller.open());
  }

  void changed() {
    if (!mounted) return;
    rows.reconcile(controller.discovery, controller.bundle);
    setState(() {});
  }

  @override
  void dispose() {
    controller.removeListener(changed);
    controller.dispose();
    rows.dispose();
    super.dispose();
  }

  Future<void> rename(BundleItem item) async {
    final name = await askBundleName(context, item);
    if (name != null && mounted) await controller.rename(item, name);
  }

  Future<void> retry(BundleItem item) async {
    if (item.attemptId == null && !item.incompleteArchive) {
      configure(item);
      return;
    }
    if (!await confirmBundleRetry(context, item) || !mounted) return;
    if (await controller.retry(item) && mounted) {
      final updated = controller.bundle!.items
          .where((value) => value.id == item.id)
          .firstOrNull;
      if (updated != null && updated.state != BundleItemState.installed) {
        await controller.configure(updated);
      }
    }
  }

  Future<void> cleanup() async {
    final bundle = controller.bundle;
    if (bundle == null) return;
    if (await confirmBundleCleanup(context, bundle) &&
        mounted &&
        await controller.delete() &&
        mounted) {
      widget.onBack();
    }
  }

  void configure(BundleItem item, {bool contained = false}) {
    pane.currentState?.closeEndDrawer();
    inspected = false;
    unawaited(controller.configure(item, contained: contained));
  }

  void primaryAction(BundleItem item) {
    if (item.state == BundleItemState.installed) {
      widget.onOpenMods();
    } else if (item.state == BundleItemState.failed) {
      unawaited(retry(item));
    } else {
      configure(item);
    }
  }

  Widget inspector(BuildContext context, VoidCallback close) => BundleInspector(
    row: current,
    archiveName: widget.artifact.originalName,
    count: displayed.length,
    busy: controller.busy,
    onClose: close,
    onPrimary: primaryAction,
    onRename: (item) => unawaited(rename(item)),
  );

  void collectionAction(String value) {
    if (controller.busy) return;
    if (picking) {
      setState(() => rows.selectAll(value == 'all'));
      return;
    }
    final item = current?.item;
    if (item == null) return;
    switch (value) {
      case 'destination':
        unawaited(rename(item));
      case 'up':
        unawaited(controller.move(item, true));
      case 'down':
        unawaited(controller.move(item, false));
      case 'nested':
        configure(item, contained: true);
      default:
        if (item.state == BundleItemState.failed) {
          unawaited(retry(item));
        } else {
          configure(item);
        }
    }
  }

  void selectRow(BundleRow row, bool narrow) {
    setState(() {
      rows.current = row;
      inspected = true;
    });
    if (narrow) pane.currentState?.openEndDrawer();
  }

  void selectArchive(BundleRow row, bool selected) {
    setState(() => rows.selectArchive(row, selected));
  }

  void toolbarAction(String value) {
    switch (value) {
      case 'cleanup':
        unawaited(cleanup());
      case 'order':
        unawaited(
          showBundleInformation(
            context,
            'Installation order',
            'Mods are installed one at a time in the order shown. Each mod has its own file review. Installed mods stay installed if a later mod fails.',
          ),
        );
      default:
        unawaited(
          showBundleInformation(
            context,
            'Bundle limits',
            '3 nested archive levels · 32 archives\n20,000 file entries · 64 GB total expansion',
          ),
        );
    }
  }

  void continueBundle() {
    if (picking) {
      unawaited(controller.select(rows.selectedArchives));
      return;
    }
    final item = next;
    if (item == null) {
      unawaited(cleanup());
    } else if (item.state == BundleItemState.failed) {
      unawaited(retry(item));
    } else {
      configure(item);
    }
  }

  @override
  Widget build(BuildContext c) {
    if (controller.prepared != null || controller.status != null) {
      return ArchiveInstallationView(
        key: ValueKey(controller.prepared?.id ?? controller.status!.id),
        artifact: widget.artifact,
        client: widget.installations,
        initialDraft: controller.prepared,
        initialStatus: controller.status,
        fomod: widget.fomod,
        bain: widget.bain,
        profileId: widget.profileId,
        backLabel: 'Back to bundle',
        onBack: () => unawaited(controller.back()),
        onCommitted: widget.onCommitted,
        onDetached: widget.onDetached,
        onAttached: widget.onAttached,
        onOpenMods: widget.onOpenMods,
      );
    }
    return LayoutBuilder(
      builder: (c, box) {
        final narrow =
            box.maxWidth < 1100 * MediaQuery.textScalerOf(c).scale(1);
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
              BundleToolbar(
                title:
                    controller.nested?.archives.last.join('/') ??
                    widget.artifact.originalName,
                picking: picking,
                hasBundle: controller.bundle != null,
                busy: controller.busy,
                hasSelection: chosen.isNotEmpty,
                next: next,
                onBack: () {
                  if (picking && controller.bundle != null) {
                    unawaited(controller.back());
                  } else {
                    widget.onBack();
                  }
                },
                onAction: toolbarAction,
                onContinue: continueBundle,
              ),
              const SizedBox(height: 8),
              if (controller.busy) const LinearProgressIndicator(),
              if (controller.problem != null &&
                  !(controller.bundle?.items.any(
                        (m) => m.problem == controller.problem,
                      ) ??
                      false)) ...[
                McStatus(title: controller.problem!, tone: McStatusTone.error),
                const SizedBox(height: 8),
              ],
              if (controller.nested != null) ...[
                Text(
                  '${widget.artifact.originalName} / ${bundlePath(controller.nested!)}',
                  style: Theme.of(c).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
              ],
              if (picking && displayed.isEmpty)
                const McStatus(title: 'No contained archives found.'),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: BundleCollection(
                        model: rows.model,
                        displayed: displayed,
                        current: current,
                        chosen: chosen,
                        installed:
                            controller.bundle?.items
                                .where(
                                  (item) =>
                                      item.state == BundleItemState.installed,
                                )
                                .length ??
                            0,
                        picking: picking,
                        narrow: narrow,
                        busy: controller.busy,
                        onAction: collectionAction,
                        onSelect: (row) => selectRow(row, narrow),
                        onArchiveSelected: selectArchive,
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
}
