part of 'app.dart';

class _HelpSections extends StatelessWidget {
  const _HelpSections({
    required this.section,
    required this.narrow,
    required this.onChanged,
  });
  final _HelpSection section;
  final bool narrow;
  final ValueChanged<_HelpSection> onChanged;

  @override
  Widget build(BuildContext context) {
    if (narrow) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SegmentedButton<_HelpSection>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(
              value: _HelpSection.diagnostics,
              label: McIconLabel(
                icon: Icon(Icons.fact_check_outlined),
                label: 'Diagnostics',
              ),
            ),
            ButtonSegment(
              value: _HelpSection.faq,
              label: McIconLabel(icon: Icon(Icons.help_outline), label: 'FAQ'),
            ),
            ButtonSegment(
              value: _HelpSection.guides,
              label: McIconLabel(
                key: ValueKey('help-guides-section'),
                icon: Icon(Icons.menu_book_outlined),
                label: 'Guides',
              ),
            ),
          ],
          selected: {section},
          onSelectionChanged: (values) => onChanged(values.first),
        ),
      );
    }
    return Material(
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width:
            190 *
            MediaQuery.textScalerOf(context).scale(1).clamp(1, 1.5).toDouble(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 18, 20, 12),
              child: Text(
                'Help',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            McNavigationList<_HelpSection>(
              selected: section,
              onSelected: onChanged,
              items: const [
                McNavigationItem(
                  value: _HelpSection.diagnostics,
                  label: 'Diagnostics',
                  icon: Icons.fact_check_outlined,
                  selectedIcon: Icons.fact_check,
                ),
                McNavigationItem(
                  value: _HelpSection.faq,
                  label: 'FAQ',
                  icon: Icons.help_outline,
                  selectedIcon: Icons.help,
                ),
                McNavigationItem(
                  value: _HelpSection.guides,
                  label: 'Guides',
                  icon: Icons.menu_book_outlined,
                  selectedIcon: Icons.menu_book,
                  key: ValueKey('help-guides-section'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
