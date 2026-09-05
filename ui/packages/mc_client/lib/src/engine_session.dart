import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:grpc/grpc.dart';

import 'generated/modconductor/v1/engine_probe.pbgrpc.dart' as wire;

typedef RuntimeSummary = ({String architecture, bool nativeAot});
typedef ProbeTick = ({int sequence, bool complete});
typedef ConnectionReport = ({RuntimeSummary runtime, int heartbeats});

/// An owned child and the small read-only wire proof. Not an authenticated session.
class EngineSession {
  EngineSession._(this._process, this._channel, this._errors)
    : _client = wire.EngineProbeClient(
        _channel,
        options: CallOptions(timeout: const Duration(seconds: 5)),
      );

  final Process _process;
  final ClientChannel _channel;
  final StreamSubscription<List<int>> _errors;
  final wire.EngineProbeClient _client;
  int _request = 0;
  Future<void>? _closing;

  Future<int> get exited => _process.exitCode;

  static Future<EngineSession> start(String executable) async {
    final process = await Process.start(executable, const []);
    final errors = process.stderr.listen((_) {});
    try {
      final endpoint = await _readEndpoint(process.stdout)
          .timeout(const Duration(seconds: 10));
      final channel = ClientChannel(
        endpoint.host,
        port: endpoint.port,
        options: const ChannelOptions(
          // Loopback-only proof, not authentication or production security.
          credentials: ChannelCredentials.insecure(),
          connectTimeout: Duration(seconds: 2),
        ),
      );
      return EngineSession._(process, channel, errors);
    } catch (_) {
      await _stop(process);
      await errors.cancel();
      rethrow;
    }
  }

  Future<RuntimeSummary> inspect() async {
    final reply = await _client.inspectRuntime(
      wire.InspectRuntimeRequest(protocolMajor: 1),
    );
    if (reply.protocolMajor != 1) {
      throw const FormatException('Unsupported engine protocol.');
    }
    return (architecture: reply.architecture, nativeAot: reply.nativeAot);
  }

  Stream<ProbeTick> heartbeats({int count = 5}) async* {
    final id = 'probe-${++_request}';
    final call = _client.watchHeartbeat(
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

  Future<void> close() => _closing ??= _close();

  Future<void> _close() async {
    await _channel.terminate();
    await _stop(_process);
    await _errors.cancel();
  }
}

Future<Uri> _readEndpoint(Stream<List<int>> output) async {
  final bytes = <int>[];
  await for (final chunk in output) {
    for (final byte in chunk) {
      if (byte == 10) {
        final endpoint = Uri.parse(utf8.decode(bytes).trim());
        if (endpoint.scheme != 'http' ||
            endpoint.host != '127.0.0.1' ||
            !endpoint.hasPort ||
            endpoint.port < 1 ||
            endpoint.port > 65535 ||
            endpoint.userInfo.isNotEmpty ||
            endpoint.path.isNotEmpty ||
            endpoint.hasQuery ||
            endpoint.hasFragment) {
          throw const FormatException('Invalid engine endpoint.');
        }
        return endpoint;
      }
      if (bytes.length == 512) {
        throw const FormatException('Engine endpoint is too long.');
      }
      bytes.add(byte);
    }
  }
  throw const FormatException(
    'Engine stopped before it announced an endpoint.',
  );
}

Future<void> _stop(Process process) async {
  try {
    await process.stdin.close();
  } on IOException {
    // A child that already exited can close its pipe before this owner does.
  }
  try {
    await process.exitCode.timeout(const Duration(seconds: 3));
  } on TimeoutException {
    process.kill(ProcessSignal.sigkill);
    await process.exitCode.timeout(const Duration(seconds: 2));
  }
}
