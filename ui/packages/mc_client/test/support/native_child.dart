import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:grpc/grpc.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_client/src/generated/modconductor/v2/engine_probe.pbgrpc.dart'
    as wire;

class NativeChild {
  NativeChild(this.process, this.ready, this.capability, this.errors);
  final Process process;
  final wire.EngineReady ready;
  final String capability;
  final List<int> errors;
  final List<ClientChannel> channels = [];

  static Future<NativeChild> start(String executable, Directory state) async {
    final process = await Process.start(executable, [
      '--state-directory',
      state.path,
    ]);
    final errors = <int>[];
    process.stderr.listen(errors.addAll);
    final random = Random.secure();
    final token = List.generate(
      32,
      (_) => random.nextInt(256),
    ).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    process.stdin.writeln(token);
    await process.stdin.flush();
    final line = await process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .first
        .timeout(const Duration(seconds: 10));
    if (line.contains(token)) {
      throw StateError('Bootstrap exposed a credential.');
    }
    return NativeChild(
      process,
      wire.EngineReady.fromBuffer(base64.decode(line)),
      token,
      errors,
    );
  }

  wire.EngineOperationsClient client({
    String? token,
    int? port,
    List<int>? certificate,
    String authority = 'localhost',
  }) {
    final channel = ClientChannel(
      '127.0.0.1',
      port: port ?? ready.port,
      options: ChannelOptions(
        credentials: ChannelCredentials.secure(
          certificates: certificate ?? ready.certificatePem,
          authority: authority,
        ),
        connectTimeout: const Duration(seconds: 1),
      ),
    );
    channels.add(channel);
    return wire.EngineOperationsClient(
      channel,
      options: CallOptions(
        timeout: const Duration(seconds: 2),
        metadata: {'mc-session': ?token},
      ),
    );
  }

  ClientChannel _localChannel() {
    final channel = ClientChannel(
      '127.0.0.1',
      port: ready.port,
      options: ChannelOptions(
        credentials: ChannelCredentials.secure(
          certificates: ready.certificatePem,
          authority: 'localhost',
        ),
      ),
    );
    channels.add(channel);
    return channel;
  }

  OperationsClient operations() {
    return OperationsClient(
      _localChannel(),
      CallOptions(
        timeout: const Duration(seconds: 5),
        metadata: {'mc-session': capability},
      ),
    );
  }

  WorkspacesClient workspaces({bool authenticate = true, String? token}) =>
      GrpcWorkspacesClient(
        _localChannel(),
        CallOptions(
          timeout: const Duration(seconds: 5),
          metadata: authenticate
              ? {'mc-session': token ?? capability}
              : const {},
        ),
      );

  ModLibraryClient modLibrary({bool authenticate = true, String? token}) =>
      ModLibraryClient(
        _localChannel(),
        CallOptions(
          timeout: const Duration(seconds: 30),
          metadata: authenticate
              ? {'mc-session': token ?? capability}
              : const {},
        ),
      );

  Future<void> disconnect() async {
    for (final channel in channels) {
      await channel.terminate();
    }
    channels.clear();
  }

  Future<void> close() async {
    for (final channel in channels) {
      await channel.terminate();
    }
    try {
      await process.stdin.close();
    } on IOException {
      /* The deliberate crash closes the pipe. */
    }
    await process.exitCode.timeout(const Duration(seconds: 5));
    if (utf8.decode(errors, allowMalformed: true).contains(capability)) {
      throw StateError('Engine diagnostics exposed a credential.');
    }
  }
}
