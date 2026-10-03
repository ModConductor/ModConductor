import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mc_bethesda/mc_bethesda.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_client/src/engine_session.dart';

void main() {
  final engine = Platform.environment['MC_ENGINE_PATH'];
  final fixture = Platform.environment['MC_NATIVE_FIXTURE'];
  final scratch = Platform.environment['MC_LOOT_TEST_ROOT'];
  test(
    'one optimise action saves a fresh order across the authenticated engine boundary',
    () async {
      final area = await Directory(scratch!).createTemp('loot-wire-');
      addTearDown(() => area.delete(recursive: true));
      final inputs = '${area.path}/inputs';
      final generated = await Process.run(fixture!, [
        '--plugin-order-files',
        inputs,
      ]);
      expect(generated.exitCode, 0, reason: '${generated.stderr}');
      final game = (generated.stdout as String).trim();
      final root = await Directory('${area.path}/workspace').create();
      final state = await Directory('${area.path}/state').create();
      Future<EngineSession> start() async {
        final session = EngineSession(
          await Process.start(engine!, ['--state-directory', state.path]),
        );
        await session.connect();
        return session;
      }

      var session = await start();
      final plugins = PluginsController(), sort = SortOrderController();
      final workspace = newOperationId(), profile = newOperationId();
      try {
        await session.workspaces.create(workspace, 'LOOT wire', root.path);
        await session.workspaces.createProfile(
          workspace,
          0,
          ProfileInfo(profile, 'Fresh'),
        );
        await session.gameContexts.save(
          workspace,
          profile,
          'skyrim-se-steam',
          0,
          game,
          proton: ProtonSelection(
            appId: 489830,
            association: SteamProtonAssociation(
              '$inputs/Steam',
              '$inputs/Second library',
            ),
            compatData: '$inputs/Second library/steamapps/compatdata/489830',
            runtimeDirectory:
                '$inputs/Steam/compatibilitytools.d/Custom Ω Proton',
            toolId: 'fixture_tool',
          ),
        );
        for (final name in ['SKSE', 'Textures']) {
          final folder = await Directory('${root.path}/$name').create();
          await File('${folder.path}/loose.txt').writeAsString(name);
          final mod = newOperationId();
          final registered = await session.modLibrary.register(
            workspace,
            mod,
            ModMetadata(name: name),
            DirectoryMod(ModKind.regular, [name]),
          );
          await session.modLibrary.publish(
            mod,
            registered.revision,
            newOperationId(),
          );
          final current = await session.modOrganization.query(
            profile,
            const ModQuery(),
          );
          await session.profileMods.enable(profile, current.selectionRevision, [
            mod,
          ], true);
        }
        final before = await session.modOrganization.query(
          profile,
          const ModQuery(),
        );
        const layout = ['files:first', 'plugin:skyrim.esm', 'files:last'];
        await session.modOrganization.saveLoadOrderLayout(profile, layout);
        plugins.attach(session.bethesda, profile, orders: session.pluginOrders);
        await plugins.scan();
        expect(plugins.problem, isNull);
        expect(plugins.order!.saved, isFalse);
        expect((await session.loot.read()).metadata, isNull);
        sort.attach(session.loot, plugins, profile);
        await sort.read();
        while (sort.reading) {
          await Future<void>.delayed(Duration.zero);
        }
        expect(sort.canPreview, isTrue);

        await sort.optimise();
        expect(sort.problem, isNull);
        expect(sort.lastResult, isNotNull);
        expect(sort.proposal, isNull);
        expect(plugins.problem, isNull);
        expect(plugins.order!.saved, isTrue);
        expect(plugins.order!.reference.revision, greaterThan(0));
        final savedNames = plugins.order!.entries
            .map((entry) => entry.name)
            .toList();
        expect(savedNames, sort.lastResult!.sorted);
        final after = await session.modOrganization.query(
          profile,
          const ModQuery(),
        );
        expect(after.selectionRevision, before.selectionRevision);
        expect(after.enabledCount, before.enabledCount);
        expect(
          after.entries.map(
            (row) =>
                (row.mod.id, row.selection.priority, row.groupId, row.position),
          ),
          before.entries.map(
            (row) =>
                (row.mod.id, row.selection.priority, row.groupId, row.position),
          ),
        );
        expect(await session.modOrganization.loadOrderLayout(profile), layout);

        final headers = plugins.order!.headers.id;
        final preview = await session.loot.preview(workspace, profile, headers);
        final dismissed = await session.loot.dismiss(preview.proposal!.id);
        expect(dismissed.proposal, isNull);
        expect(
          (await session.pluginOrders.read(
            workspace,
            profile,
            headers,
          )).entries.map((entry) => entry.name),
          savedNames,
        );

        sort.attach(null, plugins, null);
        plugins.attach(null, null);
        await session.close();
        session = await start();
        final gameState = await session.gameContexts.read(workspace, profile);
        await session.gameContexts.refresh(
          workspace,
          profile,
          gameState.revision,
        );
        final rescanned = await session.bethesda.scan(profile);
        final reopened = await session.pluginOrders.read(
          workspace,
          profile,
          rescanned.id,
        );
        expect(reopened.saved, isTrue);
        expect(reopened.entries.map((entry) => entry.name), savedNames);
      } finally {
        sort.dispose();
        plugins.dispose();
        await session.close();
      }
    },
    skip:
        !Platform.isLinux ||
        engine == null ||
        fixture == null ||
        scratch == null,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
