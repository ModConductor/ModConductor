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
