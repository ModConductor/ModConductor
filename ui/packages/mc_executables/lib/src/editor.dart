import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'controller.dart';

typedef ExecutablePathChooser = Future<String?> Function(String? initial);

class ExecutableEditor extends StatefulWidget {
  const ExecutableEditor({
    super.key,
    required this.controller,
    required this.chooseExecutable,
    required this.chooseDirectory,
    this.initial,
  });
  final ExecutablesController controller;
  final ExecutablePreset? initial;
  final ExecutablePathChooser chooseExecutable, chooseDirectory;
  @override
  State<ExecutableEditor> createState() => _ExecutableEditorState();
}

class _EnvironmentDraft {
  _EnvironmentDraft(String key, String? content)
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

class _ExecutableEditorState extends State<ExecutableEditor> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(),
      _path = TextEditingController(),
      _cwd = TextEditingController();
  final _args = <TextEditingController>[], _environment = <_EnvironmentDraft>[];
  late final String _id = widget.initial?.id ?? newOperationId();
  late final String _workspace = widget.controller.workspace!.id;
  late int _revision = widget.initial?.revision ?? 0;
  bool _busy = false, _needsRead = false;
  String? _error;
  ExecutablePreset? _attempt, _saved;
  @override
  void initState() {
    super.initState();
    final value = widget.initial;
    if (value != null) _fill(value);
  }

  void _fill(ExecutablePreset value) {
    _name.text = value.name;
    _path.text = value.executable;
    _cwd.text = value.workingDirectory;
    _revision = value.revision;
    for (final item in _args) {
      item.dispose();
    }
    _args.clear();
    for (final item in _environment) {
      item.dispose();
    }
    _environment.clear();
    _args.addAll(value.arguments.map((v) => TextEditingController(text: v)));
    _environment.addAll(
      value.environment.map((v) => _EnvironmentDraft(v.name, v.value)),
    );
  }

