import 'package:flutter/material.dart';

import 'theme.dart';

enum McStatusTone { neutral, error }

class McStatus extends StatelessWidget {
  const McStatus({
    super.key,
    required this.title,
    this.detail,
    this.tone = McStatusTone.neutral,
  });
  final String title;
  final String? detail;
  final McStatusTone tone;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            tone == McStatusTone.error
                ? Icons.error_outline
                : Icons.info_outline,
            size: 22,
            color: tone == McStatusTone.error ? colors.error : colors.primary,
          ),
          const SizedBox(width: McSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                if (detail != null) ...[
                  const SizedBox(height: McSpacing.small),
                  Text(detail!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class McSection extends StatelessWidget {
  const McSection({super.key, required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(McSpacing.large),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: McSpacing.large),
        ...children,
      ],
    ),
  );
}

class McPage extends StatelessWidget {
  const McPage({super.key, required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(McSpacing.page),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1040),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: McSpacing.large),
            ...children,
          ],
        ),
      ),
    ),
  );
}
