import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'category_controller.dart';
import 'category_picker.dart';

Future<void> manageCategories(
  BuildContext context,
  ModOrganizationClient client,
  String workspace,
) async {
  final controller = CategoryController(client, workspace);
  try {
    await showDialog<void>(
      context: context,
      builder: (context) => ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final selected = controller.model.selected;
          final editable =
              !controller.loading &&
              !controller.stale &&
              controller.revision != null;
          return McDialog(
            title: 'Manage categories',
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  McAction(
                    label: 'New category',
                    icon: Icons.add,
                    onPressed: editable
                        ? () => _edit(context, controller)
                        : null,
                  ),
                  McIconAction(
                    label: 'Edit category',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: editable && selected != null && !selected.missing
                        ? () => _edit(context, controller, original: selected)
                        : null,
                  ),
                  McIconAction(
                    label: 'Delete category',
                    icon: const Icon(Icons.delete_outline),
                    onPressed:
                        editable &&
                            selected != null &&
                            !selected.missing &&
                            !selected.hasChildren
                        ? () => _delete(context, controller, selected)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CategoryPicker(controller: controller),
            ],
          );
        },
      ),
    );
  } finally {
    controller.dispose();
  }
}

Future<void> _edit(
  BuildContext context,
  CategoryController controller, {
  ModCategory? original,
}) => showDialog<void>(
  context: context,
  builder: (_) => _CategoryEditor(controller: controller, original: original),
);
Future<void> _delete(
  BuildContext context,
  CategoryController controller,
  ModCategory category,
) async {
  await showDialog<void>(
    context: context,
    builder: (context) => ListenableBuilder(
      listenable: controller,
      builder: (context, _) => McFormDialog(
        title: 'Delete ${categoryLabel(category.label)}?',
        action: 'Delete',
        onSubmit: controller.loading || controller.stale
            ? null
            : () async {
                final saved = await controller.change(
                  (revision) => controller.client.deleteCategory(
                    controller.workspace,
                    revision,
                    category.id,
                  ),
                  removedId: category.id,
                );
                if (context.mounted && saved) Navigator.pop(context);
              },
        children: [
          Text(
            category.assignedCount == 0
                ? 'This category has no assigned mods.'
                : '${category.assignedCount} ${category.assignedCount == 1 ? 'mod will' : 'mods will'} keep ${categoryLabel(category.label)} as a missing category.',
          ),
          if (controller.problem != null) ...[
            const SizedBox(height: 12),
            McStatus(title: controller.problem!, tone: McStatusTone.error),
          ],
        ],
      ),
    ),
  );
}

class _CategoryEditor extends StatefulWidget {
  const _CategoryEditor({required this.controller, this.original});
  final CategoryController controller;
  final ModCategory? original;
  @override
  State<_CategoryEditor> createState() => _CategoryEditorState();
}

class _CategoryEditorState extends State<_CategoryEditor> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.original?.label ?? '');
  late final String _id = widget.original?.id ?? newOperationId();
  late String? _parentId = widget.original?.parentId;
  late String? _parentLabel = _parentId == null
      ? null
      : widget.controller.model[_parentId]?.label;
  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final controller = widget.controller;
    final saved = await controller.change(
      (revision) => widget.original == null
          ? controller.client.createCategory(
              controller.workspace,
              revision,
              _id,
              _name.text,
              parentId: _parentId,
            )
          : controller.client.updateCategory(
              controller.workspace,
              revision,
              _id,
              _name.text,
              parentId: _parentId,
            ),
    );
    if (mounted && saved) {
      await controller.load(parent: _id);
      controller.model.select(_id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final controller = widget.controller;
      return Form(
        key: _form,
        child: McFormDialog(
          title: widget.original == null ? 'New category' : 'Edit category',
          action: 'Save',
          onSubmit: controller.loading || controller.stale ? null : _save,
          children: [
            McNameField(
              controller: _name,
              onSubmit: _save,
              validator: (value) =>
                  value == widget.original?.label ||
                      (value != null && value.trim().isNotEmpty)
                  ? null
                  : 'Enter a name.',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _parentId == null
                        ? 'No parent category'
                        : categoryLabel(_parentLabel ?? _parentId!),
                  ),
                ),
                TextButton(
                  onPressed: controller.loading
                      ? null
                      : () async {
                          final values = await chooseCategories(
                            context,
                            controller.client,
                            controller.workspace,
                            title: 'Parent category',
                            initial: _parentId == null
                                ? const []
                                : [
                                    CategoryReference(
                                      _parentId!,
                                      _parentLabel ?? _parentId!,
                                    ),
                                  ],
                            multiple: false,
                          );
                          if (mounted && values != null) {
                            setState(() {
                              _parentId = values.isEmpty
                                  ? null
                                  : values.first.id;
                              _parentLabel = values.isEmpty
                                  ? null
                                  : values.first.label;
                            });
                          }
                        },
                  child: const Text('Choose parent'),
                ),
              ],
            ),
            if (controller.problem != null) ...[
              const SizedBox(height: 12),
              McStatus(title: controller.problem!, tone: McStatusTone.error),
            ],
            if (controller.stale)
              TextButton(
                onPressed: () async {
                  await controller.reload();
                  if (widget.original != null) {
                    await controller.load(parent: _id);
                  }
                  final current = controller.model[_id];
                  if (mounted && current != null) {
                    setState(() {
                      _name.text = current.label;
                      _parentId = current.parentId;
                      _parentLabel = _parentId == null
                          ? null
                          : controller.model[_parentId]?.label;
                    });
                  }
                },
                child: const Text('Reload categories'),
              ),
          ],
        ),
      );
    },
  );
}