  ExecutablePreset _draft() => ExecutablePreset(
    id: _id,
    workspaceId: _workspace,
    revision: _revision,
    name: _name.text,
    executable: _path.text,
    workingDirectory: _cwd.text,
    arguments: _args.map((v) => v.text).toList(),
    environment: _environment
        .map(
          (v) => ExecutableEnvironment(
            v.name.text,
            v.remove ? null : v.value.text,
          ),
        )
        .toList(),
  );
  bool _matches(ExecutablePreset a, ExecutablePreset b) =>
      a.name == b.name &&
      a.executable == b.executable &&
      a.workingDirectory == b.workingDirectory &&
      a.arguments.length == b.arguments.length &&
      a.environment.length == b.environment.length &&
      List.generate(
        a.arguments.length,
        (i) => a.arguments[i] == b.arguments[i],
      ).every((v) => v) &&
      List.generate(
        a.environment.length,
        (i) =>
            a.environment[i].name == b.environment[i].name &&
            a.environment[i].value == b.environment[i].value,
      ).every((v) => v);
  Future<void> _submit() async {
    if (_busy || _needsRead || !_form.currentState!.validate()) return;
    final value = _draft();
    setState(() {
      _busy = true;
      _error = null;
      _attempt = value;
    });
    try {
      await widget.controller.save(value);
      if (mounted) Navigator.pop(context);
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _error = ExecutablesController.errorMessage(error);
          _needsRead =
              error is! ExecutableException ||
              error.failure == ExecutableFailure.staleRevision;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _read() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final value = await widget.controller.readPreset(_workspace, _id);
      if (!mounted) return;
      if (_attempt != null && _matches(value, _attempt!)) {
        Navigator.pop(context);
        return;
      }
      setState(() {
        _saved = value;
        _error = 'The saved executable differs from this draft. Reload it before saving.';
      });
    } on ExecutableException catch (error) {
      if (mounted) {
        setState(() {
          if (error.failure == ExecutableFailure.notFound && _revision == 0) {
            _needsRead = false;
            _error = 'The executable is not saved. Save can use this draft.';
          } else {
            _error = error.detail;
          }
        });
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() => _error = ExecutablesController.errorMessage(error));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _browse(
    TextEditingController field,
    ExecutablePathChooser chooser,
  ) async {
    try {
      final result = await chooser(field.text.isEmpty ? null : field.text);
      if (mounted && result != null) setState(() => field.text = result);
    } on Object {
      if (mounted) {
        setState(() => _error = 'The file picker could not be opened.');
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _path.dispose();
    _cwd.dispose();
    for (final v in _args) {
      v.dispose();
    }
    for (final v in _environment) {
      v.dispose();
    }
    super.dispose();
  }

  Widget _field(
    String label,
    TextEditingController value, {
    bool required = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: value,
      enabled: !_busy,
      decoration: InputDecoration(labelText: label),
      validator: required
          ? (v) => v == null || v.trim().isEmpty ? 'Enter $label.' : null
          : null,
    ),
  );
  @override
  Widget build(BuildContext context) => Form(
    key: _form,
    child: McFormDialog(
      title: widget.initial == null ? 'Add executable' : 'Edit executable',
      action: _busy ? 'Saving…' : 'Save',
      onSubmit: _busy || _needsRead ? null : _submit,
      canCancel: !_busy,
      children: [
        if (_error != null) ...[
          McStatus(title: _error!, tone: McStatusTone.error),
          const SizedBox(height: 12),
        ],
        if (_needsRead)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              McAction(label: 'Read saved', onPressed: _busy ? null : _read),
              if (_saved != null)
                McAction(
                  label: 'Reload saved',
                  onPressed: _busy
                      ? null
                      : () {
                          setState(() {
                            _fill(_saved!);
                            _saved = null;
                            _needsRead = false;
                            _error = null;
                          });
                        },
                ),
            ],
          ),
        ExcludeFocus(
          excluding: _busy,
          child: AbsorbPointer(
            absorbing: _busy,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _field('Name', _name, required: true),
                _field('Executable', _path, required: true),
                Align(
                  alignment: Alignment.centerRight,
                  child: McAction(
                    label: 'Browse executable…',
                    onPressed: () => _browse(_path, widget.chooseExecutable),
                  ),
                ),
                const SizedBox(height: 16),
                _field('Working directory', _cwd, required: true),
                Align(
                  alignment: Alignment.centerRight,
                  child: McAction(
                    label: 'Browse folder…',
                    onPressed: () => _browse(_cwd, widget.chooseDirectory),
                  ),
                ),
                const SizedBox(height: 16),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: const Text('Arguments'),
                  children: [
                    for (var i = 0; i < _args.length; i++)
                      Row(
                        key: ObjectKey(_args[i]),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _field('Argument ${i + 1}', _args[i]),
                          ),
                          McIconAction(
                            label: 'Remove argument ${i + 1}',
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () {
                              setState(() {
                                _args.removeAt(i).dispose();
                              });
                            },
                          ),
                        ],
                      ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: McAction(
                        label: 'Add argument',
                        icon: Icons.add,
                        onPressed: () =>
                            setState(() => _args.add(TextEditingController())),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: const Text('Environment'),
                  children: [
                    for (final row in _environment)
                      Column(
                        key: ObjectKey(row),
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _field(
                                  'Variable',
                                  row.name,
                                  required: true,
                                ),
                              ),
                              McIconAction(
                                label: 'Remove environment setting',
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () => setState(() {
                                  _environment.remove(row);
                                  row.dispose();
                                }),
                              ),
                            ],
                          ),
                          McChoice<bool>(
                            label: 'Change',
                            value: row.remove,
                            choices: const [false, true],
                            describe: (v) =>
                                v ? 'Remove child variable' : 'Set value',
                            onChanged: (v) => setState(() => row.remove = v),
                          ),
                          const SizedBox(height: 16),
                          if (!row.remove) _field('Value', row.value),
                        ],
                      ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: McAction(
                        label: 'Add variable',
                        icon: Icons.add,
                        onPressed: () => setState(
                          () => _environment.add(_EnvironmentDraft('', '')),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
