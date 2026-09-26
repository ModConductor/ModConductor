part of 'collection.dart';

class _CollectionNavigation<I extends Object, T extends Object> {
  _CollectionNavigation({
    required this.model,
    required this.focus,
    required this.scroll,
    required this.extent,
    required this.context,
    required this.collection,
  });

  final McCollectionModel<I, T> model;
  final FocusNode focus;
  final ScrollController scroll;
  final double Function() extent;
  final BuildContext context;
  final McCollection<I, T> collection;

  void select(
    I id, {
    bool pointer = false,
    bool toggle = false,
    bool extend = false,
  }) {
    final keys = HardwareKeyboard.instance;
    model.select(
      id,
      toggle:
          collection.multiSelect &&
          (toggle ||
              (pointer &&
                  (collection.selectMultiple ||
                      keys.isControlPressed ||
                      keys.isMetaPressed))),
      extend:
          collection.multiSelect &&
          (extend || (pointer && keys.isShiftPressed)),
    );
    focus.requestFocus();
    collection.onSelect?.call(model[id]!);
  }

  void reveal(I id) {
    final position = model.position(id);
    if (position == null || !scroll.hasClients) return;
    final start = position * extent();
    final end = start + extent();
    final viewport = scroll.position.viewportDimension;
    final offset = scroll.offset;
    if (start < offset || end > offset + viewport) {
      scroll.jumpTo(
        (start < offset ? start : end - viewport).clamp(
          0.0,
          scroll.position.maxScrollExtent,
        ),
      );
    }
  }

  KeyEventResult key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (_modifierAction(key)) return KeyEventResult.handled;
    if (!focus.hasPrimaryFocus) return KeyEventResult.ignored;
    final visible = model.visible;
    if (visible.isEmpty) return KeyEventResult.ignored;
    final current = model.position(model.focusedId);
    if (_move(key, visible, current)) return KeyEventResult.handled;
    final id = current == null ? visible.first : visible[current];
    if (_tree(key, id, visible, current)) return KeyEventResult.handled;
    if (_activate(key, id)) return KeyEventResult.handled;
    return KeyEventResult.ignored;
  }

  bool _modifierAction(LogicalKeyboardKey key) {
    if (!collection.multiSelect ||
        !HardwareKeyboard.instance.isControlPressed) {
      return false;
    }
    if (key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowDown) {
      (key == LogicalKeyboardKey.arrowUp
              ? collection.onMoveUp
              : collection.onMoveDown)
          ?.call();
      return true;
    }
    if (key != LogicalKeyboardKey.space ||
        !focus.hasPrimaryFocus ||
        model.focusedId == null) {
      return false;
    }
    select(model.focusedId!, toggle: true);
    return true;
  }

  bool _move(LogicalKeyboardKey key, List<I> visible, int? current) {
    final page = scroll.hasClients
        ? (scroll.position.viewportDimension / extent()).floor().clamp(1, 1000)
        : 1;
    int? next;
    if (key == LogicalKeyboardKey.arrowDown) next = (current ?? -1) + 1;
    if (key == LogicalKeyboardKey.arrowUp) next = (current ?? 1) - 1;
    if (key == LogicalKeyboardKey.home) next = 0;
    if (key == LogicalKeyboardKey.end) next = visible.length - 1;
    if (key == LogicalKeyboardKey.pageDown) next = (current ?? 0) + page;
    if (key == LogicalKeyboardKey.pageUp) next = (current ?? 0) - page;
    if (next == null) return false;
    final id = visible[next.clamp(0, visible.length - 1)];
    select(id, extend: HardwareKeyboard.instance.isShiftPressed);
    reveal(id);
    return true;
  }

  bool _tree(LogicalKeyboardKey key, I id, List<I> visible, int? current) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final expandKey = rtl
        ? LogicalKeyboardKey.arrowLeft
        : LogicalKeyboardKey.arrowRight;
    final collapseKey = rtl
        ? LogicalKeyboardKey.arrowRight
        : LogicalKeyboardKey.arrowLeft;
    if (key == expandKey && model.branch(id)) {
      _expand(id, visible, current);
      return true;
    }
    if (key != collapseKey || model.parentOf == null) return false;
    _collapse(id);
    return true;
  }

  void _expand(I id, List<I> visible, int? current) {
    if (!model.expanded(id)) {
      model.toggle(id);
      return;
    }
    if (current == null || current + 1 >= visible.length) return;
    select(visible[current + 1]);
    reveal(visible[current + 1]);
  }

  void _collapse(I id) {
    if (model.branch(id) && model.expanded(id)) {
      model.toggle(id);
      return;
    }
    final parent = model.parent(id);
    if (parent == null) return;
    select(parent);
    reveal(parent);
  }

  bool _activate(LogicalKeyboardKey key, I id) {
    if (key != LogicalKeyboardKey.enter && key != LogicalKeyboardKey.space) {
      return false;
    }
    select(id);
    if (model.branch(id)) {
      model.toggle(id);
    } else {
      collection.onActivate?.call(model[id]!);
    }
    return true;
  }
}
