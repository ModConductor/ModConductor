import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mc_bethesda/mc_bethesda.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_mod_library/mc_mod_library.dart';
import 'package:mc_executables/mc_executables.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';
import 'package:mod_conductor/src/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets(
    'plugin order edits use saved profile state and the existing application owner',
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
        '--plugin-order-files',
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
      Finder action(String label) {
        final found = find.byWidgetPredicate(
          (w) =>
              (w is McAction && w.label == label) ||
              (w is McIconAction && w.label == label),
        );
        final inspector = find.byType(McInspector);
        return inspector.evaluate().isEmpty
            ? found
            : find.descendant(of: inspector, matching: found);
      }

      Future<void> tap(Finder finder, {bool up = false}) async {
        if (finder.evaluate().isEmpty &&
            find.byType(McInspector).evaluate().isNotEmpty) {
          await tester.scrollUntilVisible(
            finder,
            up ? -180 : 180,
            scrollable: find
                .descendant(
                  of: find.byType(McInspector),
                  matching: find.byType(Scrollable),
                )
                .first,
          );
        }
        await Scrollable.ensureVisible(
          tester.element(finder.last),
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        );
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
              pluginOrders: owner.pluginOrders,
              profileData: owner.profileData,
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
        expect(plugins().order, isNotNull);
        final local =
            '$inputs/Second library/steamapps/compatdata/489830/pfx/drive_c/users/steamuser/AppData/Local/Skyrim Special Edition';
        expect(Directory(local).existsSync(), isFalse);
        await capture('order');
        Future<void> filter(String value) async {
          if (plugins().rows.query.isNotEmpty) {
            await tap(action('Close filter'));
          }
          await tap(action('Filter plugins'));
          await tester.enterText(
            find.widgetWithText(TextField, 'Filter plugins'),
            value,
          );
          await tester.pumpAndSettle();
        }

        Future<void> selected(String name) async {
          await filter(name);
          await tap(find.text(name));
        }

        Future<void> edited() async {
          await until(() => !plugins().writing);
          expect(plugins().problem, isNull);
        }

        await selected('QuietRivers.esp');
        await tap(action('Inspect plugin'));
        await tap(action('Enable'));
        await edited();
        expect(plugins().setting('QuietRivers.esp')!.enabled, isTrue);
        expect(Directory(local).existsSync(), isTrue);
        expect(File('$local/Plugins.txt').existsSync(), isFalse);
        await capture('saved-details');
        await tap(action('Close inspector'), up: true);
        await selected('RoadSigns.esp');
        await tap(action('Inspect plugin'));
        await tap(action('Enable'));
        await edited();
        await tap(action('Lock load position'));
        await edited();
        expect(plugins().setting('RoadSigns.esp')!.lockedIndex, isNotNull);
        await capture('locked');
        await tap(action('Unlock load position'));
        await edited();
        await tap(action('Close inspector'), up: true);
        await selected('RiverPatch.esp');
        await tap(action('Inspect plugin'));
        await tap(action('Enable'));
        await edited();
        expect(plugins().order!.issues, isNotEmpty);
        await capture('missing-correction');
        await tap(action('Disable'));
        await edited();
        expect(plugins().order!.issues, isEmpty);
        await tap(action('Close inspector'), up: true);
        await tap(action('Close filter'));
        await tap(find.widgetWithText(TextButton, 'Plugin'));
        expect(plugins().rows.sortLabel, 'Plugin');
        expect(plugins().canMove, isFalse);
        await capture('sorted');
        Future<void> menu(String value) async {
          await tap(
            find.byWidgetPredicate(
              (w) => w is McIconMenu<String> && w.label == 'Plugin actions',
            ),
          );
          await tap(find.text(value).last);
        }

        await menu('Show load order');
        await selected('QuietRivers.esp');
        await tap(action('Close filter'));
        final before = plugins().position('QuietRivers.esp');
        await tap(action('Move selected plugins down (Ctrl+Down)'));
        await edited();
        expect(plugins().position('QuietRivers.esp'), greaterThan(before));
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pumpAndSettle();
        await edited();
        expect(
          plugins().position('QuietRivers.esp'),
          greaterThan(plugins().position('RoadSigns.esp')),
        );
        await capture('reordered');
        final revision = plugins().order!.reference.revision;
        final snapshot = plugins().state!.id;
        await tap(find.byKey(const ValueKey('nav-preferences')));
        await tap(find.byKey(const ValueKey('nav-workspaces')));
        if (find.byType(PluginsPane).evaluate().isEmpty) await choosePlugins();
        expect(plugins().state!.id, snapshot);
        expect(plugins().order!.reference.revision, revision);
        await capture('returned');
        await Process.run('chmod', ['u-w', local]);
        try {
          await tap(action('Play'));
          await until(() {
            final play = tester
                .widget<GamePlayDialog>(find.byType(GamePlayDialog))
                .controller;
            return play.run?.phase == ExecutableRunPhase.failed &&
                !play.starting;
          });
          await capture('application-failed');
          await tap(action('Close'));
        } finally {
          await Process.run('chmod', ['u+w', local]);
        }
        await tap(action('Refresh plugins'));
        await until(
          () => !plugins().reading && plugins().order?.pending == true,
        );
        await capture('incomplete');
        await tap(action('Resume'));
        await until(
          () => !plugins().reading && plugins().order?.applied == true,
        );
        expect(plugins().order!.pending, isFalse);
        await capture('resumed');
        // The inert local runtime completes the normal Play preparation without a game process.
        await tap(action('Play'));
        await until(() {
          final play = tester
              .widget<GamePlayDialog>(find.byType(GamePlayDialog))
              .controller;
          return play.run != null && !play.active && !play.starting;
        });
        final play = tester
            .widget<GamePlayDialog>(find.byType(GamePlayDialog))
            .controller;
        expect(play.problem, isNull);
        expect(play.run!.phase, ExecutableRunPhase.finished);
        expect(File('$local/Plugins.txt').existsSync(), isTrue);
        await capture('run-finished');
        await tap(action('Close'));
        await tap(action('Refresh plugins'));
        await until(
          () => !plugins().reading && plugins().order?.applied == true,
        );
        expect(plugins().problem, isNull);
        final applied = await File('$local/Plugins.txt').readAsString();
        expect(
          applied.indexOf('*RoadSigns.esp'),
          lessThan(applied.indexOf('*QuietRivers.esp')),
        );
        await capture('applied');
        await File('$local/Plugins.txt')
            .writeAsString('# external entry\n', mode: FileMode.append);
        await tap(action('Refresh plugins'));
        await until(() => !plugins().reading);
        expect(plugins().order!.externalChanged, isTrue);
        await capture('external');
        await tap(action('Use game order'));
        await edited();
        expect(plugins().order!.externalChanged, isFalse);
        expect(
          await File('$local/Plugins.txt').readAsString(),
          '$applied# external entry\n',
        );
        await capture('adopted');
        await File('$output/result.json').writeAsString(
          jsonEncode({
            'readDoesNotCreateTitleFolder': true,
            'explicitEditCreatesKnownTitleLeaf': true,
            'enableAndLockSavedWithoutGameFileWrite': true,
            'invalidActiveSetCorrectable': true,
            'displaySortDoesNotReorder': true,
            'keyboardAndButtonReorder': true,
            'navigationRetainsSavedOrder': true,
            'failedApplicationResumesThroughExistingControl': true,
            'normalPlayAppliesOrderedList': true,
            'externalConflictAndExplicitAdoption': true,
            'syntheticRuntimeOnly': true,
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
