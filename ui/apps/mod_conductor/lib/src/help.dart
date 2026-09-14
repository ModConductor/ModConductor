part of 'app.dart';

enum _HelpSection { diagnostics, faq, guides }

class _HelpArticle {
  const _HelpArticle(
    this.id,
    this.title,
    this.topic,
    this.paragraphs, [
    this.steps = const [],
  ]);
  final String id, title, topic;
  final List<String> paragraphs, steps;
}

const _faqArticles = [
  _HelpArticle(
    'play',
    'What happens when I select Play?',
    'Profile and game files',
    [
      'Mod Conductor applies the selected profile files and deployment before it starts the game.',
      'A failed check stops the launch and keeps the problem visible.',
    ],
  ),
  _HelpArticle(
    'versions',
    'Does Mod Conductor change my original mod files?',
    'Saved mod versions',
    [
      'Mod Conductor stores immutable mod versions.',
      'A file edit creates a new version and keeps the original version.',
    ],
  ),
  _HelpArticle(
    'archives',
    'Which archive files can I browse?',
    'BSA and BA2 files',
    [
      'Mod Conductor can browse selected BSA and BA2 files.',
      'Support depends on the archive version and compression format.',
    ],
  ),
  _HelpArticle(
    'cloud',
    'Does Mod Conductor change Steam Cloud data?',
    'Local save files',
    [
      'Mod Conductor does not change Steam Cloud data.',
      'Save tools only use qualified local save paths.',
    ],
  ),
];

const _guideArticles = [
  _HelpArticle(
    'add-mod',
    'Add a mod from an archive',
    'Mods',
    ['Use a supported archive file from a source that you trust.'],
    [
      'Open Mods.',
      'Select Add mod.',
      'Choose a supported archive file.',
      'Check the mod files.',
      'Select Add mod.',
    ],
  ),
  _HelpArticle('recover', 'Continue a deployment restore', 'Diagnostics', [], [
    'Select Diagnostics.',
    'Select Deployment did not finish.',
    'Select Preview paths.',
    'Check all affected paths.',
    'Select Continue restore.',
  ]),
  _HelpArticle(
    'profile',
    'Change the active profile',
    'Profiles',
    ['A profile keeps its own saved mod order and private game files.'],
    [
      'Select the profile name in the workspace header.',
      'Select another profile.',
      'Check the deployment status.',
      'When the deployment is ready, select Play.',
    ],
  ),
];

class DiagnosticsController extends ChangeNotifier {
  DiagnosticsClient? _client;
  String? _workspaceId, _profileId, _fileSnapshotId, _deploymentId;
  int? _deploymentRevision;
  int _epoch = 0;
  bool _disposed = false;
  DiagnosticSnapshot? snapshot;
  DiagnosticPreview? preview;
  DiagnosticApplyResult? result;
  bool busy = false;
  String? problem;

