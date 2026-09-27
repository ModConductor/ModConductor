import 'package:flutter/material.dart';

import 'theme.dart';

class McPortraitCard extends StatelessWidget {
  const McPortraitCard({
    super.key,
    required this.name,
    this.author,
    this.summary,
    this.category,
    this.image,
    this.status = const [],
    this.actions = const [],
  });

  final String name;
  final String? author, summary, category;
  final Uri? image;
  final List<String> status;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Widget fallback() => ColoredBox(
      color: colors.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 44,
          color: colors.onSurfaceVariant,
        ),
      ),
    );
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            child: SizedBox(
              height: 190,
              child: image == null
                  ? fallback()
                  : Image.network(
                      image.toString(),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => fallback(),
                    ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(McSpacing.medium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if ((author?.isNotEmpty ?? false) ||
                      (category?.isNotEmpty ?? false)) ...[
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (author?.isNotEmpty ?? false) author!,
                        if (category?.isNotEmpty ?? false) category!,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  if (summary?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 10),
                    Text(
                      summary!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const Spacer(),
                  if (status.isNotEmpty) ...[
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final label in status)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: colors.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              label,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  Wrap(spacing: 8, runSpacing: 8, children: actions),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
