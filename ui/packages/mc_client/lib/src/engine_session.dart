import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:grpc/grpc.dart';

import 'generated/modconductor/v1/engine_probe.pbgrpc.dart' as wire;

typedef RuntimeSummary = ({String architecture, bool nativeAot});
typedef ProbeTick = ({int sequence, bool complete});
typedef ConnectionReport = ({RuntimeSummary runtime, int heartbeats});

class EngineSession {
  EngineSession(this._process) : _errors = _process.stderr.listen((_) {});

  final Process _process;
  final StreamSubscription<List<int>> _errors;
  ClientChannel? _channel;
  wire.EngineProbeClient? _client;
  int _request = 0;
  Future<void>? _closing;

  Future<int> get exited => _process.exitCode;

  Future<void> connect() async {
    final random = Random.secure();
    final capability = List.generate(
      32,
      (_) => random.nextInt(256),
    ).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    _process.stdin.writeln(capability);
    await _process.stdin.flush();
    final ready = await _readReady(_process.stdout)
        .timeout(const Duration(seconds: 10));
    if (ready.protocolMajor != 1) {
      throw const EngineProtocolMismatch();
    }
    if (ready.port < 1 || ready.port > 65535 || ready.certificatePem.isEmpty) {
      throw const FormatException('Invalid engine descriptor.');
    }
    final channel = ClientChannel(
      '127.0.0.1',
      port: ready.port,
      options: ChannelOptions(
        credentials: ChannelCredentials.secure(
          certificates: ready.certificatePem,
          authority: 'localhost',
        ),
        connectTimeout: const Duration(seconds: 2),
      ),
    );
    _channel = channel;
    _client = wire.EngineProbeClient(
      channel,
      options: CallOptions(
        timeout: const Duration(seconds: 5),
        metadata: {'mc-session': capability},
      ),
    );
  }

  Future<RuntimeSummary> inspect() async {
    final reply = await _client!.inspectRuntime(
      wire.InspectRuntimeRequest(protocolMajor: 1),
    );
    if (reply.protocolMajor != 1) throw const EngineProtocolMismatch();
    return (architecture: reply.architecture, nativeAot: reply.nativeAot);
  }

  Stream<ProbeTick> heartbeats({int count = 5}) async* {
    final id = 'probe-${++_request}';
    final call = _client!.watchHeartbeat(
      wire.HeartbeatRequest(requestId: id, count: count),
    );
    var received = 0;
    try {
      await for (final tick in call) {
        received++;
        if (tick.requestId != id ||
            tick.sequence != received ||
            received > count ||
            tick.complete != (received == count)) {
          throw const FormatException('Invalid heartbeat stream.');
        }
        yield (sequence: received, complete: tick.complete);
      }
      if (received != count) {
        throw const FormatException('Incomplete heartbeat stream.');
      }
    } finally {
      await call.cancel();
    }
  }

  Future<ConnectionReport> check() async {
    final runtime = await inspect();
    var received = 0;
    await for (final tick in heartbeats()) {
      received = tick.sequence;
    }
    return (runtime: runtime, heartbeats: received);
  }

  Future<void> close() =>
      _closing ??= _close().whenComplete(() => _closing = null);

  Future<void> _close() async {
    await _channel?.terminate();
    try {
      await _process.stdin.close();
    } on IOException {
      // An exited child can close its pipe before the owner does.
    }
    await _process.exitCode.timeout(const Duration(seconds: 3));
    await _errors.cancel();
  }
}

class EngineProtocolMismatch implements Exception {
  const EngineProtocolMismatch();
}

Future<wire.EngineReady> _readReady(Stream<List<int>> output) async {
  final bytes = <int>[];
  await for (final chunk in output) {
    for (final byte in chunk) {
      if (byte == 10) {
        return wire.EngineReady.fromBuffer(
          base64.decode(ascii.decode(bytes).trim()),
        );
      }
      if (bytes.length == 4096) {
        throw const FormatException('Engine descriptor is too long.');
      }
      bytes.add(byte);
    }
  }
  throw const FormatException('The engine stopped before it was ready.');
}
