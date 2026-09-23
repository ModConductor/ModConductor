import 'package:flutter/material.dart';

import 'layout.dart';

enum McActionEmphasis { primary, secondary }

class McAction extends StatelessWidget {
  const McAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.emphasis = McActionEmphasis.secondary,
    this.icon,
    this.focusNode,
  });
  final String label;
  final VoidCallback? onPressed;
  final McActionEmphasis emphasis;
  final IconData? icon;
  final FocusNode? focusNode;
  @override
  Widget build(BuildContext context) {
    final child = icon == null
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [Flexible(child: Text(label))],
          )
        : McIconLabel(
            icon: Icon(icon, size: 18),
            label: label,
            flexible: true,
            maxLines: null,
          );
    return switch (emphasis) {
      McActionEmphasis.primary => FilledButton(
        onPressed: onPressed,
        focusNode: focusNode,
        child: child,
      ),
      McActionEmphasis.secondary => OutlinedButton(
        onPressed: onPressed,
        focusNode: focusNode,
        child: child,
      ),
    };
  }
}

class McIconAction extends StatelessWidget {
  const McIconAction({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.focusNode,
    this.padding,
    this.size,
  });
  final String label;
  final Widget icon;
  final VoidCallback? onPressed;
  final FocusNode? focusNode;
  final EdgeInsetsGeometry? padding;
  final double? size;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: Semantics(
      label: label,
      child: TooltipTheme(
        data: TooltipTheme.of(context).copyWith(excludeFromSemantics: true),
        child: IconButton(
          tooltip: label,
          icon: ExcludeSemantics(child: icon),
          onPressed: onPressed,
          focusNode: focusNode,
          padding: padding,
          constraints: size == null
              ? null
              : BoxConstraints.tightFor(width: size, height: size),
        ),
      ),
    ),
  );
}

class McIconMenu<T> extends StatelessWidget {
  const McIconMenu({
    super.key,
    required this.label,
    required this.itemBuilder,
    required this.onSelected,
    this.enabled = true,
  });
  final String label;
  final PopupMenuItemBuilder<T> itemBuilder;
  final PopupMenuItemSelected<T> onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: Semantics(
      label: label,
      child: TooltipTheme(
        data: TooltipTheme.of(context).copyWith(excludeFromSemantics: true),
        child: PopupMenuButton<T>(
          tooltip: label,
          enabled: enabled,
          itemBuilder: itemBuilder,
          onSelected: onSelected,
        ),
      ),
    ),
  );
}

class McMenuAction<T> extends StatelessWidget {
  const McMenuAction({
    super.key,
    required this.label,
    required this.choices,
    required this.describe,
    required this.onSelected,
    this.enabled = true,
  });
  final String label;
  final List<T> choices;
  final String Function(T) describe;
  final ValueChanged<T> onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) => MenuAnchor(
    menuChildren: [
      for (final choice in choices)
        MenuItemButton(
          onPressed: () => onSelected(choice),
          child: Text(describe(choice)),
        ),
    ],
    builder: (context, controller, child) => McAction(
      label: label,
      icon: Icons.arrow_drop_down,
      onPressed: enabled
          ? () => controller.isOpen ? controller.close() : controller.open()
          : null,
    ),
  );
}
