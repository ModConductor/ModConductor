import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'controller.dart';

class WorkspaceDeletionDialog extends StatefulWidget {
  const WorkspaceDeletionDialog({
    super.key,
    required this.controller,
    required this.workspace,
  });
  final WorkspaceController controller;
  final WorkspaceInfo workspace;

  @override
  State<WorkspaceDeletionDialog> createState() =>
      _WorkspaceDeletionDialogState();
}

class _WorkspaceDeletionDialogState extends State<WorkspaceDeletionDialog> {
  WorkspaceDeletionInfo? _info;
  bool _moveSaves = false, _deleting = false, _loading = true;
  String? _problem;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _problem = null;
    });
    try {
      final info = await widget.controller.deletionInfo(widget.workspace.id);
      if (mounted) setState(() => _info = info);
    } on Exception catch (error) {
      if (mounted) {
        setState(
          () => _problem = error is WorkspaceException
              ? error.detail
              : 'Workspace deletion information is unavailable. Try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete() async {
    setState(() {
      _deleting = true;
      _problem = null;
    });
    final deleted = await widget.controller.deleteWorkspace(
      widget.workspace,
      moveSaves: _moveSaves,
    );
    if (!mounted) return;
    if (deleted) {
      Navigator.pop(context);
    } else {
      setState(() {
        _deleting = false;
        _problem ??=
            widget.controller.deletionProblem(widget.workspace.id) ??
            'Workspace deletion did not complete. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_deleting,
    child: McDialog(
      title: 'Delete workspace?',
      actions: [
        McAction(
          label: 'Cancel',
          onPressed: _deleting ? null : () => Navigator.pop(context),
        ),
        McAction(
          label: 'Delete workspace',
          emphasis: McActionEmphasis.primary,
          onPressed: _deleting || _loading
              ? null
              : _info == null
              ? _load
              : _delete,
        ),
      ],
      children: [
        Text(
          widget.workspace.name,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        SelectableText(
          widget.workspace.path,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: McSpacing.medium),
        Text(
          'This cannot be undone.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.error,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (_info?.hasPrivateSaves ?? false) ...[
          const SizedBox(height: McSpacing.medium),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Move saves to game save folder'),
                value: _moveSaves,
                onChanged: _deleting
                    ? null
                    : (value) => setState(() => _moveSaves = value),
              ),
              Visibility(
                visible: _moveSaves,
                maintainSize: true,
                maintainState: true,
                maintainAnimation: true,
                child: SelectableText(
                  _info!.saveDestinations.join('\n'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ],
        if (_deleting || _loading) ...[
          const SizedBox(height: McSpacing.medium),
          McActionFeedback(
            kind: McActionFeedbackKind.pending,
            message: _deleting ? 'Deleting workspace' : 'Reading workspace',
          ),
        ],
        if (_problem != null) ...[
          const SizedBox(height: McSpacing.medium),
          McActionFeedback(
            kind: McActionFeedbackKind.failure,
            message: _problem!,
          ),
        ],
      ],
    ),
  );
}
