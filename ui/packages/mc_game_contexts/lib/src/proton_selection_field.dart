import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

class ProtonSelectionField extends StatelessWidget {
  const ProtonSelectionField({
    super.key,
    required this.selection,
    required this.onSelect,
    this.runtimeName,
  });

  final ProtonSelection? selection;
  final String? runtimeName;
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Proton', style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 4),
      if (selection case final value?) ...[
        SelectableText(runtimeName ?? value.runtimeDirectory),
        Text(value.compatData, style: Theme.of(context).textTheme.bodySmall),
      ] else
        const Text('Not selected'),
      const SizedBox(height: 8),
      McAction(
        key: const ValueKey('select-proton'),
        label: selection == null ? 'Select Proton…' : 'Change Proton…',
        icon: Icons.tune,
        onPressed: onSelect,
      ),
    ],
  );
}
