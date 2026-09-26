part of 'app.dart';

class _HelpArticleInspector extends StatelessWidget {
  const _HelpArticleInspector({
    required this.section,
    required this.article,
    required this.onClose,
    required this.actions,
  });
  final _HelpSection section;
  final _HelpArticle article;
  final VoidCallback onClose;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => McInspector(
    title: section == _HelpSection.faq ? 'FAQ' : 'Guide',
    onClose: onClose,
    footer: actions.isEmpty
        ? null
        : Wrap(
            alignment: WrapAlignment.end,
            spacing: McSpacing.small,
            runSpacing: McSpacing.small,
            children: actions,
          ),
    children: [
      Text(article.title, style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 18),
      for (final paragraph in article.paragraphs) ...[
        Text(paragraph),
        const SizedBox(height: 12),
      ],
      for (var index = 0; index < article.steps.length; index++)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(radius: 13, child: Text('${index + 1}')),
              const SizedBox(width: 12),
              Expanded(child: Text(article.steps[index])),
            ],
          ),
        ),
    ],
  );
}
