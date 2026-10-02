import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';

import 'support/native_child.dart';

void main() {
  final engine = Platform.environment['MC_ENGINE_PATH'];
  final fixture = Platform.environment['MC_NATIVE_FIXTURE'];
  final scratch = Platform.environment['MC_UNREAL_TEST_ROOT'];
  test(
    'native Unreal acquisition, selection conflict, deployment and editable settings preserve profile boundaries',
    () async {
      final area = await Directory(scratch!).createTemp('unreal-wire-');
      final state = await Directory('${area.path}/state').create();
      final root = await Directory('${area.path}/workspace').create();
      final prepared = await Process.run(fixture!, [
        '--unreal-files',
        '${area.path}/files',
      ]);
      expect(prepared.exitCode, 0, reason: '${prepared.stderr}');
      final files =
          jsonDecode(prepared.stdout as String) as Map<String, dynamic>;
      final child = await NativeChild.start(engine!, state);
      final workspace = newOperationId(), profile = newOperationId();
      try {
        await child.workspaces().create(workspace, 'Unreal', root.path);
        await child.workspaces().createProfile(
          workspace,
          0,
          ProfileInfo(profile, 'Lua'),
        );
        await child.gameContexts().save(
          workspace,
          profile,
          'subnautica2-steam',
          0,
          files['game'] as String,
          proton: Platform.isLinux
              ? ProtonSelection(
                  appId: 1962700,
                  association: SteamProtonAssociation(
                    files['steam'] as String,
                    files['library'] as String,
                  ),
                  compatData: files['compatdata'] as String,
                  runtimeDirectory: files['runtime'] as String,
                  toolId: 'fixture_tool',
                )
              : null,
        );
        final client = child.unreal();
        final unauthenticated = await child
            .unreal(authenticate: false)
            .read(workspace, profile);
        expect(unauthenticated, isA<LoaderProblem<UnrealLoaderState>>());
        final initial = (await client.read(
          workspace,
          profile,
        ) as LoaderValue<UnrealLoaderState>).value;
        final events = await client
            .acquire(initial, files['archive'] as String)
            .toList();
        expect(events.last.problem, isNull);
        final loader = events.last.state!;
        expect(loader.enabled, true);
        expect(loader.mod, isNotNull);
        expect(
          await client.change(initial, false),
          isA<LoaderProblem<UnrealLoaderState>>(),
        );
        expect(
          (await client.read(
            workspace,
            profile,
          ) as LoaderValue<UnrealLoaderState>).value.enabled,
          true,
        );
        final deployment = child.deployments();
        final current = await deployment.read(profile);
        final stages = await deployment
            .prepare(newOperationId(), profile, current.sourceToken)
            .toList();
        final ready = (stages.last as DeploymentPrepared).prepared;
        final activated = await deployment
            .activate(ready.id, profile, ready.sourceToken)
            .toList();
        expect(
          (activated.last as DeploymentFinished).receipt.phase,
          DeploymentPhase.complete,
        );
        final settings = (await client.settings(
          loader,
          'UE4SS-settings.ini',
        ) as LoaderValue<LoaderText>).value;
        final saved = await client.save(
          loader,
          'UE4SS-settings.ini',
          settings,
          'Enabled = false\n',
        );
        expect(saved, isA<LoaderValue<LoaderText>>());
        expect(
          await client.save(loader, 'UE4SS-settings.ini', settings, 'stale'),
          isA<LoaderProblem<LoaderText>>(),
        );
        final reread = (await client.settings(
          loader,
          'UE4SS-settings.ini',
        ) as LoaderValue<LoaderText>).value;
        expect(reread.document.content, 'Enabled = false\n');
      } finally {
        await child.close();
      }
    },
    skip: engine == null || fixture == null || scratch == null
        ? 'Native Unreal verification paths are required.'
        : false,
  );
}
