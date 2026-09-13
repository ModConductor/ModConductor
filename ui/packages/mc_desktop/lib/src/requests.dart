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
  NxmClient? _nxm;
  NexusLink? nexusLink;
  String? nexusReference;
  bool nexusPending = false, nexusFailed = false, startingNexus = false;
  int _connectionGeneration = 0;
  bool get isNexus => nexusPending || nexusReference != null;

  Future<void> connectNexus() async {
    final client = _nxm, generation = _connectionGeneration;
    if (client == null) return;
    try {
      final native = await _channel.invokeMapMethod<String, Object?>('state');
      if (disposed || generation != _connectionGeneration || native == null)
        return;
      final pid = native['processId'] as int?;
      if (pid == null) return;
      final descriptor = await client.configure(pid);
      if (disposed || generation != _connectionGeneration) return;
      await _channel.invokeMethod<Object?>('configureNxm', {
        'endpoint': descriptor.endpoint,
        'capability': descriptor.capability,
        'processId': descriptor.processId,
      });
      await refresh();
    } on DesktopNexusProblem catch (error) {
      if (!disposed && generation == _connectionGeneration) fail(error.message);
    } on PlatformException {
      if (!disposed && generation == _connectionGeneration)
        fail('The Nexus link connection is unavailable.');
    } on MissingPluginException {
      if (!disposed && generation == _connectionGeneration)
        fail('The Nexus link connection is unavailable.');
    }
  }

  Future<Artifact?> startNexus(String workspace) async {
    final client = _nxm, reference = nexusReference;
    if (client == null || reference == null || startingNexus) return null;
    startingNexus = true;
    notifyListeners();
    try {
      final result = await client.read(reference, workspace, download: true);
      if (disposed || reference != nexusReference) return null;
      nexusLink = result;
      problem = result.problem;
      return result.problem == null ? result.artifact : null;
    } on DesktopNexusProblem catch (error) {
      if (!disposed && reference == nexusReference) problem = error.message;
      return null;
    } finally {
      if (!disposed) {
        startingNexus = false;
        notifyListeners();
      }
    }
  }

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

  Future<void> recheck() => _resolve();

  void selectWorkspace(String? value) {
    hasWorkspaceSelection = true;
    workspaceId = value;
    if (isNexus) unawaited(_resolve());
    notifyListeners();
  }

  void fail(String detail) {
    problem = detail;
    notifyListeners();
  }

  void attach(DesktopClient? client, {NxmClient? nxm}) {
    if (identical(client, _client) && identical(nxm, _nxm)) return;
    _client = client;
    _nxm = nxm;
    ++_connectionGeneration;
    unawaited(connectNexus());
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
      final nextReference = state['nxmReference'] as String?;
      final reference = nextReference == null || nextReference.isEmpty
          ? null
          : nextReference;
      final pending = state['nxmPending'] == true,
          failed = state['nxmFailed'] == true;
      final nxmChanged =
          reference != nexusReference ||
          pending != nexusPending ||
          failed != nexusFailed;
      nexusReference = reference;
      nexusPending = pending;
      nexusFailed = failed;
      if (next != id) {
        id = next;
        arguments = (state['arguments'] as List<Object?>? ?? const [])
            .cast<String>();
        workspaceId = null;
        hasWorkspaceSelection = false;
        _adoptionKey = null;
        _operationId = null;
        await _resolve();
      } else if (nxmChanged) {
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
    nexusLink = null;
    problem = null;
    resolving = false;
    if (id == null) {
      if (!disposed) notifyListeners();
      return;
    }
    if (isNexus) {
      if (nexusFailed)
        problem = 'The Nexus link could not be sent. Retry the connection.';
      else if (nexusPending)
        resolving = _nxm != null;
      else if (_nxm != null && nexusReference != null) {
        resolving = true;
        notifyListeners();
        try {
          final result = await _nxm!.read(nexusReference!, workspaceId);
          if (!disposed && generation == _generation) {
            nexusLink = result;
            problem = result.problem;
          }
        } on DesktopNexusProblem catch (error) {
          if (!disposed && generation == _generation) problem = error.message;
        }
        resolving = false;
      }
      if (!disposed && generation == _generation) notifyListeners();
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
      if (requestId == id && nexusReference != null && _nxm != null)
        await _nxm!.dismiss(nexusReference!);
      await _channel.invokeMethod<Object?>('dismiss', requestId);
      await refresh();
    } on DesktopNexusProblem catch (error) {
      if (!disposed) fail(error.message);
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
    ++_connectionGeneration;
    _channel.setMethodCallHandler(null);
    super.dispose();
  }
}
