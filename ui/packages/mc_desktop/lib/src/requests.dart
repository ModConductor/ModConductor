import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mc_client/mc_client.dart';

class DesktopRequests extends ChangeNotifier {
  DesktopRequests({
    MethodChannel channel = const MethodChannel('dev.modconductor/desktop'),
  }) : _channel = channel {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'changed') await refresh();
    });
    unawaited(refresh());
  }
  final MethodChannel _channel;
  DesktopClient? _client;
  int? id;
  int count = 0, _generation = 0, _readGeneration = 0;
  bool available = true,
      resolving = false,
      disposed = false,
      hasWorkspaceSelection = false;
  List<String> arguments = const [];
  DesktopIntent? intent;
  String? problem, workspaceId;
  String? _adoptionKey, _operationId;
  bool get connected => _client != null;
  String operationId(String workspace, String path, ArtifactStorage storage) {
    final key = '$id\n$workspace\n$path\n${storage.name}';
    if (_adoptionKey != key) {
      _adoptionKey = key;
      _operationId = newOperationId();
    }
    return _operationId!;
  }

  void selectWorkspace(String? value) {
    hasWorkspaceSelection = true;
    workspaceId = value;
    notifyListeners();
  }

  void fail(String detail) {
    problem = detail;
    notifyListeners();
  }

  void attach(DesktopClient? client) {
    if (identical(client, _client)) return;
    _client = client;
    unawaited(_resolve());
  }

  Future<void> refresh() async {
    final generation = ++_readGeneration;
    try {
      final state = await _channel.invokeMapMethod<String, Object?>('state');
      if (disposed || state == null || generation != _readGeneration) return;
      available = state['available'] == true;
      count = state['count'] as int;
      final next = state['id'] as int?;
      if (next != id) {
        id = next;
        arguments = (state['arguments'] as List<Object?>? ?? const [])
            .cast<String>();
        workspaceId = null;
        hasWorkspaceSelection = false;
        _adoptionKey = null;
        _operationId = null;
        await _resolve();
      } else {
        notifyListeners();
      }
    } on MissingPluginException {
      if (!disposed) {
        available = false;
        notifyListeners();
      }
    } on PlatformException {
      if (!disposed) {
        available = false;
        notifyListeners();
      }
    }
  }

  Future<void> _resolve() async {
    final generation = ++_generation, client = _client;
    intent = null;
    problem = null;
    resolving = false;
    if (id == null) {
      if (!disposed) notifyListeners();
      return;
    }
    if (arguments.firstOrNull == '--unsupported-link')
      problem = 'This link is not supported.';
    else if (arguments.firstOrNull == '--invalid-request')
      problem = 'This request is not supported.';
    else if (client != null) {
      resolving = true;
      notifyListeners();
      try {
        final result = await client.resolve(arguments);
        if (!disposed && generation == _generation) intent = result;
      } on DesktopProblem catch (error) {
        if (!disposed && generation == _generation) problem = error.detail;
      }
    }
    if (!disposed && generation == _generation) {
      resolving = false;
      notifyListeners();
    }
  }

  Future<void> dismiss(int requestId) async {
    try {
      await _channel.invokeMethod<Object?>('dismiss', requestId);
      await refresh();
    } on PlatformException {
      if (!disposed) {
        available = false;
        fail('The request could not be dismissed.');
      }
    }
  }

  @override
  void dispose() {
    disposed = true;
    ++_generation;
    _channel.setMethodCallHandler(null);
    super.dispose();
  }
}
