import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';
import 'package:mc_client/mc_client.dart';

import 'support/native_child.dart';

void main() {
  final executable = Platform.environment['MC_ENGINE_PATH'];
  late Directory state;
  final children = <NativeChild>[];
  Future<NativeChild> start() async {
    final child = await NativeChild.start(executable!, state);
    children.add(child);
    return child;
  }

  setUp(() async {
    state = await Directory.systemTemp.createTemp('mc-operations-');
  });
  tearDown(() async {
    for (final child in children) {
      await child.close();
    }
    children.clear();
    await state.delete(recursive: true);
  });
  group(
    'native durable operations',
    skip: executable == null
        ? 'Set MC_ENGINE_PATH to a published NativeAOT engine.'
        : false,
    () {
      test('replay survives restart and stale or changed requests cannot overwrite a result', () async {
        final child = await start();
        final client = child.operations();
        final id = newOperationId();
        await client.begin(id: id, expectedRevision: 0, count: 1);
        final completed = await client.waitForResult(id);
        expect(completed.phase, OperationPhase.completed);
        expect(completed.result!.nativeAot, isTrue);
        expect(completed.resultRevision, 1);
        final cursor = (await client.state()).cursor;
        expect(
          (await client.begin(
            id: id,
            expectedRevision: 0,
            count: 1,
          )).resultRevision,
          1,
        );
        expect((await client.state()).cursor, cursor);
        await expectLater(
          client.begin(id: id, expectedRevision: 0, count: 2),
          throwsA(
            isA<GrpcError>().having(
              (e) => e.code,
              'status',
              StatusCode.alreadyExists,
            ),
          ),
        );
        await expectLater(
          client.begin(id: newOperationId(), expectedRevision: 0),
          throwsA(
            isA<GrpcError>().having(
              (e) => e.code,
              'status',
              StatusCode.failedPrecondition,
            ),
          ),
        );
        child.process.kill(ProcessSignal.sigkill);
        await child.process.exitCode;
        final restored = (await start()).operations();
        final replay = await restored.begin(
          id: id,
          expectedRevision: 0,
          count: 1,
        );
        expect(replay.result, completed.result);
        expect((await restored.state()).revision, 1);
        expect((await restored.state()).cursor, cursor);
      });

      test('explicit cancellation before commit differs from cancellation after commit', () async {
        final child = await start();
        final client = child.operations();
        final cancelledId = newOperationId();
        await client.begin(id: cancelledId, expectedRevision: 0, count: 16);
        expect(
          (await client.cancel(cancelledId)).phase,
          OperationPhase.cancelled,
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect((await client.get(cancelledId)).phase, OperationPhase.cancelled);
        expect((await client.state()).revision, 0);
        final completedId = newOperationId();
        await client.begin(id: completedId, expectedRevision: 0, count: 1);
        final completed = await client.waitForResult(completedId);
        final cursor = (await client.state()).cursor;
        expect(
          (await client.cancel(completedId)).phase,
          OperationPhase.completed,
        );
        expect((await client.get(completedId)).result, completed.result);
        expect((await client.state()).revision, 1);
        expect((await client.state()).cursor, cursor);
        child.process.kill(ProcessSignal.sigkill);
        await child.process.exitCode;
        final restarted = (await start()).operations();
        expect(
          (await restarted.get(cancelledId)).phase,
          OperationPhase.cancelled,
        );
        expect((await restarted.get(completedId)).result, completed.result);
        expect((await restarted.state()).revision, 1);
      });

      test(
        'disconnect and graceful owner close do not cancel accepted work',
        () async {
          final child = await start();
          final client = child.operations();
          final id = newOperationId();
          await client.begin(id: id, expectedRevision: 0, count: 16);
          await child.disconnect();
          final restored = child.operations();
          expect(
            (await restored.waitForResult(id)).phase,
            OperationPhase.completed,
          );
          final next = newOperationId();
          await restored.begin(id: next, expectedRevision: 1, count: 16);
          await child.close();
          final restarted = (await start()).operations();
          expect((await restarted.get(next)).phase, OperationPhase.completed);
          expect((await restarted.state()).revision, 2);
        },
      );

      test('restart interrupts abandoned work without interrupting another live owner', () async {
        final crashed = await start();
        final live = await start();
        final abandonedId = newOperationId();
        final liveId = newOperationId();
        await crashed.operations().begin(
          id: abandonedId,
          expectedRevision: 0,
          count: 16,
        );
        await live.operations().begin(
          id: liveId,
          expectedRevision: 0,
          count: 16,
        );
        crashed.process.kill(ProcessSignal.sigkill);
        await crashed.process.exitCode;
        final recovery = (await start()).operations();
        expect(
          (await recovery.get(abandonedId)).phase,
          OperationPhase.interrupted,
        );
        expect(
          (await recovery.waitForResult(liveId)).phase,
          OperationPhase.completed,
        );
        expect((await recovery.state()).revision, 1);
      });

      test(
        'a bounded snapshot resync still resolves an older committed operation',
        () async {
          final client = (await start()).operations();
          final first = newOperationId();
          await client.begin(id: first, expectedRevision: 0, count: 1);
          await client.waitForResult(first);
          final slow = client.watch().listen((_) {});
          slow.pause();
          for (var revision = 1; revision <= 70; revision++) {
            final id = newOperationId();
            await client.begin(id: id, expectedRevision: revision, count: 1);
            await client.waitForResult(id);
          }
          await slow.cancel();
          final feed = await client.watch(afterCursor: 0).first;
          expect(feed.resyncRequired, isTrue);
          expect(feed.snapshot!.length, lessThanOrEqualTo(16));
          expect(feed.snapshot!.any((entry) => entry.id == first), isFalse);
          expect(
            (await client.waitForResult(first, afterCursor: 0)).resultRevision,
            1,
          );
          expect((await client.state()).revision, 71);
        },
        timeout: const Timeout(Duration(seconds: 60)),
      );

      test(
        'reader pressure cannot orphan accepted operations under a live owner',
        () async {
          final client = (await start()).operations();
          final ids = List.generate(16, (_) => newOperationId());
          await Future.wait(
            ids.map(
              (id) => client.begin(id: id, expectedRevision: 0, count: 16),
            ),
          );
          await Future.wait(
            List.generate(256, (_) async {
              try {
                await client.state();
              } on GrpcError catch (error) {
                expect(error.code, StatusCode.resourceExhausted);
              }
            }),
          );
          for (final id in ids) {
            final result = await client.waitForResult(id);
            expect(result.terminal, isTrue);
            expect([
              OperationPhase.completed,
              OperationPhase.stale,
            ], contains(result.phase));
          }
          expect((await client.state()).revision, 1);
        },
        timeout: const Timeout(Duration(seconds: 60)),
      );
    },
  );
}
