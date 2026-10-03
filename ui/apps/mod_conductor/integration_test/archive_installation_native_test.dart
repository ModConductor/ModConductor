import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mc_artifacts/mc_artifacts.dart';
import 'package:mc_artifacts/src/installation_view.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';
import 'package:mod_conductor/src/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets(
    'direct and manual installation retain navigation and temporary cleanup',
    (tester) async {
      const engine = String.fromEnvironment('MC_ENGINE_PATH'),
          fixture = String.fromEnvironment('MC_NATIVE_FIXTURE'),
          output = String.fromEnvironment('MC_INSTALLATION_OUTPUT');
      const narrow = bool.fromEnvironment('MC_INSTALLATION_NARROW');
      if (!Platform.isLinux ||
          engine.isEmpty ||
          fixture.isEmpty ||
          output.isEmpty) {
        throw StateError(
          'Select native Linux binaries and an owned output folder.',
        );
      }
      await Directory(output).create(recursive: true);
      final area = await Directory(output).createTemp('fixture-');
      final root = await Directory('${area.path}/workspace').create();
      final files = '${area.path}/archives';
      final made = await Process.run(fixture, ['--installation-files', files]);
      expect(made.exitCode, 0, reason: '${made.stderr}');
      final gameFiles = '${area.path}/game';
      final gameMade = await Process.run(fixture, [
        '--proton-files',
        gameFiles,
      ]);
      expect(gameMade.exitCode, 0, reason: '${gameMade.stderr}');
      final steam = '$gameFiles/Steam', library = '$gameFiles/Second library';
      final runtime = '$steam/compatibilitytools.d/Custom Ω Proton';
      await File('$runtime/proton').writeAsString('#!/bin/sh\nexit 0\n');
      final executable = await Process.run('chmod', ['700', '$runtime/proton']);
      expect(executable.exitCode, 0, reason: '${executable.stderr}');
      await File('$runtime/toolmanifest.vdf')
          .writeAsString('manifest { version 2 commandline "/proton %verb%" }');
      final owner = EngineOwner(
        engine,
        launch: (path) =>
            Process.start(path, ['--state-directory', '${area.path}/state']),
      );
      final boundary = GlobalKey(),
          workspace = newOperationId(),
          profile = newOperationId();
      ArtifactController controller() => tester
          .widget<ArtifactBrowser>(
            find.byType(ArtifactBrowser, skipOffstage: false),
          )
          .controller;
      Finder action(String label) => find.byWidgetPredicate(
        (w) =>
            (w is McAction && w.label == label) ||
            (w is McIconAction && w.label == label),
      );
      Future<void> tap(String label) async {
        final found = action(label).last;
        await tester.ensureVisible(found);
        await tester.pumpAndSettle();
        await tester.tap(found);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      Future<void> until(bool Function() done) async {
        final end = DateTime.now().add(const Duration(seconds: 30));
        while (!done() && DateTime.now().isBefore(end)) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(done(), isTrue);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      Future<void> capture(String name) async {
        final image =
            await (boundary.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage();
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('$output/$name.png')
            .writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      }

      final previousError = FlutterError.onError;
      FlutterError.onError = (details) {
        File(
          '$output/primary-ui-errors.log',
        ).writeAsStringSync('${details.toString()}\n', mode: FileMode.append);
        previousError?.call(details);
      };
      try {
        await owner.connect();
        expect(owner.state, isA<EngineConnected>());
        await owner.workspaces!.create(workspace, 'Weekend', root.path);
        await owner.workspaces!.createProfile(
          workspace,
          0,
          ProfileInfo(profile, 'Everyday'),
        );
        final context = await owner.gameContexts!.save(
          workspace,
          profile,
          'skyrim-se-steam',
          0,
          '$library/steamapps/common/Skyrim Special Edition',
          proton: ProtonSelection(
            appId: 489830,
            association: SteamProtonAssociation(steam, library),
            compatData: '$library/steamapps/compatdata/489830',
            runtimeDirectory: runtime,
            toolId: 'fixture_tool',
          ),
        );
        expect(context.binding!.evidence.runtimeReady, isTrue);
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
              artifacts: owner.artifacts,
              installations: owner.installations,
              status: DesktopConnected((owner.state as EngineConnected).report),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(ValueKey('workspace-$workspace')));
        await until(
          () =>
              find
                  .byType(ArtifactBrowser, skipOffstage: false)
                  .evaluate()
                  .isNotEmpty &&
              controller().loaded,
        );
        await tester.tap(find.text('Archives').first);
        await tester.pumpAndSettle();
        if (narrow) {
          await tester.tap(find.byKey(const ValueKey('nav-preferences')));
          await tester.pumpAndSettle();
          await tester.tap(find.text('100%'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('150%').last);
          await tester.pumpAndSettle();
          await tap('Apply');
          await tester.tap(find.byKey(const ValueKey('nav-workspaces')));
          await tester.pumpAndSettle();
        }
        final good = await owner.artifacts!.add(
          workspace,
          newOperationId(),
          '$files/Rivière textures.zip',
          ArtifactStorage.reference,
        );
        final bad = await owner.artifacts!.add(
          workspace,
          newOperationId(),
          '$files/wrong-size.zip',
          ArtifactStorage.reference,
        );
        final direct = await owner.artifacts!.add(
          workspace,
          newOperationId(),
          '$files/Nested data.zip',
          ArtifactStorage.reference,
        );
        await controller().load();
        await until(() => controller().model.ids.length == 3);
        await tester.tap(find.byKey(ValueKey(direct.id)).first);
        await tester.pumpAndSettle();
        await tap('Install');
        await until(() => action('Open Mods').evaluate().isNotEmpty);
        await until(
          () => controller().model[direct.id]?.state == ArtifactState.installed,
        );
        final directlyInstalled = (await owner.installations!.recent(workspace))
            .single;
        expect(directlyInstalled.phase, InstallationPhase.complete);
        expect(
          controller().model[direct.id]!.links.single.modId,
          directlyInstalled.modId,
        );
        final directVersion = await owner.modLibrary!.version(
          directlyInstalled.versionId!,
        );
        expect(
          directVersion.entries.map((entry) => entry.path.join('/')),
          unorderedEquals([
            'Meshes/actors/character/behaviors/0_master.hkx',
            'source/scripts/FNIS_example.psc',
            'FNIS.esp',
          ]),
        );
        await capture('direct-installed');
        await tap('Back to archives');
        await tester.tap(find.byKey(ValueKey(good.id)).first);
        await tester.pumpAndSettle();
        await tap('Install options');
        await until(() => action('Change layout').evaluate().isNotEmpty);
        await capture('quick-review');
        await tap('Change layout');
        await capture('manual-layout');
        final list = find
            .descendant(
              of: find.byType(ArchiveInstallationView),
              matching: find.byWidgetPredicate(
                (widget) =>
                    widget is Scrollable &&
                    widget.axisDirection == AxisDirection.down,
              ),
            )
            .first;
        await tester.scrollUntilVisible(
          find.text('water.dds'),
          90,
          scrollable: list,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('water.dds').last);
        await tester.pumpAndSettle();
        await tap('Change destination');
        await tester.enterText(
          find.byType(TextField).last,
          'textures/renamed.dds',
        );
        await tester.pump();
        await capture('destination');
        await tap('Apply');
        if (narrow) {
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await tester.pumpAndSettle();
        }
        await tap('Review');
        await tap('Included (2)');
        await tester.tap(find.text('Excluded (1)').last);
        await tester.pumpAndSettle();
        await capture('excluded');
        await tap('Excluded (1)');
        await tester.tap(find.text('Included (2)').last);
        await tester.pumpAndSettle();
        await capture('confirmed-review');
        await tester.tap(action('Install').last);
        await tester.pump();
        await tester.tap(find.text('Mods').first);
        await tester.pumpAndSettle();
        InstallationStatus? saved;
        for (var i = 0; i < 150; ++i) {
          final jobs = await owner.installations!.recent(workspace);
          saved = jobs.where((s) => s.artifactId == good.id).firstOrNull;
          if (saved != null && saved.phase != InstallationPhase.running) break;
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(
          saved?.phase,
          InstallationPhase.complete,
          reason: saved?.problem,
        );
        await tester.tap(find.text('Archives').first);
        await until(() => action('Open Mods').evaluate().isNotEmpty);
        await capture('installed');
        await tap('Open Mods');
        await until(() => find.text(saved!.name).evaluate().isNotEmpty);
        await capture('mods');
        await tester.tap(find.text('Archives').first);
        await tester.pumpAndSettle();
        await tap('Back to archives');
        await tester.tap(find.byKey(ValueKey(bad.id)).first);
        await tester.pumpAndSettle();
        await tap('Install');
        await until(
          () => action('Delete temporary files').evaluate().isNotEmpty,
        );
        await capture('corrupt');
        await tap('Delete temporary files');
        await until(
          () => find.byType(ArchiveInstallationView).evaluate().isEmpty,
        );
        await capture('after-cleanup');
        await File('$output/result.txt').writeAsString(
          'Production widgets and the supplied engine completed a direct ordinary install, preserved archive links and file destinations, allowed manual layout changes, retained installation across tab navigation, and removed temporary files after a corrupt payload.\n',
        );
      } catch (error, stack) {
        File('$output/primary-ui-error.log')
            .writeAsStringSync('$error\n$stack\n');
        rethrow;
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await owner.close();
        FlutterError.onError = previousError;
      }
    },
  );
}
