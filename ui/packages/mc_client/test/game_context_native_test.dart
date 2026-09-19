import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';
import 'package:mc_client/mc_client.dart';

import 'support/native_child.dart';

void main() {
  final engine = Platform.environment['MC_ENGINE_PATH'];
  final fixtureTool = Platform.environment['MC_NATIVE_FIXTURE'];
  test(
    'authenticated manual contexts preserve bindings across invalid, concurrent, and restarted checks',
    () async {
      final area = await Directory.systemTemp.createTemp('mc-game-context-');
      final state = await Directory('${area.path}/state').create();
      final root = await Directory('${area.path}/root').create();
      final game = '${area.path}/game';
      final prepared = await Process.run(fixtureTool!, ['--game-files', game]);
      expect(prepared.exitCode, 0, reason: '${prepared.stderr}');
      var child = await NativeChild.start(engine!, state);
      final workspace = newOperationId();
      try {
        await child.workspaces().create(workspace, 'Game', root.path);
        final client = child.gameContexts();
        final empty = await client.read(workspace);
        final installationCapability = empty.definition.capability(
          GameCapabilityId.gameInstallationValidation,
        );
        expect(
          installationCapability?.disposition,
          GameCapabilityDisposition.available,
        );
        expect(
          installationCapability?.supports(
            empty.definition.id,
            GameContextPlatform.windows,
          ),
          isTrue,
        );
        expect(
          installationCapability?.supports(
            empty.definition.id,
            GameContextPlatform.proton,
          ),
          isTrue,
        );
        expect(
          empty.definition.capability(GameCapabilityId.archiveInspection)?.kind,
          GameCapabilityKind.gameAdapter,
        );
        expect(
          empty.definition
              .capability(GameCapabilityId.archiveInspection)
              ?.disposition,
          GameCapabilityDisposition.available,
        );
        expect(
          empty.definition.capability(GameCapabilityId.legacyExtensionAbi),
          isNull,
        );
        await expectLater(
          child
              .gameContexts(authenticate: false)
              .save(workspace, empty.revision, game),
          throwsA(
            isA<GrpcError>().having(
              (e) => e.code,
              'code',
              StatusCode.unauthenticated,
            ),
          ),
        );
        expect((await client.read(workspace)).binding, isNull);
        final saved = await client.save(workspace, empty.revision, game);
        expect(saved.binding!.evidence.executable!.fileVersion, '1.7.104.0');
        if (Platform.isLinux) {
          expect(
            saved.binding!.evidence.documents,
            isA<UnavailableGameLocation>(),
          );
        }
        await expectLater(
          client.save(workspace, saved.revision, '$game/absent'),
          throwsA(
            isA<GameContextException>().having(
              (e) => e.code,
              'code',
              GameContextFailure.invalidInstallation,
            ),
          ),
        );
        expect((await client.read(workspace)).revision, saved.revision);
        final results = await Future.wait([
          for (var i = 0; i < 2; i++)
            client
                .save(workspace, saved.revision, game)
                .then<Object>(
                  (value) => value,
                  onError: (Object error) => error,
                ),
        ]);
        expect(results.whereType<GameContextState>().length, 1);
        final rejected = results.whereType<GameContextException>().single;
        expect(
          rejected.code,
          anyOf(
            GameContextFailure.stale,
            GameContextFailure.busy,
            GameContextFailure.workspaceUnavailable,
          ),
        );
        final current = await client.read(workspace);
        expect(current.revision, saved.revision + 1);
        await child.close();
        child = await NativeChild.start(engine, state);
        final reopened = await child.gameContexts().read(workspace);
        expect(reopened.binding!.id, saved.binding!.id);
        expect(reopened.binding!.needsCheck, isTrue);
        expect(
          reopened.binding!.evidence.fingerprint,
          saved.binding!.evidence.fingerprint,
        );
        final checked = await child.gameContexts().refresh(
          workspace,
          reopened.revision,
        );
        expect(checked.binding!.needsCheck, isFalse);
        final data = Directory('$game/Data');
        await data.rename('$game/moved-data');
        final unavailable = await child.gameContexts().refresh(
          workspace,
          checked.revision,
        );
        expect(unavailable.binding!.needsCheck, isTrue);
        expect(
          unavailable.binding!.evidence.fingerprint,
          checked.binding!.evidence.fingerprint,
        );
        expect(unavailable.binding!.path, game);
      } finally {
        await child.close();
        await area.delete(recursive: true);
      }
    },
    skip: engine == null || fixtureTool == null,
    timeout: const Timeout(Duration(seconds: 90)),
  );
}