  void attach(
    DiagnosticsClient? client,
    String? workspaceId,
    String? profileId, {
    String? fileSnapshotId,
    String? deploymentId,
    int? deploymentRevision,
  }) {
    if (identical(client, _client) &&
        workspaceId == _workspaceId &&
        profileId == _profileId &&
        fileSnapshotId == _fileSnapshotId &&
        deploymentId == _deploymentId &&
        deploymentRevision == _deploymentRevision) {
      return;
    }
    _client = client;
    _workspaceId = workspaceId;
    _profileId = profileId;
    _fileSnapshotId = fileSnapshotId;
    _deploymentId = deploymentId;
    _deploymentRevision = deploymentRevision;
    ++_epoch;
    snapshot = null;
    preview = null;
    result = null;
    problem = null;
    busy = false;
    if (client != null && workspaceId != null && profileId != null) {
      unawaited(refresh());
    }
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  String _message(Object error) {
    if (error is! DiagnosticsException) {
      return 'Diagnostics did not return a result.';
    }
    return switch (error.fault) {
      DiagnosticFault.expired || DiagnosticFault.stale =>
        'The selected information changed. Run Diagnostics again.',
      DiagnosticFault.foreign || DiagnosticFault.notOwned => 'This change belongs to another workspace. Mod Conductor changed no files.',
      DiagnosticFault.busy =>
        'Another action is active. After the action finishes, try again.',
      DiagnosticFault.oversized =>
        'This change affects too many paths. Mod Conductor changed no files.',
      DiagnosticFault.cancelled =>
        'The action was canceled. Mod Conductor changed no files.',
      DiagnosticFault.notFound =>
        'The selected information is no longer available.',
      DiagnosticFault.unsupported => 'Mod Conductor cannot make this change.',
    };
  }

  Future<void> refresh() async {
    final client = _client, workspace = _workspaceId, profile = _profileId;
    if (client == null || workspace == null || profile == null || busy) return;
    final epoch = ++_epoch;
    busy = true;
    problem = null;
    preview = null;
    result = null;
    _notify();
    try {
      final value = await client.check(
        workspaceId: workspace,
        profileId: profile,
        fileSnapshotId: _fileSnapshotId,
        deploymentId: _deploymentId,
        deploymentRevision: _deploymentRevision,
      );
      if (!_disposed && epoch == _epoch) snapshot = value;
    } on Exception catch (error) {
      if (!_disposed && epoch == _epoch) problem = _message(error);
    } finally {
      if (!_disposed && epoch == _epoch) {
        busy = false;
        _notify();
      }
    }
  }

  Future<DiagnosticPreview?> previewChange(DiagnosticFinding finding) async {
    final client = _client, current = snapshot;
    if (client == null || current == null || busy) return null;
    final epoch = ++_epoch;
    busy = true;
    preview = null;
    result = null;
    problem = null;
    _notify();
    try {
      final value = await client.preview(current.id, finding.id);
      if (!_disposed && epoch == _epoch) preview = value;
      return !_disposed && epoch == _epoch ? value : null;
    } on Exception catch (error) {
      if (!_disposed && epoch == _epoch) problem = _message(error);
      return null;
    } finally {
      if (!_disposed && epoch == _epoch) {
        busy = false;
        _notify();
      }
    }
  }

  Future<bool> applyChange() async {
    final client = _client, value = preview;
    if (client == null || value == null || busy) return false;
    final epoch = ++_epoch;
    busy = true;
    problem = null;
    _notify();
    try {
      final applied = await client.apply(value.id);
      if (!_disposed && epoch == _epoch) {
        result = applied;
        preview = null;
      }
      return !_disposed && epoch == _epoch && applied.complete;
    } on Exception catch (error) {
      if (!_disposed && epoch == _epoch) {
        problem = _message(error);
        preview = null;
      }
      return false;
    } finally {
      if (!_disposed && epoch == _epoch) {
        busy = false;
        _notify();
      }
    }
  }

  Future<bool> exportReport() async {
    final client = _client, current = snapshot;
    if (client == null || current == null || busy) return false;
    final epoch = ++_epoch;
    busy = true;
    problem = null;
    _notify();
    try {
      final report = await client.export(current.id);
      final saved = await saveSupportReport(report.fileName, report.content);
      return !_disposed && epoch == _epoch && saved;
    } on Exception catch (error) {
      if (!_disposed && epoch == _epoch) problem = _message(error);
      return false;
    } finally {
      if (!_disposed && epoch == _epoch) {
        busy = false;
        _notify();
      }
    }
  }

  void clearResult() {
    if (result == null) return;
    result = null;
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    ++_epoch;
    super.dispose();
  }
}

class HelpBrowser extends StatefulWidget {
  const HelpBrowser({super.key, required this.controller});
  final DiagnosticsController controller;

  @override
  State<HelpBrowser> createState() => _HelpBrowserState();
}

class _HelpBrowserState extends State<HelpBrowser> {
  final _scaffold = GlobalKey<ScaffoldState>();
  final _listFocus = FocusNode(debugLabel: 'Help topics');
  final _previewFocus = FocusNode(debugLabel: 'Preview diagnostic change');
  final _diagnostics = McCollectionModel<String, DiagnosticFinding>(
    idOf: (row) => row.id,
    labelOf: (row) => '${row.title} ${row.area} ${row.fixDetail}',
  );
  final _faq = McCollectionModel<String, _HelpArticle>(
    idOf: (row) => row.id,
    labelOf: (row) => '${row.title} ${row.topic}',
  )..apply(upserts: _faqArticles);
  final _guides = McCollectionModel<String, _HelpArticle>(
    idOf: (row) => row.id,
    labelOf: (row) => '${row.title} ${row.topic}',
  )..apply(upserts: _guideArticles);
  _HelpSection _section = _HelpSection.diagnostics;
  DiagnosticFinding? _finding;
  _HelpArticle _article = _faqArticles.first;
  bool _compact = false;

