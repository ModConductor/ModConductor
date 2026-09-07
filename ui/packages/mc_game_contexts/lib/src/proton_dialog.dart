import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'installation_dialog.dart' show GameDirectoryChooser;
import 'proton_search_controller.dart';

class ProtonDialog extends StatefulWidget {
  const ProtonDialog({
    super.key,
    required this.game,
    required this.gamePath,
    required this.client,
    required this.chooseDirectory,
    required this.roots,
    this.initial,
  });
  final GameDefinitionInfo game;
  final String gamePath;
  final ProtonContextsClient client;
  final GameDirectoryChooser chooseDirectory;
  final List<String> roots;
  final ProtonSelection? initial;
  @override
  State<ProtonDialog> createState() => _ProtonDialogState();
}

class _ProtonDialogState extends State<ProtonDialog> {
  late final search = ProtonSearchController(
    widget.client,
    widget.game.id,
    widget.gamePath,
    widget.roots,
  );
  late final data = TextEditingController(
    text: widget.initial?.compatData ?? '',
  );
  late final runtime = TextEditingController(
    text: widget.initial?.runtimeDirectory ?? '',
  );
  late ProtonAssociation association =
      widget.initial?.association ?? const ManualProtonAssociation();
  late String toolId = widget.initial?.toolId ?? '';
  late bool dataTouched = widget.initial != null;
  bool busy = false;
  late bool manualRuntime = widget.initial != null;
  String? problem;
  @override
  void initState() {
    super.initState();
    search.addListener(changed);
    unawaited(search.search());
  }

  void changed() {
    if (!mounted) return;
    final candidates = search.report?.prefixes;
    if (!dataTouched && widget.initial == null && candidates?.length == 1) {
      selectPrefix(candidates!.single);
    }
    setState(() {});
  }

  void selectPrefix(ProtonPrefixCandidate value) {
    final origin = value.origins.first;
    association = SteamProtonAssociation(
      origin.steamRoot.canonicalPath,
      origin.library.canonicalPath,
    );
    data.text = value.compatData;
    dataTouched = true;
  }

  @override
  void dispose() {
    search.removeListener(changed);
    search.dispose();
    data.dispose();
    runtime.dispose();
    super.dispose();
  }

  Future<void> browse(bool proton) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final controller = proton ? runtime : data;
      final chosen = await widget.chooseDirectory(
        controller.text.isEmpty ? null : controller.text,
      );
      if (!mounted || chosen == null) return;
      setState(() {
        controller.text = chosen;
        problem = null;
        if (proton) {
          manualRuntime = true;
          toolId = '';
        } else {
          dataTouched = true;
          association = const ManualProtonAssociation();
        }
      });
    } on Exception {
      if (mounted) {
        setState(() => problem = 'The folder selector could not open.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = search.report;
    final prefixes = report?.prefixes ?? const <ProtonPrefixCandidate>[];
    final tools = report?.tools ?? const <ProtonInstalledTool>[];
    return McFormDialog(
      title: 'Proton for ${widget.game.name}',
      action: 'Choose',
      onSubmit: busy || data.text.isEmpty || runtime.text.isEmpty
          ? null
          : () => Navigator.pop(
              context,
              ProtonSelection(
                appId: widget.game.declaredSteamAppId,
                association: association,
                compatData: data.text,
                runtimeDirectory: runtime.text,
                toolId: toolId,
              ),
            ),
      children: [
        if (search.loading) const McStatus(title: 'Finding Proton folders'),
        if (prefixes.length > 1 &&
            !(dataTouched && association is ManualProtonAssociation)) ...[
          McChoice<String>(
            label: 'Proton data folder',
            value: prefixes.any((p) => p.compatData == data.text)
                ? data.text
                : '',
            choices: ['', ...prefixes.map((p) => p.compatData)],
            describe: (v) => v.isEmpty ? 'Select a folder' : v,
            onChanged: (v) {
              if (busy) return;
              if (v.isNotEmpty) {
                setState(
                  () => selectPrefix(
                    prefixes.firstWhere((p) => p.compatData == v),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 10),
          if (data.text.isNotEmpty)
            Text(data.text, style: Theme.of(context).textTheme.bodySmall),
        ] else
          TextFormField(
            key: const ValueKey('proton-data-folder'),
            controller: data,
            enabled: !busy,
            minLines: 2,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Proton data folder'),
            onChanged: (_) => setState(() {
              dataTouched = true;
              association = const ManualProtonAssociation();
            }),
          ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: McAction(
            label: 'Browse…',
            icon: Icons.folder_open,
            onPressed: busy ? null : () => browse(false),
          ),
        ),
        if (association is ManualProtonAssociation && data.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Selected manually · AppID ${widget.game.declaredSteamAppId}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 16),
        if (!manualRuntime && tools.isNotEmpty) ...[
          McChoice<(String, String)>(
            label: 'Proton',
            value:
                tools.any((t) => t.directory == runtime.text && t.id == toolId)
                ? (toolId, runtime.text)
                : ('', ''),
            choices: [('', ''), for (final t in tools) (t.id, t.directory)],
            describe: (key) {
              if (key == ('', '')) return 'Select Proton';
              final t = tools.firstWhere(
                (t) => t.id == key.$1 && t.directory == key.$2,
              );
              return tools.where((other) => other.name == t.name).length > 1
                  ? '${t.name} · ${t.id}'
                  : t.name;
            },
            onChanged: (key) {
              if (busy) return;
              setState(() {
                runtime.text = key.$2;
                toolId = key.$1;
              });
            },
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: McAction(
              label: 'Browse Proton folder…',
              icon: Icons.folder_open,
              onPressed: busy ? null : () => browse(true),
            ),
          ),
        ] else ...[
          TextFormField(
            key: const ValueKey('proton-runtime-folder'),
            controller: runtime,
            enabled: !busy,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Proton folder'),
            onChanged: (_) => setState(() {
              toolId = '';
              manualRuntime = true;
            }),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: McAction(
              label: 'Browse…',
              icon: Icons.folder_open,
              onPressed: busy ? null : () => browse(true),
            ),
          ),
        ],
        if (problem != null || search.problem != null) ...[
          const SizedBox(height: 12),
          McStatus(title: problem ?? search.problem!, tone: McStatusTone.error),
          McAction(
            label: 'Retry search',
            onPressed: search.loading ? null : () => unawaited(search.search()),
          ),
        ],
        const SizedBox(height: 12),
        Material(
          color: Colors.transparent,
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('Proton details'),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (data.text.isNotEmpty)
                      SelectableText('Prefix folder: ${data.text}/pfx'),
                    if (runtime.text.isNotEmpty)
                      SelectableText('Proton folder: ${runtime.text}'),
                    for (final mapping
                        in report?.mappings ?? const <ProtonToolMapping>[]) ...[
                      Text(
                        'Steam game-specific setting: ${mapping.perGame ?? 'Not set'}',
                      ),
                      Text(
                        'Steam default: ${mapping.globalDefault ?? 'Not set'}',
                      ),
                      SelectableText(mapping.source.path),
                    ],
                    if (report?.limited ?? false)
                      const McStatus(title: 'The search reached its limit.'),
                    for (final issue
                        in report?.problems ?? const <GameValidationProblem>[])
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text('${issue.path}\n${issue.detail}'),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
