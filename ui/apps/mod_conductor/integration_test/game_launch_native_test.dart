import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_executables/mc_executables.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';
import 'package:mod_conductor/src/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets(
    'Play applies selected files before the native consumer and Stop waiting preserves them',
    (tester) async {
      const engine = String.fromEnvironment('MC_ENGINE_PATH'),
          fixture = String.fromEnvironment('MC_NATIVE_FIXTURE'),
          output = String.fromEnvironment('MC_GAME_OUTPUT');
      const narrow = bool.fromEnvironment('MC_GAME_NARROW');
      if (!Platform.isLinux ||
          engine.isEmpty ||
          fixture.isEmpty ||
          output.isEmpty) {
        throw StateError(
          'Select Linux native tools and an owned evidence directory.',
        );
      }
      await Directory(output).create(recursive: true);
      final area = await Directory(output).createTemp('fixture-');
      final root = await Directory('${area.path}/workspace').create();
      final controls = await Directory('${area.path}/controls').create();
      final inputs = '${area.path}/installation';
      final prepared = await Process.run(fixture, ['--proton-files', inputs]);
      expect(prepared.exitCode, 0, reason: '${prepared.stderr}');
      final steam = '$inputs/Steam', library = '$inputs/Second library';
      final game = '$library/steamapps/common/Skyrim Special Edition';
      final runtime = '$steam/compatibilitytools.d/Custom Ω Proton';
      String quote(String value) => "'${value.replaceAll("'", "'\\''")}'";
      await File('$runtime/proton').writeAsString(
        '#!/bin/sh\nexec ${quote(fixture)} --game-load ${quote(controls.path)} "\$2"\n',
      );
      expect(
        (await Process.run('chmod', ['u+x', '$runtime/proton'])).exitCode,
        0,
      );
      final manifest = File('$runtime/toolmanifest.vdf');
      await manifest.writeAsString(
        'manifest { version 2 commandline "/proton %verb%" }',
      );
      final target = File('$game/Data/Marker.TXT');
      await target.writeAsString('original base');
      final owner = EngineOwner(
        engine,
        launch: (path) =>
            Process.start(path, ['--state-directory', '${area.path}/state']),
      );
      await Directory(output).create(recursive: true);
      final boundary = GlobalKey();
      GamePlayController controller() => tester
          .widget<GamePlayActions>(find.byType(GamePlayActions))
          .controller;
      Finder action(String label) =>
          find.byWidgetPredicate((w) => w is McAction && w.label == label);
      Future<void> frames() async {
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
      }

      Future<void> tap(Finder finder) async {
        await tester.ensureVisible(finder);
        await frames();
        await tester.tap(finder);
        await frames();
      }

      Future<void> until(bool Function() condition) async {
        final deadline = DateTime.now().add(const Duration(seconds: 30));
        while (!condition() && DateTime.now().isBefore(deadline)) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        if (!condition()) {
          await File('$output/failure.json').writeAsString(
            jsonEncode({
              'problem': controller().problem,
              'phase': controller().run?.phase.name,
              'runProblem': controller().run?.problem,
              'rootExit': controller().run?.rootExitCode,
            }),
          );
        }
        expect(condition(), isTrue);
        await frames();
      }

      Future<void> capture(String name) async {
        await frames();
        final image =
            await (boundary.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('$output/$name.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      }

      try {
        await owner.connect();
        final id = newOperationId(),
            profile = newOperationId(),
            empty = newOperationId(),
            mod = newOperationId();
        await owner.workspaces!.create(id, 'Game launch workspace', root.path);
        await owner.workspaces!.createProfile(
          id,
          0,
          ProfileInfo(profile, 'Everyday'),
        );
        final source = await Directory('${root.path}/Managed').create();
        await File('${source.path}/marker.txt')
            .writeAsString('intended managed bytes Ω');
        final registered = await owner.modLibrary!.register(
          id,
          mod,
          const ModMetadata(name: 'Managed'),
          const DirectoryMod(ModKind.regular, ['Managed']),
        );
        await owner.modLibrary!.publish(
          mod,
          registered.revision,
          newOperationId(),
        );
        final inventory = await owner.modOrganization!.query(
          profile,
          const ModQuery(),
        );
        await owner.profileMods!.enable(profile, inventory.selectionRevision, [
          mod,
        ], true);
        await owner.gameContexts!.save(
          id,
          0,
          game,
          proton: ProtonSelection(
            appId: 489830,
            association: SteamProtonAssociation(steam, library),
            compatData: '$library/steamapps/compatdata/489830',
            runtimeDirectory: runtime,
            toolId: 'fixture_tool',
          ),
        );
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundary,
            child: ModConductorApp(
              workspaces: owner.workspaces,
              modLibrary: owner.modLibrary,
              profileMods: owner.profileMods,
              modOrganization: owner.modOrganization,
              gameContexts: owner.gameContexts,
              deployments: owner.deployments,
              executables: owner.executables,
              gameLaunching: owner.gameLaunching,
              status: DesktopConnected((owner.state as EngineConnected).report),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tap(find.byKey(ValueKey('workspace-$id')));
        await until(() => controller().connected && !controller().reading);
        if (narrow) {
          await tap(find.byKey(const ValueKey('nav-preferences')));
          await tap(find.byKey(const ValueKey('preferences-scale')));
          await tap(find.text('150%').last);
          await tap(find.byKey(const ValueKey('apply-preferences')));
          await tap(find.byKey(const ValueKey('nav-workspaces')));
        }
        await capture('ready-light');
        await tap(action('Play'));
        await until(
          () => controller().run?.phase == ExecutableRunPhase.running,
        );
        await until(() => File('${controls.path}/read.json').existsSync());
        final first = controller().run!;
        final read = jsonDecode(
          await File('${controls.path}/read.json').readAsString(),
        ) as Map<String, dynamic>;
        expect(read['content'], 'intended managed bytes Ω');
        expect(first.profileId, profile);
        expect(first.game!.files, isNotNull);
        expect(await target.readAsString(), 'intended managed bytes Ω');
        await capture('running-light');
        await tap(action('Run details'));
        await capture('details-light');
        await tap(action('Close').last);
        await tap(action('Stop waiting'));
        await until(
          () => controller().run?.phase == ExecutableRunPhase.detached,
        );
        expect(await target.readAsString(), 'intended managed bytes Ω');
        await capture('detached-light');
        await File('${controls.path}/finish').writeAsString('finish');
        await tap(action('Close'));
        await tap(find.byKey(const ValueKey('nav-preferences')));
        await tap(find.byKey(const ValueKey('preferences-theme')));
        await tap(find.text('Dark').last);
        await tap(find.byKey(const ValueKey('apply-preferences')));
        await tap(find.byKey(const ValueKey('nav-workspaces')));
        final current = await owner.workspaces!.read(id);
        final added = await owner.workspaces!.createProfile(
          id,
          current.workspace.revision,
          ProfileInfo(empty, 'Empty'),
        );
        await owner.workspaces!.selectProfile(
          id,
          added.workspace.revision,
          empty,
        );
        await tap(find.byKey(const ValueKey('close-workspace')));
        await tap(find.byKey(ValueKey('workspace-$id')));
        await until(
          () =>
              controller().workspace?.selectedProfile?.id == empty &&
              !controller().reading,
        );
        await tap(action('Play'));
        await until(
          () => controller().run?.phase == ExecutableRunPhase.finished,
        );
        expect(controller().run!.profileId, empty);
        expect(await target.readAsString(), 'original base');
        expect(
          (await owner.executables!.read(
            id,
            first.id,
          )).game!.files!.generationId,
          first.game!.files!.generationId,
        );
        await capture('finished-dark');
        await tap(action('Close'));
        await manifest.writeAsString(
          'manifest { version 2 commandline "/unsupported" }',
        );
        final context = await owner.gameContexts!.read(id);
        await owner.gameContexts!.refresh(id, context.revision);
        await tap(action('Play'));
        await until(
          () => controller().problem != null && !controller().changing,
        );
        await capture('unavailable-dark');
        expect(
          await File('${source.path}/marker.txt').readAsString(),
          'intended managed bytes Ω',
        );
        await File('$output/result.json').writeAsString(
          jsonEncode({
            'nativeConsumerLoadedManagedFile': true,
            'capturedProfileAndDeployment': true,
            'detachPreservedFiles': true,
            'emptyProfileRestoredBase': true,
            'oldRunPinsPreserved': true,
            'unsupportedRefreshDidNotLaunch': true,
            'viewport': tester.view.physicalSize.toString(),
            'textScale': narrow ? 1.5 : 1.0,
            'scope':
                'Owned Linux fixture dispatch; not actual Skyrim or Proton',
          }),
        );
      } finally {
        await File('${controls.path}/finish').writeAsString('finish');
        await tester.pumpWidget(const SizedBox());
        await owner.close();
        // Immutable fixture payloads are normalized only after the preservation assertions.
        await Process.run('chmod', ['-R', 'u+w', root.path]);
        await area.delete(recursive: true);
      }
    },
  );
}