  DiagnosticsController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    controller.addListener(_changed);
    _faq.select('play');
    _guides.select('recover');
    _changed();
  }

  @override
  void didUpdateWidget(HelpBrowser oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, controller)) {
      oldWidget.controller.removeListener(_changed);
      controller.addListener(_changed);
      _changed();
    }
  }

  void _changed() {
    final rows = controller.snapshot?.findings ?? const <DiagnosticFinding>[];
    final ids = rows.map((row) => row.id).toSet();
    _diagnostics.apply(
      upserts: rows,
      removed: _diagnostics.ids.where((id) => !ids.contains(id)).toList(),
    );
    final selected = _finding;
    if (selected == null || !ids.contains(selected.id)) {
      _finding = rows.firstOrNull;
      if (_finding != null) _diagnostics.select(_finding!.id);
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    controller.removeListener(_changed);
    _listFocus.dispose();
    _previewFocus.dispose();
    _diagnostics.dispose();
    _faq.dispose();
    _guides.dispose();
    super.dispose();
  }

  void _openInspector() {
    if (_compact) _scaffold.currentState?.openEndDrawer();
  }

  void _closeInspector() {
    if (_compact && (_scaffold.currentState?.isEndDrawerOpen ?? false)) {
      _scaffold.currentState?.closeEndDrawer();
    }
    _listFocus.requestFocus();
  }

  void _selectSection(_HelpSection value) {
    setState(() {
      _section = value;
      if (value == _HelpSection.faq) {
        _article = _faq.selected ?? _faqArticles.first;
      }
      if (value == _HelpSection.guides) {
        _article = _guides.selected ?? _guideArticles.first;
      }
    });
    _listFocus.requestFocus();
  }

  Future<void> _preview(DiagnosticFinding finding) async {
    final opener = FocusManager.instance.primaryFocus;
    final preview = await controller.previewChange(finding);
    if (!mounted || preview == null) return;
    final deployment = finding.code == 'deployment-incomplete';
    final apply = await showDialog<bool>(
      context: context,
      builder: (context) => McDialog(
        title: deployment
            ? 'Continue the deployment restore?'
            : 'Hide this file copy?',
        actions: [
          McAction(
            label: 'Cancel',
            onPressed: () => Navigator.pop(context, false),
          ),
          McAction(
            label: deployment ? 'Continue restore' : 'Hide this copy',
            emphasis: McActionEmphasis.primary,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
        children: [
          Text(
            deployment
                ? 'These managed paths will change:'
                : 'This change affects these items:',
          ),
          const SizedBox(height: 12),
          _AffectedItems(items: preview.items),
          const SizedBox(height: 12),
          McStatus(
            title: deployment
                ? '${preview.items.length} managed paths will change'
                : '1 profile setting will change',
            detail: deployment
                ? null
                : 'Mod Conductor will not delete a mod file or a game file.',
          ),
          if (preview.identifiers.isNotEmpty)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('Technical details'),
              children: [
                for (final item in preview.identifiers)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.label),
                    subtitle: SelectableText(item.value),
                  ),
              ],
            ),
        ],
      ),
    );
    if (apply == true) await controller.applyChange();
    opener?.requestFocus();
  }

  Future<void> _export() async {
    final opener = FocusManager.instance.primaryFocus;
    final save = await showDialog<bool>(
      context: context,
      builder: (context) => McDialog(
        title: 'Export support report?',
        actions: [
          McAction(
            label: 'Cancel',
            onPressed: () => Navigator.pop(context, false),
          ),
          McAction(
            label: 'Choose save location',
            emphasis: McActionEmphasis.primary,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
        children: const [
          Text('The report contains:'),
          SizedBox(height: 8),
          _HelpBullets(
            values: [
              'Problems and their result types',
              'Launch, mod file, game setup, deployment, profile, and action IDs',
              'Report format, operating system, and processor architecture',
            ],
          ),
          SizedBox(height: 14),
          Text('The report does not contain:'),
          SizedBox(height: 8),
          _HelpBullets(
            values: [
              'Credentials, sign-in details or access tokens',
              'File contents or command lines',
              'Full personal, game, Steam, Proton, or temporary paths',
            ],
          ),
          SizedBox(height: 12),
          McStatus(
            title: 'Mod Conductor writes no report until you select a location',
          ),
        ],
      ),
    );
    if (save == true) await controller.exportReport();
    opener?.requestFocus();
  }

  Widget _inspector() {
    if (_section != _HelpSection.diagnostics) {
      return _HelpArticleInspector(
        section: _section,
        article: _article,
        onClose: _closeInspector,
      );
    }
    final finding = _finding;
    if (finding == null) {
      return McInspector(
        title: 'Diagnostics',
        onClose: _closeInspector,
        footer: Align(
          alignment: Alignment.centerRight,
          child: McAction(
            label: 'Check again',
            onPressed: controller.busy ? null : controller.refresh,
          ),
        ),
        children: [
          McStatus(
            title:
                controller.problem ??
                (controller.busy ? 'Diagnostics is active' : 'No problems'),
            tone: controller.problem == null
                ? McStatusTone.neutral
                : McStatusTone.error,
          ),
        ],
      );
    }
    return McInspector(
      title: finding.title,
      onClose: _closeInspector,
      footer: Wrap(
        alignment: WrapAlignment.end,
        spacing: 8,
        runSpacing: 8,
        children: [
          if (finding.fixability == DiagnosticFixability.previewAvailable)
            McAction(
              key: const ValueKey('preview-diagnostic-change'),
              focusNode: _previewFocus,
              label: finding.code == 'deployment-incomplete'
                  ? 'Preview paths'
                  : 'Preview change',
              emphasis: McActionEmphasis.primary,
              onPressed: controller.busy ? null : () => _preview(finding),
            )
          else
            McAction(
              label: 'Check again',
              onPressed: controller.busy ? null : controller.refresh,
            ),
        ],
      ),
      children: [
        McStatus(
          title: controller.result?.result ?? finding.summary,
          detail: controller.result?.detail ?? finding.detail,
          tone:
              controller.result == null &&
                  finding.severity == DiagnosticSeverity.error
              ? McStatusTone.error
              : McStatusTone.neutral,
        ),
        const SizedBox(height: 20),
        const Text('Applies to', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        _FindingFacts(
          values: [
            DiagnosticEvidence('Workspace', finding.workspaceName),
            DiagnosticEvidence('Profile', finding.profileName),
            ...finding.evidence.where(
              (item) => item.label != 'Workspace' && item.label != 'Profile',
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'Next action',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(finding.nextAction),
        if (finding.fixDetail.isNotEmpty) ...[
          const SizedBox(height: 16),
          McStatus(title: finding.fixDetail),
        ],
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text('Technical details'),
          children: [
            for (final value in finding.correlations)
              Align(
                alignment: Alignment.centerLeft,
                child: SelectableText(
                  '${_correlationLabel(value.kind)}: ${value.id}${value.revision == null ? '' : ' · ${value.revision}'}',
                ),
              ),
          ],
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: const ValueKey('export-support'),
            onPressed: controller.busy ? null : _export,
            icon: const Icon(Icons.save_alt, size: 18),
            label: const Text('Export support report'),
          ),
        ),
      ],
    );
  }

  String _correlationLabel(String value) => switch (value) {
    'launch' => 'Launch ID',
    'mod-files' => 'Mod file check ID',
    'game-setup' => 'Game setup ID',
    'deployment' => 'Deployment restore ID',
    'profile' => 'Profile ID',
    'action' => 'Action ID',
    _ => 'Support ID',
  };

  Widget _collection() {
    if (_section == _HelpSection.diagnostics) {
      return McCollection<String, DiagnosticFinding>(
        model: _diagnostics,
        focusNode: _listFocus,
        title: 'Diagnostics',
        showTree: false,
        filterLabel: 'Filter diagnostics',
        countLabel: '${_diagnostics.length} problems',
        empty: controller.busy ? 'Diagnostics is active.' : 'No problems.',
        loading: controller.busy,
        problem: controller.problem,
        onRefresh: controller.busy ? null : controller.refresh,
        onSelect: (row) {
          controller.clearResult();
          setState(() => _finding = row);
        },
        onActivate: (_) => _openInspector(),
        filterActions: [
          McIconAction(
            label: 'Open problem',
            icon: const Icon(Icons.open_in_new),
            onPressed: _finding == null ? null : _openInspector,
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
          if (!_compact) McColumn('Area', (row) => Text(row.area), width: 170),
          if (!_compact)
            McColumn('Next step', (row) => Text(row.fixDetail), width: 190),
        ],
      );
    }
    final model = _section == _HelpSection.faq ? _faq : _guides;
    return McCollection<String, _HelpArticle>(
      model: model,
      focusNode: _listFocus,
      title: _section == _HelpSection.faq ? 'FAQ' : 'Guides',
      showTree: false,
      filterLabel: _section == _HelpSection.faq
          ? 'Filter questions'
          : 'Filter guides',
      countLabel:
          '${model.length} ${_section == _HelpSection.faq ? 'questions' : 'guides'}',
      onSelect: (row) => setState(() => _article = row),
      onActivate: (_) => _openInspector(),
      filterActions: [
        McIconAction(
          label: _section == _HelpSection.faq ? 'Open answer' : 'Open guide',
          icon: const Icon(Icons.open_in_new),
          onPressed: _openInspector,
        ),
      ],
      columns: [
        McColumn(
          _section == _HelpSection.faq ? 'Question' : 'Guide',
          (row) => McCollectionName(
            row.title,
            icon: _section == _HelpSection.faq
                ? Icons.help_outline
                : Icons.menu_book_outlined,
          ),
        ),
        if (!_compact) McColumn('Topic', (row) => Text(row.topic), width: 150),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      _compact =
          bounds.maxWidth < 900 * MediaQuery.textScalerOf(context).scale(1);
      final inspector = _inspector();
      final body = Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _collection()),
          if (!_compact) ...[
            const SizedBox(width: 16),
            SizedBox(width: 430, child: inspector),
          ],
        ],
      );
      return Scaffold(
        key: _scaffold,
        backgroundColor: Colors.transparent,
        endDrawer: _compact ? Drawer(width: 540, child: inspector) : null,
        onEndDrawerChanged: (open) {
          if (!open) _listFocus.requestFocus();
        },
        body: _compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _HelpSections(
                    section: _section,
                    narrow: true,
                    onChanged: _selectSection,
                  ),
                  const SizedBox(height: 12),
                  Expanded(child: body),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _HelpSections(
                    section: _section,
                    narrow: false,
                    onChanged: _selectSection,
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: body),
                ],
              ),
      );
    },
  );
}

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
          segments: const [
            ButtonSegment(
              value: _HelpSection.diagnostics,
              label: Text('Diagnostics'),
              icon: Icon(Icons.fact_check_outlined),
            ),
            ButtonSegment(
              value: _HelpSection.faq,
              label: Text('FAQ'),
              icon: Icon(Icons.help_outline),
            ),
            ButtonSegment(
              value: _HelpSection.guides,
              label: Text('Guides'),
              icon: Icon(Icons.menu_book_outlined),
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
      child: NavigationRail(
        minWidth: 154,
        minExtendedWidth: 154,
        extended: true,
        groupAlignment: -1,
        selectedIndex: section.index,
        onDestinationSelected: (index) => onChanged(_HelpSection.values[index]),
        leading: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Help', style: Theme.of(context).textTheme.titleMedium),
          ),
        ),
        destinations: const [
          NavigationRailDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check),
            label: Text('Diagnostics'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.help_outline),
            selectedIcon: Icon(Icons.help),
            label: Text('FAQ'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: Text('Guides'),
          ),
        ],
      ),
    );
  }
}

class _HelpArticleInspector extends StatelessWidget {
  const _HelpArticleInspector({
    required this.section,
    required this.article,
    required this.onClose,
  });
  final _HelpSection section;
  final _HelpArticle article;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => McInspector(
    title: section == _HelpSection.faq ? 'FAQ' : 'Guide',
    onClose: onClose,
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

class _FindingFacts extends StatelessWidget {
  const _FindingFacts({required this.values});
  final List<DiagnosticEvidence> values;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final value in values)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 116,
                child: Text(
                  value.label,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(value.value)),
            ],
          ),
        ),
    ],
  );
}

class _AffectedItems extends StatelessWidget {
  const _AffectedItems({required this.items});
  final List<DiagnosticRemediationItem> items;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 116,
                  child: Text(
                    item.label,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SelectableText(
                    item.value,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

class _HelpBullets extends StatelessWidget {
  const _HelpBullets({required this.values});
  final List<String> values;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final value in values)
        Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('•  '),
              Expanded(child: Text(value)),
            ],
          ),
        ),
    ],
  );
}
