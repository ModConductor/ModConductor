import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'model.dart';

class McColumn<T> {
  const McColumn(
    this.label,
    this.cell, {
    this.width,
    this.compare,
    this.interactive = false,
  });
  final String label;
  final Widget Function(T) cell;
  final double? width;
  final Comparator<T>? compare;
  final bool interactive;
}

/// One bounded viewport and keyboard focus owner for tables and trees.
class McCollection<I extends Object, T extends Object> extends StatefulWidget {
  const McCollection({
    super.key,
    required this.model,
    required this.title,
    required this.columns,
    required this.filterLabel,
    required this.countLabel,
    this.empty = 'No items.',
    this.actions = const [],
    this.onSelect,
    this.onActivate,
    this.semanticLabel,
    this.focusNode,
    this.scrollController,
    this.loading = false,
    this.problem,
    this.onLoad,
    this.onCancel,
    this.onRefresh,
    this.footer,
    this.toolbar,
    this.multiSelect = false,
    this.selectMultiple = false,
    this.onMoveUp,
    this.onMoveDown,
  });
  final McCollectionModel<I, T> model;
  final String title, filterLabel, countLabel, empty;
  final List<McColumn<T>> columns;
  final List<Widget> actions;
  final ValueChanged<T>? onSelect, onActivate;
  final String Function(T)? semanticLabel;
  final FocusNode? focusNode;
  final ScrollController? scrollController;
  final bool loading;
  final String? problem;
  final VoidCallback? onLoad, onCancel, onRefresh;
  final Widget? footer, toolbar;
  final bool multiSelect, selectMultiple;
  final VoidCallback? onMoveUp, onMoveDown;
  @override
  State<McCollection<I, T>> createState() => _McCollectionState<I, T>();
}

