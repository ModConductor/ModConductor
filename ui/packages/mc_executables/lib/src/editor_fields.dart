import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

String executableRuntimeLabel(ExecutableRuntime value) => switch (value) {
  ExecutableRuntime.native => 'Native',
  ExecutableRuntime.wine => 'Wine',
  ExecutableRuntime.proton => 'Proton',
};

Widget executableField(
  String label,
  TextEditingController value, {
  bool required = false,
}) => Padding(
  padding: const EdgeInsets.only(bottom: 16),
  child: TextFormField(
    controller: value,
    decoration: InputDecoration(labelText: label),
    validator: required
        ? (v) => v == null || v.trim().isEmpty ? 'Enter $label.' : null
        : null,
  ),
);

Widget executablePathField(
  String label,
  TextEditingController value, {
  required VoidCallback onBrowse,
}) => Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Expanded(child: executableField(label, value, required: true)),
    const SizedBox(width: 8),
    McIconAction(
      label: 'Choose $label',
      icon: const Icon(Icons.folder_open_outlined),
      onPressed: onBrowse,
    ),
  ],
);

class ExecutableArguments extends StatelessWidget {
  const ExecutableArguments({
    super.key,
    required this.values,
    required this.onChanged,
  });
  final List<TextEditingController> values;
  final VoidCallback onChanged;
  @override
  Widget build(BuildContext context) => ExpansionTile(
    tilePadding: EdgeInsets.zero,
    title: const Text('Arguments'),
    children: [
      for (var i = 0; i < values.length; i++)
        Row(
          key: ObjectKey(values[i]),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: executableField('Argument ${i + 1}', values[i])),
            McIconAction(
              label: 'Remove argument ${i + 1}',
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () {
                values.removeAt(i).dispose();
                onChanged();
              },
            ),
          ],
        ),
      Align(
        alignment: Alignment.centerRight,
        child: McIconAction(
          label: 'Add argument; {game} is the profile game folder, {output} is its output folder.',
          icon: const Icon(Icons.add),
          onPressed: () {
            values.add(TextEditingController());
            onChanged();
          },
        ),
      ),
      const SizedBox(height: 12),
    ],
  );
}

class ExecutableEnvironmentDraft {
  ExecutableEnvironmentDraft(String key, String? content)
    : name = TextEditingController(text: key),
      value = TextEditingController(text: content ?? ''),
      remove = content == null;
  final TextEditingController name, value;
  bool remove;
  void dispose() {
    name.dispose();
    value.dispose();
  }
}

class ExecutableEnvironmentFields extends StatelessWidget {
  const ExecutableEnvironmentFields({
    super.key,
    required this.values,
    required this.onChanged,
  });
  final List<ExecutableEnvironmentDraft> values;
  final VoidCallback onChanged;
  @override
  Widget build(BuildContext context) => ExpansionTile(
    tilePadding: EdgeInsets.zero,
    title: const Text('Environment'),
    children: [
      for (final row in values)
        Column(
          key: ObjectKey(row),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: executableField('Variable', row.name, required: true),
                ),
                McIconAction(
                  label: 'Remove environment setting',
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () {
                    values.remove(row);
                    row.dispose();
                    onChanged();
                  },
                ),
              ],
            ),
            McChoice<bool>(
              label: 'Change',
              value: row.remove,
              choices: const [false, true],
              describe: (v) => v ? 'Remove child variable' : 'Set value',
              onChanged: (v) {
                row.remove = v;
                onChanged();
              },
            ),
            const SizedBox(height: 16),
            if (!row.remove) executableField('Value', row.value),
          ],
        ),
      Align(
        alignment: Alignment.centerRight,
        child: McIconAction(
          label: 'Add variable',
          icon: const Icon(Icons.add),
          onPressed: () {
            values.add(ExecutableEnvironmentDraft('', ''));
            onChanged();
          },
        ),
      ),
      const SizedBox(height: 12),
    ],
  );
}
