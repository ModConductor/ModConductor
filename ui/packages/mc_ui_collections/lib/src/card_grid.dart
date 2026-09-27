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
    this.onActivate,
    this.onLoad,
    this.loading = false,
    this.problem,
    this.empty = 'No mods in this collection.',
  });

  final McCollectionModel<I, T> model;
  final Widget Function(T) card;
  final String filterLabel, empty;
  final ValueChanged<T>? onActivate;
  final VoidCallback? onLoad;
  final bool loading;
  final String? problem;

  @override
  State<McCardGrid<I, T>> createState() => _McCardGridState<I, T>();
}

class _McCardGridState<I extends Object, T extends Object>
    extends State<McCardGrid<I, T>> {
  final scroll = ScrollController();
  final filter = TextEditingController();
  final nodes = <I, FocusNode>{};
  double rowExtent = 446;

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
      widget.onActivate?.call(widget.model[visible[index]]!);
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
    widget.model.select(id);
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
        TextField(
          controller: filter,
          decoration: InputDecoration(
            labelText: widget.filterLabel,
            prefixIcon: const Icon(Icons.filter_list),
          ),
          onChanged: widget.model.filter,
        ),
        McAsyncStatusSlot(active: widget.loading, problem: widget.problem),
        Expanded(
          child: LayoutBuilder(
            builder: (context, bounds) {
              final columns = bounds.maxWidth >= 1200
                  ? 3
                  : bounds.maxWidth >= 700
                  ? 2
                  : 1;
              final scale = MediaQuery.textScalerOf(context)
                  .scale(1)
                  .clamp(1, 2);
              rowExtent = 430 * scale.toDouble() + 16;
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
                  mainAxisExtent: 430 * scale.toDouble(),
                ),
                itemCount: visible.length,
                itemBuilder: (context, index) {
                  final id = visible[index], item = widget.model[id]!;
                  final node = nodes.putIfAbsent(id, () => FocusNode());
                  return Focus(
                    focusNode: node,
                    onFocusChange: (focused) {
                      if (focused) widget.model.select(id);
                    },
                    onKeyEvent: (_, event) => _key(event, index, columns),
                    child: InkWell(
                      onTap: () {
                        widget.model.select(id);
                        widget.onActivate?.call(item);
                      },
                      child: widget.card(item),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    ),
  );
}
