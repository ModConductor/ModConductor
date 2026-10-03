part of 'collection.dart';

enum McCollectionDropPosition { before, after, inside }

class _CollectionDrag<I extends Object> {
  const _CollectionDrag(this.model, this.scope, this.ids);
  final Object model, scope;
  final List<I> ids;
}

class _CollectionDragRow<I extends Object, T extends Object>
    extends StatefulWidget {
  const _CollectionDragRow({
    required this.collection,
    required this.navigation,
    required this.id,
    required this.child,
  });
  final McCollection<I, T> collection;
  final _CollectionNavigation<I, T> navigation;
  final I id;
  final Widget child;

  @override
  State<_CollectionDragRow<I, T>> createState() =>
      _CollectionDragRowState<I, T>();
}

class _CollectionDragRowState<I extends Object, T extends Object>
    extends State<_CollectionDragRow<I, T>> {
  McCollectionDropPosition? _position;
  EdgeDraggingAutoScroller? _scroller;

  @override
  void dispose() {
    _scroller?.stopAutoScroll();
    super.dispose();
  }

  McCollectionDropPosition _placement(Offset offset) {
    final box = context.findRenderObject()! as RenderBox;
    final fraction = box.globalToLocal(offset).dy / box.size.height;
    final collection = widget.collection;
    if (collection.drawerLabel?.call(collection.model[widget.id]!) != null &&
        fraction >= .25 &&
        fraction <= .75) {
      return McCollectionDropPosition.inside;
    }
    return fraction < .5
        ? McCollectionDropPosition.before
        : McCollectionDropPosition.after;
  }

  bool _accept(
    DragTargetDetails<_CollectionDrag<I>> details, {
    bool anyPosition = false,
  }) {
    final collection = widget.collection;
    final drag = details.data;
    final position = _placement(details.offset);
    return identical(drag.model, collection.model) &&
        drag.scope == collection.dragScope &&
        !drag.ids.contains(widget.id) &&
        (collection.canDrop == null ||
            (anyPosition
                ? McCollectionDropPosition.values.any(
                    (position) =>
                        collection.canDrop!(drag.ids, widget.id, position),
                  )
                : collection.canDrop!(drag.ids, widget.id, position)));
  }

  void _hover(DragTargetDetails<_CollectionDrag<I>> details) {
    final position = _accept(details) ? _placement(details.offset) : null;
    if (position != _position) setState(() => _position = position);
  }

  @override
  Widget build(BuildContext context) {
    final collection = widget.collection;
    final model = collection.model;
    final row = model[widget.id]!;
    final ids = model.selectedIds.contains(widget.id)
        ? model.selectedIds.toList()
        : [widget.id];
    Widget child = widget.child;
    if (collection.dragScope != null &&
        ids.every(
          (id) =>
              model[id] != null &&
              (collection.canDrag?.call(model[id]!) ?? true),
        )) {
      child = Draggable<_CollectionDrag<I>>(
        data: _CollectionDrag(
          model,
          collection.dragScope!,
          List.unmodifiable(ids),
        ),
        maxSimultaneousDrags: 1,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        onDragStarted: () {
          if (!model.selectedIds.contains(widget.id)) {
            widget.navigation.select(widget.id);
          }
        },
        onDragUpdate: (details) {
          _scroller ??= EdgeDraggingAutoScroller(
            Scrollable.of(context),
            velocityScalar: 20,
          );
          _scroller!.startAutoScrollIfNecessary(
            Rect.fromCenter(
              center: details.globalPosition,
              width: 1,
              height: 40,
            ),
          );
        },
        onDragEnd: (_) => _scroller?.stopAutoScroll(),
        onDraggableCanceled: (_, _) => _scroller?.stopAutoScroll(),
        feedback: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              ids.length == 1
                  ? model.labelOf(row)
                  : '${model.labelOf(row)} + ${ids.length - 1}',
            ),
          ),
        ),
        child: child,
      );
    }
    return DragTarget<_CollectionDrag<I>>(
      onWillAcceptWithDetails: (details) {
        _hover(details);
        return _accept(details, anyPosition: true);
      },
      onMove: _hover,
      onLeave: (_) => setState(() => _position = null),
      onAcceptWithDetails: (details) {
        if (_accept(details)) {
          collection.onDrop!(
            details.data.ids,
            widget.id,
            _placement(details.offset),
          );
        }
        setState(() => _position = null);
      },
      builder: (context, candidates, rejected) {
        final color = Theme.of(context).colorScheme.primary;
        return DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            color: _position == McCollectionDropPosition.inside
                ? color.withValues(alpha: .14)
                : null,
            border: _position == null
                ? null
                : Border(
                    top: BorderSide(
                      color: _position != McCollectionDropPosition.after
                          ? color
                          : Colors.transparent,
                      width: 2,
                    ),
                    bottom: BorderSide(
                      color: _position != McCollectionDropPosition.before
                          ? color
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
          ),
          child: child,
        );
      },
    );
  }
}
