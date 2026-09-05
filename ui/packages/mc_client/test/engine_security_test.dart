import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';
import 'package:mc_client/src/generated/modconductor/v1/engine_probe.pbgrpc.dart'
    as wire;

class _Child {
  _Child(this.process, this.ready, this.capability, this.errors);
  final Process process;
  final wire.EngineReady ready;
  final String capability;
  final List<int> errors;
  final List<ClientChannel> channels = [];

  static Future<_Child> start(String executable) async {
    final process = await Process.start(executable, const []);
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
    return _Child(
      process,
      wire.EngineReady.fromBuffer(base64.decode(line)),
      token,
      errors,
    );
  }

  wire.EngineProbeClient client({
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
    return wire.EngineProbeClient(
      channel,
      options: CallOptions(
        timeout: const Duration(seconds: 2),
        metadata: {'mc-session': ?token},
      ),
    );
  }

  Future<void> close() async {
    for (final channel in channels) {
      await channel.terminate();
    }
    await process.stdin.close();
    await process.exitCode.timeout(const Duration(seconds: 5));
    if (utf8.decode(errors, allowMalformed: true).contains(capability)) {
      throw StateError('Engine diagnostics exposed a credential.');
    }
  }
}

void main() {
  final executable = Platform.environment['MC_ENGINE_PATH'];
  group(
    'native authenticated boundary',
    skip: executable == null
        ? 'Set MC_ENGINE_PATH to a published NativeAOT engine.'
        : false,
    () {
      test(
        'missing and wrong sessions cannot invoke unary or streamed calls',
        () async {
          final child = await _Child.start(executable!);
          addTearDown(child.close);
          for (final token in [null, '0' * 64]) {
            final client = child.client(token: token);
            final denied = isA<GrpcError>().having(
              (error) => error.code,
              'status',
              StatusCode.unauthenticated,
            );
            await expectLater(
              client.inspectRuntime(
                wire.InspectRuntimeRequest(protocolMajor: 1),
              ),
              throwsA(denied),
            );
            await expectLater(
              client.watchHeartbeat(
                wire.HeartbeatRequest(requestId: 'denied', count: 1),
              ),
              emitsError(denied),
            );
          }
          final accepted = child.client(token: child.capability);
          expect(
            (await accepted.inspectRuntime(
              wire.InspectRuntimeRequest(protocolMajor: 1),
            )).nativeAot,
            isTrue,
          );
          expect(
            (await accepted
                    .watchHeartbeat(
                      wire.HeartbeatRequest(requestId: 'accepted', count: 1),
                    )
                    .single)
                .complete,
            isTrue,
          );
        },
      );

      test('a substituted endpoint or authority cannot receive an authenticated RPC', () async {
        final original = await _Child.start(executable!);
        final substitute = await _Child.start(executable);
        addTearDown(original.close);
        addTearDown(substitute.close);
        // Even a capability valid at the substitute cannot cross the wrong TLS identity.
        final wrongPeer = original.client(
          port: substitute.ready.port,
          token: substitute.capability,
        );
        final wrongName = original.client(
          authority: 'not-localhost.invalid',
          token: original.capability,
        );
        for (final client in [wrongPeer, wrongName]) {
          await expectLater(
            client.inspectRuntime(wire.InspectRuntimeRequest(protocolMajor: 1)),
            throwsA(
              isA<GrpcError>().having(
                (error) => error.code,
                'status',
                StatusCode.unavailable,
              ),
            ),
          );
        }
        final rightPeer = substitute.client(token: substitute.capability);
        expect(
          (await rightPeer.inspectRuntime(
            wire.InspectRuntimeRequest(protocolMajor: 1),
          )).nativeAot,
          isTrue,
        );
      });

      test(
        'a stale endpoint and an incompatible runtime cannot report success',
        () async {
          final child = await _Child.start(executable!);
          final client = child.client(token: child.capability);
          await expectLater(
            client.inspectRuntime(wire.InspectRuntimeRequest(protocolMajor: 2)),
            throwsA(
              isA<GrpcError>().having(
                (error) => error.code,
                'status',
                StatusCode.failedPrecondition,
              ),
            ),
          );
          await child.process.stdin.close();
          expect(await child.process.exitCode, 0);
          await expectLater(
            client.inspectRuntime(wire.InspectRuntimeRequest(protocolMajor: 1)),
            throwsA(isA<GrpcError>()),
          );
          await child.close();
        },
      );
    },
  );
}
