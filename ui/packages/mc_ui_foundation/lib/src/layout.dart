import 'package:flutter/material.dart';

import 'theme.dart';

class McIconLabel extends StatelessWidget {
  const McIconLabel({
    super.key,
    required this.icon,
    required this.label,
    this.expanded = false,
    this.flexible = false,
    this.maxLines = 1,
    this.gap = McSpacing.small,
  });

  final Widget icon;
  final String label;
  final bool expanded;
  final bool flexible;
  final int? maxLines;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      maxLines: maxLines,
      softWrap: maxLines != 1,
      overflow: maxLines == null ? TextOverflow.clip : TextOverflow.ellipsis,
    );
    return Row(
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ExcludeSemantics(child: icon),
        SizedBox(width: gap),
        if (expanded)
          Expanded(child: text)
        else if (flexible)
          Flexible(child: text)
        else
          text,
      ],
    );
  }
}

class McPropertyRow extends StatelessWidget {
  const McPropertyRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 3),
          ClipRect(child: SelectionArea(child: Text(value))),
        ],
      ),
    ),
  );
}

class McAsyncStatusSlot extends StatelessWidget {
  const McAsyncStatusSlot({super.key, required this.active, this.problem});

  final bool active;
  final String? problem;

  @override
  Widget build(BuildContext context) {
    final message = problem;
    final scale = MediaQuery.textScalerOf(context)
        .scale(1)
        .clamp(1, 3)
        .toDouble();
    return SizedBox(
      height: 44 * scale,
      child: active
          ? Semantics(
              liveRegion: true,
              label: 'Updating',
              child: const Align(
                alignment: AlignmentDirectional.centerStart,
                child: SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          : message == null
          ? null
          : Semantics(
              liveRegion: true,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: McIconLabel(
                  icon: Icon(
                    Icons.error_outline,
                    size: 20,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  label: message,
                  expanded: true,
                  maxLines: 2,
                ),
              ),
            ),
    );
  }
}

enum McSortDirection { ascending, descending }

class McSortHeader extends StatelessWidget {
  const McSortHeader({
    super.key,
    required this.label,
    required this.onPressed,
    this.direction,
  });

  final String label;
  final VoidCallback onPressed;
  final McSortDirection? direction;

  @override
  Widget build(BuildContext context) {
    final state = switch (direction) {
      McSortDirection.ascending => 'ascending',
      McSortDirection.descending => 'descending',
      null => 'not sorted',
    };
    final icon = switch (direction) {
      McSortDirection.ascending => Icons.arrow_upward,
      McSortDirection.descending => Icons.arrow_downward,
      null => Icons.unfold_more,
    };
    return TextButton(
      style: TextButton.styleFrom(
        minimumSize: Size.zero,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: onPressed,
      child: Semantics(
        label: '$label, $state',
        excludeSemantics: true,
        child: McIconLabel(icon: Icon(icon, size: 16), label: label),
      ),
    );
  }
}

class McNavigationItem<T> {
  const McNavigationItem({
    required this.value,
    required this.label,
    required this.icon,
    this.selectedIcon,
    this.key,
  });

  final T value;
  final String label;
  final IconData icon;
  final IconData? selectedIcon;
  final Key? key;
}

class McNavigationList<T> extends StatelessWidget {
  const McNavigationList({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelected,
  });

  final List<McNavigationItem<T>> items;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) => FocusTraversalGroup(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: MergeSemantics(
              child: Semantics(
                selected: item.value == selected,
                child: TextButton(
                  key: item.key,
                  style: TextButton.styleFrom(
                    alignment: AlignmentDirectional.centerStart,
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      12,
                      11,
                      12,
                      11,
                    ),
                    backgroundColor: item.value == selected
                        ? Theme.of(context).colorScheme.primary
                              .withValues(alpha: .12)
                        : Colors.transparent,
                  ),
                  onPressed: () => onSelected(item.value),
                  child: McIconLabel(
                    icon: Icon(
                      item.value == selected
                          ? item.selectedIcon ?? item.icon
                          : item.icon,
                      size: 20,
                    ),
                    label: item.label,
                    expanded: true,
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
