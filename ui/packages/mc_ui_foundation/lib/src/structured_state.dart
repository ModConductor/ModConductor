import 'package:flutter/material.dart';

import 'theme.dart';

enum McStructuredStateTone { loading, empty, partial, unavailable, error }

class McStructuredState extends StatelessWidget {
  const McStructuredState({
    super.key,
    required this.tone,
    required this.title,
    this.detail,
    this.action,
  });

  final McStructuredStateTone tone;
  final String title;
  final String? detail;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final icon = switch (tone) {
      McStructuredStateTone.loading => null,
      McStructuredStateTone.empty => Icons.folder_open_outlined,
      McStructuredStateTone.partial => Icons.warning_amber_outlined,
      McStructuredStateTone.unavailable => Icons.block_outlined,
      McStructuredStateTone.error => Icons.error_outline,
    };
    final color = tone == McStructuredStateTone.error
        ? colors.error
        : colors.primary;
    return Semantics(
      liveRegion:
          tone == McStructuredStateTone.loading ||
          tone == McStructuredStateTone.error,
      container: true,
      explicitChildNodes: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon == null)
              const SizedBox.square(
                dimension: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            else
              Icon(icon, color: color, size: 32),
            const SizedBox(height: 14),
            Semantics(
              label: '$title${detail == null ? '' : ', $detail'}',
              excludeSemantics: true,
              child: Column(
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (detail case final value?) ...[
                    const SizedBox(height: 5),
                    SelectionArea(
                      child: Text(
                        value,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (action case final value?) ...[
              const SizedBox(height: McSpacing.medium),
              value,
            ],
          ],
        ),
      ),
    );
  }
}
