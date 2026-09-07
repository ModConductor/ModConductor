import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_collections/mc_ui_collections.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'category_controller.dart';

class CategoryPicker extends StatelessWidget {
  const CategoryPicker({super.key, required this.controller});
  final CategoryController controller;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final model = controller.model;
      return SizedBox(
        height: 400,
        child: McCollection<String, ModCategory>(
          model: model,
          title: 'Categories',
          showTitle: false,
          nodeLabel: (row) => categoryLabel(row.label),
          nodeIcon: (_) => const Icon(Icons.label_outline, size: 19),
          filterLabel: 'Filter loaded categories',
          countLabel: '${model.length} categories loaded',
          loading: controller.loading,
          problem: controller.problem,
          onLoad: controller.stale
              ? controller.reload
              : controller.canLoad || controller.problem != null
              ? controller.more
              : null,
          onCancel: controller.cancel,
          onRefresh: controller.reload,
          multiSelect: controller.multiple,
          selectMultiple: controller.multiple,
          semanticLabel: (row) =>
              '${categoryLabel(row.label)}${row.missing ? ', missing category' : ''}',
          footer: TextButton(
            onPressed: model.selectedIds.isEmpty ? null : model.clearSelection,
            child: const Text('Clear selection'),
          ),
          columns: [
            if (controller.multiple)
              McColumn(
                '',
                (row) => Semantics(
                  label: 'Assign ${categoryLabel(row.label)}',
                  child: Checkbox(
                    value: model.selectedIds.contains(row.id),
                    onChanged: (_) => model.select(row.id, toggle: true),
                  ),
                ),
                width: 44,
                interactive: true,
              ),
            McColumn(
              'Name',
              (row) => Text(
                '${categoryLabel(row.label)}${row.missing ? ' · Missing' : ''}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    },
  );
}

Future<List<CategoryReference>?> chooseCategories(
  BuildContext context,
  ModOrganizationClient client,
  String workspace, {
  required String title,
  List<CategoryReference> initial = const [],
  bool multiple = true,
}) async {
  final controller = CategoryController(
    client,
    workspace,
    initial: initial,
    multiple: multiple,
  );
  try {
    return await showDialog<List<CategoryReference>>(
      context: context,
      builder: (context) => ListenableBuilder(
        listenable: controller,
        builder: (context, _) => McFormDialog(
          title: title,
          action: multiple ? 'Apply' : 'Choose',
          onSubmit: controller.stale || controller.loading
              ? null
              : () => Navigator.pop(context, controller.selected),
          children: [CategoryPicker(controller: controller)],
        ),
      ),
    );
  } finally {
    controller.dispose();
  }
}
