import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'output_controller.dart';

class OutputPromotionDialog extends StatefulWidget {
  const OutputPromotionDialog({
    super.key,
    required this.controller,
    required this.files,
    required this.copy,
    required this.create,
    required this.profileId,
    required this.organization,
    this.initialMod,
  });
  final OutputController controller;
  final List<OutputSelection> files;
  final bool copy, create;
  final String profileId;
  final ModOrganizationClient organization;
  final ModEntry? initialMod;
  @override
  State<OutputPromotionDialog> createState() => _OutputPromotionDialogState();
}

class _OutputPromotionDialogState extends State<OutputPromotionDialog> {
  final _name = TextEditingController(), _version = TextEditingController();
  final _form = GlobalKey<FormState>();
  final _newId = newOperationId();
  final _mods = <String, ModEntry>{};
  String? _selected;
  ModQueryCursor? _next;
  bool _modsLoaded = false, _loadingMods = false;
  OutputPromotionPreview? _preview;
  String? _error;
  bool _checking = false, _saving = false;
  int _epoch = 0;
  Timer? _debounce;
  @override
  void initState() {
    super.initState();
    final initial = widget.initialMod;
    if (initial?.kind == ModKind.regular) {
      _mods[initial!.id] = initial;
      _selected = initial.id;
      _version.text = initial.metadata.version;
    }
    _name.addListener(_changed);
    _version.addListener(_changed);
    if (!widget.create) unawaited(_loadMods());
    _changed();
  }

  @override
  void dispose() {
    ++_epoch;
    _debounce?.cancel();
    _name.dispose();
    _version.dispose();
    super.dispose();
  }

  OutputAction? get action {
    final OutputDestination destination;
    if (widget.create) {
      if (_name.text.trim().isEmpty) return null;
      destination = NewOutputMod(_newId, _name.text, _version.text);
    } else {
      final mod = _mods[_selected];
      if (mod == null) return null;
      destination = ExistingOutputMod(mod.id, mod.revision, _version.text);
    }
    return widget.copy
        ? SaveOutputCopy(destination)
        : MoveOutputToMod(destination);
  }

  void _changed() {
    ++_epoch;
    _debounce?.cancel();
    _preview = null;
    _checking = false;
    _error = null;
    if (mounted) setState(() {});
    if (action != null) {
      _debounce = Timer(
        const Duration(milliseconds: 200),
        () => unawaited(_check()),
      );
    }
  }

  Future<void> _loadMods() async {
    if (_loadingMods || (_modsLoaded && _next == null)) return;
    setState(() => _loadingMods = true);
    try {
      final page = await widget.organization.query(
        widget.profileId,
        const ModQuery(
          filters: [KindFilter(ModKind.regular)],
          sort: OrganizationSort.name,
        ),
        cursor: _next,
      );
      if (!mounted) return;
      final selectedRevision = _mods[_selected]?.revision;
      for (final row in page.entries) {
        _mods[row.mod.id] = row.mod;
      }
      _modsLoaded = true;
      _next = page.next;
      if (_mods[_selected]?.revision != selectedRevision) _changed();
    } on Exception catch (error) {
      if (mounted) {
        _error = error is LibraryException
            ? error.detail
            : 'The destination mods could not be read.';
      }
    } finally {
      if (mounted) setState(() => _loadingMods = false);
    }
  }

  Future<void> _check() async {
    final value = action;
    if (value == null || _saving) return;
    final epoch = _epoch;
    setState(() => _checking = true);
    try {
      final preview = await widget.controller.preview(widget.files, value);
      if (mounted && epoch == _epoch) setState(() => _preview = preview);
    } on Exception catch (error) {
      if (mounted && epoch == _epoch) {
        setState(
          () => _error = error is OutputException
              ? error.detail
              : 'The output promotion could not be checked.',
        );
      }
    } finally {
      if (mounted && epoch == _epoch) setState(() => _checking = false);
    }
  }

  Future<void> submit() async {
    final value = action;
    if (value == null ||
        _preview == null ||
        _saving ||
        !_form.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);
    final success = await widget.controller.apply(widget.files, value);
    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
    } else {
      setState(() {
        _saving = false;
        _preview = null;
        _error = widget.controller.problem;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _form,
    child: McFormDialog(
      title: widget.copy
          ? 'Save copy to mod'
          : widget.create
          ? 'Create mod from outputs'
          : 'Move outputs to mod',
      action: _saving
          ? 'Saving…'
          : widget.copy
          ? 'Save copy'
          : widget.create
          ? 'Create mod'
          : 'Move',
      onSubmit: _saving || _checking || _preview == null ? null : submit,
      canCancel: !_saving,
      children: [
        if (widget.create)
          McNameField(controller: _name, onSubmit: submit)
        else if (_mods.isNotEmpty)
          McChoice<String?>(
            label: 'Mod',
            value: _selected,
            choices: [null, ..._mods.keys],
            describe: (id) =>
                id == null ? 'Choose a mod' : _mods[id]!.metadata.name,
            onChanged: (value) {
              _selected = value;
              _version.text = _mods[value]?.metadata.version ?? '';
              _changed();
            },
          )
        else
          Text(
            _loadingMods ? 'Reading mods…' : 'No regular mods are available.',
          ),
        if (!widget.create && (!_modsLoaded || _next != null))
          McAction(
            label: 'Load more mods',
            onPressed: _loadingMods || _saving ? null : _loadMods,
          ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _version,
          enabled: !_saving,
          decoration: const InputDecoration(labelText: 'Version'),
          onFieldSubmitted: (_) => submit(),
        ),
        const SizedBox(height: 16),
        Text(
          '${widget.files.length} selected ${widget.files.length == 1 ? 'file' : 'files'}',
        ),
        if (_checking) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator(),
        ],
        if (_preview case final preview?) ...[
          if (preview.replaced.isNotEmpty)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(
                '${preview.replaced.length} saved mod files replaced',
              ),
              children: [
                for (final path in preview.replaced)
                  ListTile(dense: true, title: Text(path.join('/'))),
              ],
            ),
          if (preview.registeredSource) ...[
            const SizedBox(height: 12),
            const Text(
              'Later Save version publishes the registered source again.',
            ),
          ],
          if (widget.copy) ...[
            const SizedBox(height: 12),
            const Text('Working files stay in their shared locations.'),
          ],
        ],
        if (_error != null) ...[
          const SizedBox(height: 12),
          McStatus(title: _error!, tone: McStatusTone.error),
        ],
      ],
    ),
  );
}
