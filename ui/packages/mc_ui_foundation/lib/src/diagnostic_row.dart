part of 'diagnostics.dart';

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
