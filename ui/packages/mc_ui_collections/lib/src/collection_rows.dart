part of 'collection.dart';

class _CollectionRows<I extends Object, T extends Object>
    extends StatelessWidget {
  const _CollectionRows({
    required this.collection,
    required this.scroll,
    required this.focus,
    required this.navigation,
    required this.widths,
    required this.tree,
    required this.extent,
  });

  final McCollection<I, T> collection;
  final ScrollController scroll;
  final FocusNode focus;
  final _CollectionNavigation<I, T> navigation;
  final List<double> widths;
  final bool tree;
  final double extent;

  @override
  Widget build(BuildContext context) {
    final model = collection.model;
    final labels = McUiLocalization.labelsOf(context);
    final visible = model.visible;
    return Focus(
      focusNode: focus,
      onKeyEvent: navigation.key,
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        label: collection.title,
        child: visible.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child:
                      collection.emptyContent ??
                      Text(
                        model.query.isNotEmpty
                            ? labels.noMatches
                            : collection.empty ?? labels.noItems,
                      ),
                ),
              )
            : Scrollbar(
                controller: scroll,
                child: ListView.builder(
                  controller: scroll,
                  itemExtent: extent,
                  itemCount: visible.length,
                  findChildIndexCallback: (key) =>
                      key is ValueKey<I> ? model.position(key.value) : null,
                  itemBuilder: (context, index) => _CollectionRow(
                    key: ValueKey<I>(visible[index]),
                    collection: collection,
                    navigation: navigation,
                    focus: focus,
                    id: visible[index],
                    widths: widths,
                    tree: tree,
                  ),
                ),
              ),
      ),
    );
  }
}

class _CollectionRow<I extends Object, T extends Object>
    extends StatelessWidget {
  const _CollectionRow({
    super.key,
    required this.collection,
    required this.navigation,
    required this.focus,
    required this.id,
    required this.widths,
    required this.tree,
  });

  final McCollection<I, T> collection;
  final _CollectionNavigation<I, T> navigation;
  final FocusNode focus;
  final I id;
  final List<double> widths;
  final bool tree;

  Widget _cell(int index, T row, bool branch) {
    final column = collection.columns[index];
    final contents = ExcludeSemantics(
      excluding: !column.interactive,
      child: column.cell(row),
    );
    if (!tree || index != 0) {
      return SizedBox(width: widths[index], child: contents);
    }
    final model = collection.model;
    return SizedBox(
      width: widths[index],
      child: Row(
        children: [
          SizedBox(width: (model.depth(id) * 18.0).clamp(0, 108)),
          SizedBox(
            width: 32,
            child: branch
                ? McCollectionExpander(
                    model: model,
                    id: id,
                    label: collection.nodeLabel?.call(row),
                  )
                : ExcludeSemantics(
                    child:
                        collection.nodeIcon?.call(row) ??
                        const Icon(Icons.insert_drive_file_outlined, size: 19),
                  ),
          ),
          Expanded(child: contents),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = collection.model;
    final colors = Theme.of(context).colorScheme;
    final labels = McUiLocalization.labelsOf(context);
    final row = model[id]!;
    final selected = model.selectedIds.contains(id);
    final focused = id == model.focusedId && focus.hasPrimaryFocus;
    final branch = model.branch(id);
    return Semantics(
      container: true,
      selected: selected,
      focusable: true,
      focused: focused,
      expanded: branch ? model.expanded(id) : null,
      label: [
        collection.semanticLabel?.call(row) ?? model.labelOf(row),
        if (branch) model.expanded(id) ? labels.expanded : labels.collapsed,
      ].join(', '),
      onTap: () => navigation.select(id),
      onFocus: () => navigation.select(id),
      child: Material(
        color: selected
            ? colors.primary.withValues(alpha: .14)
            : Colors.transparent,
        child: InkWell(
          canRequestFocus: false,
          excludeFromSemantics: true,
          onTap: () => navigation.select(id, pointer: true),
          onDoubleTap: branch ? () => model.toggle(id) : null,
          child: Container(
            decoration: BoxDecoration(
              border: BorderDirectional(
                start: BorderSide(
                  width: 3,
                  color: selected ? colors.primary : Colors.transparent,
                ),
                bottom: BorderSide(
                  color: focused
                      ? colors.primary
                      : colors.outlineVariant.withValues(alpha: .55),
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
            child: Row(
              children: [
                for (var index = 0; index < collection.columns.length; index++)
                  _cell(index, row, branch),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
