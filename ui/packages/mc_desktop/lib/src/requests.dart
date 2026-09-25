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
      final result = await client.read(
        reference,
        workspace,
        profile: profileId,
        download: true,
      );
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
  String? problem, workspaceId, profileId;
  final _actionProblems = <int, String>{};
  final _operations = <int, ({String key, String id})>{};
  bool get connected => _client != null;
  String operationId(
    int requestId,
    String workspace,
    String path,
    ArtifactStorage storage,
  ) {
    final key = '$workspace\n$path\n${storage.name}';
    final existing = _operations[requestId];
    if (existing != null && existing.key == key) return existing.id;
    final next = newOperationId();
    _operations[requestId] = (key: key, id: next);
    return next;
  }

  Future<void> recheck() {
    _actionProblems.remove(id);
    return _resolve();
  }

  void selectWorkspace(String? value) => selectContext(value, profileId);

  void selectContext(String? value, String? profile) {
    hasWorkspaceSelection = true;
    workspaceId = value;
    profileId = profile;
    if (isNexus) unawaited(_resolve());
    notifyListeners();
  }

  void fail(String detail) {
    problem = detail;
    notifyListeners();
  }

  void failFor(int requestId, String detail) {
    _actionProblems[requestId] = detail;
    if (requestId == id) fail(detail);
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
    final requestId = id;
    intent = null;
    nexusLink = null;
    problem = requestId == null ? null : _actionProblems[requestId];
    resolving = false;
    if (requestId == null) {
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
          final result = await _nxm!.read(
            nexusReference!,
            workspaceId,
            profile: profileId,
          );
          if (!disposed && generation == _generation) {
            nexusLink = result;
            problem = result.problem;
          }
        } on DesktopNexusProblem catch (error) {
          if (!disposed && generation == _generation) problem = error.message;
        }
        resolving = false;
      }
      if (!disposed && generation == _generation) {
        problem = _actionProblems[requestId] ?? problem;
        notifyListeners();
      }
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
      problem = _actionProblems[requestId] ?? problem;
      resolving = false;
      notifyListeners();
    }
  }

  Future<void> dismiss(int requestId, {String? nexusReference}) async {
    try {
      final reference =
          nexusReference ?? (requestId == id ? this.nexusReference : null);
      if (reference != null && _nxm != null) await _nxm!.dismiss(reference);
      await _channel.invokeMethod<Object?>('dismiss', requestId);
      _actionProblems.remove(requestId);
      _operations.remove(requestId);
      await refresh();
    } on DesktopNexusProblem catch (error) {
      if (!disposed) failFor(requestId, error.message);
    } on PlatformException {
      if (!disposed) {
        available = false;
        failFor(requestId, 'The request could not be dismissed.');
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
