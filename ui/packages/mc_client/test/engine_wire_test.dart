import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/src/engine_session.dart';

void main() {
  final executable = Platform.environment['MC_ENGINE_PATH'];
  group(
    'published engine',
    skip: executable == null
        ? 'Set MC_ENGINE_PATH to a published NativeAOT engine.'
        : false,
    () {
      late EngineSession engine;
      setUp(() async {
        engine = EngineSession(await Process.start(executable!, const []));
        await engine.connect();
      });
      tearDown(() async => engine.close());

      test(
        'unary and ordered terminal stream survive the generated wire boundary',
        () async {
          final report = await engine.check();
          expect(report.runtime.nativeAot, isTrue);
          expect(report.runtime.architecture, isNotEmpty);
          expect(report.heartbeats, greaterThan(0));
          await engine.close();
          expect(await engine.exited, 0);
        },
      );

      test('cancelling a live stream does not terminate the child or a later request', () async {
        final first = Completer<ProbeTick>();
        final subscription = engine.heartbeats(count: 16).listen((tick) {
          if (!first.isCompleted) first.complete(tick);
        });
        expect((await first.future).complete, isFalse);
        await subscription.cancel();
        final after = await engine.check();
        expect(after.runtime.nativeAot, isTrue);
        expect(after.heartbeats, greaterThan(0));
      });

      test(
        'closing the owner interrupts its stream and reaps the child',
        () async {
          final first = Completer<void>();
          final done = Completer<void>();
          final subscription = engine
              .heartbeats(count: 16)
              .listen(
                (_) {
                  if (!first.isCompleted) first.complete();
                },
                onError: (Object _) {
                  if (!done.isCompleted) done.complete();
                },
                onDone: () {
                  if (!done.isCompleted) done.complete();
                },
              );
          await first.future;
          await engine.close();
          await done.future.timeout(const Duration(seconds: 5));
          await subscription.cancel();
          expect(await engine.exited, 0);
        },
      );
    },
  );
}
