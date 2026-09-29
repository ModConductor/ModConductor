import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';
import 'package:mc_client/mc_client.dart';

import 'support/native_child.dart';

void main() {
  final engine = Platform.environment['MC_ENGINE_PATH'];
  final fixture = Platform.environment['MC_NATIVE_FIXTURE'];
  test(
    'authenticated large output actions retain complete records, replay one publication and guard deployment pins',
    () async {
      final area = await Directory.systemTemp.createTemp('mc-outputs-wire-');
      final root = await Directory('${area.path}/root').create();
      final state = await Directory('${area.path}/state').create();
      final inputs = '${area.path}/inputs';
      final prepared = await Process.run(fixture!, ['--proton-files', inputs]);
      expect(prepared.exitCode, 0, reason: '${prepared.stderr}');
      final library = '$inputs/Second library';
      final game = '$library/steamapps/common/Skyrim Special Edition';
      var child = await NativeChild.start(engine!, state);
      final workspace = newOperationId(), profile = newOperationId();
      try {
        await child.workspaces().create(workspace, 'Outputs', root.path);
        await child.workspaces().createProfile(
          workspace,
          0,
          ProfileInfo(profile, 'Everyday'),
        );
        await child.gameContexts().save(
          workspace,
          profile,
          'skyrim-se-steam',
          0,
          game,
          proton: Platform.isLinux
              ? ProtonSelection(
                  appId: 489830,
                  association: SteamProtonAssociation('$inputs/Steam', library),
                  compatData: '$library/steamapps/compatdata/489830',
                  runtimeDirectory:
                      '$inputs/Steam/compatibilitytools.d/Custom Ω Proton',
                  toolId: 'fixture_tool',
                )
              : null,
        );
        if (Platform.isWindows) {
          final isolated = await Process.run(fixture, [
            '--isolate-windows-game-locations',
            state.path,
            area.path,
            workspace,
            profile,
          ]);
          expect(isolated.exitCode, 0, reason: '${isolated.stderr}');
        }
        await expectLater(
          child.outputs(authenticate: false).read(workspace, profile),
          throwsA(
            isA<GrpcError>().having(
              (e) => e.code,
              'authentication',
              StatusCode.unauthenticated,
            ),
          ),
        );
        await expectLater(
          child.deployments(authenticate: false).read(profile),
          throwsA(
            isA<GrpcError>().having(
              (e) => e.code,
              'authentication',
              StatusCode.unauthenticated,
            ),
          ),
        );
        final outputs = child.outputs();
        var scope = await outputs.read(workspace, profile);
        final folder = await outputs.add(
          newOperationId(),
          scope.reference,
          'Tool outputs',
          OutputLocationKind.toolFolder,
        );
        final names = <String>{};
        for (var i = 0; i < 400; i++) {
          final name = '${'界' * 50}-$i.txt';
          names.add(name);
          await File('${folder.physicalPath}/$name').writeAsString('Output $i');
        }
        scope = await outputs.read(workspace, profile);
        final events = await outputs.observe(scope.reference).toList();
        var snapshot = events.whereType<OutputsObserved>().single.snapshot;
        expect(snapshot.files, names.length);
        final selected = <OutputSelection>[];
        String? cursor;
        do {
          final page = await outputs.page(
            snapshot.id,
            kind: OutputLocationKind.toolFolder,
            cursor: cursor,
          );
          selected.addAll(page.entries.map((e) => e.selection));
          cursor = page.nextCursor;
        } while (cursor != null);
        expect(selected.map((e) => e.path.single).toSet(), names);
        expect(selected.length, names.length);
        final byteFloor = selected.fold<int>(
          0,
          (n, e) =>
              n +
              utf8.encode(e.path.join('/')).length +
              utf8.encode(e.locationId).length,
        );
        expect(byteFloor, greaterThan(64 * 1024));
        final kept = await outputs.apply(
          newOperationId(),
          snapshot.id,
          selected,
          const KeepOutput(),
        );
        expect(kept.entries.length, selected.length);
        expect(
          kept.entries.every((e) => e.disposition == OutputDisposition.kept),
          isTrue,
        );
        expect(kept.complete, isTrue);
        snapshot =
            (await outputs
                    .observe((await outputs.read(workspace, profile)).reference)
                    .where((e) => e is OutputsObserved)
                    .cast<OutputsObserved>()
                    .single)
                .snapshot;
        final operation = newOperationId(), mod = newOperationId();
        final moved = await outputs.apply(operation, snapshot.id, [
          selected.first,
        ], MoveOutputToMod(NewOutputMod(mod, 'Generated mod', '1')));
        expect(moved.published, isTrue);
        expect(
          await File('${folder.physicalPath}/${selected.first.path.single}')
              .exists(),
          isFalse,
        );
        final replay = await outputs.resume(operation);
        expect(replay.versionId, moved.versionId);
        final inventory = await child.modOrganization().query(
          profile,
          const ModQuery(),
        );
        await child.profileMods().enable(profile, inventory.selectionRevision, [
          mod,
        ], true);
        final deployments = child.deployments();
        final before = await deployments.read(profile);
        await outputs.add(
          newOperationId(),
          (await outputs.read(workspace, profile)).reference,
          'Second folder',
          OutputLocationKind.toolFolder,
        );
        await expectLater(
          deployments
              .prepare(newOperationId(), profile, before.sourceToken)
              .toList(),
          throwsA(
            isA<DeploymentException>().having(
              (e) => e.failure,
              'stale pins',
              DeploymentFailure.stale,
            ),
          ),
        );
        final current = await deployments.read(profile);
        final plan =
            (await deployments
                    .prepare(newOperationId(), profile, current.sourceToken)
                    .where((e) => e is DeploymentPrepared)
                    .cast<DeploymentPrepared>()
                    .single)
                .prepared;
        final deployed =
            (await deployments
                    .activate(plan.id, profile, plan.sourceToken)
                    .where((e) => e is DeploymentFinished)
                    .cast<DeploymentFinished>()
                    .single)
                .receipt;
        expect(deployed.phase, DeploymentPhase.complete);
        expect(
          await File('$game/Data/${selected.first.path.single}').exists(),
          isFalse,
        );
        final active = await deployments.read(profile);
        expect(active.active?.profile?.id, profile);
        final base =
            (await deployments
                    .prepare(
                      newOperationId(),
                      profile,
                      active.sourceToken,
                      retained: true,
                    )
                    .where((e) => e is DeploymentPrepared)
                    .cast<DeploymentPrepared>()
                    .single)
                .prepared;
        await deployments.activate(base.id, profile, base.sourceToken).toList();
        expect(
          await File('$game/Data/${selected.first.path.single}').exists(),
          isFalse,
        );
        await child.close();
        child = await NativeChild.start(engine, state);
        final restoredAction = await child.outputs().action(operation);
        expect(restoredAction.versionId, moved.versionId);
        expect(
          restoredAction.entries.single.disposition,
          OutputDisposition.moved,
        );
        final saved = await child.deployments().saved(profile);
        expect(
          saved.entries.any((e) => e.id == plan.id && e.canRestore),
          isTrue,
        );
      } finally {
        await child.close();
        final normalized = await Process.run(fixture, [
          '--normalize-owned-fixture',
          area.path,
        ]);
        expect(normalized.exitCode, 0, reason: '${normalized.stderr}');
        await area.delete(recursive: true);
      }
    },
    skip: engine == null || fixture == null
        ? 'Set MC_ENGINE_PATH and MC_NATIVE_FIXTURE to published native tools.'
        : false,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
