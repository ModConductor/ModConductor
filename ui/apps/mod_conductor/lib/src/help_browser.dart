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
    return _HelpDiagnosticInspector(
      controller: controller,
      finding: _finding,
      settingsDiagnostic: widget.settingsDiagnostic,
      onClose: _closeInspector,
      previewFocus: _previewFocus,
      onPreview: (finding) =>
          _previewDiagnosticChange(context, controller, finding),
      onExport: () => _exportSupportReport(context, controller),
    );
  }

  Widget _collection() {
    if (_section == _HelpSection.diagnostics) {
      return _HelpDiagnosticCollection(
        controller: controller,
        model: _diagnostics,
        focusNode: _listFocus,
        selected: _finding,
        compact: _compact,
        onSelect: (row) {
          controller.clearResult();
          setState(() => _finding = row);
        },
        onOpen: _openInspector,
      );
    }
    return _HelpArticleCollection(
      section: _section,
      model: _section == _HelpSection.faq ? _faq : _guides,
      focusNode: _listFocus,
      compact: _compact,
      onSelect: (row) => setState(() => _article = row),
      onOpen: _openInspector,
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
