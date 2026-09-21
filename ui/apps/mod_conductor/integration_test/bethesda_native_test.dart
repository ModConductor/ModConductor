import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mc_bethesda/mc_bethesda.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_mod_library/mc_mod_library.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';
import 'package:mod_conductor/src/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets(
    'read-only plugin scan retains winners and survives view navigation',
    (tester) async {
      const fixture = String.fromEnvironment('MC_DESKTOP_FIXTURE'),
          output = String.fromEnvironment('MC_DESKTOP_OUTPUT');
      const narrow = bool.fromEnvironment('MC_DESKTOP_NARROW');
      if (!Platform.isLinux || fixture.isEmpty || output.isEmpty) {
        throw StateError('Use the private desktop fixture.');
      }
      await Directory(output).create(recursive: true);
      final area = await Directory('$output/fixture').create();
      final root = await Directory(
        '${area.path}/Texture collections/Weekend workspace',
      ).create(recursive: true);
      final inputs = '${area.path}/inputs';
      final generated = await Process.run(fixture, [
        '--bethesda-files',
        inputs,
      ]);
      expect(generated.exitCode, 0, reason: '${generated.stderr}');
      final game = (generated.stdout as String).trim();
      final owner = EngineOwner(
        fixture,
        launch: (path) =>
            Process.start(path, ['--desktop-engine', '${area.path}/state']),
      );
      final boundary = GlobalKey();
      final workspace = newOperationId(),
          profile = newOperationId(),
          mod = newOperationId(),
          version = newOperationId();
      Finder action(String label) => find.byWidgetPredicate(
        (w) =>
            (w is McAction && w.label == label) ||
            (w is McIconAction && w.label == label),
      );
      Future<void> tap(Finder finder) async {
        await tester.ensureVisible(finder.last);
        await tester.pumpAndSettle();
        await tester.tap(finder.last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      PluginsController plugins() =>
          tester.widget<PluginsPane>(find.byType(PluginsPane)).controller;
      Future<void> until(bool Function() done) async {
        final deadline = DateTime.now().add(const Duration(seconds: 30));
        while (!done() && DateTime.now().isBefore(deadline)) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        if (!done() && find.byType(PluginsPane).evaluate().isNotEmpty) {
          await File('$output/failure.json').writeAsString(
            jsonEncode({
              'problem': plugins().problem,
              'reading': plugins().reading,
              'state': plugins().state?.id,
            }),
          );
        }
        expect(done(), isTrue);
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

      Future<void> choosePlugins() async {
        await tap(
          find.byWidgetPredicate(
            (w) => w is McChoice<String> && w.label == 'View',
          ),
        );
        await tap(find.text('Plugins').last);
        await until(() => find.byType(PluginsPane).evaluate().isNotEmpty);
      }

      final oldError = FlutterError.onError;
      FlutterError.onError = (details) {
        File('$output/framework-errors.log')
            .writeAsStringSync('$details\n', mode: FileMode.append);
        oldError?.call(details);
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
        final folder = await Directory('${root.path}/Quiet rivers').create();
        await for (final file in Directory('$inputs/plugins').list()) {
          if (file is File) {
            await file.copy('${folder.path}/${file.uri.pathSegments.last}');
          }
        }
        final registered = await owner.modLibrary!.register(
          workspace,
          mod,
          const ModMetadata(name: 'Quiet rivers', version: '1.5'),
          const DirectoryMod(ModKind.regular, ['Quiet rivers']),
        );
        await owner.modLibrary!.publish(mod, registered.revision, version);
        final inventory = await owner.modOrganization!.query(
          profile,
          const ModQuery(),
        );
        await owner.profileMods!.enable(profile, inventory.selectionRevision, [
          mod,
        ], true);
        await owner.gameContexts!.save(
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
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundary,
            child: ModConductorApp(
              workspaces: owner.workspaces,
              modLibrary: owner.modLibrary,
              profileMods: owner.profileMods,
              modOrganization: owner.modOrganization,
              gameContexts: owner.gameContexts,
              filePlans: owner.filePlans,
              bethesda: owner.bethesda,
              outputs: owner.outputs,
              deployments: owner.deployments,
              executables: owner.executables,
              gameLaunching: owner.gameLaunching,
              artifacts: owner.artifacts,
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
        final browser = tester.widget<ModLibraryBrowser>(
          find.byType(ModLibraryBrowser),
        );
        if (browser.controller.inventory.problem != null) {
          await tap(find.text('Retry').first);
        }
        await choosePlugins();
        await capture('initial');
        await tap(action('Scan plugins'));
        await until(() => plugins().state != null && !plugins().reading);
        expect(plugins().problem, isNull);
        final scan = plugins().state!;
        expect(
          scan.entries
              .firstWhere((p) => p.name == 'QuietRivers.esp')
              .winner!
              .versionId,
          version,
        );
        await capture('plugins');
        await tap(action('Filter plugins'));
        await tester.enterText(
          find.widgetWithText(TextField, 'Filter plugins'),
          'Quiet',
        );
        await tester.pumpAndSettle();
        await tap(find.text('QuietRivers.esp'));
        await tap(action('Inspect plugin'));
        await capture('details');
        await tap(action('Close inspector'));
        await tap(find.byKey(const ValueKey('nav-preferences')));
        await tap(find.byKey(const ValueKey('nav-workspaces')));
        // The workbench can restore its pane or rebuild it; neither path starts another header scan.
        if (find.byType(PluginsPane).evaluate().isEmpty) await choosePlugins();
        expect(plugins().state!.id, scan.id);
        expect(plugins().rows.query, 'Quiet');
        await tap(action('Close filter'));
        await tap(action('Filter plugins'));
        await tester.enterText(
          find.widgetWithText(TextField, 'Filter plugins'),
          'RiverPatch',
        );
        await tester.pumpAndSettle();
        await tap(find.text('RiverPatch.esp'));
        await tap(action('Inspect plugin'));
        await capture('missing');
        await tap(action('Close inspector'));
        await tap(action('Close filter'));
        // Use the existing enabled-mod control, not a new plugin activation API.
        if (narrow) {
          await tap(
            find.byWidgetPredicate(
              (w) => w is McChoice<String> && w.label == 'View',
            ),
          );
          await tap(find.text('Installed mods').last);
        }
        await tap(find.byType(Checkbox).first);
        await until(
          () => browser.controller.mods.ids
              .map((id) => browser.controller.mods[id]!)
              .any(
                (row) =>
                    row.mod.id == mod &&
                    row.selection is ManagedProfileMod &&
                    !(row.selection as ManagedProfileMod).enabled,
              ),
        );
        if (narrow) await choosePlugins();
        expect(plugins().stale, isTrue);
        await capture('stale');
        await tap(action('Refresh plugins'));
        await until(() => !plugins().reading && !plugins().stale);
        expect(plugins().state!.entries.map((p) => p.name), ['Skyrim.esm']);
        await capture('refreshed');
        await File('$output/result.json').writeAsString(
          jsonEncode({
            'sourceWinner': true,
            'navigationPreservesScan': true,
            'missingMasterVisible': true,
            'selectionRefresh': true,
          }),
        );
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        expect(await owner.close(), isTrue);
        FlutterError.onError = oldError;
      }
    },
  );
}
