import 'dart:async';

import 'package:mc_client/mc_client.dart';

class CredentialAccountWatch {
  CredentialAccountWatch({required this.onAccount, required this.onError});

  final void Function(NexusAccount) onAccount;
  final void Function() onError;
  NexusClient? _client;
  StreamSubscription<NexusAccount>? _subscription;
  Timer? _reconnect;
  int _attempt = 0;
  bool _disposed = false;

  void observe(NexusClient? client) {
    _client = client;
    _connect();
  }

  void _connect() {
    final client = _client;
    final attempt = ++_attempt;
    _reconnect?.cancel();
    _reconnect = null;
    unawaited(_subscription?.cancel() ?? Future<void>.value());
    _subscription = null;
    if (_disposed || client == null) return;

    void reconnect() {
      if (_disposed || attempt != _attempt) return;
      _reconnect?.cancel();
      _reconnect = Timer(const Duration(seconds: 1), () {
        if (!_disposed && attempt == _attempt) _connect();
      });
    }

    _subscription = client.watchStatus().listen(
      (account) {
        if (!_disposed && attempt == _attempt) onAccount(account);
      },
      onError: (Object _) {
        if (_disposed || attempt != _attempt) return;
        onError();
        reconnect();
      },
      onDone: reconnect,
      cancelOnError: true,
    );
  }

  void dispose() {
    _disposed = true;
    ++_attempt;
    _reconnect?.cancel();
    if (_subscription != null) unawaited(_subscription!.cancel());
  }
}
