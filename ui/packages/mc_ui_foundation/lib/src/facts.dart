import 'package:flutter/material.dart';

import 'path_value.dart';
import 'theme.dart';

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
