import 'package:flutter/material.dart';

import 'actions.dart';
import 'localization.dart';

class McDialog extends StatelessWidget {
  const McDialog({
    super.key,
    required this.title,
    required this.children,
    this.actions,
    this.contentWidth = 460,
  });
  final String title;
  final List<Widget> children;
  final List<Widget>? actions;
  final double contentWidth;

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: Text(title),
    content: SizedBox(
      width: contentWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    ),
    actions:
        actions ??
        [
          McAction(
            label: McUiLocalization.labelsOf(context).close,
            onPressed: () => Navigator.pop(context),
          ),
        ],
  );
}

class McFormDialog extends StatelessWidget {
  const McFormDialog({
    super.key,
    required this.title,
    required this.children,
    required this.action,
    required this.onSubmit,
    this.canCancel = true,
  });
  final String title;
  final List<Widget> children;
  final String action;
  final VoidCallback? onSubmit;
  final bool canCancel;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: canCancel,
    child: McDialog(
      title: title,
      actions: [
        McAction(
          label: McUiLocalization.labelsOf(context).cancel,
          onPressed: canCancel ? () => Navigator.pop(context) : null,
        ),
        McAction(
          key: const ValueKey('submit'),
          label: action,
          emphasis: McActionEmphasis.primary,
          onPressed: onSubmit,
        ),
      ],
      children: children,
    ),
  );
}

/// A display name is not a directory name. Shared by both kinds of creation
/// and the profile rename/clone forms.
class McNameField extends StatelessWidget {
  const McNameField({
    super.key,
    required this.controller,
    required this.onSubmit,
    this.validator,
  });
  final FormFieldValidator<String>? validator;
  final TextEditingController controller;
  final VoidCallback onSubmit;
  @override
  Widget build(BuildContext context) => TextFormField(
    key: const ValueKey('name'),
    controller: controller,
    autofocus: true,
    onFieldSubmitted: (_) => onSubmit(),
    decoration: InputDecoration(
      labelText: McUiLocalization.labelsOf(context).name,
    ),
    validator:
        validator ??
        (value) => value == null || value.trim().isEmpty
            ? McUiLocalization.labelsOf(context).enterName
            : null,
  );
}

class McNameDialog extends StatefulWidget {
  const McNameDialog({
    super.key,
    required this.title,
    required this.action,
    this.initial = '',
  });
  final String title;
  final String action;
  final String initial;
  @override
  State<McNameDialog> createState() => _McNameDialogState();
}

class _McNameDialogState extends State<McNameDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial);
  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    if (_form.currentState!.validate()) {
      Navigator.pop(context, _name.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _form,
    child: McFormDialog(
      title: widget.title,
      action: widget.action,
      onSubmit: _submit,
      children: [McNameField(controller: _name, onSubmit: _submit)],
    ),
  );
}
