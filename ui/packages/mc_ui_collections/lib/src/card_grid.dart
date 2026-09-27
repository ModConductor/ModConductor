import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'model.dart';

class McCardGrid<I extends Object, T extends Object> extends StatefulWidget {
  const McCardGrid({
    super.key,
    required this.model,
    required this.card,
    required this.filterLabel,
    this.cardWithFocus,
    this.onSelect,
    this.filterActions = const [],
    this.cardExtent = 430,
    this.compactCardExtent,
    this.twoColumnWidth = 700,
    this.countLabel,
    this.onRefresh,
    this.onActivate,
    this.onLoad,
    this.loading = false,
    this.problem,
    this.empty = 'No mods in this collection.',
  });

  final McCollectionModel<I, T> model;
  final Widget Function(T) card;
  final Widget Function(T, bool)? cardWithFocus;
  final String filterLabel, empty;
  final ValueChanged<T>? onActivate, onSelect;
  final List<Widget> filterActions;
  final double cardExtent;
  final double? compactCardExtent;
  final double twoColumnWidth;
  final String? countLabel;
  final VoidCallback? onRefresh;
  final VoidCallback? onLoad;
  final bool loading;
  final String? problem;

  @override
  McCardGridState<I, T> createState() => McCardGridState<I, T>();
}

class McCardGridState<I extends Object, T extends Object>
    extends State<McCardGrid<I, T>> {
  final scroll = ScrollController();
  final filter = TextEditingController();
  final nodes = <I, FocusNode>{};
  double rowExtent = 446;
  int columnCount = 1;

  void focusSelected() {
    final selected = widget.model.selectedId;
    if (selected == null || !scroll.hasClients) return;
    final index = widget.model.visible.indexOf(selected);
    if (index < 0) return;
    final node = nodes[selected];
    if (node?.context != null) {
      node!.requestFocus();
      return;
    }
    scroll.jumpTo(
      ((index ~/ columnCount) * rowExtent).clamp(
        0,
        scroll.position.maxScrollExtent,
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) nodes[selected]?.requestFocus();
    });
  }

  @override
  void initState() {
    super.initState();
    filter.text = widget.model.query;
    scroll.addListener(_onScroll);
  }

  void _onScroll() {
    if (widget.onLoad != null &&
        scroll.hasClients &&
        scroll.position.extentAfter < 500 &&
        !widget.loading) {
      widget.onLoad!();
    }
  }

  @override
  void didUpdateWidget(McCardGrid<I, T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.model, widget.model)) {
      filter.text = widget.model.query;
    }
  }

  @override
  void dispose() {
    scroll.dispose();
    filter.dispose();
    for (final node in nodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  KeyEventResult _key(KeyEvent event, int index, int columns) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final visible = widget.model.visible;
    if (!nodes[visible[index]]!.hasPrimaryFocus) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.space) {
      final activate = widget.onActivate;
      if (activate == null) return KeyEventResult.ignored;
      activate(widget.model[visible[index]]!);
      return KeyEventResult.handled;
    }
    final delta = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowLeft => -1,
      LogicalKeyboardKey.arrowRight => 1,
      LogicalKeyboardKey.arrowUp => -columns,
      LogicalKeyboardKey.arrowDown => columns,
      _ => 0,
    };
    if (delta == 0) return KeyEventResult.ignored;
    final next = index + delta;
    if (next < 0 || next >= visible.length) return KeyEventResult.ignored;
    final id = visible[next];
    if (widget.onSelect case final select?) {
      select(widget.model[id]!);
    } else {
      widget.model.select(id);
    }
    final node = nodes[id];
    if (node != null && node.context != null) {
      node.requestFocus();
    } else {
      final row = next ~/ columns;
      scroll.jumpTo(
        (row * rowExtent).clamp(0, scroll.position.maxScrollExtent),
      );
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => nodes[id]?.requestFocus(),
      );
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.model,
    builder: (context, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: filter,
                decoration: InputDecoration(
                  labelText: widget.filterLabel,
                  prefixIcon: const Icon(Icons.filter_list),
                ),
                onChanged: widget.model.filter,
              ),
            ),
            if (widget.filterActions.isNotEmpty) ...[
              const SizedBox(width: 12),
              ...widget.filterActions,
            ],
          ],
        ),
        McAsyncStatusSlot(active: widget.loading, problem: widget.problem),
        Expanded(
          child: LayoutBuilder(
            builder: (context, bounds) {
              final columns = bounds.maxWidth >= 1200
                  ? 3
                  : bounds.maxWidth >= widget.twoColumnWidth
                  ? 2
                  : 1;
              columnCount = columns;
              final scale = MediaQuery.textScalerOf(context)
                  .scale(1)
                  .clamp(1, 2);
              final cardWidth =
                  (bounds.maxWidth - 8 - 16 * (columns - 1)) / columns;
              final extent = cardWidth < 400
                  ? widget.compactCardExtent ?? widget.cardExtent
                  : widget.cardExtent;
              rowExtent = extent * scale.toDouble() + 16;
              final visible = widget.model.visible;
              if (visible.isEmpty && widget.loading) {
                return const SizedBox.shrink();
              }
              if (visible.isEmpty) {
                return Center(child: McStatus(title: widget.empty));
              }
              return GridView.builder(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(0, 0, 8, 16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  mainAxisExtent: extent * scale.toDouble(),
                ),
                itemCount: visible.length,
                itemBuilder: (context, index) {
                  final id = visible[index], item = widget.model[id]!;
                  final node = nodes.putIfAbsent(id, () => FocusNode());
                  return Focus(
                    key: ValueKey(id),
                    focusNode: node,
                    onFocusChange: (focused) {
                      if (focused) {
                        if (widget.onSelect case final select?) {
                          select(item);
                        } else {
                          widget.model.select(id);
                        }
                      }
                    },
                    onKeyEvent: (_, event) => _key(event, index, columns),
                    child: ListenableBuilder(
                      listenable: node,
                      builder: (context, _) => InkWell(
                        onTap: () {
                          if (widget.onSelect case final select?) {
                            select(item);
                          } else {
                            widget.model.select(id);
                          }
                          widget.onActivate?.call(item);
                        },
                        child:
                            widget.cardWithFocus?.call(item, node.hasFocus) ??
                            widget.card(item),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        if (widget.countLabel != null ||
            widget.onLoad != null ||
            widget.onRefresh != null)
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              if (widget.countLabel != null) Text(widget.countLabel!),
              if (widget.onRefresh != null)
                McAction(label: 'Refresh', onPressed: widget.onRefresh),
              if (widget.onLoad != null)
                McAction(label: 'Load more', onPressed: widget.onLoad),
            ],
          ),
      ],
    ),
  );
}
