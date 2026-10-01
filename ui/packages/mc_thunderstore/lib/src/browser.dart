import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';
import 'package:mc_ui_collections/mc_ui_collections.dart';

import 'controller.dart';

part 'results.dart';
part 'inspector.dart';
part 'acquisition_footer.dart';

class ThunderstoreBrowser extends StatefulWidget {
  const ThunderstoreBrowser({
    super.key,
    required this.client,
    required this.workspaceId,
    required this.visible,
    this.onInstalled,
  });
  final ThunderstoreClient client;
  final String workspaceId;
  final bool visible;
  final VoidCallback? onInstalled;
  @override
  State<ThunderstoreBrowser> createState() => _ThunderstoreBrowserState();
}

class _ThunderstoreBrowserState extends State<ThunderstoreBrowser> {
  late ThunderstoreController controller;
  bool _loaded = false, _wasRunning = false;
  @override
  void initState() {
    super.initState();
    _attach();
  }

  void _attach() {
    controller = ThunderstoreController(widget.client, widget.workspaceId)
      ..addListener(_changed);
    _loaded = false;
    _wasRunning = false;
    _load();
  }

  void _load() {
    if (_loaded || !widget.visible) return;
    _loaded = true;
    unawaited(controller.search());
  }

  void _changed() {
    if (!mounted) return;
    if (_wasRunning && !controller.running) widget.onInstalled?.call();
    _wasRunning = controller.running;
    setState(() {});
  }

  @override
  void didUpdateWidget(ThunderstoreBrowser old) {
    super.didUpdateWidget(old);
    if (old.client != widget.client || old.workspaceId != widget.workspaceId) {
      controller.removeListener(_changed);
      controller.dispose();
      _attach();
    } else {
      _load();
    }
  }

  @override
  void dispose() {
    controller.removeListener(_changed);
    controller.dispose();
    super.dispose();
  }

  Widget _artwork(Uri? image, double size) => SizedBox.square(
    dimension: size,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: McPortraitArtwork(image: image),
    ),
  );
  Widget _controls(double width) => Wrap(
    alignment: WrapAlignment.spaceBetween,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 24,
    runSpacing: 12,
    children: [
      Text('Thunderstore', style: Theme.of(context).textTheme.titleMedium),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          SizedBox(
            width: width < 600 ? 190 : 220,
            child: McChoice(
              label: 'Community',
              value: 'Valheim',
              choices: const ['Valheim'],
              describe: (value) => value,
              onChanged: (_) {},
            ),
          ),
          SizedBox(
            width: width < 600 ? 230 : 240,
            child: McChoice(
              label: 'Sort',
              value: controller.ordering,
              choices: const [
                'most-downloaded',
                'last-updated',
                'newest',
                'top-rated',
              ],
              describe: (value) => switch (value) {
                'most-downloaded' => 'Most downloaded',
                'last-updated' => 'Recently updated',
                'newest' => 'Newest',
                _ => 'Highest rated',
              },
              enabled: !controller.running,
              onChanged: controller.changeOrdering,
            ),
          ),
        ],
      ),
    ],
  );
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _controls(bounds.maxWidth),
        const SizedBox(height: 16),
        Expanded(
          child: LayoutBuilder(
            builder: (context, bounds) {
              final selected = controller.selected != null;
              if (selected && bounds.maxWidth < 1050)
                return _inspector(context);
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _results(
                      bounds.maxWidth - (selected ? 436 : 0) < 760,
                    ),
                  ),
                  if (selected) ...[
                    const SizedBox(width: 16),
                    SizedBox(width: 420, child: _inspector(context)),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    ),
  );
}
