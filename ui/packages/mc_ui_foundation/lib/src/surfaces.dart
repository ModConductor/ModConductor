import 'package:flutter/material.dart';

import 'theme.dart';
import 'localization.dart';

enum McStatusTone { neutral, error }

enum McCapabilityDisposition { available, unavailable, unsupported }

class McCapabilityState extends StatelessWidget {
  const McCapabilityState({
    super.key,
    required this.title,
    required this.disposition,
    this.reason,
  });

  final String title;
  final McCapabilityDisposition disposition;
  final String? reason;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final icon = switch (disposition) {
      McCapabilityDisposition.available => Icons.check_circle_outline,
      McCapabilityDisposition.unavailable => Icons.schedule,
      McCapabilityDisposition.unsupported => Icons.block,
    };
    final color = switch (disposition) {
      McCapabilityDisposition.available => colors.primary,
      McCapabilityDisposition.unavailable => colors.onSurfaceVariant,
      McCapabilityDisposition.unsupported => colors.error,
    };
    final labels = McUiLocalization.labelsOf(context);
    final status = switch (disposition) {
      McCapabilityDisposition.available => labels.available,
      McCapabilityDisposition.unavailable => labels.unavailable,
      McCapabilityDisposition.unsupported => labels.unsupported,
    };

    return Semantics(
      label: '$title, $status${reason == null ? '' : ', $reason'}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: McSpacing.small),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(child: Icon(icon, size: 20, color: color)),
            const SizedBox(width: McSpacing.small),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(status, style: Theme.of(context).textTheme.bodySmall),
                  if (reason case final detail?) ...[
                    const SizedBox(height: 2),
                    Text(detail, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
    final labels = McUiLocalization.labelsOf(context);
    final status = tone == McStatusTone.error
        ? labels.error
        : labels.information;
    return Semantics(
      liveRegion: true,
      label: '$status, $title${detail == null ? '' : ', $detail'}',
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Icon(
              tone == McStatusTone.error
                  ? Icons.error_outline
                  : Icons.info_outline,
              size: 22,
              color: tone == McStatusTone.error ? colors.error : colors.primary,
            ),
          ),
          const SizedBox(width: McSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$status: $title',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
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
