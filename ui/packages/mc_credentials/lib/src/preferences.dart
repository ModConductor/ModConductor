import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

class CredentialPreferences extends StatefulWidget {
  const CredentialPreferences({super.key, required this.client, this.nexus});
  final CredentialsClient? client;
  final NexusClient? nexus;
  @override
  State<CredentialPreferences> createState() => _CredentialPreferencesState();
}

class _CredentialPreferencesState extends State<CredentialPreferences> {
  CredentialStatus? _status;
  NexusAccount? _account;
  Timer? _poll;
  bool _busy = false, _connectionProblem = false;
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void didUpdateWidget(CredentialPreferences oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.client != widget.client || oldWidget.nexus != widget.nexus) {
      _generation++;
      _busy = false;
      _status = null;
      _account = null;
      _poll?.cancel();
      _refresh();
    }
  }

  Future<void> _run(Future<CredentialStatus> Function() action) async {
    if (_busy) return;
    final generation = _generation;
    setState(() {
      _busy = true;
      _connectionProblem = false;
    });
    try {
      final result = await action();
      final account = await widget.nexus?.status();
      if (mounted && generation == _generation)
        setState(() {
          _status = result;
          _account = account;
        });
    } catch (_) {
      if (mounted && generation == _generation)
        setState(() => _connectionProblem = true);
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _busy = false);
        _poll?.cancel();
        if (_account?.waiting == true)
          _poll = Timer(const Duration(milliseconds: 500), _refresh);
      }
    }
  }

  void _refresh() {
    final client = widget.client;
    if (client != null) _run(client.status);
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _nexus(Future<NexusAccount> Function() action) async {
    final client = widget.client;
    if (client == null) return;
    await _run(() async {
      await action();
      return client.status();
    });
  }

  Future<void> _disconnect() async {
    if (!await _confirm(
      title: 'Disconnect from Nexus Mods?',
      action: 'Disconnect',
      children: [
        const Text(
          'Nexus downloads will pause. Local files will not be deleted.',
        ),
        _gap,
        const Text('Saved sign-in details will be removed.'),
      ],
    ))
      return;
    if (mounted && widget.client != null) await _run(widget.client!.remove);
  }

  Future<bool> _confirm({
    required String title,
    required String action,
    required List<Widget> children,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => McFormDialog(
          title: title,
          action: action,
          onSubmit: () => Navigator.pop(context, true),
          children: children,
        ),
      ) ??
      false;
  Future<void> _mode(CredentialMode mode) async {
    final client = widget.client;
    if (client == null) return;
    if (mode == CredentialMode.sessionOnly &&
        !await _confirm(
          title: 'Use this session only?',
          action: 'Use this session only',
          children: [
            const Text('New sign-in details will be lost when MC closes.'),
            _gap,
            const Text('Existing saved sign-in details will not be deleted.'),
          ],
        ))
      return;
    if (mounted && client == widget.client)
      await _run(() => client.setMode(mode));
  }

  Future<void> _remove() async {
    final client = widget.client;
    if (client == null) return;
    if (!await _confirm(
      title: _status?.saved == SavedCredentials.absent
          ? 'Clear session sign-in?'
          : 'Remove saved sign-in?',
      action: _status?.saved == SavedCredentials.absent
          ? 'Clear sign-in'
          : 'Remove sign-in',
      children: [
        const Text('Nexus Mods'),
        _gap,
        const Text('MC will also clear sign-in details held for this session.'),
      ],
    ))
      return;
    if (mounted && client == widget.client) await _run(client.remove);
  }

  void _details() {
    final status = _status;
    if (status == null) return;
    showDialog<void>(
      context: context,
      builder: (context) => McDialog(
        title: 'Sign-in storage details',
        actions: [
          McAction(label: 'Close', onPressed: () => Navigator.pop(context)),
        ],
        children: [SelectableText(status.diagnosticReport)],
      ),
    );
  }

  static const _gap = SizedBox(height: McSpacing.medium);
  String _problem(CredentialProblem problem) => switch (problem) {
    CredentialProblem.locked => 'System keyring is locked',
    CredentialProblem.unavailable => 'Secure storage is not available',
    CredentialProblem.denied => 'Access to secure storage was denied',
    CredentialProblem.timedOut => 'Secure storage did not respond in time',
    CredentialProblem.cancelled => 'The storage operation was cancelled',
    CredentialProblem.tooLarge => 'Sign-in details exceed the storage limit',
    CredentialProblem.failed => 'The storage operation failed',
  };
  @override
  Widget build(BuildContext context) {
    final status = _status;
    final reconnect =
        status?.saved == SavedCredentials.present &&
        status?.mode != CredentialMode.sessionOnly &&
        _account?.problem?.code != 'sign_in_required';
    final enabled = !_busy && widget.client != null;
    return McSection(
      title: 'Nexus Mods',
      children: [
        if (_account?.configured != true)
          const Text('Sign-in is not configured in this build.')
        else if (_account?.waiting == true)
          const Text('Waiting for sign-in')
        else if (_account?.name case final name?)
          Row(
            children: [
              Expanded(child: Text('Connected as $name')),
              if (_account?.premium == true) const Chip(label: Text('Premium')),
            ],
          )
        else
          Text(
            status?.saved == SavedCredentials.present
                ? 'Not connected'
                : 'Not signed in',
          ),
        if (_account?.problem case final problem?) ...[
          _gap,
          McStatus(
            title: problem.code == 'storage'
                ? 'Sign-in details were not saved'
                : problem.message,
            detail: problem.code == 'storage' ? problem.message : null,
            tone: McStatusTone.error,
          ),
        ],
        if (_account?.configured == true && widget.nexus != null) ...[
          _gap,
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (_account?.waiting == true)
                McAction(
                  label: 'Cancel sign-in',
                  onPressed: enabled
                      ? () => _nexus(widget.nexus!.cancel)
                      : null,
                )
              else if (_account?.name != null) ...[
                McAction(
                  label: 'Check account',
                  icon: Icons.refresh,
                  onPressed: enabled ? () => _nexus(widget.nexus!.check) : null,
                ),
                McAction(
                  label: 'Disconnect',
                  icon: Icons.logout,
                  onPressed: enabled ? _disconnect : null,
                ),
              ] else
                McAction(
                  label: _account?.problem?.code == 'sign_in_required'
                      ? 'Sign in again'
                      : reconnect
                      ? 'Connect'
                      : 'Sign in',
                  icon: Icons.login,
                  emphasis: McActionEmphasis.primary,
                  onPressed: enabled
                      ? () => _nexus(
                          reconnect
                              ? widget.nexus!.connect
                              : widget.nexus!.signIn,
                        )
                      : null,
                ),
            ],
          ),
        ],
        _gap,
        if (widget.client == null || _connectionProblem) ...[
          const McStatus(
            title: 'Sign-in storage could not be checked',
            detail: 'Check the engine connection and try again.',
            tone: McStatusTone.error,
          ),
          _gap,
        ] else if (status?.removalProblem case final problem?) ...[
          McStatus(
            title: 'Saved sign-in not removed',
            detail: problem == CredentialProblem.locked
                ? 'Unlock the system keyring and try again.'
                : _problem(problem),
            tone: McStatusTone.error,
          ),
          _gap,
        ] else if (status?.problem case final problem?) ...[
          McStatus(title: _problem(problem)),
          _gap,
        ],
        Text(switch (status?.saved) {
          SavedCredentials.present =>
            'Sign-in details are saved on this computer.',
          SavedCredentials.absent => 'No saved sign-in details.',
          SavedCredentials.unknown ||
          null => 'Saved sign-in details cannot be checked.',
        }),
        _gap,
        if (status != null)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: McChoice<CredentialMode>(
              label: 'New sign-ins',
              value: status.mode,
              choices: CredentialMode.values,
              enabled: enabled,
              describe: (mode) => switch (mode) {
                CredentialMode.secure => 'Save on this computer',
                CredentialMode.sessionOnly => 'This session only',
              },
              onChanged: _mode,
            ),
          ),
        _gap,
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            McAction(
              label: 'Check storage',
              icon: Icons.refresh,
              onPressed: enabled ? _refresh : null,
            ),
            if (_account?.name == null &&
                status != null &&
                (status.saved == SavedCredentials.present ||
                    status.hasSession ||
                    status.removalProblem != null))
              McAction(
                label: status.removalProblem == null
                    ? (status.saved == SavedCredentials.absent
                          ? 'Clear session sign-in'
                          : 'Remove saved sign-in')
                    : 'Retry removal',
                icon: Icons.delete_outline,
                onPressed: enabled ? _remove : null,
              ),
            IconButton(
              tooltip: 'Sign-in storage details',
              icon: const Icon(Icons.info_outline),
              onPressed: status == null || _busy ? null : _details,
            ),
          ],
        ),
      ],
    );
  }
}
