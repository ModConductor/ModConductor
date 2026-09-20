import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

class CredentialPreferencesLabels {
  const CredentialPreferencesLabels({
    required this.nexusMods,
    required this.disconnectTitle,
    required this.disconnect,
    required this.disconnectPause,
    required this.disconnectRemovesSaved,
    required this.sessionOnlyTitle,
    required this.sessionOnly,
    required this.sessionOnlyLost,
    required this.sessionOnlyKeepsSaved,
    required this.clearSessionTitle,
    required this.removeSavedTitle,
    required this.clearSignIn,
    required this.removeSignIn,
    required this.clearsSessionToo,
    required this.storageDetails,
    required this.close,
    required this.problem,
    required this.notConfigured,
    required this.waitingSignIn,
    required this.connectedAs,
    required this.premium,
    required this.notConnected,
    required this.notSignedIn,
    required this.notSaved,
    required this.cancelSignIn,
    required this.checkAccount,
    required this.signInAgain,
    required this.connect,
    required this.signIn,
    required this.storageCheckFailed,
    required this.checkEngine,
    required this.savedNotRemoved,
    required this.unlockKeyring,
    required this.saved,
    required this.noneSaved,
    required this.cannotCheckSaved,
    required this.newSignIns,
    required this.saveOnComputer,
    required this.checkStorage,
    required this.retryRemoval,
  });

  final String nexusMods;
  final String disconnectTitle;
  final String disconnect;
  final String disconnectPause;
  final String disconnectRemovesSaved;
  final String sessionOnlyTitle;
  final String sessionOnly;
  final String sessionOnlyLost;
  final String sessionOnlyKeepsSaved;
  final String clearSessionTitle;
  final String removeSavedTitle;
  final String clearSignIn;
  final String removeSignIn;
  final String clearsSessionToo;
  final String storageDetails;
  final String close;
  final String Function(CredentialProblem) problem;
  final String notConfigured;
  final String waitingSignIn;
  final String Function(String) connectedAs;
  final String premium;
  final String notConnected;
  final String notSignedIn;
  final String notSaved;
  final String cancelSignIn;
  final String checkAccount;
  final String signInAgain;
  final String connect;
  final String signIn;
  final String storageCheckFailed;
  final String checkEngine;
  final String savedNotRemoved;
  final String unlockKeyring;
  final String saved;
  final String noneSaved;
  final String cannotCheckSaved;
  final String newSignIns;
  final String saveOnComputer;
  final String checkStorage;
  final String retryRemoval;
}

class CredentialPreferences extends StatefulWidget {
  const CredentialPreferences({
    super.key,
    required this.client,
    required this.labels,
    this.nexus,
  });
  final CredentialsClient? client;
  final NexusClient? nexus;
  final CredentialPreferencesLabels labels;
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
    final labels = widget.labels;
    if (!await _confirm(
      title: labels.disconnectTitle,
      action: labels.disconnect,
      children: [
        Text(labels.disconnectPause),
        _gap,
        Text(labels.disconnectRemovesSaved),
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
    final labels = widget.labels;
    if (mode == CredentialMode.sessionOnly &&
        !await _confirm(
          title: labels.sessionOnlyTitle,
          action: labels.sessionOnly,
          children: [
            Text(labels.sessionOnlyLost),
            _gap,
            Text(labels.sessionOnlyKeepsSaved),
          ],
        ))
      return;
    if (mounted && client == widget.client)
      await _run(() => client.setMode(mode));
  }

  Future<void> _remove() async {
    final client = widget.client;
    if (client == null) return;
    final labels = widget.labels;
    if (!await _confirm(
      title: _status?.saved == SavedCredentials.absent
          ? labels.clearSessionTitle
          : labels.removeSavedTitle,
      action: _status?.saved == SavedCredentials.absent
          ? labels.clearSignIn
          : labels.removeSignIn,
      children: [Text(labels.nexusMods), _gap, Text(labels.clearsSessionToo)],
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
        title: widget.labels.storageDetails,
        actions: [
          McAction(
            label: widget.labels.close,
            onPressed: () => Navigator.pop(context),
          ),
        ],
        children: [SelectableText(status.diagnosticReport)],
      ),
    );
  }

  static const _gap = SizedBox(height: McSpacing.medium);
  @override
  Widget build(BuildContext context) {
    final labels = widget.labels;
    final status = _status;
    final reconnect =
        status?.saved == SavedCredentials.present &&
        status?.mode != CredentialMode.sessionOnly &&
        _account?.problem?.code != 'sign_in_required';
    final enabled = !_busy && widget.client != null;
    return McSection(
      title: labels.nexusMods,
      children: [
        if (_account?.configured != true)
          Text(labels.notConfigured)
        else if (_account?.waiting == true)
          Text(labels.waitingSignIn)
        else if (_account?.name case final name?)
          Row(
            children: [
              Expanded(child: Text(labels.connectedAs(name))),
              if (_account?.premium == true) Chip(label: Text(labels.premium)),
            ],
          )
        else
          Text(
            status?.saved == SavedCredentials.present
                ? labels.notConnected
                : labels.notSignedIn,
          ),
        if (_account?.problem case final problem?) ...[
          _gap,
          McStatus(
            title: problem.code == 'storage'
                ? labels.notSaved
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
                  label: labels.cancelSignIn,
                  onPressed: enabled
                      ? () => _nexus(widget.nexus!.cancel)
                      : null,
                )
              else if (_account?.name != null) ...[
                McAction(
                  label: labels.checkAccount,
                  icon: Icons.refresh,
                  onPressed: enabled ? () => _nexus(widget.nexus!.check) : null,
                ),
                McAction(
                  label: labels.disconnect,
                  icon: Icons.logout,
                  onPressed: enabled ? _disconnect : null,
                ),
              ] else
                McAction(
                  label: _account?.problem?.code == 'sign_in_required'
                      ? labels.signInAgain
                      : reconnect
                      ? labels.connect
                      : labels.signIn,
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
          McStatus(
            title: labels.storageCheckFailed,
            detail: labels.checkEngine,
            tone: McStatusTone.error,
          ),
          _gap,
        ] else if (status?.removalProblem case final problem?) ...[
          McStatus(
            title: labels.savedNotRemoved,
            detail: problem == CredentialProblem.locked
                ? labels.unlockKeyring
                : labels.problem(problem),
            tone: McStatusTone.error,
          ),
          _gap,
        ] else if (status?.problem case final problem?) ...[
          McStatus(title: labels.problem(problem)),
          _gap,
        ],
        Text(switch (status?.saved) {
          SavedCredentials.present => labels.saved,
          SavedCredentials.absent => labels.noneSaved,
          SavedCredentials.unknown || null => labels.cannotCheckSaved,
        }),
        _gap,
        if (status != null)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: McChoice<CredentialMode>(
              label: labels.newSignIns,
              value: status.mode,
              choices: CredentialMode.values,
              enabled: enabled,
              describe: (mode) => switch (mode) {
                CredentialMode.secure => labels.saveOnComputer,
                CredentialMode.sessionOnly => labels.sessionOnly,
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
              label: labels.checkStorage,
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
                          ? labels.clearSignIn
                          : labels.removeSignIn)
                    : labels.retryRemoval,
                icon: Icons.delete_outline,
                onPressed: enabled ? _remove : null,
              ),
            McIconAction(
              label: labels.storageDetails,
              icon: const Icon(Icons.info_outline),
              onPressed: status == null || _busy ? null : _details,
            ),
          ],
        ),
      ],
    );
  }
}
