import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'controller.dart';
import 'editor_fields.dart';

typedef ExecutablePathChooser = Future<String?> Function(String? initial);

class ExecutableEditor extends StatefulWidget {
  const ExecutableEditor({
    super.key,
    required this.controller,
    required this.chooseExecutable,
    required this.chooseDirectory,
    this.initial,
    this.outputs,
  });
  final ExecutablesController controller;
  final GeneratedOutputsClient? outputs;
  final ExecutablePreset? initial;
  final ExecutablePathChooser chooseExecutable, chooseDirectory;
  @override
  State<ExecutableEditor> createState() => _ExecutableEditorState();
}

class _ExecutableEditorState extends State<ExecutableEditor> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(),
      _path = TextEditingController(),
      _cwd = TextEditingController();
  final _args = <TextEditingController>[],
      _environment = <ExecutableEnvironmentDraft>[];
  late final String _id = widget.initial?.id ?? newOperationId();
  late final String _workspace = widget.controller.workspace!.id;
  late int _revision = widget.initial?.revision ?? 0;
  ExecutableRuntime _runtime = ExecutableRuntime.native;
  String? _outputName;
  List<String> _outputNames = const [];
  bool _busy = false, _needsRead = false;
  String? _error;
  ExecutablePreset? _attempt, _saved;
  @override
  void initState() {
    super.initState();
    final value = widget.initial;
    if (value != null) {
      _fill(value);
    }
    _name.addListener(_nameChanged);
    _readOutputs();
  }

  void _nameChanged() => setState(() {});

  Future<void> _readOutputs() async {
    final outputs = widget.outputs;
    final profile = widget.controller.workspace?.selectedProfile?.id;
    if (outputs == null || profile == null) {
      return;
    }
    try {
      final scope = await outputs.read(_workspace, profile);
      if (mounted) {
        setState(() {
          _outputNames = scope.locations
              .where(
                (v) =>
                    v.kind == OutputLocationKind.toolFolder &&
                    v.status == OutputLocationStatus.ready,
              )
              .map((v) => v.name)
              .toSet()
              .toList();
        });
      }
    } on Object {
      // New folders are resolved when Run is requested; no file acquisition here.
    }
  }

  void _fill(ExecutablePreset value) {
    _name.text = value.name;
    _path.text = value.executable;
    _cwd.text = value.workingDirectory;
    _revision = value.revision;
    _runtime = value.runtime;
    _outputName = value.outputName;
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
      value.environment.map((v) => ExecutableEnvironmentDraft(v.name, v.value)),
    );
  }

  ExecutablePreset _draft() => ExecutablePreset(
    id: _id,
    workspaceId: _workspace,
    revision: _revision,
    name: _name.text,
    runtime: _runtime,
    outputName: _outputName,
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
      a.runtime == b.runtime &&
      a.outputName == b.outputName &&
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
    _name.removeListener(_nameChanged);
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
                executableField('Name', _name, required: true),
                executablePathField(
                  'Executable',
                  _path,
                  onBrowse: () => _browse(_path, widget.chooseExecutable),
                ),
                McChoice<ExecutableRuntime>(
                  label: 'Runtime',
                  value: _runtime,
                  choices: ExecutableRuntime.values,
                  describe: executableRuntimeLabel,
                  onChanged: (value) => setState(() => _runtime = value),
                ),
                const SizedBox(height: 16),
                executablePathField(
                  'Working directory',
                  _cwd,
                  onBrowse: () => _browse(_cwd, widget.chooseDirectory),
                ),
                McChoice<String>(
                  label: 'Output folder',
                  value: _outputName ?? '',
                  choices: {
                    '',
                    _outputName ?? '',
                    ..._outputNames,
                    '${_name.text.trim().isEmpty ? 'Tool' : _name.text.trim()} output',
                  }.toList(),
                  describe: (value) => value.isEmpty ? 'None' : value,
                  onChanged: (value) => setState(
                    () => _outputName = value.isEmpty ? null : value,
                  ),
                ),
                const SizedBox(height: 16),
                ExecutableArguments(
                  values: _args,
                  onChanged: () => setState(() {}),
                ),
                ExecutableEnvironmentFields(
                  values: _environment,
                  onChanged: () => setState(() {}),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
