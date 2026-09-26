part of 'app.dart';

class _HelpDiagnosticCollection extends StatelessWidget {
  const _HelpDiagnosticCollection({
    required this.controller,
    required this.model,
    required this.focusNode,
    required this.selected,
    required this.compact,
    required this.onSelect,
    required this.onOpen,
  });

  final DiagnosticsController controller;
  final McCollectionModel<String, DiagnosticFinding> model;
  final FocusNode focusNode;
  final DiagnosticFinding? selected;
  final bool compact;
  final ValueChanged<DiagnosticFinding> onSelect;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => McCollection<String, DiagnosticFinding>(
    model: model,
    focusNode: focusNode,
    title: 'Diagnostics',
    showTree: false,
    filterLabel: 'Filter diagnostics',
    countLabel: '${model.length} problems',
    empty: controller.busy ? 'Diagnostics is active.' : 'No problems.',
    loading: controller.busy,
    problem: controller.problem,
    onRefresh: controller.busy ? null : controller.refresh,
    onSelect: onSelect,
    onActivate: (_) => onOpen(),
    filterActions: [
      McIconAction(
        label: 'Open problem',
        icon: const Icon(Icons.open_in_new),
        onPressed: selected == null ? null : onOpen,
      ),
    ],
    columns: [
      McColumn(
        'Problem',
        (row) => McCollectionName(
          row.title,
          icon: switch (row.severity) {
            DiagnosticSeverity.error => Icons.error_outline,
            DiagnosticSeverity.warning => Icons.warning_amber,
            DiagnosticSeverity.information => Icons.info_outline,
          },
        ),
      ),
      if (!compact) McColumn('Area', (row) => Text(row.area), width: 170),
      if (!compact)
        McColumn('Next step', (row) => Text(row.fixDetail), width: 190),
    ],
  );
}

class _HelpArticleCollection extends StatelessWidget {
  const _HelpArticleCollection({
    required this.section,
    required this.model,
    required this.focusNode,
    required this.compact,
    required this.onSelect,
    required this.onOpen,
  });

  final _HelpSection section;
  final McCollectionModel<String, _HelpArticle> model;
  final FocusNode focusNode;
  final bool compact;
  final ValueChanged<_HelpArticle> onSelect;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => McCollection<String, _HelpArticle>(
    model: model,
    focusNode: focusNode,
    title: section == _HelpSection.faq ? 'FAQ' : 'Guides',
    showTree: false,
    filterLabel: section == _HelpSection.faq
        ? 'Filter questions'
        : 'Filter guides',
    countLabel:
        '${model.length} ${section == _HelpSection.faq ? 'questions' : 'guides'}',
    onSelect: onSelect,
    onActivate: (_) => onOpen(),
    filterActions: [
      McIconAction(
        label: section == _HelpSection.faq ? 'Open answer' : 'Open guide',
        icon: const Icon(Icons.open_in_new),
        onPressed: onOpen,
      ),
    ],
    columns: [
      McColumn(
        section == _HelpSection.faq ? 'Question' : 'Guide',
        (row) => McCollectionName(
          row.title,
          icon: section == _HelpSection.faq
              ? Icons.help_outline
              : Icons.menu_book_outlined,
        ),
      ),
      if (!compact) McColumn('Topic', (row) => Text(row.topic), width: 150),
    ],
  );
}
