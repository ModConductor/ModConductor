part of 'nexus_view.dart';

extension _NexusFilesView on _ModNexusViewState {
  bool get canDownload =>
      !controller.busy &&
      controller.details?.current == true &&
      controller.model.selected?.downloadable == true &&
      controller.model.selected?.file.id != controller.refusedFile;
  Widget fileInspector(BuildContext c, VoidCallback close) {
    final file = controller.model.selected;
    return McInspector(
      title: file?.file.name ?? 'File',
      onClose: close,
      footer: McAction(
        label: 'Download',
        icon: Icons.download,
        emphasis: McActionEmphasis.primary,
        onPressed: canDownload ? download : null,
      ),
      children: [
        fact(c, 'Version', file?.file.version ?? ''),
        fact(c, 'Type', file?.file.category ?? ''),
        fact(c, 'Size', size(file?.file.bytes)),
        fact(c, 'Uploaded', date(file?.uploaded)),
        Text(file?.file.description ?? ''),
      ],
    );
  }

  Widget fileChoices() => McChoice<bool>(
    label: 'Show',
    value: controller.updates,
    choices: const [true, false],
    describe: (updates) {
      final all =
          controller.details?.metadata?.files ?? const <NexusMetadataFile>[];
      if (controller.details?.current != true) {
        return updates ? 'Saved files (${all.length})' : 'Other files';
      }
      final count = all
          .where((f) => updates ? f.update : !f.update && f.downloadable)
          .length;
      return '${updates ? 'Updates' : 'Other files'} ($count)';
    },
    onChanged: controller.chooseView,
  );
  Widget filesView(BuildContext c, bool compact) {
    final collection = McCollection<int, NexusMetadataFile>(
      model: controller.model,
      title: 'Nexus files',
      showTitle: !compact,
      compactFilter: compact,
      showTree: false,
      filterLabel: 'Filter files',
      countLabel:
          '${controller.model.length} ${controller.model.length == 1 ? 'file' : 'files'}',
      onSelect: (file) => controller.select(file.file.id),
      onActivate: (_) {
        if (compact) {
          pane.currentState?.openEndDrawer();
        } else {
          changeView(() => inspected = true);
        }
      },
      actions: compact
          ? const []
          : [
              McAction(
                label: 'Download',
                icon: Icons.download,
                emphasis: McActionEmphasis.primary,
                onPressed: canDownload ? download : null,
              ),
            ],
      filterActions: compact
          ? [
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: SizedBox(width: 240, child: fileChoices()),
              ),
              McIconAction(
                label: 'Open mod page',
                icon: const Icon(Icons.open_in_new),
                onPressed: controller.busy ? null : controller.openPage,
              ),
              McIconAction(
                label: 'Download',
                icon: const Icon(Icons.download),
                onPressed: canDownload ? download : null,
              ),
            ]
          : const [],
      columns: [
        McColumn(
          'File',
          (r) => compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      r.file.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${r.file.version} · ${r.file.category} · ${size(r.file.bytes)}',
                      style: Theme.of(c).textTheme.bodySmall,
                    ),
                  ],
                )
              : Text(r.file.name),
        ),
        if (!compact) ...[
          McColumn('Version', (r) => Text(r.file.version), width: 100),
          McColumn('Type', (r) => Text(r.file.category), width: 100),
          McColumn('Uploaded', (r) => Text(date(r.uploaded)), width: 125),
          McColumn('Size', (r) => Text(size(r.file.bytes)), width: 90),
        ],
      ],
    );
    return Scaffold(
      key: pane,
      backgroundColor: Colors.transparent,
      endDrawer: Drawer(
        width: 440,
        child: fileInspector(c, () => pane.currentState?.closeEndDrawer()),
      ),
      body: Column(
        children: [
          if (!compact) ...[
            Row(
              children: [
                Expanded(child: fileChoices()),
                const SizedBox(width: 12),
                McAction(
                  label: 'Open mod page',
                  onPressed: controller.busy ? null : controller.openPage,
                ),
              ],
            ),
            gap(12),
          ],
          Expanded(
            child: Row(
              children: [
                Expanded(child: collection),
                if (!compact && inspected) ...[
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 360,
                    child: fileInspector(
                      c,
                      () => changeView(() => inspected = false),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