class _McCollectionState<I extends Object, T extends Object>
    extends State<McCollection<I, T>> {
  final _ownScroll = ScrollController();
  ScrollController get _scroll => widget.scrollController ?? _ownScroll;
  final _filter = TextEditingController();
  late final _ownFocus = FocusNode(debugLabel: widget.title);
  FocusNode get _focus => widget.focusNode ?? _ownFocus;
  McCollectionModel<I, T> get model => widget.model;
  double _extent = 48;
  @override
  void initState() {
    super.initState();
    _filter.text = model.query;
  }

  @override
  void didUpdateWidget(McCollection<I, T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_filter.text != model.query) _filter.text = model.query;
  }

  @override
  void dispose() {
    _ownFocus.dispose();
    _ownScroll.dispose();
    _filter.dispose();
    super.dispose();
  }

  void _select(
    I id, {
    bool pointer = false,
    bool toggle = false,
    bool extend = false,
  }) {
    final keys = HardwareKeyboard.instance;
    model.select(
      id,
      toggle:
          widget.multiSelect &&
          (toggle ||
              (pointer &&
                  (widget.selectMultiple ||
                      keys.isControlPressed ||
                      keys.isMetaPressed))),
      extend:
          widget.multiSelect && (extend || (pointer && keys.isShiftPressed)),
    );
    _focus.requestFocus();
    widget.onSelect?.call(model[id]!);
  }

  void _reveal(I id) {
    final position = model.position(id);
    if (position == null || !_scroll.hasClients) return;
    final start = position * _extent;
    final end = start + _extent;
    final viewport = _scroll.position.viewportDimension;
    final offset = _scroll.offset;
    if (start < offset || end > offset + viewport) {
      _scroll.jumpTo(
        (start < offset ? start : end - viewport).clamp(
          0.0,
          _scroll.position.maxScrollExtent,
        ),
      );
    }
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (widget.multiSelect && HardwareKeyboard.instance.isControlPressed) {
      if (key == LogicalKeyboardKey.arrowUp ||
          key == LogicalKeyboardKey.arrowDown) {
        (key == LogicalKeyboardKey.arrowUp
                ? widget.onMoveUp
                : widget.onMoveDown)
            ?.call();
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.space &&
          _focus.hasPrimaryFocus &&
          model.focusedId != null) {
        _select(model.focusedId!, toggle: true);
        return KeyEventResult.handled;
      }
    }
    if (!_focus.hasPrimaryFocus) return KeyEventResult.ignored;
    final visible = model.visible;
    if (visible.isEmpty) return KeyEventResult.ignored;
    final current = model.position(model.focusedId);
    final page = _scroll.hasClients
        ? (_scroll.position.viewportDimension / _extent).floor().clamp(1, 1000)
        : 1;
    int? next;
    if (key == LogicalKeyboardKey.arrowDown) next = (current ?? -1) + 1;
    if (key == LogicalKeyboardKey.arrowUp) next = (current ?? 1) - 1;
    if (key == LogicalKeyboardKey.home) next = 0;
    if (key == LogicalKeyboardKey.end) next = visible.length - 1;
    if (key == LogicalKeyboardKey.pageDown) next = (current ?? 0) + page;
    if (key == LogicalKeyboardKey.pageUp) next = (current ?? 0) - page;
    if (next != null) {
      final id = visible[next.clamp(0, visible.length - 1)];
      _select(id, extend: HardwareKeyboard.instance.isShiftPressed);
      _reveal(id);
      return KeyEventResult.handled;
    }
    final id = current == null ? visible.first : visible[current];
    if (key == LogicalKeyboardKey.arrowRight && model.branch(id)) {
      if (!model.expanded(id)) {
        model.toggle(id);
      } else if (current != null && current + 1 < visible.length) {
        _select(visible[current + 1]);
        _reveal(visible[current + 1]);
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft && model.parentOf != null) {
      if (model.branch(id) && model.expanded(id)) {
        model.toggle(id);
      } else {
        final parent = model.parent(id);
        if (parent != null) {
          _select(parent);
          _reveal(parent);
        }
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space) {
      _select(id);
      if (model.branch(id)) {
        model.toggle(id);
      } else {
        widget.onActivate?.call(model[id]!);
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([model, _focus]),
    builder: (context, _) {
      final colors = Theme.of(context).colorScheme;
      final scale = MediaQuery.textScalerOf(context).scale(1);
      _extent = 48 * scale.clamp(1, 3);
      Widget cell(Widget child, double? width) => width == null
          ? Expanded(child: child)
          : SizedBox(width: width * scale.clamp(1, 1.25), child: child);
      final visible = model.visible;
      if (_focus.hasPrimaryFocus && model.focusedId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && model.focusedId != null) _reveal(model.focusedId!);
        });
      }
      return Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Tooltip(
                      message: widget.title,
                      child: Text(
                        widget.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ...widget.actions,
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: TextField(
                controller: _filter,
                onChanged: model.filter,
                decoration: InputDecoration(
                  labelText: widget.filterLabel,
                  prefixIcon: const Icon(Icons.search, size: 20),
                ),
              ),
            ),
            if (widget.toolbar != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: widget.toolbar!,
              ),
            Container(
              decoration: BoxDecoration(
                border: Border.symmetric(
                  horizontal: BorderSide(color: colors.outlineVariant),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  for (final column in widget.columns)
                    cell(
                      column.compare == null
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Text(
                                column.label,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            )
                          : Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed: () {
                                  final descending =
                                      model.sortLabel == column.label &&
                                      !model.descending;
                                  model.sort(
                                    column.compare!,
                                    descending: descending,
                                    label: column.label,
                                  );
                                },
                                child: Text(
                                  '${column.label}${model.sortLabel == column.label
                                      ? model.descending
                                            ? ' ↓'
                                            : ' ↑'
                                      : ''}',
                                ),
                              ),
                            ),
                      column.width,
                    ),
                ],
              ),
            ),
            Expanded(
              child: Focus(
                focusNode: _focus,
                onKeyEvent: _key,
                child: Semantics(
                  container: true,
                  explicitChildNodes: true,
                  label: widget.title,
                  child: visible.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              model.query.isNotEmpty
                                  ? 'No matches in loaded items.'
                                  : widget.empty,
                            ),
                          ),
                        )
                      : Scrollbar(
                          controller: _scroll,
                          child: ListView.builder(
                            controller: _scroll,
                            itemExtent: _extent,
                            itemCount: visible.length,
                            findChildIndexCallback: (key) => key is ValueKey<I>
                                ? model.position(key.value)
                                : null,
                            itemBuilder: (context, index) {
                              final id = visible[index], row = model[id]!;
                              final selected = model.selectedIds.contains(id);
                              final focused =
                                  id == model.focusedId &&
                                  _focus.hasPrimaryFocus;
                              final branch = model.branch(id);
                              return Semantics(
                                key: ValueKey<I>(id),
                                container: true,
                                selected: selected,
                                focusable: true,
                                focused: focused,
                                expanded: branch ? model.expanded(id) : null,
                                label: [
                                  widget.semanticLabel?.call(row) ??
                                      model.labelOf(row),
                                  if (branch)
                                    model.expanded(id)
                                        ? 'Expanded'
                                        : 'Collapsed',
                                ].join(', '),
                                onTap: () => _select(id),
                                onFocus: () => _select(id),
                                child: Material(
                                  color: selected
                                      ? colors.primary.withValues(alpha: .14)
                                      : Colors.transparent,
                                  child: InkWell(
                                    canRequestFocus: false,
                                    excludeFromSemantics: true,
                                    onTap: () => _select(id, pointer: true),
                                    onDoubleTap: branch
                                        ? () => model.toggle(id)
                                        : null,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border(
                                          left: BorderSide(
                                            width: 3,
                                            color: selected
                                                ? colors.primary
                                                : Colors.transparent,
                                          ),
                                          bottom: BorderSide(
                                            color: focused
                                                ? colors.primary
                                                : colors.outlineVariant
                                                      .withValues(alpha: .55),
                                          ),
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 13,
                                        vertical: 5,
                                      ),
                                      child: Row(
                                        children: [
                                          if (model.parentOf != null) ...[
                                            SizedBox(
                                              width: (model.depth(id) * 18.0)
                                                  .clamp(0, 108),
                                            ),
                                            SizedBox(
                                              width: 32,
                                              child: branch
                                                  ? McIconAction(
                                                      padding: EdgeInsets.zero,
                                                      label:
                                                          '${model.expanded(id) ? 'Collapse' : 'Expand'} ${model.labelOf(row)}',
                                                      onPressed: () =>
                                                          model.toggle(id),
                                                      icon: Icon(
                                                        model.expanded(id)
                                                            ? Icons
                                                                  .keyboard_arrow_down
                                                            : Icons
                                                                  .chevron_right,
                                                        size: 20,
                                                      ),
                                                    )
                                                  : const Icon(
                                                      Icons
                                                          .insert_drive_file_outlined,
                                                      size: 19,
                                                    ),
                                            ),
                                          ],
                                          for (final column in widget.columns)
                                            cell(
                                              ExcludeSemantics(
                                                excluding: !column.interactive,
                                                child: column.cell(row),
                                              ),
                                              column.width,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ),
            ),
            if (widget.problem != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: McStatus(
                  title: widget.problem!,
                  tone: McStatusTone.error,
                ),
              ),
            Container(
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
                  if (widget.footer != null) widget.footer!,
                  Text(
                    widget.countLabel,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (widget.loading)
                    TextButton(
                      onPressed: widget.onCancel,
                      child: const Text('Cancel load'),
                    )
                  else if (widget.onLoad != null)
                    TextButton(
                      onPressed: widget.onLoad,
                      child: Text(
                        widget.problem == null ? 'Load more' : 'Retry',
                      ),
                    ),
                  if (widget.onRefresh != null)
                    McIconAction(
                      label: 'Refresh ${widget.title}',
                      onPressed: widget.onRefresh,
                      icon: const Icon(Icons.refresh, size: 18),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

class McCollectionName extends StatelessWidget {
  const McCollectionName(this.text, {super.key, this.icon});
  final String text;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      if (icon != null) ...[
        Icon(
          icon,
          size: 19,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 9),
      ],
      Expanded(
        child: Tooltip(
          message: text,
          child: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis),
        ),
      ),
    ],
  );
}
