import 'package:flutter/material.dart';

import 'actions.dart';

/// Shared modal composition for workspace, profile, and deletion forms.
class McFormDialog extends StatelessWidget {
  const McFormDialog({
    super.key,
    required this.title,
    required this.children,
    required this.action,
    required this.onSubmit,
  });
  final String title;
  final List<Widget> children;
  final String action;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: Text(title),
    content: SizedBox(
      width: 460,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    ),
    actions: [
      McAction(label: 'Cancel', onPressed: () => Navigator.pop(context)),
      McAction(
        key: const ValueKey('submit'),
        label: action,
        emphasis: McActionEmphasis.primary,
        onPressed: onSubmit,
      ),
    ],
  );
}

/// A display name is not a directory name. Shared by both kinds of creation
/// and the profile rename/clone forms.
class McNameField extends StatelessWidget {
  const McNameField({
    super.key,
    required this.controller,
    required this.onSubmit,
  });
  final TextEditingController controller;
  final VoidCallback onSubmit;
  @override
  Widget build(BuildContext context) => TextFormField(
    key: const ValueKey('name'),
    controller: controller,
    autofocus: true,
    onFieldSubmitted: (_) => onSubmit(),
    decoration: const InputDecoration(labelText: 'Name'),
    validator: (value) =>
        value == null || value.trim().isEmpty ? 'Enter a name.' : null,
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
