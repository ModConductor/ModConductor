import 'package:flutter/material.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

class BainToolbar extends StatelessWidget {
  const BainToolbar({
    super.key,
    required this.name,
    required this.backLabel,
    required this.review,
    required this.available,
    required this.canAdvance,
    required this.supported,
    required this.hasNotes,
    required this.canUseFomod,
    required this.canUpdate,
    required this.onBack,
    required this.onAction,
    required this.onAdvance,
  });

  final String name, backLabel;
  final bool review, available, canAdvance, supported;
  final bool hasNotes, canUseFomod, canUpdate;
  final VoidCallback onBack, onAdvance;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      McIconAction(
        label: review ? 'Back to package folders' : backLabel,
        icon: const Icon(Icons.arrow_back),
        onPressed: review && !available ? null : onBack,
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          '${review ? 'Review ' : ''}$name',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      McIconMenu<String>(
        label: 'Installer actions',
        itemBuilder: (_) => [
          if (hasNotes)
            PopupMenuItem(
              value: 'notes',
              enabled: available,
              child: const Text('Package notes'),
            ),
          if (canUseFomod)
            PopupMenuItem(
              value: 'fomod',
              enabled: available,
              child: const Text('Use XML installer'),
            ),
          PopupMenuItem(
            value: 'manual',
            enabled: available,
            child: const Text('Use manual layout'),
          ),
          if (review && canUpdate)
            PopupMenuItem(
              value: 'update',
              enabled: canAdvance,
              child: const Text('Update installed mod'),
            ),
        ],
        onSelected: onAction,
      ),
      if (supported) ...[
        const SizedBox(width: 8),
        McAction(
          label: review ? 'Install' : 'Review files',
          emphasis: McActionEmphasis.primary,
          onPressed: canAdvance ? onAdvance : null,
        ),
      ],
    ],
  );
}
