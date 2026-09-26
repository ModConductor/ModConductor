import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

class BundleToolbar extends StatelessWidget {
  const BundleToolbar({
    super.key,
    required this.title,
    required this.picking,
    required this.hasBundle,
    required this.busy,
    required this.hasSelection,
    required this.next,
    required this.onBack,
    required this.onAction,
    required this.onContinue,
  });

  final String title;
  final bool picking, hasBundle, busy, hasSelection;
  final BundleItem? next;
  final VoidCallback onBack, onContinue;
  final ValueChanged<String> onAction;

  String get primaryLabel {
    if (picking) return 'Continue';
    if (next == null) return 'Finish';
    return switch (next!.state) {
      BundleItemState.failed => 'Retry',
      BundleItemState.installing => 'View installation',
      BundleItemState.needsReview ||
      BundleItemState.installed => 'Configure next',
    };
  }

  @override
  Widget build(BuildContext context) => Row(
    children: [
      McIconAction(
        label: picking && hasBundle ? 'Back to bundle' : 'Back to archives',
        icon: const Icon(Icons.arrow_back),
        onPressed: busy ? null : onBack,
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      McIconMenu<String>(
        label: 'Bundle actions',
        itemBuilder: (_) => [
          const PopupMenuItem(
            value: 'order',
            child: Text('Installation order'),
          ),
          const PopupMenuItem(value: 'limits', child: Text('Bundle limits')),
          PopupMenuItem(
            value: 'cleanup',
            enabled: hasBundle && !busy,
            child: const Text('Delete temporary files'),
          ),
        ],
        onSelected: onAction,
      ),
      const SizedBox(width: 8),
      McAction(
        label: primaryLabel,
        emphasis: McActionEmphasis.primary,
        onPressed: busy || (picking ? !hasSelection : !hasBundle)
            ? null
            : onContinue,
      ),
    ],
  );
}
