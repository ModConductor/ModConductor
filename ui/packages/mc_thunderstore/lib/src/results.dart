part of 'browser.dart';

extension _ThunderstoreResults on _ThunderstoreBrowserState {
  Widget _results(bool compact) => McCollection<String, ThunderstorePreview>(
    model: controller.model,
    title: 'Thunderstore packages',
    showTitle: false,
    filterLabel: 'Search Thunderstore',
    filterText: controller.query,
    filterEnabled: !controller.running,
    onFilterChanged: controller.changeQuery,
    countLabel: '${controller.model.length} of ${controller.count} packages',
    loading: controller.loading,
    problem: controller.problem?.message,
    onLoad: controller.next != null
        ? () => unawaited(controller.search(more: true))
        : null,
    onRefresh: !controller.running
        ? () => unawaited(controller.search())
        : null,
    onSelect: controller.running
        ? null
        : (row) => unawaited(controller.inspect(row.package)),
    onActivate: controller.running
        ? null
        : (row) => unawaited(controller.inspect(row.package)),
    columns: [
      McColumn(
        'Package',
        (row) => Row(
          children: [
            _artwork(row.icon, 34),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.package.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    row.package.namespace,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
        width: compact ? null : 290,
      ),
      if (!compact)
        McColumn(
          'Description',
          (row) => Tooltip(
            message: row.description,
            child: Text(
              row.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      McColumn(
        'Status',
        (row) => Text(
          controller.status(row),
          style: row.deprecated
              ? TextStyle(color: Theme.of(context).colorScheme.error)
              : null,
        ),
        width: 138,
      ),
      McColumn(
        '',
        (row) => McIconAction(
          label: 'View package',
          icon: const Icon(Icons.chevron_right),
          onPressed: controller.running
              ? null
              : () => unawaited(controller.inspect(row.package)),
        ),
        width: 48,
        interactive: true,
      ),
    ],
  );
}
