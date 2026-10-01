import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

class ScriptExtenderSection extends StatefulWidget {
  const ScriptExtenderSection({
    super.key,
    required this.definition,
    required this.onTools,
    this.client,
  });
  final GameDefinitionInfo definition;
  final GameCatalogueClient? client;
  final VoidCallback onTools;
  @override
  State<ScriptExtenderSection> createState() => _ScriptExtenderSectionState();
}

class _ScriptExtenderSectionState extends State<ScriptExtenderSection> {
  bool opening = false;
  String? problem;
  Future<void> open() async {
    if (opening || widget.client == null) return;
    setState(() => opening = true);
    try {
      final result = await widget.client!.openScriptExtenderPage(
        widget.definition.id,
      );
      if (mounted) setState(() => problem = result);
    } on Exception {
      if (mounted) setState(() => problem = 'The project page could not open.');
    } finally {
      if (mounted) setState(() => opening = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: McSpacing.large),
    child: McSection(
      title: 'Script extender',
      children: [
        Row(
          children: [
            const Icon(Icons.extension_outlined, size: 28),
            const SizedBox(width: McSpacing.medium),
            Expanded(
              child: Text(
                widget.definition.extenderName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            McIconAction(
              label: 'Open ${widget.definition.extenderName} project page',
              icon: const Icon(Icons.open_in_new),
              onPressed: opening || widget.client == null ? null : open,
            ),
            const SizedBox(width: McSpacing.small),
            McAction(
              label: 'Tools',
              icon: Icons.terminal,
              onPressed: widget.onTools,
            ),
          ],
        ),
        if (problem case final detail?)
          McStatus(title: detail, tone: McStatusTone.error),
      ],
    ),
  );
}
