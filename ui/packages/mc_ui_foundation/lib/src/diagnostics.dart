import 'package:flutter/material.dart';

import 'actions.dart';
import 'facts.dart';
import 'theme.dart';

part 'diagnostic_row.dart';

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
