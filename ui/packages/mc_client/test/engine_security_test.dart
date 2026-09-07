import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';
import 'package:mc_client/src/generated/modconductor/v1/operations.pbgrpc.dart'
    as wire;

import 'support/native_child.dart';

void main() {
  late Directory state;
  setUp(() async {
    state = await Directory.systemTemp.createTemp('mc-security-');
  });
  tearDown(() async {
    await state.delete(recursive: true);
  });
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
          final child = await NativeChild.start(executable!, state);
          addTearDown(child.close);
          for (final token in [null, '0' * 64]) {
            final client = child.client(token: token);
            final denied = isA<GrpcError>().having(
              (error) => error.code,
              'status',
              StatusCode.unauthenticated,
            );
            await expectLater(
              client.getState(wire.StateRequest(protocolMajor: 1)),
              throwsA(denied),
            );
            await expectLater(
              client.beginRuntimeCheck(
                wire.RuntimeCheckRequest(
                  operationId: '1' * 32,
                  heartbeatCount: 5,
                ),
              ),
              throwsA(denied),
            );
            await expectLater(
              client.watchOperations(wire.WatchRequest()),
              emitsError(denied),
            );
          }
          final accepted = child.client(token: child.capability);
          expect(
            (await accepted.getState(wire.StateRequest(protocolMajor: 1)))
                .hasSnapshot,
            isTrue,
          );
          expect(
            (await accepted.watchOperations(wire.WatchRequest()).first)
                .hasSnapshot,
            isTrue,
          );
        },
      );

      test('a substituted endpoint or authority cannot receive an authenticated RPC', () async {
        final original = await NativeChild.start(executable!, state);
        final substitute = await NativeChild.start(executable, state);
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
            client.getState(wire.StateRequest(protocolMajor: 1)),
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
          (await rightPeer.getState(wire.StateRequest(protocolMajor: 1)))
              .hasSnapshot,
          isTrue,
        );
      });

      test(
        'a stale endpoint and an incompatible runtime cannot report success',
        () async {
          final child = await NativeChild.start(executable!, state);
          final client = child.client(token: child.capability);
          await expectLater(
            client.getState(wire.StateRequest(protocolMajor: 3)),
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
            client.getState(wire.StateRequest(protocolMajor: 1)),
            throwsA(isA<GrpcError>()),
          );
          await child.close();
        },
      );
    },
  );
}
