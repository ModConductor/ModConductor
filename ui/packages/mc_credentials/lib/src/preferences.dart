import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

export 'preferences_labels.dart' show CredentialPreferencesLabels;

import 'preferences_labels.dart';
import 'account_watch.dart';
import 'account_content.dart';
import 'storage_content.dart';

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
  late final _accountWatch = CredentialAccountWatch(
    onAccount: _accountObserved,
    onError: _accountWatchFailed,
  );
  bool _accountEventPending = false;
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
    _accountWatch.observe(widget.nexus);
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
      _accountEventPending = false;
      _refresh();
      _accountWatch.observe(widget.nexus);
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
        if (_accountEventPending) {
          _accountEventPending = false;
          _refresh();
        }
      }
    }
  }

  void _refresh() {
    final client = widget.client;
    if (client != null) _run(client.status);
  }

  void _accountObserved(NexusAccount account) {
    if (!mounted) return;
    setState(() {
      _account = account;
      _connectionProblem = false;
    });
    if (_busy) {
      _accountEventPending = true;
    } else {
      _refresh();
    }
  }

  void _accountWatchFailed() {
    if (mounted) setState(() => _connectionProblem = true);
  }

  @override
  void dispose() {
    ++_generation;
    _accountWatch.dispose();
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
    final enabled = !_busy && widget.client != null;
    return McSection(
      title: widget.labels.nexusMods,
      children: [
        CredentialAccountContent(
          labels: widget.labels,
          status: _status,
          account: _account,
          hasNexus: widget.nexus != null,
          enabled: enabled,
          checkingAccount: _checkingAccount,
          accountChecked: _accountChecked,
          accountCheckFailed: _accountCheckFailed,
          showPersonalApiKey: _showPersonalApiKey,
          personalApiKey: _personalApiKey,
          onCancelSignIn: () => _nexus(widget.nexus!.cancel),
          onCheckAccount: _checkAccount,
          onDisconnect: _disconnect,
          onConnect: () => _nexus(widget.nexus!.connect),
          onSignIn: () => _nexus(widget.nexus!.signIn),
          onSubmitPersonalApiKey: _submitPersonalApiKey,
          onTogglePersonalApiKey: () =>
              setState(() => _showPersonalApiKey = !_showPersonalApiKey),
        ),
        _gap,
        CredentialStorageContent(
          labels: widget.labels,
          status: _status,
          accountName: _account?.name,
          clientAvailable: widget.client != null,
          connectionProblem: _connectionProblem,
          enabled: enabled,
          busy: _busy,
          onMode: _mode,
          onRefresh: _refresh,
          onRemove: _remove,
          onDetails: _details,
        ),
      ],
    );
  }
}
