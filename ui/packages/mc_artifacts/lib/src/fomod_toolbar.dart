import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

class FomodToolbar extends StatelessWidget {
  const FomodToolbar({
    super.key,
    required this.name,
    required this.backLabel,
    required this.value,
    required this.review,
    required this.available,
    required this.editable,
    required this.canUsePackages,
    required this.canUpdate,
    required this.onBack,
    required this.onAction,
    required this.onAdvance,
  });

  final String name, backLabel;
  final FomodChoices? value;
  final bool review, available, editable, canUsePackages, canUpdate;
  final VoidCallback onBack, onAdvance;
  final ValueChanged<String> onAction;

  String get advanceLabel {
    if (review) return 'Install';
    return value!.stepNumber == value!.visibleSteps ? 'Review files' : 'Next';
  }

  @override
  Widget build(BuildContext context) => Row(
    children: [
      McIconAction(
        label: value?.canBack == true ? 'Previous step' : backLabel,
        icon: const Icon(Icons.arrow_back),
        onPressed: value?.canBack == true && !available ? null : onBack,
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
          PopupMenuItem(
            value: 'manual',
            enabled: available,
            child: const Text('Use manual layout'),
          ),
          if (canUsePackages)
            PopupMenuItem(
              value: 'packages',
              enabled: available,
              child: const Text('Use package folders'),
            ),
          if (review && canUpdate)
            PopupMenuItem(
              value: 'update',
              enabled: editable,
              child: const Text('Update installed mod'),
            ),
        ],
        onSelected: onAction,
      ),
      if (value?.hasStep == true || review) ...[
        const SizedBox(width: 8),
        McAction(
          label: advanceLabel,
          emphasis: McActionEmphasis.primary,
          onPressed: editable ? onAdvance : null,
        ),
      ],
    ],
  );
}
