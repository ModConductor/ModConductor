import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'model.dart';

part 'collection_navigation.dart';
part 'collection_viewport.dart';
part 'collection_rows.dart';
part 'collection_chrome.dart';

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
    this.showTitle = true,
    required this.columns,
    required this.filterLabel,
    required this.countLabel,
    this.empty,
    this.emptyContent,
    this.actions = const [],
    this.onSelect,
    this.onActivate,
    this.semanticLabel,
    this.nodeIcon,
    this.nodeLabel,
    this.showTree,
    this.filterText,
    this.filterEnabled = true,
    this.compactFilter = false,
    this.onFilterChanged,
    this.filterActions = const [],
    this.onSort,
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
  final String title, filterLabel, countLabel;
  final String? empty;
  final bool showTitle;
  final List<McColumn<T>> columns;
  final List<Widget> actions;
  final ValueChanged<T>? onSelect, onActivate;
  final String Function(T)? semanticLabel;
  final Widget Function(T)? nodeIcon;
  final String Function(T)? nodeLabel;
  final bool? showTree;
  final String? filterText;
  final bool filterEnabled, compactFilter;
  final ValueChanged<String>? onFilterChanged, onSort;
  final List<Widget> filterActions;
  final FocusNode? focusNode;
  final ScrollController? scrollController;
  final bool loading;
  final String? problem;
  final VoidCallback? onLoad, onCancel, onRefresh;
  final Widget? footer, toolbar, emptyContent;
  final bool multiSelect, selectMultiple;
  final VoidCallback? onMoveUp, onMoveDown;
  @override
  State<McCollection<I, T>> createState() => _McCollectionState<I, T>();
}

class _McCollectionState<I extends Object, T extends Object>
    extends State<McCollection<I, T>> {
  final _ownScroll = ScrollController();
  ScrollController get _scroll => widget.scrollController ?? _ownScroll;
  final _horizontalScroll = ScrollController();
  final _filter = TextEditingController();
  late final _ownFocus = FocusNode(debugLabel: widget.title);
  FocusNode get _focus => widget.focusNode ?? _ownFocus;
  double _extent = 48;
  bool filterOpen = false;
  bool get showingFilter =>
      !widget.compactFilter || filterOpen || _filter.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _filter.text = widget.filterText ?? widget.model.query;
  }

  @override
  void didUpdateWidget(McCollection<I, T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_filter.text != (widget.filterText ?? widget.model.query)) {
      _filter.text = widget.filterText ?? widget.model.query;
    }
  }

  @override
  void dispose() {
    _ownFocus.dispose();
    _ownScroll.dispose();
    _horizontalScroll.dispose();
    _filter.dispose();
    super.dispose();
  }

  void _toggleFilter() => setState(() {
    filterOpen = !showingFilter;
    if (!filterOpen) {
      _filter.clear();
      (widget.onFilterChanged ?? widget.model.filter)('');
    }
  });

  void _revealFocused(_CollectionNavigation<I, T> navigation) {
    if (!_focus.hasPrimaryFocus || widget.model.focusedId == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.model.focusedId != null) {
        navigation.reveal(widget.model.focusedId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([widget.model, _focus]),
    builder: (context, _) {
      final colors = Theme.of(context).colorScheme;
      final scale = MediaQuery.textScalerOf(context).scale(1);
      _extent = 52 * scale.clamp(1, 3);
      final navigation = _CollectionNavigation<I, T>(
        model: widget.model,
        focus: _focus,
        scroll: _scroll,
        extent: () => _extent,
        context: context,
        collection: widget,
      );
      _revealFocused(navigation);
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
            if (widget.showTitle || widget.actions.isNotEmpty)
              _CollectionTitle(widget),
            _CollectionFilter(
              collection: widget,
              controller: _filter,
              showing: showingFilter,
              onToggle: _toggleFilter,
            ),
            if (widget.toolbar != null)
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 12, 8),
                child: widget.toolbar!,
              ),
            Expanded(
              child: _CollectionViewport<I, T>(
                collection: widget,
                scroll: _scroll,
                horizontalScroll: _horizontalScroll,
                focus: _focus,
                navigation: navigation,
                extent: _extent,
                scale: scale,
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
            _CollectionFooter(widget),
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
  Widget build(BuildContext context) => Tooltip(
    message: text,
    child: icon == null
        ? Text(text, maxLines: 2, overflow: TextOverflow.ellipsis)
        : McIconLabel(
            icon: Icon(
              icon,
              size: 19,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            label: text,
            expanded: true,
            maxLines: 2,
            gap: 9,
          ),
  );
}

class McCollectionExpander<I extends Object, T extends Object>
    extends StatelessWidget {
  const McCollectionExpander({
    super.key,
    required this.model,
    required this.id,
    this.label,
  });
  final McCollectionModel<I, T> model;
  final I id;
  final String? label;
  @override
  Widget build(BuildContext context) {
    final labels = McUiLocalization.labelsOf(context);
    final item = label ?? model.labelOf(model[id]!);
    final expanded = model.expanded(id);
    final direction = Directionality.of(context);
    return McIconAction(
      padding: EdgeInsets.zero,
      label: expanded ? labels.collapseItem(item) : labels.expandItem(item),
      onPressed: () => model.toggle(id),
      icon: Icon(
        expanded
            ? Icons.keyboard_arrow_down
            : direction == TextDirection.rtl
            ? Icons.chevron_left
            : Icons.chevron_right,
        size: 20,
      ),
    );
  }
}
