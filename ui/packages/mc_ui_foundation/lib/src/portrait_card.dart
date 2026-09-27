import 'dart:io';

import 'package:flutter/material.dart';

import 'theme.dart';

class McPortraitArtwork extends StatelessWidget {
  const McPortraitArtwork({
    super.key,
    this.image,
    this.imagePath,
    this.questionFallback = false,
  });

  final Uri? image;
  final String? imagePath;
  final bool questionFallback;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Widget fallback() => ColoredBox(
      color: colors.surfaceContainerHighest,
      child: Center(
        child: questionFallback
            ? Text('?', style: Theme.of(context).textTheme.displayLarge)
            : Icon(
                Icons.image_outlined,
                size: 44,
                color: colors.onSurfaceVariant,
              ),
      ),
    );
    Widget hosted() => image == null
        ? fallback()
        : Image.network(
            image.toString(),
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => fallback(),
          );
    return SizedBox.expand(
      child: imagePath == null
          ? hosted()
          : Image.file(
              File(imagePath!),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => hosted(),
            ),
    );
  }
}

class McPortraitCard extends StatelessWidget {
  const McPortraitCard({
    super.key,
    required this.name,
    this.author,
    this.summary,
    this.category,
    this.image,
    this.imagePath,
    this.questionFallback = false,
    this.badge,
    this.badgeEmphasis = false,
    this.selected = false,
    this.actionsRow = false,
    this.status = const [],
    this.actions = const [],
  });

  final String name;
  final String? author, summary, category;
  final Uri? image;
  final String? imagePath;
  final bool questionFallback, selected, actionsRow, badgeEmphasis;
  final String? badge;
  final List<String> status;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(
          color: selected ? colors.primary : colors.outlineVariant,
          width: selected ? 3 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            child: Stack(
              children: [
                SizedBox(
                  height: 190,
                  width: double.infinity,
                  child: McPortraitArtwork(
                    image: image,
                    imagePath: imagePath,
                    questionFallback: questionFallback,
                  ),
                ),
                if (badge != null)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: badgeEmphasis ? colors.primary : colors.surface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        child: Text(
                          badge!,
                          style: TextStyle(
                            color: badgeEmphasis
                                ? colors.onPrimary
                                : colors.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
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
                  if (actionsRow)
                    Row(spacing: 8, children: actions)
                  else
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
