import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/src/engine_session.dart';

void main() {
  final executable = Platform.environment['MC_ENGINE_PATH'];
  group(
    'published operation client',
    skip: executable == null
        ? 'Set MC_ENGINE_PATH to a published NativeAOT engine.'
        : false,
    () {
      test('the real client consumes a durable runtime check and cleanly closes its child', () async {
        final state = await Directory.systemTemp.createTemp('mc-wire-');
        final engine = EngineSession(
          await Process.start(executable!, ['--state-directory', state.path]),
        );
        try {
          await engine.connect();
          final report = await engine.check();
          expect(report.runtime.nativeAot, isTrue);
          expect(report.runtime.sqliteVersion, isNotEmpty);
          expect(report.heartbeats, greaterThan(0));
          expect((await engine.operations.state()).revision, 1);
        } finally {
          await engine.close();
          expect(await engine.exited, 0);
          await state.delete(recursive: true);
        }
      });
    },
  );
}
