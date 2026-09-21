import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';
import 'package:mc_client/mc_client.dart';

import 'support/native_child.dart';

void main() {
  final engine = Platform.environment['MC_ENGINE_PATH'];
  final fixture = Platform.environment['MC_NATIVE_FIXTURE'];
  test(
    'authenticated Proton choices persist atomically and refresh only the saved context',
    () async {
      final area = await Directory.systemTemp.createTemp('mc-proton-');
      final state = await Directory('${area.path}/state').create();
      final root = await Directory('${area.path}/workspace').create();
      final files = '${area.path}/files';
      final prepared = await Process.run(fixture!, ['--proton-files', files]);
      expect(prepared.exitCode, 0, reason: '${prepared.stderr}');
      final steam = '$files/Steam';
      final library = '$files/Second library';
      final game = '$library/steamapps/common/Skyrim Special Edition';
      final runtime = '$steam/compatibilitytools.d/Custom Ω Proton';
      var child = await NativeChild.start(engine!, state);
      try {
        final workspace = newOperationId(), profile = newOperationId();
        await child.workspaces().create(workspace, 'Proton', root.path);
        await child.workspaces().createProfile(
          workspace,
          0,
          ProfileInfo(profile, 'Proton'),
        );
        var contexts = child.gameContexts();
        final initial = await contexts.read(workspace, profile);
        await expectLater(
          child.protonContexts(authenticate: false).search(
            'skyrim-se-steam',
            game,
            [steam],
          ).result,
          throwsA(
            isA<GrpcError>().having(
              (e) => e.code,
              'code',
              StatusCode.unauthenticated,
            ),
          ),
        );
        final report = await child.protonContexts().search(
          'skyrim-se-steam',
          game,
          [steam],
        ).result;
        final selection = ProtonSelection(
          appId: 489830,
          association: SteamProtonAssociation(steam, library),
          compatData: '$library/steamapps/compatdata/489830',
          runtimeDirectory: runtime,
          toolId: 'fixture_tool',
        );
        if (Platform.isWindows) {
          expect(report.prefixes, isEmpty);
          expect(report.problems, isNotEmpty);
          await expectLater(
            contexts.save(
              workspace,
              profile,
              'skyrim-se-steam',
              initial.revision,
              game,
              proton: selection,
            ),
            throwsA(
              isA<GameContextException>().having(
                (e) => e.code,
                'code',
                GameContextFailure.invalidInstallation,
              ),
            ),
          );
          expect((await contexts.read(workspace, profile)).binding, isNull);
          final native = await contexts.save(
            workspace,
            profile,
            'skyrim-se-steam',
            initial.revision,
            game,
          );
          expect(
            native.binding!.evidence.platform,
            GameContextPlatform.windows,
          );
          return;
        }
        final prefix = report.prefixes.single;
        expect(prefix.origins.single.manifest.appId, 489830);
        expect(report.mappings.single.perGame, isNull);
        expect(report.mappings.single.globalDefault, 'fixture_tool');
        expect((await contexts.read(workspace, profile)).binding, isNull);
        final saved = await contexts.save(
          workspace,
          profile,
          'skyrim-se-steam',
          initial.revision,
          game,
          proton: selection,
        );
        final evidence = saved.binding!.evidence.proton!;
        expect(evidence.runtimeName, 'Fixture Proton Ω');
        expect(evidence.runtimeVersion, isNot(evidence.prefixVersion));
        expect(evidence.globalTool, 'fixture_tool');
        expect(evidence.perGameTool, isNull);
        expect(
          evidence.paths.any(
            (p) => p.windowsPath?.startsWith(r'C:\users\steamuser') ?? false,
          ),
          isTrue,
        );
        await expectLater(
          contexts.save(
            workspace,
            profile,
            'skyrim-se-steam',
            initial.revision,
            game,
          ),
          throwsA(
            isA<GameContextException>().having(
              (e) => e.code,
              'code',
              GameContextFailure.stale,
            ),
          ),
        );
        expect(
          (await contexts.read(
            workspace,
            profile,
          )).binding!.proton!.runtimeDirectory,
          runtime,
        );
        await child.close();
        child = await NativeChild.start(engine, state);
        contexts = child.gameContexts();
        final reopened = await contexts.read(workspace, profile);
        expect(reopened.binding!.needsCheck, isTrue);
        expect(
          reopened.binding!.evidence.fingerprint,
          saved.binding!.evidence.fingerprint,
        );
        final launcher = File('$runtime/proton');
        await launcher.rename('$runtime/proton.hidden');
        final failed = await contexts.refresh(
          workspace,
          profile,
          reopened.revision,
        );
        expect(failed.binding!.needsCheck, isTrue);
        expect(
          failed.binding!.evidence.fingerprint,
          saved.binding!.evidence.fingerprint,
        );
        expect(failed.binding!.proton!.compatData, selection.compatData);
        await File('$runtime/proton.hidden').rename('$runtime/proton');
        final checked = await contexts.refresh(
          workspace,
          profile,
          failed.revision,
        );
        expect(checked.binding!.needsCheck, isFalse);
        expect(
          checked.binding!.evidence.fingerprint,
          saved.binding!.evidence.fingerprint,
        );
      } finally {
        await child.close();
        await area.delete(recursive: true);
      }
    },
    skip: engine == null || fixture == null,
    timeout: const Timeout(Duration(seconds: 90)),
  );
}
