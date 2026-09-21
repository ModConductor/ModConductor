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
      final secondGame = '${area.path}/second-game';
      final prepared = await Process.run(fixtureTool!, ['--game-files', game]);
      expect(prepared.exitCode, 0, reason: '${prepared.stderr}');
      final preparedSecond = await Process.run(fixtureTool, [
        '--game-files',
        secondGame,
      ]);
      expect(preparedSecond.exitCode, 0, reason: '${preparedSecond.stderr}');
      var child = await NativeChild.start(engine!, state);
      final workspace = newOperationId();
      final profile = newOperationId();
      final secondProfile = newOperationId();
      try {
        await child.workspaces().create(workspace, 'Game', root.path);
        final created = await child.workspaces().createProfile(
          workspace,
          0,
          ProfileInfo(profile, 'Game'),
        );
        await child.workspaces().createProfile(
          workspace,
          created.workspace.revision,
          ProfileInfo(secondProfile, 'Second game'),
        );
        final client = child.gameContexts();
        final empty = await client.read(workspace, profile);
        expect(empty.definition, isNull);
        expect(empty.binding, isNull);
        final saved = await client.save(
          workspace,
          profile,
          'skyrim-se-steam',
          empty.revision,
          game,
        );
        final secondEmpty = await client.read(workspace, secondProfile);
        expect(secondEmpty.binding, isNull);
        final secondSaved = await client.save(
          workspace,
          secondProfile,
          'skyrim-se-steam',
          secondEmpty.revision,
          secondGame,
        );
        expect(secondSaved.binding!.path, secondGame);
        expect((await client.read(workspace, profile)).binding!.path, game);
        final definition = saved.definition!;
        final installationCapability = definition.capability(
          GameCapabilityId.gameInstallationValidation,
        );
        expect(
          installationCapability?.disposition,
          GameCapabilityDisposition.available,
        );
        expect(
          installationCapability?.supports(
            definition.id,
            GameContextPlatform.windows,
          ),
          isTrue,
        );
        expect(
          installationCapability?.supports(
            definition.id,
            GameContextPlatform.proton,
          ),
          isTrue,
        );
        expect(
          definition.capability(GameCapabilityId.archiveInspection)?.kind,
          GameCapabilityKind.gameAdapter,
        );
        expect(
          definition
              .capability(GameCapabilityId.archiveInspection)
              ?.disposition,
          GameCapabilityDisposition.available,
        );
        expect(
          definition.capability(GameCapabilityId.legacyExtensionAbi),
          isNull,
        );
        await expectLater(
          child
              .gameContexts(authenticate: false)
              .save(
                workspace,
                profile,
                'skyrim-se-steam',
                saved.revision,
                game,
              ),
          throwsA(
            isA<GrpcError>().having(
              (e) => e.code,
              'code',
              StatusCode.unauthenticated,
            ),
          ),
        );
        expect(saved.binding!.evidence.executable!.fileVersion, '1.7.104.0');
        if (Platform.isLinux) {
          expect(
            saved.binding!.evidence.documents,
            isA<UnavailableGameLocation>(),
          );
        }
        await expectLater(
          client.save(
            workspace,
            profile,
            'skyrim-se-steam',
            saved.revision,
            '$game/absent',
          ),
          throwsA(
            isA<GameContextException>().having(
              (e) => e.code,
              'code',
              GameContextFailure.invalidInstallation,
            ),
          ),
        );
        expect(
          (await client.read(workspace, profile)).revision,
          saved.revision,
        );
        final results = await Future.wait([
          for (var i = 0; i < 2; i++)
            client
                .save(
                  workspace,
                  profile,
                  'skyrim-se-steam',
                  saved.revision,
                  game,
                )
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
        final current = await client.read(workspace, profile);
        expect(current.revision, saved.revision + 1);
        await child.close();
        child = await NativeChild.start(engine, state);
        final reopened = await child.gameContexts().read(workspace, profile);
        expect(reopened.binding!.id, saved.binding!.id);
        expect(reopened.binding!.needsCheck, isTrue);
        expect(
          reopened.binding!.evidence.fingerprint,
          saved.binding!.evidence.fingerprint,
        );
        final checked = await child.gameContexts().refresh(
          workspace,
          profile,
          reopened.revision,
        );
        expect(checked.binding!.needsCheck, isFalse);
        final data = Directory('$game/Data');
        await data.rename('$game/moved-data');
        final unavailable = await child.gameContexts().refresh(
          workspace,
          profile,
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
