import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'actions.dart';
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

class McFact {
  const McFact(this.label, this.value, {this.path = false, this.action});

  final String label;
  final String value;
  final bool path;
  final Widget? action;
}

class McFactGroup extends StatelessWidget {
  const McFactGroup({super.key, required this.title, required this.rows});

  final String title;
  final List<McFact> rows;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    explicitChildNodes: true,
    label: title,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: McSpacing.small),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              for (var index = 0; index < rows.length; index++)
                _McFactRow(
                  key: ValueKey((rows[index].label, rows[index].value)),
                  row: rows[index],
                  narrow: MediaQuery.sizeOf(context).width < 700,
                  last: index == rows.length - 1,
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _McFactRow extends StatelessWidget {
  const _McFactRow({
    super.key,
    required this.row,
    required this.narrow,
    required this.last,
  });

  final McFact row;
  final bool narrow;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final label = Text(
      row.label,
      style: Theme.of(context).textTheme.labelMedium
          ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
    );
    final value = row.path
        ? McPathValue(path: row.value, label: row.label)
        : Semantics(
            label: '${row.label}, ${row.value}',
            excludeSemantics: true,
            child: SelectionArea(child: Text(row.value)),
          );
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: last
              ? null
              : Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
        ),
        child: narrow
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  label,
                  const SizedBox(height: 5),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: value),
                      ?row.action,
                    ],
                  ),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 176, child: label),
                  Expanded(child: value),
                  ?row.action,
                ],
              ),
      ),
    );
  }
}

class McPathValue extends StatelessWidget {
  const McPathValue({super.key, required this.path, this.label});

  final String path;
  final String? label;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: path));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Path copied')));
  }

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Semantics(
          label: label == null ? path : '$label, $path',
          excludeSemantics: true,
          child: SelectionArea(
            child: Text(path, style: const TextStyle(fontFamily: 'monospace')),
          ),
        ),
      ),
      const SizedBox(width: McSpacing.small),
      McIconAction(
        label: 'Copy path',
        onPressed: () => _copy(context),
        icon: const Icon(Icons.copy_outlined, size: 18),
        padding: EdgeInsets.zero,
      ),
    ],
  );
}

enum McDiagnosticTone { warning, error }

class McDiagnosticItem {
  const McDiagnosticItem({
    required this.id,
    required this.title,
    required this.affected,
    required this.evidence,
    this.origins = const [],
    this.action,
    this.tone = McDiagnosticTone.error,
  });

  final String id;
  final String title;
  final String affected;
  final List<McFact> evidence;
  final List<String> origins;
  final Widget? action;
  final McDiagnosticTone tone;
}

class McDiagnosticTable extends StatelessWidget {
  const McDiagnosticTable({
    super.key,
    required this.title,
    required this.diagnostics,
  });

  final String title;
  final List<McDiagnosticItem> diagnostics;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    explicitChildNodes: true,
    label: '$title, ${diagnostics.length} findings',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Text(
              '${diagnostics.length}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: McSpacing.small),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              for (var index = 0; index < diagnostics.length; index++)
                _McDiagnosticRow(
                  key: ValueKey(diagnostics[index].id),
                  item: diagnostics[index],
                  last: index == diagnostics.length - 1,
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _McDiagnosticRow extends StatefulWidget {
  const _McDiagnosticRow({super.key, required this.item, required this.last});

  final McDiagnosticItem item;
  final bool last;

  @override
  State<_McDiagnosticRow> createState() => _McDiagnosticRowState();
}

class _McDiagnosticRowState extends State<_McDiagnosticRow> {
  bool expanded = false;

  void _toggle() => setState(() => expanded = !expanded);

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final colors = Theme.of(context).colorScheme;
    final icon = item.tone == McDiagnosticTone.error
        ? Icons.error_outline
        : Icons.warning_amber_outlined;
    final color = item.tone == McDiagnosticTone.error
        ? colors.error
        : colors.primary;
    return Semantics(
      container: true,
      expanded: expanded,
      label: '${item.title}. Affected item, ${item.affected}',
      child: Container(
        decoration: BoxDecoration(
          border: widget.last
              ? null
              : Border(bottom: BorderSide(color: colors.outlineVariant)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: _toggle,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExcludeSemantics(child: Icon(icon, color: color, size: 21)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 5),
                          SelectionArea(
                            child: Text(
                              item.affected,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(fontFamily: 'monospace'),
                            ),
                          ),
                          if (item.origins.isNotEmpty) ...[
                            const SizedBox(height: McSpacing.small),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (final origin in item.origins)
                                  _McOriginChip(label: origin),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    McIconAction(
                      label: expanded ? 'Hide evidence' : 'Show evidence',
                      onPressed: _toggle,
                      icon: Icon(
                        expanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (expanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(45, 0, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (item.evidence.isNotEmpty)
                      McFactGroup(title: 'Evidence', rows: item.evidence),
                    if (item.action case final action?) ...[
                      if (item.evidence.isNotEmpty)
                        const SizedBox(height: McSpacing.medium),
                      Align(alignment: Alignment.centerLeft, child: action),
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

class _McOriginChip extends StatelessWidget {
  const _McOriginChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest
          .withValues(alpha: .5),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(label, style: Theme.of(context).textTheme.bodySmall),
  );
}
