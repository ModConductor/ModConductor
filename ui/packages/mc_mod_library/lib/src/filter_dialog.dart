import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'category_controller.dart';
import 'category_picker.dart';

enum _FilterType { enabled, category, kind, status, uncategorized, missing }

String _typeLabel(_FilterType type) => switch (type) {
  _FilterType.enabled => 'Enabled',
  _FilterType.category => 'Category',
  _FilterType.kind => 'Mod kind',
  _FilterType.status => 'Status',
  _FilterType.uncategorized => 'No categories',
  _FilterType.missing => 'Missing category',
};
_FilterType _type(ModFilter value) => switch (value) {
  EnabledFilter() => _FilterType.enabled,
  CategoryFilter() => _FilterType.category,
  KindFilter() => _FilterType.kind,
  StatusFilter() => _FilterType.status,
  UncategorizedFilter() => _FilterType.uncategorized,
  MissingCategoryFilter() => _FilterType.missing,
};
String _kind(ModKind value) => switch (value) {
  ModKind.regular => 'Mod',
  ModKind.separator => 'Separator',
  ModKind.backup => 'Backup',
  ModKind.unmanaged => 'Unmanaged',
  ModKind.generatedOutput => 'Generated output',
};
String _status(InventoryStatus value) => switch (value) {
  InventoryStatus.ready => 'Ready',
  InventoryStatus.detached => 'Detached',
  InventoryStatus.changed => 'Changed',
  InventoryStatus.unproved => 'Unverified',
  InventoryStatus.publishing => 'Saving version',
  InventoryStatus.deleting => 'Deletion unfinished',
};

class ModFilterDialog extends StatefulWidget {
  const ModFilterDialog({
    super.key,
    required this.query,
    required this.client,
    required this.workspace,
  });
  final ModQuery query;
  final ModOrganizationClient client;
  final String workspace;
  @override
  State<ModFilterDialog> createState() => _ModFilterDialogState();
}

class _ModFilterDialogState extends State<ModFilterDialog> {
  late FilterMode _mode = widget.query.mode;
  late final List<ModFilter> _filters = List.of(widget.query.filters);
  Future<void> _category(int? index, {CategoryFilter? original}) async {
    final result = await chooseCategories(
      context,
      widget.client,
      widget.workspace,
      title: 'Filter category',
      initial: original == null ? const [] : [original.category],
      multiple: false,
    );
    if (!mounted || result == null) return;
    setState(() {
      if (result.isEmpty) {
        if (index != null) _filters.removeAt(index);
      } else {
        final filter = CategoryFilter(
          result.first,
          descendants: original?.descendants ?? false,
        );
        if (index == null) {
          _filters.add(filter);
        } else {
          _filters[index] = filter;
        }
      }
    });
  }

  void _add(_FilterType type) {
    if (type == _FilterType.category) {
      _category(null);
      return;
    }
    setState(
      () => _filters.add(switch (type) {
        _FilterType.enabled => const EnabledFilter(true),
        _FilterType.kind => const KindFilter(ModKind.regular),
        _FilterType.status => const StatusFilter(InventoryStatus.ready),
        _FilterType.uncategorized => const UncategorizedFilter(),
        _FilterType.missing => const MissingCategoryFilter(),
        _FilterType.category => throw StateError(
          'Category chooser owns this change.',
        ),
      }),
    );
  }

  @override
  Widget build(BuildContext context) => McFormDialog(
    title: 'Filter mods',
    action: 'Apply',
    onSubmit: () => Navigator.pop(
      context,
      widget.query.copyWith(mode: _mode, filters: List.unmodifiable(_filters)),
    ),
    children: [
      McChoice(
        label: 'Match',
        value: _mode,
        choices: FilterMode.values,
        describe: (value) =>
            value == FilterMode.all ? 'All filters' : 'Any filter',
        onChanged: (value) => setState(() => _mode = value),
      ),
      for (var i = 0; i < _filters.length; i++) ...[
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: switch (_filters[i]) {
                EnabledFilter(:final enabled) => McChoice<String>(
                  label: 'Enabled',
                  value: enabled == null
                      ? 'Not applicable'
                      : enabled
                      ? 'Yes'
                      : 'No',
                  choices: const ['Yes', 'No', 'Not applicable'],
                  describe: (value) => value,
                  onChanged: (value) => setState(
                    () => _filters[i] = EnabledFilter(
                      value == 'Not applicable' ? null : value == 'Yes',
                    ),
                  ),
                ),
                KindFilter(:final kind) => McChoice(
                  label: 'Mod kind',
                  value: kind,
                  choices: ModKind.values,
                  describe: _kind,
                  onChanged: (value) =>
                      setState(() => _filters[i] = KindFilter(value)),
                ),
                StatusFilter(:final status) => McChoice(
                  label: 'Status',
                  value: status,
                  choices: InventoryStatus.values,
                  describe: _status,
                  onChanged: (value) =>
                      setState(() => _filters[i] = StatusFilter(value)),
                ),
                CategoryFilter(:final category, :final descendants) => Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${categoryLabel(category.label)}${category.missing ? ' · Missing' : ''}',
                          ),
                        ),
                        TextButton(
                          onPressed: () => _category(
                            i,
                            original: _filters[i] as CategoryFilter,
                          ),
                          child: const Text('Choose'),
                        ),
                      ],
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Include child categories'),
                      value: descendants,
                      onChanged: (value) => setState(
                        () => _filters[i] = CategoryFilter(
                          category,
                          descendants: value!,
                        ),
                      ),
                    ),
                  ],
                ),
                UncategorizedFilter() => const Text('No categories'),
                MissingCategoryFilter() => const Text('Missing category'),
              },
            ),
            const SizedBox(width: 8),
            McIconAction(
              label: 'Remove ${_typeLabel(_type(_filters[i]))} filter',
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => _filters.removeAt(i)),
            ),
          ],
        ),
      ],
      const SizedBox(height: 16),
      Wrap(
        spacing: 8,
        children: [
          McMenuAction<_FilterType>(
            label: 'Add filter',
            choices: _FilterType.values,
            describe: _typeLabel,
            enabled: _filters.length < 16,
            onSelected: _add,
          ),
          TextButton(
            onPressed: _filters.isEmpty ? null : () => setState(_filters.clear),
            child: const Text('Clear filters'),
          ),
        ],
      ),
    ],
  );
}
