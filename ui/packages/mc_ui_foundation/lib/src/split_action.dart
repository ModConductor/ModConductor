import 'package:flutter/material.dart';

class McSplitAction<T> extends StatelessWidget {
  const McSplitAction({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.menuLabel,
    required this.itemBuilder,
    required this.onSelected,
    this.menuEnabled = true,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final String menuLabel;
  final PopupMenuItemBuilder<T> itemBuilder;
  final PopupMenuItemSelected<T> onSelected;
  final bool menuEnabled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: onPressed != null || menuEnabled
          ? colors.primary
          : colors.onSurface.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: FilledButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 18),
              label: Text(label),
              style: FilledButton.styleFrom(
                shape: const RoundedRectangleBorder(),
                disabledBackgroundColor: Colors.transparent,
              ),
            ),
          ),
          SizedBox(
            height: 24,
            child: VerticalDivider(
              width: 1,
              color: colors.onPrimary.withValues(alpha: .25),
            ),
          ),
          PopupMenuButton<T>(
            tooltip: menuLabel,
            enabled: menuEnabled,
            position: PopupMenuPosition.under,
            icon: Icon(
              Icons.arrow_drop_down,
              color: menuEnabled
                  ? colors.onPrimary
                  : colors.onSurface.withValues(alpha: .38),
            ),
            itemBuilder: itemBuilder,
            onSelected: onSelected,
          ),
        ],
      ),
    );
  }
}
