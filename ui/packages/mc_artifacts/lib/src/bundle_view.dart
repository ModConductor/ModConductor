import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_collections/mc_ui_collections.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'archive_facts.dart';
import 'bundle_controller.dart';
import 'bundle_collection.dart';
import 'bundle_toolbar.dart';
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
  final rows = McCollectionModel<String, BundleRow>(
    idOf: (v) => v.id,
    labelOf: (v) => v.name,
  );
  final chosen = <int>{};
  List<BundleRow> displayed = [];
  BundleRow? current;
  BundleDiscovery? lastDiscovery;
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
    rows.sort((a, b) => a.order.compareTo(b.order));
    controller.addListener(changed);
    unawaited(controller.open());
  }

  void changed() {
    if (!mounted) return;
    final source = controller.discovery;
    if (!identical(source, lastDiscovery)) {
      chosen.clear();
      lastDiscovery = source;
    }
    final items = controller.bundle?.items ?? <BundleItem>[];
    displayed = source != null
        ? [
            for (var i = 0; i < source.archives.length; i++)
              BundleRow(
                'archive:${source.archives[i].index}',
                i,
                source.archives[i].path.last,
                source.archives[i].path.join('/'),
                source.archives[i].bytes,
                archive: source.archives[i],
              ),
          ]
        : [
            for (var i = 0; i < items.length; i++)
              BundleRow(
                items[i].id,
                i,
                items[i].name,
                bundlePath(items[i]),
                items[i].bytes,
                item: items[i],
              ),
          ];
    rows.apply(
      removed: rows.ids
          .where((id) => !displayed.any((row) => row.id == id))
          .toList(),
      upserts: displayed,
    );
    final old = current?.id;
    current = null;
    for (final row in displayed) {
      if (row.id == old) current = row;
    }
    current ??= displayed.isEmpty ? null : displayed.first;
    if (current != null) rows.select(current!.id);
    setState(() {});
  }

  @override
  void dispose() {
    controller.removeListener(changed);
    controller.dispose();
    rows.dispose();
    super.dispose();
  }

  Future<void> information(String title, String message) => showDialog<void>(
    context: context,
    builder: (c) => McDialog(
      title: title,
      actions: [McAction(label: 'Close', onPressed: () => Navigator.pop(c))],
      children: [Text(message)],
    ),
  );
  Future<void> rename(BundleItem item) async {
    final field = TextEditingController(text: item.name);
    final name = await showDialog<String>(
      context: context,
      builder: (c) => McFormDialog(
        title: 'Mod name',
        action: 'Save',
        onSubmit: () => Navigator.pop(c, field.text),
        children: [
          Text(bundlePath(item)),
          const SizedBox(height: 16),
          McNameField(
            controller: field,
            onSubmit: () => Navigator.pop(c, field.text),
          ),
          const SizedBox(height: 16),
          const Text('Mod starts disabled'),
        ],
      ),
    );
    field.dispose();
    if (name != null && mounted) await controller.rename(item, name);
  }

  Future<void> retry(BundleItem item) async {
    if (item.attemptId == null && !item.incompleteArchive) {
      configure(item);
      return;
    }
    final accepted = await showDialog<bool>(
      context: context,
      builder: (c) => McFormDialog(
        title: 'Delete incomplete files?',
        action: 'Delete files and review',
        onSubmit: () => Navigator.pop(c, true),
        children: [
          Text(item.name),
          const SizedBox(height: 16),
          const Text('Installed mods stay installed.'),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    if (await controller.retry(item) && mounted) {
      final updated = controller.bundle!.items
          .where((v) => v.id == item.id)
          .firstOrNull;
      if (updated != null && updated.state != BundleItemState.installed)
        await controller.configure(updated);
    }
  }

  Future<void> cleanup() async {
    final bundle = controller.bundle;
    if (bundle == null) return;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (c) => McFormDialog(
        title: 'Delete temporary files?',
        action: 'Delete temporary files',
        onSubmit: () => Navigator.pop(c, true),
        children: [
          Text(bundle.archiveName),
          const SizedBox(height: 16),
          Text(
            '${archiveSize(bundle.temporaryBytes)} of temporary archive copies',
          ),
          const SizedBox(height: 16),
          const Text(
            'Installed mods and the original archive stay unchanged. This checklist will close.',
          ),
        ],
      ),
    );
    if (accepted == true && mounted && await controller.delete() && mounted)
      widget.onBack();
  }

  void configure(BundleItem item, {bool contained = false}) {
    pane.currentState?.closeEndDrawer();
    inspected = false;
    unawaited(controller.configure(item, contained: contained));
  }

  Widget inspector(BuildContext c, VoidCallback close) {
    final row = current, item = current?.item;
    return McInspector(
      title: row?.name ?? 'Archive',
      onClose: close,
      children: [
        if (row != null) ...[
          if (item?.problem != null) ...[
            McStatus(title: item!.problem!, tone: McStatusTone.error),
            const SizedBox(height: 16),
          ],
          archiveFact(c, 'Archive', row.path),
          if (item != null)
            archiveFact(c, 'Destination', 'New mod: ${item.name}'),
          archiveFact(c, 'Archive size', archiveSize(row.bytes)),
          if (item != null) ...[
            archiveFact(c, 'Status', bundleState(item.state)),
            McAction(
              label: item.state == BundleItemState.installed
                  ? 'Open Mods'
                  : item.state == BundleItemState.failed
                  ? 'Retry'
                  : item.state == BundleItemState.installing
                  ? 'View installation'
                  : 'Configure',
              onPressed: controller.busy
                  ? null
                  : () {
                      if (item.state == BundleItemState.installed)
                        widget.onOpenMods();
                      else if (item.state == BundleItemState.failed)
                        unawaited(retry(item));
                      else
                        configure(item);
                    },
            ),
            const SizedBox(height: 16),
            if (item.state == BundleItemState.needsReview) ...[
              McAction(
                label: 'Change destination',
                onPressed: controller.busy ? null : () => rename(item),
              ),
              const SizedBox(height: 16),
            ],
            archiveFact(c, 'Source', widget.artifact.originalName),
            archiveFact(
              c,
              'Installation order',
              '${row.order + 1} of ${displayed.length}',
            ),
          ],
        ] else
          const Text('No archives selected.'),
      ],
    );
  }

  void collectionAction(String value) {
    if (controller.busy) return;
    if (picking) {
      setState(() {
        chosen.clear();
        if (value == 'all') {
          chosen.addAll(displayed.map((row) => row.archive!.index));
        }
      });
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
      current = row;
      inspected = true;
    });
    if (narrow) pane.currentState?.openEndDrawer();
  }

  void selectArchive(BundleRow row, bool selected) {
    setState(() {
      if (selected) {
        chosen.add(row.archive!.index);
      } else {
        chosen.remove(row.archive!.index);
      }
    });
  }

  void toolbarAction(String value) {
    switch (value) {
      case 'cleanup':
        unawaited(cleanup());
      case 'order':
        unawaited(
          information(
            'Installation order',
            'Mods are installed one at a time in the order shown. Each mod has its own file review. Installed mods stay installed if a later mod fails.',
          ),
        );
      default:
        unawaited(
          information(
            'Bundle limits',
            '3 nested archive levels · 32 archives\n20,000 file entries · 64 GB total expansion',
          ),
        );
    }
  }

  void continueBundle() {
    if (picking) {
      unawaited(
        controller.select([
          for (final row in displayed)
            if (chosen.contains(row.archive!.index)) row.archive!.index,
        ]),
      );
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
                        model: rows,
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
