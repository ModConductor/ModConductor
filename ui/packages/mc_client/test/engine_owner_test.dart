import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';

void main() {
  late Directory state;
  setUp(() async {
    state = await Directory.systemTemp.createTemp('mc-owner-');
  });
  tearDown(() async {
    await state.delete(recursive: true);
  });
  final executable = Platform.environment['MC_ENGINE_PATH'];
  final root = Directory.current.parent.parent.parent.path;
  final dart =
      '$root/.tools/flutter/bin/cache/dart-sdk/bin/dart${Platform.isWindows ? '.exe' : ''}';
  Future<Process> fixture(String engine, String mode) => Process.start(dart, [
    '--packages=$root/ui/.dart_tool/package_config.json',
    '$root/ui/packages/mc_client/test/fixtures/bootstrap_child.dart',
    engine,
    mode,
    state.path,
  ]);

  group(
    'native child ownership',
    skip: executable == null
        ? 'Set MC_ENGINE_PATH to a published NativeAOT engine.'
        : false,
    () {
      test(
        'concurrent starts share one child and a crash permits a fresh attempt',
        () async {
          final children = <Process>[];
          final owner = EngineOwner(
            executable!,
            launch: (path) async {
              final child = await Process.start(path, [
                '--state-directory',
                state.path,
              ]);
              children.add(child);
              return child;
            },
          );
          addTearDown(owner.close);
          await Future.wait([
            owner.connect(),
            owner.connect(),
            owner.connect(),
          ]);
          expect(children, hasLength(1));
          expect(owner.state, isA<EngineConnected>());
          final crashed = owner.changes.firstWhere(
            (state) => state is EngineFailure,
          );
          children.single.kill(ProcessSignal.sigkill);
          await crashed.timeout(const Duration(seconds: 5));
          await owner.connect();
          expect(children, hasLength(2));
          expect(owner.state, isA<EngineConnected>());
          expect(await owner.close(), isTrue);
          expect(await children.last.exitCode, 0);
        },
      );

      test(
        'an initial launch failure can retry without replacing another child',
        () async {
          var attempts = 0;
          final owner = EngineOwner(
            executable!,
            launch: (path) => Process.start(
              attempts++ == 0 ? '$path-missing' : path,
              ['--state-directory', state.path],
            ),
          );
          addTearDown(owner.close);
          await owner.connect();
          expect(
            owner.state,
            isA<EngineFailure>().having(
              (state) => state.canRetry,
              'retry',
              isTrue,
            ),
          );
          await owner.connect();
          expect(owner.state, isA<EngineConnected>());
          expect(attempts, 2);
        },
      );

      test(
        'close during delayed startup cannot publish a late connected state',
        () async {
          final owner = EngineOwner(
            executable!,
            launch: (path) => fixture(path, 'delay'),
          );
          final states = <EngineState>[];
          final changes = owner.changes.listen(states.add);
          addTearDown(changes.cancel);
          addTearDown(owner.close);
          final connect = owner.connect();
          await Future<void>.delayed(const Duration(milliseconds: 200));
          final close = owner.close();
          await connect;
          expect(await close, isTrue);
          expect(states.whereType<EngineConnected>(), isEmpty);
          expect(owner.state, isA<EngineIdle>());
          await owner.connect();
          expect(owner.state, isA<EngineConnected>());
        },
      );

      test(
        'a late bootstrap cannot turn a timed out start into success',
        () async {
          final owner = EngineOwner(
            executable!,
            launch: (path) => fixture(path, 'delay-long'),
          );
          final states = <EngineState>[];
          final changes = owner.changes.listen(states.add);
          addTearDown(changes.cancel);
          addTearDown(owner.close);
          await owner.connect().timeout(const Duration(seconds: 20));
          expect(owner.state, isA<EngineFailure>());
          expect(states.whereType<EngineConnected>(), isEmpty);
          expect(await owner.close(), isTrue);
        },
      );

      test('a bootstrap version mismatch or oversized frame never becomes connected', () async {
        for (final mode in ['version', 'oversized']) {
          final owner = EngineOwner(
            executable!,
            launch: (path) => fixture(path, mode),
          );
          addTearDown(owner.close);
          await owner.connect();
          expect(
            owner.state,
            isA<EngineFailure>().having(
              (state) => state.canRetry,
              'retry',
              isTrue,
            ),
          );
          if (mode == 'version') {
            expect(
              (owner.state as EngineFailure).reason,
              EngineFailureReason.protocol,
            );
          }
          expect(await owner.close(), isTrue);
        }
      });

      test(
        'a shutdown timeout keeps its child and a later close can finish',
        () async {
          var starts = 0;
          final owner = EngineOwner(
            executable!,
            launch: (path) {
              starts++;
              return fixture(path, 'slow-stop');
            },
          );
          addTearDown(owner.close);
          await owner.connect();
          expect(owner.state, isA<EngineConnected>());
          expect(await owner.close(), isFalse);
          expect(
            owner.state,
            isA<EngineFailure>().having(
              (state) => state.canRetry,
              'retry',
              isFalse,
            ),
          );
          await owner.connect();
          expect(starts, 1);
          expect(await owner.close(), isTrue);
        },
      );
    },
  );
}
