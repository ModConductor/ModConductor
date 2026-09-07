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
  final focus = FocusNode(debugLabel: 'Categories');
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
                        ? () => _edit(context, controller, focusNode: focus)
                        : null,
                  ),
                  McIconAction(
                    label: 'Edit category',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: editable && selected != null && !selected.missing
                        ? () => _edit(
                            context,
                            controller,
                            original: selected,
                            focusNode: focus,
                          )
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
              CategoryPicker(controller: controller, focusNode: focus),
            ],
          );
        },
      ),
    );
  } finally {
    focus.dispose();
    controller.dispose();
  }
}

Future<void> _edit(
  BuildContext context,
  CategoryController controller, {
  ModCategory? original,
  required FocusNode focusNode,
}) async {
  final revealed = await showDialog<bool>(
    context: context,
    builder: (_) => _CategoryEditor(controller: controller, original: original),
  );
  if (context.mounted && revealed == true) focusNode.requestFocus();
}

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
  bool _committed = false;
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

  void _finishReveal() {
    final controller = widget.controller;
    if (controller.problem == null &&
        !controller.stale &&
        controller.model[_id] != null) {
      controller.model.select(_id);
      Navigator.pop(context, true);
    }
  }

  Future<void> _save() async {
    final controller = widget.controller;
    if (_committed) {
      await controller.reload(revealId: _id);
      if (mounted) _finishReveal();
      return;
    }
    if (!_form.currentState!.validate()) return;
    final name = _name.text, parent = _parentId;
    final saved = await controller.change(
      (revision) => widget.original == null
          ? controller.client.createCategory(
              controller.workspace,
              revision,
              _id,
              name,
              parentId: parent,
            )
          : controller.client.updateCategory(
              controller.workspace,
              revision,
              _id,
              name,
              parentId: parent,
            ),
      revealId: _id,
    );
    if (mounted && saved) {
      setState(() {
        _committed = true;
        _name.text = name;
        _parentId = parent;
      });
      _finishReveal();
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
          title: _committed
              ? 'Show saved category'
              : widget.original == null
              ? 'New category'
              : 'Edit category',
          action: _committed ? 'Retry' : 'Save',
          onSubmit: controller.loading || controller.stale ? null : _save,
          children: [
            if (_committed)
              Text(categoryLabel(_name.text))
            else
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
                  onPressed: controller.loading || _committed
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
                  if (_committed) {
                    await _save();
                    return;
                  }
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
