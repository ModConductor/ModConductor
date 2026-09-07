import 'package:flutter/material.dart';

import 'theme.dart';

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
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18),
          const SizedBox(width: McSpacing.small),
        ],
        Flexible(child: Text(label)),
      ],
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
  });
  final String label;
  final Widget icon;
  final VoidCallback? onPressed;
  final FocusNode? focusNode;
  final EdgeInsetsGeometry? padding;

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
