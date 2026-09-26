part of 'collection.dart';

class _CollectionViewport<I extends Object, T extends Object>
    extends StatelessWidget {
  const _CollectionViewport({
    required this.collection,
    required this.scroll,
    required this.horizontalScroll,
    required this.focus,
    required this.navigation,
    required this.extent,
    required this.scale,
  });

  final McCollection<I, T> collection;
  final ScrollController scroll, horizontalScroll;
  final FocusNode focus;
  final _CollectionNavigation<I, T> navigation;
  final double extent, scale;
  McCollectionModel<I, T> get model => collection.model;

  double _headerMinimumWidth(BuildContext context, McColumn<T> column) {
    final painter = TextPainter(
      text: TextSpan(
        text: column.label,
        style: column.compare == null
            ? Theme.of(context).textTheme.bodySmall
            : Theme.of(context).textTheme.labelLarge,
      ),
      maxLines: 1,
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    return painter.width.ceilToDouble() +
        (column.compare == null ? 0 : 16 + McSpacing.small + 16);
  }

  List<double> _columnWidths(
    BuildContext context,
    double available,
    bool tree,
  ) {
    final widthScale = scale.clamp(1, 1.25).toDouble();
    final widths = <double>[
      for (var index = 0; index < collection.columns.length; index++)
        () {
          final column = collection.columns[index];
          final requested = (column.width ?? 0) * widthScale;
          final treeLead = tree && index == 0 ? 32.0 : 0.0;
          return requested
              .clamp(
                _headerMinimumWidth(context, column) + treeLead,
                double.infinity,
              )
              .toDouble();
        }(),
    ];
    final flexible = <int>[
      for (var index = 0; index < collection.columns.length; index++)
        if (collection.columns[index].width == null) index,
    ];
    final minimum = widths.fold(0.0, (sum, value) => sum + value);
    final remaining = available - minimum;
    if (remaining > 0 && flexible.isNotEmpty) {
      final share = remaining / flexible.length;
      for (final index in flexible) {
        widths[index] += share;
      }
    }
    return widths;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final colors = Theme.of(context).colorScheme;
      final tree = collection.showTree ?? (model.parentOf != null);
      final available = (bounds.maxWidth - 32)
          .clamp(0, double.infinity)
          .toDouble();
      final widths = _columnWidths(context, available, tree);
      final minimum = widths.fold(0.0, (sum, value) => sum + value);
      final overflows = minimum > available;
      final contentWidth = overflows ? minimum + 32 : bounds.maxWidth;
      return Scrollbar(
        controller: horizontalScroll,
        interactive: true,
        thumbVisibility: overflows,
        scrollbarOrientation: ScrollbarOrientation.bottom,
        child: SingleChildScrollView(
          controller: horizontalScroll,
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: contentWidth,
            height: bounds.maxHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.symmetric(
                      horizontal: BorderSide(color: colors.outlineVariant),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      for (
                        var index = 0;
                        index < collection.columns.length;
                        index++
                      )
                        _CollectionHeader(
                          collection: collection,
                          column: collection.columns[index],
                          width: widths[index],
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: _CollectionRows(
                    collection: collection,
                    scroll: scroll,
                    focus: focus,
                    navigation: navigation,
                    widths: widths,
                    tree: tree,
                    extent: extent,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _CollectionHeader<I extends Object, T extends Object>
    extends StatelessWidget {
  const _CollectionHeader({
    required this.collection,
    required this.column,
    required this.width,
  });

  final McCollection<I, T> collection;
  final McColumn<T> column;
  final double width;

  void _sort() {
    if (collection.onSort != null) {
      collection.onSort!(column.label);
      return;
    }
    final model = collection.model;
    final descending = model.sortLabel == column.label && !model.descending;
    model.sort(column.compare!, descending: descending, label: column.label);
  }

  @override
  Widget build(BuildContext context) {
    final model = collection.model;
    return SizedBox(
      width: width,
      child: column.compare == null
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                column.label,
                maxLines: 1,
                softWrap: false,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            )
          : Align(
              alignment: AlignmentDirectional.centerStart,
              child: McSortHeader(
                label: column.label,
                direction: model.sortLabel == column.label
                    ? model.descending
                          ? McSortDirection.descending
                          : McSortDirection.ascending
                    : null,
                onPressed: _sort,
              ),
            ),
    );
  }
}
