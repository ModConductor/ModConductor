import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'installation_dialog.dart' show GameDirectoryChooser;
import 'game_editor_controller.dart';
import 'game_editor_advanced.dart';

class GameEditor extends StatefulWidget {
  const GameEditor({
    super.key,
    required this.controller,
    required this.chooseDirectory,
    required this.onSaved,
    required this.onCancel,
  });
  final GameEditorController controller;
  final GameDirectoryChooser chooseDirectory;
  final ValueChanged<RegisteredGame> onSaved;
  final VoidCallback onCancel;
  @override
  State<GameEditor> createState() => _GameEditorState();
}

class _GameEditorState extends State<GameEditor> {
  final query = TextEditingController(), thunderstore = TextEditingController();
  final advanced = ExpansibleController();
  GameEditorController get model => widget.controller;
  void syncAdvanced() {
    if (model.advanced == advanced.isExpanded) return;
    if (model.advanced) {
      advanced.expand();
    } else {
      advanced.collapse();
    }
  }

  void showSearch() {
    model.advanced = false;
    model.showSearch();
  }

  @override
  void initState() {
    super.initState();
    model.addListener(syncAdvanced);
    unawaited(model.load());
  }

  @override
  void dispose() {
    model.removeListener(syncAdvanced);
    advanced.dispose();
    query.dispose();
    thunderstore.dispose();
    super.dispose();
  }

  Future<void> browse() async {
    final folder = await widget.chooseDirectory(
      model.path.isEmpty ? null : model.path,
    );
    if (mounted && folder != null) await model.inspect(folder);
  }

  Future<void> save() async {
    final saved = await model.save();
    if (mounted && saved != null) widget.onSaved(saved);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: model,
    builder: (context, _) {
      final d = model.draft;
      final selected = model.installations.where(
        (row) => model
            .installationName(row)
            .toLowerCase()
            .contains(query.text.toLowerCase()),
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          McChoice(
            key: const ValueKey('game-source'),
            label: 'Source',
            value: model.source,
            choices: GameRegistrationSource.values,
            describe: (source) =>
                source == GameRegistrationSource.steam ? 'Steam' : 'Folder',
            enabled: !model.busy && !model.editing,
            onChanged: model.changeSource,
          ),
          const SizedBox(height: McSpacing.medium),
          if (model.source == GameRegistrationSource.steam &&
              !model.editing) ...[
            TextField(
              controller: query,
              decoration: const InputDecoration(
                labelText: 'Search installed Steam games',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (_) => model.changed(),
            ),
            const SizedBox(height: McSpacing.small),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final row in selected)
                    ListTile(
                      leading: const Icon(Icons.sports_esports_outlined),
                      title: Text(model.installationName(row)),
                      subtitle: Text(
                        row.directory.canonicalPath,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      selected: model.path == row.directory.canonicalPath,
                      trailing: model.path == row.directory.canonicalPath
                          ? const Icon(Icons.check_circle)
                          : null,
                      onTap: model.busy
                          ? null
                          : () => unawaited(model.selectInstallation(row)),
                    ),
                ],
              ),
            ),
          ],
          if (model.source == GameRegistrationSource.folder || model.editing)
            TextFormField(
              key: ValueKey(('game-name', d)),
              initialValue: d.name,
              enabled: !model.busy,
              decoration: const InputDecoration(labelText: 'Name'),
              onChanged: model.chooseName,
            ),
          if (!model.editing) ...[
            const SizedBox(height: McSpacing.medium),
            Row(
              children: [
                const Icon(Icons.folder_outlined, size: 18),
                const SizedBox(width: McSpacing.small),
                Expanded(
                  child: SelectableText(
                    model.path.isEmpty ? 'Select game folder' : model.path,
                  ),
                ),
                McIconAction(
                  key: const ValueKey('choose-game-folder'),
                  label: 'Choose game folder',
                  icon: const Icon(Icons.folder_open),
                  onPressed: model.busy ? null : browse,
                ),
              ],
            ),
          ],
          const SizedBox(height: McSpacing.medium),
          if (model.detected && !model.editing) ...[
            Row(
              children: [
                const Icon(Icons.check_circle_outline, size: 18),
                const SizedBox(width: McSpacing.small),
                Expanded(
                  child: Text(
                    model.detectedEngine.startsWith('unity-')
                        ? (model.detectedEngine == 'unity-mono'
                              ? 'Unity · Mono'
                              : 'Unity · IL2CPP')
                        : 'Unreal',
                  ),
                ),
                Text('Detected', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: McSpacing.small),
          ],
          if (!model.editing) GameSetupFields(controller: model),
          ExpansionTile(
            controller: advanced,
            onExpansionChanged: (value) => model.advanced = value,
            title: const Text('Advanced'),
            initiallyExpanded: model.advanced,
            tilePadding: EdgeInsets.zero,
            children: [
              GameSetupFields(controller: model, advanced: true),
              if (!model.editing &&
                  model.source == GameRegistrationSource.steam)
                TextFormField(
                  key: ValueKey(('game-name', d)),
                  initialValue: d.name,
                  decoration: const InputDecoration(labelText: 'Name'),
                  enabled: !model.busy,
                  onChanged: model.chooseName,
                ),
              if (!model.editing &&
                  !model.searchVisible &&
                  d.mechanism.isNotEmpty)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: McAction(
                    label: 'Search Thunderstore',
                    icon: Icons.search,
                    onPressed: model.busy ? null : showSearch,
                  ),
                ),
            ],
          ),
          if (model.searchVisible) ...[
            TextField(
              controller: thunderstore,
              decoration: InputDecoration(
                labelText: 'Search Thunderstore games',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: McIconAction(
                  label: 'Search Thunderstore games',
                  icon: const Icon(Icons.search),
                  onPressed: model.busy
                      ? null
                      : () => unawaited(model.search(thunderstore.text)),
                ),
              ),
              onSubmitted: (value) => unawaited(model.search(value)),
            ),
            for (final game in model.matches)
              ListTile(
                leading: const Icon(Icons.sports_esports_outlined),
                title: Text(game.name),
                subtitle: Text(
                  game.suppliesSetup
                      ? 'Thunderstore · ${game.community}'
                      : 'Thunderstore community · ${game.community}',
                ),
                onTap: model.busy || model.path.isEmpty
                    ? null
                    : () => unawaited(model.selectMetadata(game)),
              ),
          ],
          if (model.problem case final problem?)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: McSpacing.medium),
              child: McStatus(title: problem, tone: McStatusTone.error),
            ),
          const SizedBox(height: McSpacing.medium),
          Wrap(
            spacing: McSpacing.small,
            runSpacing: McSpacing.small,
            children: [
              if (d.mechanism.isEmpty && !model.searchVisible)
                McAction(
                  label: 'Search Thunderstore',
                  icon: Icons.search,
                  onPressed: model.busy ? null : showSearch,
                ),
              McAction(
                key: const ValueKey('register-game'),
                label: model.editing ? 'Save game' : 'Add game',
                emphasis: McActionEmphasis.primary,
                onPressed: model.canSave ? save : null,
              ),
              McAction(
                label: 'Cancel',
                onPressed: model.busy ? null : widget.onCancel,
              ),
            ],
          ),
        ],
      );
    },
  );
}
