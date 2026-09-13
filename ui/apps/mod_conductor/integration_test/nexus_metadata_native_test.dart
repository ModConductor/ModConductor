import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_mod_library/mc_mod_library.dart';
import 'package:mc_artifacts/src/update_form.dart';
import 'package:mc_artifacts/mc_artifacts.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';
import 'package:mod_conductor/src/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets(
    'provider refresh and explicit update use the installed mod workflow',
    (tester) async {
      const fixture = String.fromEnvironment('MC_DESKTOP_FIXTURE'),
          output = String.fromEnvironment('MC_DESKTOP_OUTPUT');
      const narrow = bool.fromEnvironment('MC_DESKTOP_NARROW');
      if (!Platform.isLinux || fixture.isEmpty || output.isEmpty) {
        throw StateError('Use the private desktop fixture.');
      }
      await Directory(output).create(recursive: true);
      final root = await Directory(
        '$output/Texture collections/Weekend workspace with a long path',
      ).create(recursive: true);
      final game = '$output/synthetic-game';
      expect((await Process.run(fixture, ['--game-files', game])).exitCode, 0);
      final info = '$output/provider.txt';
      final owner = EngineOwner(
        fixture,
        launch: (path) => Process.start(path, [
          '--nexus-metadata-engine',
          '$output/state',
          info,
        ]),
      );
      final boundary = GlobalKey();
      final workspace = newOperationId(), profile = newOperationId();
      Finder action(String label) => find.byWidgetPredicate(
        (w) =>
            (w is McAction && w.label == label) ||
            (w is McIconAction && w.label == label),
      );
      Future<void> until(bool Function() ready) async {
        final deadline = DateTime.now().add(const Duration(seconds: 30));
        while (!ready() && DateTime.now().isBefore(deadline)) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(ready(), isTrue);
        expect(tester.takeException(), isNull);
      }

      Future<void> tap(Finder item) async {
        await tester.ensureVisible(item.last);
        await tester.pumpAndSettle();
        await tester.tap(item.last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      Future<void> capture(String name) async {
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.runAsync(() async {
          final image =
              await (boundary.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File('$output/$name.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }

      final previous = FlutterError.onError;
      FlutterError.onError = (details) {
        File('$output/framework-errors.log')
            .writeAsStringSync('$details\n', mode: FileMode.append);
        previous?.call(details);
      };
      try {
        await owner.connect();
        expect(owner.state, isA<EngineConnected>());
        await owner.credentials!.setMode(CredentialMode.sessionOnly);
        await owner.nexus!.signIn();
        for (
          var n = 0;
          n < 60 && (await owner.nexus!.status()).name == null;
          n++
        ) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
        expect((await owner.nexus!.status()).name, isNotNull);
        await owner.workspaces!.create(workspace, 'Weekend', root.path);
        await owner.workspaces!.createProfile(
          workspace,
          0,
          ProfileInfo(profile, 'Everyday'),
        );
        await owner.gameContexts!.save(workspace, 0, game);
        Future<Artifact> available(Artifact initial) async {
          var value = initial;
          for (var n = 0; n < 100 && value.state != ArtifactState.ready; n++) {
            await Future<void>.delayed(const Duration(milliseconds: 50));
            value = await owner.artifacts!.read(workspace, value.id);
          }
          expect(value.state, ArtifactState.ready);
          return value;
        }

        final archive = await available(
          await owner.nexus!.download(workspace, newOperationId(), 64012, 501),
        );
        final draft = await owner.installations!.prepare(archive).result;
        final started = await owner.installations!.start(
          draft,
          newOperationId(),
        );
        final installed = await owner.installations!.watch(started).last;
        expect(installed.phase, InstallationPhase.complete);
        final mod = (await owner.modLibrary!.scan(
          workspace,
          candidateLimit: 100,
        )).entries.firstWhere((m) => m.id == installed.modId);
        await owner.modLibrary!.edit(
          mod.id,
          mod.revision,
          ModMetadata(
            name: 'Quiet rivers',
            notes: 'My local notes',
            version: 'local label',
          ),
        );
        final categories = await owner.modOrganization!.categories(workspace);
        await owner.modOrganization!.createCategory(
          workspace,
          categories.revision,
          newOperationId(),
          'Environment',
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
              artifacts: owner.artifacts,
              credentials: owner.credentials,
              nexus: owner.nexus,
              nexusMetadata: owner.nexusMetadata,
              installations: owner.installations,
              maintenance: owner.maintenance,
              fomod: owner.fomod,
              bain: owner.bain,
              chooseArchive: () async => null,
              status: DesktopConnected((owner.state as EngineConnected).report),
            ),
          ),
        );
        await tester.pumpAndSettle();
        if (narrow) {
          await tap(find.byKey(const ValueKey('nav-preferences')));
          await tap(find.byKey(const ValueKey('preferences-scale')));
          await tap(find.text('150%'));
          await tap(find.byKey(const ValueKey('apply-preferences')));
          await tap(find.byKey(const ValueKey('nav-workspaces')));
        }
        await tap(find.byKey(ValueKey('workspace-$workspace')));
        await tap(find.text('Mods').first);
        await capture('mods-before-load');
        final browser = tester.widget<ModLibraryBrowser>(
          find.byType(ModLibraryBrowser),
        );
        await File('$output/mods-state.txt').writeAsString(
          'connected=${browser.controller.inventory.connected}; problem=${browser.controller.inventory.problem}; loaded=${browser.controller.inventory.loaded}; workspace=${browser.controller.workspaceId}',
        );
        if (browser.controller.inventory.problem != null) {
          await tap(find.text('Retry').first);
        }
        await until(() => find.text('Quiet rivers').evaluate().isNotEmpty);
        await capture('mods');
        await tap(find.text('Quiet rivers').first);
        await tap(action('Nexus Mods'));
        ModNexusController controller() =>
            tester.widget<ModNexusView>(find.byType(ModNexusView)).controller;
        await until(() => !controller().busy && controller().details != null);
        await tap(action('Refresh'));
        await until(
          () => !controller().busy && controller().details?.current == true,
        );
        await capture('details');
        if (const bool.fromEnvironment('MC_NEXUS_DETAILS_ONLY')) return;
        await tap(action('Start tracking'));
        await until(
          () =>
              !controller().busy && controller().interactions?.tracking == true,
        );
        await capture('tracked');
        await tap(action('Map category'));
        await until(() => find.text('Environment').evaluate().isNotEmpty);
        await tap(find.text('Environment').last);
        await capture('category');
        await tap(action('Add category'));
        await until(
          () => !controller().busy && controller().details?.categoryId != null,
        );
        await tap(action('Link details'));
        await tap(action('Change link'));
        await tap(action('Look up mod'));
        await until(
          () =>
              tester.widget<McFormDialog>(find.byType(McFormDialog)).onSubmit !=
              null,
        );
        await capture('link');
        await tap(action('Link mod'));
        await until(
          () => !controller().busy && controller().details?.manual == true,
        );
        await tap(action('Refresh'));
        await until(() => !controller().busy);
        final provider = Uri.parse(await File(info).readAsString());
        Future<void> mode(String value) async {
          final http = HttpClient();
          final response = await (await http.getUrl(
            provider.resolve('fixture/mode?value=$value'),
          )).close();
          await response.drain<void>();
          http.close();
        }

        await mode('write-uncertain');
        await tap(action('Stop tracking'));
        await until(
          () =>
              !controller().busy && controller().interactions?.tracking == null,
        );
        await capture('uncertain');
        await mode('metadata-error');
        await tap(action('Refresh'));
        await until(
          () =>
              !controller().busy && controller().details?.freshness == 'stale',
        );
        await capture('stale');
        await mode('good');
        await tap(action('Refresh'));
        await until(
          () => !controller().busy && controller().details?.current == true,
        );
        await tap(action('View updates'));
        await capture('files');
        final details = controller().details!;
        final file = controller().model.selected!.file.id;
        await available(
          await owner.nexusMetadata!.download(
            details.reference,
            file,
            true,
            newOperationId(),
          ),
        );
        await tap(action('Download'));
        await until(
          () =>
              find.byType(ArtifactBrowser).evaluate().isNotEmpty &&
              action('Review update').evaluate().isNotEmpty,
        );
        await tap(action('Review update'));
        await until(() => find.byType(UpdateTargetForm).evaluate().isNotEmpty);
        expect(
          tester
              .widget<UpdateTargetForm>(find.byType(UpdateTargetForm))
              .target
              ?.id,
          mod.id,
        );
        await capture('review-target');
        await tap(action('Review update'));
        await until(() => find.text('Update').evaluate().isNotEmpty);
        await capture('review');
        await tap(action('Update'));
        await until(
          () => find.text('Quiet rivers updated').evaluate().isNotEmpty,
        );
        await capture('updated');
        final finalDetails = await owner.nexusMetadata!.read(workspace, mod.id);
        expect(finalDetails.installedFile, file);
        expect(finalDetails.installedVersion, '1.5');
        await tap(action('Open Mods'));
        await until(
          () =>
              find.byType(ModLibraryBrowser).evaluate().isNotEmpty &&
              find.text('Quiet rivers').evaluate().isNotEmpty,
        );
        await capture('mods-updated');
        await File('$output/observations.txt').writeAsString(
          'Production widgets and native services: explicit refresh, tracking, category selection, manual file link, uncertain-write refusal, stale snapshot, explicit successor acquisition and preselected reviewed update. Local mod identity retained; new provider file version observed. Private synthetic account and archives only.\n',
        );
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await owner.close();
        FlutterError.onError = previous;
      }
    },
  );
}
