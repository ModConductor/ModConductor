import 'package:flutter/material.dart';

import 'actions.dart';
import 'theme.dart';
import 'localization.dart';

class McInspector extends StatelessWidget {
  const McInspector({
    super.key,
    required this.title,
    required this.onClose,
    required this.children,
    this.footer,
  });
  final String title;
  final VoidCallback onClose;
  final List<Widget> children;
  final Widget? footer;
  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    shape: RoundedRectangleBorder(
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      borderRadius: BorderRadius.circular(12),
    ),
    clipBehavior: Clip.antiAlias,
    child: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(McSpacing.large),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    McIconAction(
                      label: McUiLocalization.labelsOf(context).closeInspector,
                      onPressed: onClose,
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: McSpacing.large),
                ...children,
              ],
            ),
          ),
          if (footer != null) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(McSpacing.large),
              child: footer,
            ),
          ],
        ],
      ),
    ),
  );
}
