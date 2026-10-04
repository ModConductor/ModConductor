import 'package:flutter/material.dart';

import 'layout.dart';

class McNavigationStrip<T> extends StatelessWidget {
  const McNavigationStrip({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelected,
  });

  final List<McNavigationItem<T>> items;
  final T selected;
  final ValueChanged<T> onSelected;

  Widget _tab(BuildContext context, McNavigationItem<T> item) {
    final active = item.value == selected;
    final theme = Theme.of(context);
    return Semantics(
      selected: active,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              width: 3,
              color: active ? theme.colorScheme.primary : Colors.transparent,
            ),
          ),
        ),
        child: TextButton(
          key: item.key,
          onPressed: () => onSelected(item.value),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: const RoundedRectangleBorder(),
            foregroundColor: active
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface,
            backgroundColor: active ? theme.scaffoldBackgroundColor : null,
          ),
          child: McIconLabel(
            icon: Icon(
              active ? item.selectedIcon ?? item.icon : item.icon,
              size: 18,
            ),
            label: item.label,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
    ),
    child: FocusTraversalGroup(
      child: Wrap(children: [for (final item in items) _tab(context, item)]),
    ),
  );
}
