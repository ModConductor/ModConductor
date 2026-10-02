import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'catalogue_controller.dart';
import 'game_editor.dart';
import 'game_editor_controller.dart';
import 'installation_dialog.dart' show GameDirectoryChooser;

class GamesPage extends StatefulWidget {
  const GamesPage({
    super.key,
    required this.catalogue,
    required this.client,
    required this.chooseDirectory,
  });
  final GameCatalogueController catalogue;
  final GameRegistrationClient? client;
  final GameDirectoryChooser chooseDirectory;
  @override
  State<GamesPage> createState() => _GamesPageState();
}

class _GamesPageState extends State<GamesPage> {
  GameEditorController? editor;
  void edit([String? id]) {
    final client = widget.client;
    if (client == null) return;
    setState(
      () => editor = GameEditorController(client, widget.catalogue, editId: id),
    );
  }

  void close() {
    editor?.dispose();
    setState(() => editor = null);
  }

  @override
  void dispose() {
    editor?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => McPage(
    title: editor == null
        ? 'Games'
        : editor!.editing
        ? 'Edit game'
        : 'Add game',
    children: [
      if (editor case final current?)
        GameEditor(
          key: ValueKey(current),
          controller: current,
          chooseDirectory: widget.chooseDirectory,
          onSaved: (_) => close(),
          onCancel: close,
        )
      else ...[
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: McAction(
            label: 'Add game',
            icon: Icons.add,
            emphasis: McActionEmphasis.primary,
            onPressed: widget.client == null ? null : edit,
          ),
        ),
        const SizedBox(height: McSpacing.large),
        ListenableBuilder(
          listenable: widget.catalogue,
          builder: (context, _) => Card(
            child: Column(
              children: [
                for (final game in widget.catalogue.games)
                  ListTile(
                    key: ValueKey(game.id),
                    leading: SizedBox(
                      width: 64,
                      height: 44,
                      child: game.artworkUrl.isEmpty
                          ? const Icon(Icons.sports_esports_outlined)
                          : McPortraitArtwork(
                              image: Uri.parse(game.artworkUrl),
                            ),
                    ),
                    title: Text(game.selectionLabel(widget.catalogue.games)),
                    subtitle: Text(
                      game.capability(GameCapabilityId.unityMono) != null
                          ? 'Unity · Mono · BepInEx'
                          : game.capability(GameCapabilityId.unityIl2Cpp) !=
                                null
                          ? 'Unity · IL2CPP · BepInEx'
                          : game.capability(GameCapabilityId.unreal) != null
                          ? 'Unreal'
                          : game.storefront,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          game.storefront,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (game.id.startsWith('custom-'))
                          McIconAction(
                            label: 'Edit ${game.name}',
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: widget.client == null
                                ? null
                                : () => edit(game.id),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    ],
  );
}

Future<RegisteredGame?> showGameEditor(
  BuildContext context,
  GameRegistrationClient client,
  GameCatalogueController catalogue,
  GameDirectoryChooser chooseDirectory,
) async {
  final controller = GameEditorController(client, catalogue);
  try {
    return await showDialog<RegisteredGame>(
      context: context,
      barrierDismissible: false,
      builder: (context) => McDialog(
        title: 'Add game',
        contentWidth: 1040,
        actions: const [],
        children: [
          GameEditor(
            controller: controller,
            chooseDirectory: chooseDirectory,
            onSaved: (result) => Navigator.pop(context, result),
            onCancel: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  } finally {
    controller.dispose();
  }
}
