import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_client/src/engine_session.dart';

void main() {
  final engine = Platform.environment['MC_ENGINE_PATH'];
  final fixture = Platform.environment['MC_NATIVE_FIXTURE'];
  test(
    'authenticated FNIS read and terminal observation preserve full persisted diagnostics',
    () async {
      final area = await Directory.systemTemp.createTemp('mc-fnis-wire-');
      EngineSession? session;
      try {
        final prepared = await Process.run(fixture!, [
          '--fnis-wire-files',
          area.path,
        ]);
        expect(prepared.exitCode, 0, reason: '${prepared.stderr}');
        final identity =
            jsonDecode(prepared.stdout as String) as Map<String, dynamic>;
        final workspace = identity['workspaceId'] as String;
        final profile = identity['profileId'] as String;
        final run = identity['runId'] as String;
        session = EngineSession(
          await Process.start(engine!, [
            '--state-directory',
            '${area.path}/state',
          ]),
        );
        await session.connect();

        final read = await session.fnis.read(workspace, profile);
        final observed = await session.fnis
            .observeRun(workspace, profile, run)
            .toList()
            .timeout(const Duration(seconds: 10));
        expect(observed, hasLength(1));

        const limit = 256 * 1024;
        const logPrefix = 'FNIS diagnostic\n';
        for (final result in [read, observed.single]) {
          expect(result.runId, run);
          expect(result.outputPhase, FnisOutputStatusPhase.failed);
          expect(result.exitCode, 255);
          expect(result.canCancelRun, isFalse);
          expect(result.standardOutput, 'stdout\n${'\uFFFD' * (limit - 7)}');
          expect(result.standardError, 'stderr\n${'\uFFFD' * (limit - 7)}');
          expect(
            result.runLog,
            '$logPrefix${'L' * (limit - logPrefix.length)}',
          );
        }
      } finally {
        if (session != null) {
          await session.close();
          expect(await session.exited, 0);
        }
        final normalized = await Process.run(fixture!, [
          '--normalize-owned-fixture',
          area.path,
        ]);
        expect(normalized.exitCode, 0, reason: '${normalized.stderr}');
        await area.delete(recursive: true);
      }
    },
    skip: engine == null || fixture == null
        ? 'Set MC_ENGINE_PATH and MC_NATIVE_FIXTURE for real engine verification.'
        : false,
  );
}
