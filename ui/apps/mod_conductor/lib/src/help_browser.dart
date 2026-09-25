part of 'app.dart';

class HelpBrowser extends StatefulWidget {
  const HelpBrowser({
    super.key,
    required this.controller,
    this.settingsDiagnostic,
    this.onCreateWorkspace,
    this.onOpenWorkspace,
    this.onCreateProfile,
    this.onOpenSkyrimSetup,
  });
  final DiagnosticsController controller;
  final String? settingsDiagnostic;
  final VoidCallback? onCreateWorkspace;
  final VoidCallback? onOpenWorkspace;
  final VoidCallback? onCreateProfile;
  final VoidCallback? onOpenSkyrimSetup;

  @override
  State<HelpBrowser> createState() => _HelpBrowserState();
}

class _HelpBrowserState extends State<HelpBrowser> {
  final _scaffold = GlobalKey<ScaffoldState>();
  final _listFocus = FocusNode(debugLabel: 'Help topics');
  final _previewFocus = FocusNode(debugLabel: 'Preview diagnostic change');
  final _guideActionFocus = FocusNode(debugLabel: 'Open guide action');
  final _secondaryGuideActionFocus = FocusNode(
    debugLabel: 'Open secondary guide action',
  );
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
    _guides.select('first-skyrim-workspace');
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
    _guideActionFocus.dispose();
    _secondaryGuideActionFocus.dispose();
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

  DiagnosticFinding? _diagnostic(String code) => controller.snapshot?.findings
      .where((row) => row.code == code)
      .firstOrNull;

  void _openDiagnostic(String code) {
    final finding = _diagnostic(code);
    setState(() {
      _section = _HelpSection.diagnostics;
      _finding = finding ?? controller.snapshot?.findings.firstOrNull;
      if (_finding case final selected?) {
        _diagnostics.select(selected.id);
      }
    });
    _listFocus.requestFocus();
  }

  List<Widget> _guideActions(_HelpArticle article) => switch (article.id) {
    'first-skyrim-workspace' => [
      if (widget.onOpenSkyrimSetup != null)
        McAction(
          key: const ValueKey('open-skyrim-setup'),
          label: 'Open Skyrim setup',
          icon: Icons.videogame_asset_outlined,
          emphasis: McActionEmphasis.primary,
          focusNode: _guideActionFocus,
          onPressed: widget.onOpenSkyrimSetup,
        ),
      if (widget.onOpenSkyrimSetup == null && widget.onCreateProfile != null)
        McAction(
          key: const ValueKey('guide-create-profile'),
          label: 'Create profile',
          icon: Icons.person_add_alt,
          emphasis: McActionEmphasis.primary,
          focusNode: _guideActionFocus,
          onPressed: widget.onCreateProfile,
        ),
      if (widget.onOpenSkyrimSetup == null &&
          widget.onCreateProfile == null) ...[
        if (widget.onCreateWorkspace != null)
          McAction(
            key: const ValueKey('guide-create-workspace'),
            label: 'Create workspace',
            icon: Icons.add,
            emphasis: McActionEmphasis.primary,
            focusNode: _guideActionFocus,
            onPressed: widget.onCreateWorkspace,
          ),
        if (widget.onOpenWorkspace != null)
          McAction(
            key: const ValueKey('guide-open-workspace'),
            label: 'Open workspace',
            icon: Icons.folder_open,
            focusNode: _secondaryGuideActionFocus,
            onPressed: widget.onOpenWorkspace,
          ),
      ],
    ],
    'recover' => [
      McAction(
        key: const ValueKey('open-deployment-recovery'),
        label: _diagnostic('deployment-incomplete') == null
            ? 'Open diagnostics'
            : 'Open deployment problem',
        icon: Icons.fact_check_outlined,
        emphasis: McActionEmphasis.primary,
        focusNode: _guideActionFocus,
        onPressed: () => _openDiagnostic('deployment-incomplete'),
      ),
    ],
    'conflict' => [
      McAction(
        key: const ValueKey('open-conflict-diagnostics'),
        label: _diagnostic('priority-tie') == null
            ? 'Open diagnostics'
            : 'Open file conflict',
        icon: Icons.fact_check_outlined,
        emphasis: McActionEmphasis.primary,
        focusNode: _guideActionFocus,
        onPressed: () => _openDiagnostic('priority-tie'),
      ),
    ],
    _ => const [],
  };

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
            key: const ValueKey('apply-diagnostic-change'),
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
          McFactGroup(
            title: 'Affected items',
            rows: [
              for (final item in preview.items) McFact(item.label, item.value),
            ],
          ),
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
        actions: _section == _HelpSection.guides
            ? _guideActions(_article)
            : const [],
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
          if (widget.settingsDiagnostic case final detail?) ...[
            const McStatus(
              title: 'Settings need attention.',
              tone: McStatusTone.error,
            ),
            ExpansionTile(
              title: const Text('Technical details'),
              children: [SelectableText(detail)],
            ),
            const SizedBox(height: McSpacing.medium),
          ],
          if (widget.settingsDiagnostic == null ||
              controller.busy ||
              controller.problem != null)
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
        McFactGroup(
          title: 'Applies to',
          rows: [
            McFact('Workspace', finding.workspaceName),
            McFact('Profile', finding.profileName),
            for (final item in finding.evidence.where(
              (item) => item.label != 'Workspace' && item.label != 'Profile',
            ))
              McFact(item.label, item.value),
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
          child: TextButton(
            key: const ValueKey('export-support'),
            onPressed: controller.busy ? null : _export,
            child: const McIconLabel(
              icon: Icon(Icons.save_alt, size: 18),
              label: 'Export support report',
            ),
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
    'plugin-snapshot' => 'Plugin check ID',
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
          bounds.maxWidth * McUiScale.of(context) <
          900 * MediaQuery.textScalerOf(context).scale(1);
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
