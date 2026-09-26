import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'actions.dart';
import 'theme.dart';

class McPathValue extends StatelessWidget {
  const McPathValue({super.key, required this.path, this.label});

  final String path;
  final String? label;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: path));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Path copied')));
  }

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Semantics(
          label: label == null ? path : '$label, $path',
          excludeSemantics: true,
          child: SelectionArea(
            child: Text(path, style: const TextStyle(fontFamily: 'monospace')),
          ),
        ),
      ),
      const SizedBox(width: McSpacing.small),
      McIconAction(
        label: 'Copy path',
        onPressed: () => _copy(context),
        icon: const Icon(Icons.copy_outlined, size: 18),
        padding: EdgeInsets.zero,
      ),
    ],
  );
}
