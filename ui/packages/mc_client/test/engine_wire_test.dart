import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_client/src/engine_session.dart';

void main() {
  final executable = Platform.environment['MC_ENGINE_PATH'];
  group(
    'published operation client',
    skip: executable == null
        ? 'Set MC_ENGINE_PATH to a published NativeAOT engine.'
        : false,
    () {
      test(
        'a fresh default data directory keeps results across restart without writing to the working directory',
        () async {
          final root = await Directory.systemTemp.createTemp(
            'mc-default-state-',
          );
          final working = await Directory('${root.path}/working').create();
          final home = await Directory('${root.path}/home').create();
          final data = Directory('${root.path}/data');
          final sessions = <EngineSession>[];
          Future<EngineSession> start() async {
            final session = EngineSession(
              await Process.start(
                executable!,
                const [],
                workingDirectory: working.path,
                environment: {'HOME': home.path, 'XDG_DATA_HOME': data.path},
              ),
            );
            sessions.add(session);
            await session.connect();
            return session;
          }

          try {
            final first = await start();
            await first.check();
            final snapshot = (await first.operations.state()).snapshot!.single;
            await first.close();
            expect(await first.exited, 0);
            final restarted = await start();
            final recovered = await restarted.operations.get(snapshot.id);
            expect(recovered.result, snapshot.result);
            expect(recovered.resultRevision, 1);
            expect(
              await File('${data.path}/ModConductor/state/state.db').exists(),
              isTrue,
            );
            expect(await working.list().isEmpty, isTrue);
          } finally {
            for (final session in sessions) {
              await session.close();
            }
            await root.delete(recursive: true);
          }
        },
        skip: !Platform.isLinux ? 'Linux XDG fresh-directory behavior.' : false,
      );

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

      test('the diagnostics client maps a qualified refusal from the native engine', () async {
        final state = await Directory.systemTemp.createTemp(
          'mc-diagnostics-wire-',
        );
        final engine = EngineSession(
          await Process.start(executable!, ['--state-directory', state.path]),
        );
        try {
          await engine.connect();
          await expectLater(
            engine.diagnostics.check(
              workspaceId: '11111111111111111111111111111111',
              profileId: '22222222222222222222222222222222',
            ),
            throwsA(
              isA<DiagnosticsException>().having(
                (error) => error.fault,
                'fault',
                DiagnosticFault.notFound,
              ),
            ),
          );
        } finally {
          await engine.close();
          expect(await engine.exited, 0);
          await state.delete(recursive: true);
        }
      });

      test('the authenticated SKSE service reports an unavailable game without changing it', () async {
        final state = await Directory.systemTemp.createTemp('mc-skse-wire-');
        final engine = EngineSession(
          await Process.start(executable!, ['--state-directory', state.path]),
        );
        try {
          await engine.connect();
          final result = await engine.skse.read(
            '11111111111111111111111111111111',
            '22222222222222222222222222222222',
          );
          expect(result.phase, SkseStatusPhase.unavailable);
          expect(result.status, isNotEmpty);
        } finally {
          await engine.close();
          expect(await engine.exited, 0);
          await state.delete(recursive: true);
        }
      });

      test('the authenticated ENB service reaches game qualification instead of the adoption gate', () async {
        final state = await Directory.systemTemp.createTemp('mc-enb-wire-');
        final engine = EngineSession(
          await Process.start(executable!, ['--state-directory', state.path]),
        );
        try {
          await engine.connect();
          final result = await engine.enb.read(
            '11111111111111111111111111111111',
            '22222222222222222222222222222222',
          );
          expect(result.phase, EnbStatusPhase.unavailable);
          expect(result.canOpenAuthorPage, isFalse);
          expect(result.canSelectArchive, isFalse);
        } finally {
          await engine.close();
          expect(await engine.exited, 0);
          await state.delete(recursive: true);
        }
      });

      test('the authenticated FNIS service refuses an unavailable game without acquisition', () async {
        final state = await Directory.systemTemp.createTemp('mc-fnis-wire-');
        final engine = EngineSession(
          await Process.start(executable!, ['--state-directory', state.path]),
        );
        try {
          await engine.connect();
          final result = await engine.fnis.read(
            '11111111111111111111111111111111',
            '22222222222222222222222222222222',
          );
          expect(result.phase, FnisStatusPhase.unavailable);
          expect(result.canInstall, isFalse);
          expect(result.canRemove, isFalse);
        } finally {
          await engine.close();
          expect(await engine.exited, 0);
          await state.delete(recursive: true);
        }
      });

      test('the authenticated Skyrim setup service reports its blocked installation step', () async {
        final state = await Directory.systemTemp.createTemp(
          'mc-skyrim-setup-wire-',
        );
        final engine = EngineSession(
          await Process.start(executable!, ['--state-directory', state.path]),
        );
        try {
          await engine.connect();
          final result = await engine.skyrimSetup.read(
            '11111111111111111111111111111111',
            '22222222222222222222222222222222',
            selection: const SkyrimSetupSelection(),
          );
          expect(result.phase, SkyrimSetupStatusPhase.unavailable);
          expect(result.canStart, isFalse);
          expect(result.components.single.blocked, isTrue);
          final cancelled = await engine.skyrimSetup.cancel(
            '11111111111111111111111111111111',
            '22222222222222222222222222222222',
          );
          expect(cancelled.phase, SkyrimSetupStatusPhase.unavailable);
        } finally {
          await engine.close();
          expect(await engine.exited, 0);
          await state.delete(recursive: true);
        }
      });
    },
  );
}
