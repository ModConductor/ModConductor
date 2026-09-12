import 'package:flutter/material.dart';

class McChoice<T> extends StatelessWidget {
  const McChoice({
    super.key,
    required this.label,
    required this.value,
    required this.choices,
    required this.describe,
    required this.onChanged,
    this.enabled = true,
  });
  final String label;
  final T value;
  final List<T> choices;
  final String Function(T) describe;
  final ValueChanged<T> onChanged;
  final bool enabled;
  @override
  Widget build(BuildContext context) => DropdownButtonFormField<T>(
    key: ValueKey((label, value)),
    initialValue: value,
    isExpanded: true,
    decoration: InputDecoration(labelText: label),
    items: [
      for (final choice in choices)
        DropdownMenuItem(
          value: choice,
          child: Text(describe(choice), overflow: TextOverflow.ellipsis),
        ),
    ],
    onChanged: enabled
        ? (value) {
            if (value != null) onChanged(value);
          }
        : null,
  );
}
