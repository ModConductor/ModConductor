part of 'collection.dart';

class _CollectionTitle<I extends Object, T extends Object>
    extends StatelessWidget {
  const _CollectionTitle(this.collection);
  final McCollection<I, T> collection;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 10),
    child: Row(
      children: [
        if (collection.showTitle)
          Expanded(
            child: Tooltip(
              message: collection.title,
              child: Text(
                collection.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
        if (!collection.showTitle) const Spacer(),
        const SizedBox(width: 12),
        ...collection.actions,
      ],
    ),
  );
}

class _CollectionFilter<I extends Object, T extends Object>
    extends StatelessWidget {
  const _CollectionFilter({
    required this.collection,
    required this.controller,
    required this.showing,
    required this.onToggle,
  });

  final McCollection<I, T> collection;
  final TextEditingController controller;
  final bool showing;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final labels = McUiLocalization.labelsOf(context);
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        12,
        !showing
            ? 0
            : collection.showTitle || collection.actions.isNotEmpty
            ? 0
            : 12,
        12,
        !showing ? 0 : 12,
      ),
      child: Row(
        children: [
          if (showing)
            Expanded(
              child: TextField(
                controller: controller,
                enabled: collection.filterEnabled,
                onChanged:
                    collection.onFilterChanged ?? collection.model.filter,
                decoration: InputDecoration(
                  labelText: collection.filterLabel,
                  prefixIcon: const Icon(Icons.search, size: 20),
                ),
              ),
            ),
          if (collection.compactFilter) ...[
            McIconAction(
              label: showing ? labels.closeFilter : collection.filterLabel,
              icon: Icon(showing ? Icons.close : Icons.search),
              onPressed: onToggle,
            ),
            if (!showing) const Spacer(),
          ],
          ...collection.filterActions,
        ],
      ),
    );
  }
}

class _CollectionFooter<I extends Object, T extends Object>
    extends StatelessWidget {
  const _CollectionFooter(this.collection);
  final McCollection<I, T> collection;

  @override
  Widget build(BuildContext context) {
    final labels = McUiLocalization.labelsOf(context);
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          if (collection.footer != null) collection.footer!,
          Text(
            collection.countLabel,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (collection.loading)
            TextButton(
              onPressed: collection.onCancel,
              child: Text(labels.cancelLoad),
            )
          else if (collection.onLoad != null)
            TextButton(
              onPressed: collection.onLoad,
              child: Text(
                collection.problem == null ? labels.loadMore : labels.retry,
              ),
            ),
          if (collection.onRefresh != null)
            McIconAction(
              label: labels.refreshCollection(collection.title),
              onPressed: collection.onRefresh,
              icon: const Icon(Icons.refresh, size: 18),
            ),
        ],
      ),
    );
  }
}
