import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_collections/mc_ui_collections.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'steam_search_controller.dart';

class SteamInstallationChooser extends StatefulWidget {
  const SteamInstallationChooser({
    super.key,
    required this.controller,
    required this.gameName,
    required this.chooseDirectory,
  });
  final SteamSearchController controller;
  final String gameName;
  final Future<String?> Function(String?) chooseDirectory;
  @override
  State<SteamInstallationChooser> createState() =>
      _SteamInstallationChooserState();
}

class _SteamInstallationChooserState extends State<SteamInstallationChooser> {
  final focus = FocusNode(debugLabel: 'Steam installations');
  @override
  void initState() {
    super.initState();
    unawaited(widget.controller.search());
  }

  @override
  void dispose() {
    widget.controller.cancel();
    focus.dispose();
    super.dispose();
  }

  Future<void> addRoot() async {
    final path = await widget.chooseDirectory(null);
    if (mounted && path != null) await widget.controller.addRoot(path);
  }

  String? steamBuild(SteamInstallationCandidate row) {
    final builds = row.origins.map((o) => o.manifest.buildId).toSet();
    return builds.length == 1 ? builds.single : null;
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([widget.controller, widget.controller.model]),
    builder: (context, _) {
      final c = widget.controller, model = c.model;
      final selected = model.selected;
      final report = c.report;
      final problems = report?.diagnostics ?? const <SteamSearchDiagnostic>[];
      return McDialog(
        title: '${widget.gameName} in Steam',
        actions: [
          McAction(label: 'Cancel', onPressed: () => Navigator.pop(context)),
          McAction(
            key: const ValueKey('choose-steam-installation'),
            label: 'Choose',
            emphasis: McActionEmphasis.primary,
            onPressed: selected == null || c.loading
                ? null
                : () =>
                      Navigator.pop(context, selected.directory.canonicalPath),
          ),
        ],
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              McAction(
                key: const ValueKey('search-steam-folder'),
                label: 'Search Steam folder…',
                icon: Icons.folder_open,
                onPressed: c.canAddRoot ? addRoot : null,
              ),
              McIconAction(
                label: 'Refresh search',
                icon: const Icon(Icons.refresh),
                onPressed: c.loading ? null : () => unawaited(c.search()),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 340,
            child: McCollection<String, SteamInstallationCandidate>(
              model: model,
              title: 'Steam installations',
              showTitle: false,
              focusNode: focus,
              columns: [
                McColumn(
                  'Installation folder',
                  (r) => Text(
                    r.directory.canonicalPath,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              filterLabel: 'Filter installations',
              filterEnabled: !c.loading,
              countLabel: c.loading && report == null
                  ? ''
                  : report?.limited == true
                  ? '${model.visible.length} ${model.visible.length == 1 ? 'installation' : 'installations'} found'
                  : model.query.isEmpty
                  ? '${model.length} ${model.length == 1 ? 'installation' : 'installations'}'
                  : '${model.visible.length} of ${model.length} ${model.length == 1 ? 'installation' : 'installations'}',
              empty: c.loading
                  ? 'Searching Steam folders…'
                  : c.cancelled && report == null
                  ? 'Search cancelled.'
                  : model.query.isEmpty
                  ? 'No installation found.'
                  : 'No matching installation.',
              loading: c.loading,
              onCancel: c.cancel,
              problem: c.problem,
              onLoad: c.problem == null ? null : () => unawaited(c.search()),
              onActivate: c.loading
                  ? null
                  : (row) =>
                        Navigator.pop(context, row.directory.canonicalPath),
              semanticLabel: (row) => row.directory.canonicalPath,
            ),
          ),
          if (selected != null) ...[
            const SizedBox(height: 12),
            SelectableText(selected.directory.canonicalPath),
            if (steamBuild(selected) case final String id) ...[
              const SizedBox(height: 4),
              Text(
                'Steam build $id',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
          const SizedBox(height: 8),
          Material(
            color: Colors.transparent,
            child: ExpansionTile(
              key: ValueKey(('steam-details', problems.isNotEmpty)),
              tilePadding: EdgeInsets.zero,
              title: Text(
                problems.isEmpty
                    ? 'Search details'
                    : 'Search problems · ${problems.length}',
              ),
              children: [
                for (final problem in problems)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: McStatus(
                      title: problem.detail,
                      detail: problem.path,
                      tone: McStatusTone.error,
                    ),
                  ),
                if (selected != null) ...[
                  for (final origin in selected.origins)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            origin.root.origin,
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          SelectableText(origin.root.path),
                          if (origin.library.declaredPath != origin.root.path)
                            SelectableText(origin.library.declaredPath),
                          SelectableText(origin.manifest.path),
                          Text(
                            'AppID ${origin.manifest.appId}${origin.manifest.buildId == null ? '' : ' · Steam build ${origin.manifest.buildId}'}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (origin.library.declaredPath !=
                              origin.library.canonicalPath)
                            SelectableText(origin.library.canonicalPath),
                        ],
                      ),
                    ),
                ] else ...[
                  for (final root in report?.roots ?? const <SteamSearchRoot>[])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: SelectableText(root.path),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      );
    },
  );
}
