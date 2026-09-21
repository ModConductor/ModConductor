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
    required this.waitingSignIn,
    required this.premium,
    required this.accountCurrent,
    required this.checkingAccount,
    required this.accountCheckFailed,
    required this.notConnected,
    required this.notSignedIn,
    required this.notSaved,
    required this.cancelSignIn,
    required this.checkAccount,
    required this.signInAgain,
    required this.connect,
    required this.signIn,
    required this.personalApiKey,
    required this.showPersonalApiKey,
    required this.hidePersonalApiKey,
    required this.submitPersonalApiKey,
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
  final String waitingSignIn;
  final String premium;
  final String accountCurrent;
  final String checkingAccount;
  final String accountCheckFailed;
  final String notConnected;
  final String notSignedIn;
  final String notSaved;
  final String cancelSignIn;
  final String checkAccount;
  final String signInAgain;
  final String connect;
  final String signIn;
  final String personalApiKey;
  final String showPersonalApiKey;
  final String hidePersonalApiKey;
  final String submitPersonalApiKey;
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
  bool _checkingAccount = false,
      _accountChecked = false,
      _accountCheckFailed = false;
  bool _showPersonalApiKey = false;
  final _personalApiKey = TextEditingController();
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
      _checkingAccount = false;
      _accountChecked = false;
      _accountCheckFailed = false;
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
    _personalApiKey.dispose();
    super.dispose();
  }

  Future<void> _nexus(
    Future<NexusAccount> Function() action, {
    bool accountCheck = false,
  }) async {
    final client = widget.client;
    if (client == null) return;
    if (!accountCheck) {
      _accountChecked = false;
      _accountCheckFailed = false;
    }
    await _run(() async {
      await action();
      return client.status();
    });
  }

  Future<void> _checkAccount() async {
    final nexus = widget.nexus;
    if (nexus == null || _checkingAccount) return;
    setState(() {
      _checkingAccount = true;
      _accountCheckFailed = false;
    });
    await _nexus(nexus.check, accountCheck: true);
    if (mounted) {
      setState(() {
        _checkingAccount = false;
        _accountChecked = true;
        _accountCheckFailed = _connectionProblem || _account?.problem != null;
      });
    }
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
    if (mounted && widget.client != null) {
      _accountChecked = false;
      _accountCheckFailed = false;
      await _run(widget.client!.remove);
    }
  }

  Future<void> _submitPersonalApiKey() async {
    final nexus = widget.nexus;
    if (nexus == null || _personalApiKey.text.isEmpty) return;
    await _nexus(() => nexus.submitPersonalApiKey(_personalApiKey.text));
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
    if (mounted && client == widget.client) {
      _accountChecked = false;
      _accountCheckFailed = false;
      await _run(client.remove);
    }
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
    final accountProblem = _account?.problem;
    return McSection(
      title: labels.nexusMods,
      children: [
        if (_account?.waiting == true)
          McActionFeedback(
            kind: McActionFeedbackKind.pending,
            message: labels.waitingSignIn,
          )
        else
          McIdentityCard(
            key: const ValueKey('nexus-identity'),
            name:
                _account?.name ??
                (status?.saved == SavedCredentials.present
                    ? labels.notConnected
                    : labels.notSignedIn),
            provider: labels.nexusMods,
            semanticLabel:
                '${_account?.name ?? (status?.saved == SavedCredentials.present ? labels.notConnected : labels.notSignedIn)}, ${labels.nexusMods}${_account?.premium == true ? ', ${labels.premium}' : ''}',
            image: _account?.profileImage == null
                ? null
                : NetworkImage(_account!.profileImage!.toString()),
            fallbackIcon: _account?.name == null
                ? Icons.person_outline
                : Icons.person,
            badges: [
              if (_account?.premium == true)
                Chip(
                  avatar: const Icon(
                    Icons.workspace_premium_outlined,
                    size: 17,
                  ),
                  label: Text(labels.premium),
                ),
            ],
          ),
        if (!_accountChecked && accountProblem != null) ...[
          _gap,
          McStatus(
            title: accountProblem.code == 'storage'
                ? labels.notSaved
                : accountProblem.message,
            detail: accountProblem.code == 'storage'
                ? accountProblem.message
                : null,
            tone: McStatusTone.error,
          ),
        ],
        if (widget.nexus != null &&
            (_account?.configured == true ||
                _account?.name != null ||
                reconnect)) ...[
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
                  key: const ValueKey('nexus-check-account'),
                  label: labels.checkAccount,
                  icon: Icons.refresh,
                  onPressed: enabled ? _checkAccount : null,
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
        if (_checkingAccount || _accountChecked) ...[
          _gap,
          McActionFeedback(
            key: const ValueKey('nexus-account-feedback'),
            kind: _checkingAccount
                ? McActionFeedbackKind.pending
                : _accountCheckFailed
                ? McActionFeedbackKind.failure
                : McActionFeedbackKind.success,
            message: _checkingAccount
                ? labels.checkingAccount
                : _accountCheckFailed
                ? labels.accountCheckFailed
                : labels.accountCurrent,
            detail: !_accountCheckFailed
                ? null
                : _account?.problem?.message ?? labels.checkEngine,
          ),
        ],
        if (_account?.name == null && widget.nexus != null) ...[
          _gap,
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: TextField(
              key: const ValueKey('nexus-personal-api-key'),
              controller: _personalApiKey,
              obscureText: !_showPersonalApiKey,
              enableSuggestions: false,
              autocorrect: false,
              textInputAction: TextInputAction.done,
              onSubmitted: enabled ? (_) => _submitPersonalApiKey() : null,
              decoration: InputDecoration(
                labelText: labels.personalApiKey,
                suffixIcon: McIconAction(
                  label: _showPersonalApiKey
                      ? labels.hidePersonalApiKey
                      : labels.showPersonalApiKey,
                  icon: Icon(
                    _showPersonalApiKey
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: enabled
                      ? () => setState(
                          () => _showPersonalApiKey = !_showPersonalApiKey,
                        )
                      : null,
                ),
              ),
            ),
          ),
          _gap,
          McAction(
            key: const ValueKey('submit-nexus-personal-api-key'),
            label: labels.submitPersonalApiKey,
            icon: Icons.key,
            onPressed: enabled ? _submitPersonalApiKey : null,
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
