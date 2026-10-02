import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'game_editor_controller.dart';

class GameSearchArtwork extends StatelessWidget {
  const GameSearchArtwork(this.address, {super.key});
  final String address;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 44,
    height: 44,
    child: McPortraitArtwork(
      image: address.isEmpty ? null : Uri.parse(address),
    ),
  );
}

class GameSearchResults extends StatelessWidget {
  const GameSearchResults({super.key, required this.rows});
  final List<Widget> rows;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: (rows.length * 80.0).clamp(0, 220),
    child: ListView(shrinkWrap: true, children: rows),
  );
}

class ThunderstoreGameSearch extends StatelessWidget {
  const ThunderstoreGameSearch({
    super.key,
    required this.model,
    required this.query,
  });
  final GameEditorController model;
  final TextEditingController query;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextField(
        autofocus: true,
        controller: query,
        decoration: InputDecoration(
          labelText: 'Search Thunderstore games',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: McIconAction(
            label: 'Search Thunderstore games',
            icon: const Icon(Icons.search),
            onPressed: model.busy
                ? null
                : () => unawaited(model.search(query.text)),
          ),
        ),
        onSubmitted: model.busy
            ? null
            : (value) => unawaited(model.search(value)),
      ),
      if (model.searching)
        const McActionFeedback(
          kind: McActionFeedbackKind.pending,
          message: 'Searching Thunderstore games',
        )
      else if (model.searched && model.matches.isEmpty && model.problem == null)
        const McStatus(title: 'No Thunderstore games match this search.'),
      GameSearchResults(
        rows: [
          for (final game in model.matches)
            ListTile(
              leading: GameSearchArtwork(game.artworkUrl),
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
      ),
    ],
  );
}
