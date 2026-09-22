import 'package:flutter/material.dart';

import 'theme.dart';
import 'localization.dart';

enum McStatusTone { neutral, error }

enum McActionFeedbackKind { pending, success, refusal, failure }

enum McCapabilityDisposition { available, unavailable, unsupported }

class McIdentityCard extends StatelessWidget {
  const McIdentityCard({
    super.key,
    required this.name,
    required this.provider,
    this.image,
    this.badges = const [],
    this.fallbackIcon = Icons.person,
    this.semanticLabel,
  });

  final String name;
  final String provider;
  final ImageProvider<Object>? image;
  final List<Widget> badges;
  final IconData fallbackIcon;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Widget fallback() => Icon(fallbackIcon, color: colors.primary, size: 30);
    return Semantics(
      container: true,
      excludeSemantics: true,
      label: semanticLabel ?? '$name, $provider',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(McSpacing.medium),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withValues(alpha: .35),
          border: Border.all(color: colors.outlineVariant),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            ExcludeSemantics(
              child: CircleAvatar(
                radius: 28,
                backgroundColor: colors.primary.withValues(alpha: .16),
                child: image == null
                    ? fallback()
                    : ClipOval(
                        child: Image(
                          image: image!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => fallback(),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: McSpacing.medium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 3),
                  Text(provider, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            if (badges.isNotEmpty) ...[
              const SizedBox(width: McSpacing.medium),
              Wrap(spacing: McSpacing.small, children: badges),
            ],
          ],
        ),
      ),
    );
  }
}

class McActionFeedback extends StatelessWidget {
  const McActionFeedback({
    super.key,
    required this.kind,
    required this.message,
    this.detail,
  });

  final McActionFeedbackKind kind;
  final String message;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final icon = switch (kind) {
      McActionFeedbackKind.pending => null,
      McActionFeedbackKind.success => Icons.check_circle_outline,
      McActionFeedbackKind.refusal => Icons.block,
      McActionFeedbackKind.failure => Icons.error_outline,
    };
    final color = switch (kind) {
      McActionFeedbackKind.pending ||
      McActionFeedbackKind.success => colors.primary,
      McActionFeedbackKind.refusal => colors.onSurfaceVariant,
      McActionFeedbackKind.failure => colors.error,
    };
    return Semantics(
      liveRegion: true,
      container: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: McSpacing.small),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: icon == null
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: McSpacing.small),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message),
                  if (detail case final value?) ...[
                    const SizedBox(height: 2),
                    Text(value, style: Theme.of(context).textTheme.bodySmall),
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
