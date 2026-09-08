import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_generated_outputs/mc_generated_outputs.dart';
import 'package:mc_generated_outputs/src/location_dialog.dart';
import 'package:mc_generated_outputs/src/promotion_dialog.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';
import 'package:mod_conductor/src/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets(
    'output review and deployment keep immutable publication separate from shared working files',
    (tester) async {
      tester.testTextInput.register();
      const engine = String.fromEnvironment('MC_ENGINE_PATH');
      const fixture = String.fromEnvironment('MC_NATIVE_FIXTURE');
      const output = String.fromEnvironment('MC_OUTPUTS_EVIDENCE');
      const narrow = bool.fromEnvironment('MC_OUTPUTS_NARROW');
      const windowGate = bool.fromEnvironment('MC_OUTPUTS_WINDOW_GATE');
      if (engine.isEmpty || fixture.isEmpty || output.isEmpty) {
        throw StateError(
          'Select native tools and an owned evidence directory.',
        );
      }
      final area = await Directory.systemTemp.createTemp('mc-outputs-ui-');
      await Directory(output).create(recursive: true);
      final root = await Directory('${area.path}/workspace').create();
      final inputs = '${area.path}/inputs';
      final seed = await Process.run(fixture, ['--proton-files', inputs]);
      expect(seed.exitCode, 0, reason: '${seed.stderr}');
      final library = '$inputs/Second library';
      final game = '$library/steamapps/common/Skyrim Special Edition';
      final owner = EngineOwner(
        engine,
        launch: (path) =>
            Process.start(path, ['--state-directory', '${area.path}/state']),
      );
      final boundary = GlobalKey();
      OutputController outputs() => tester
          .widget<DeploymentOutputsWorkbench>(
            find.byType(DeploymentOutputsWorkbench, skipOffstage: false),
          )
          .outputs;
      DeploymentController deployment() => tester
          .widget<DeploymentAction>(
            find.byType(DeploymentAction, skipOffstage: false),
          )
          .controller;
      Finder action(String text) =>
          find.byWidgetPredicate((w) => w is McAction && w.label == text);
      Finder icon(String text) =>
          find.byWidgetPredicate((w) => w is McIconAction && w.label == text);
      bool dark = false;
      Future<void> capture(String name) async {
        if (dark) name = name.replaceAll("-light", "-dark");
        await tester.pumpAndSettle();
        final image =
            await (boundary.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('$output/$name.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      }

      Future<void> until(bool Function() ready) async {
        final deadline = DateTime.now().add(const Duration(seconds: 40));
        while (!ready() && DateTime.now().isBefore(deadline)) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        if (!ready()) {
          await capture('failure');
          await File('$output/failure.json').writeAsString(
            jsonEncode({
              'outputs': outputs().problem,
              'needsRead': outputs().needsRead,
              'loading': outputs().loading,
              'reading': outputs().reading,
              'deployment': deployment().problem,
            }),
          );
        }
        expect(ready(), isTrue);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      Future<void> tap(Finder finder) async {
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
        await tester.tap(finder);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      String currentView = "Tool outputs";
      Future<void> view(String label) async {
        currentView = label;
        final choice = find.byWidgetPredicate(
          (w) =>
              w is McChoice<String> &&
              (w.label == 'Files' || w.label == 'View'),
        );
        await tap(choice);
        await tap(find.text(label).last);
      }

      Future<void> review(String label) async {
        if (narrow) {
          await tap(find.byTooltip('Review selected outputs'));
          await tap(find.text(label).last);
        } else {
          await tap(action(label));
        }
      }

      try {
        await owner.connect();
        final workspace = newOperationId(),
            profile = newOperationId(),
            mod = newOperationId(),
            version = newOperationId();
        await owner.workspaces!.create(
          workspace,
          'Output check workspace',
          root.path,
        );
        await owner.workspaces!.createProfile(
          workspace,
          0,
          ProfileInfo(profile, 'Everyday'),
        );
        final source = await Directory('${root.path}/source').create();
        await File('${source.path}/settings.txt')
            .writeAsString('Immutable settings');
        final registered = await owner.modLibrary!.register(
          workspace,
          mod,
          const ModMetadata(name: 'Settings', version: '1'),
          const DirectoryMod(ModKind.regular, ['source']),
        );
        await owner.modLibrary!.publish(mod, registered.revision, version);
        var inventory = await owner.modOrganization!.query(
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
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundary,
            child: ModConductorApp(
              workspaces: owner.workspaces,
              modLibrary: owner.modLibrary,
              profileMods: owner.profileMods,
              modOrganization: owner.modOrganization,
              filePlans: owner.filePlans,
              gameContexts: owner.gameContexts,
              steamDiscovery: owner.steamDiscovery,
              protonContexts: owner.protonContexts,
              outputs: owner.outputs,
              deployments: owner.deployments,
              status: DesktopConnected((owner.state as EngineConnected).report),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await File('$output/ready.json')
            .writeAsString(jsonEncode({'pid': pid, 'area': area.path}));
        if (windowGate) {
          final deadline = DateTime.now().add(const Duration(seconds: 40));
          while (!await File('$output/window-ready').exists() &&
              DateTime.now().isBefore(deadline)) {
            await tester.pump(const Duration(milliseconds: 100));
          }
          expect(await File('$output/window-ready').exists(), isTrue);
        }
        await tap(find.byKey(ValueKey('workspace-$workspace')));
        await tap(find.text('Mods'));
        await until(() => outputs().scope != null && !outputs().reading);
        if (narrow) {
          await tap(find.byKey(const ValueKey('nav-preferences')));
          await tap(find.byKey(const ValueKey('preferences-scale')));
          await tap(find.text('150%').last);
          await tap(find.byKey(const ValueKey('apply-preferences')));
          await tap(find.byKey(const ValueKey('nav-workspaces')));
        }
        await view('Tool outputs');
        await until(() => !outputs().loading && !outputs().reading);
        await capture('empty-light');
        await tap(action('Add tool folder'));
        await tester.enterText(
          find
              .descendant(
                of: find.byType(AddOutputLocationDialog),
                matching: find.byType(TextFormField),
              )
              .first,
          'Tool results',
        );
        await capture('add-folder-light');
        await tap(find.byKey(const ValueKey('submit')));
        await until(
          () =>
              !outputs().changing &&
              find.byType(AddOutputLocationDialog).evaluate().isEmpty,
        );
        final folder = (await owner.outputs!.read(workspace)).locations.single;
        await File('${folder.physicalPath}/generated.txt')
            .writeAsString('Generated bytes');
        await tap(icon('Refresh $currentView'));
        await until(
          () =>
              outputs().snapshot?.files == 1 &&
              !outputs().tools.loading &&
              !outputs().loading,
        );
        await tap(find.text('generated.txt').first);
        await capture('outputs-light');
        await tap(icon('Inspect output'));
        await capture('inspector-light');
        if (narrow) {
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await tester.pumpAndSettle();
          expect(outputs().inspected, isNull);
        } else {
          await tap(icon('Close inspector'));
        }
        await review('Create mod…');
        final promotion = find.byType(OutputPromotionDialog);
        await tester.enterText(
          find
              .descendant(of: promotion, matching: find.byType(TextFormField))
              .first,
          'Generated result',
        );
        await until(
          () =>
              tester
                  .widget<McAction>(find.byKey(const ValueKey('submit')))
                  .onPressed !=
              null,
        );
        await capture('promotion-light');
        await tap(find.byKey(const ValueKey('submit')));
        await until(() => !outputs().changing && promotion.evaluate().isEmpty);
        expect(
          await File('${folder.physicalPath}/generated.txt').exists(),
          isFalse,
        );
        inventory = await owner.modOrganization!.query(
          profile,
          const ModQuery(),
        );
        final generated = inventory.entries.singleWhere(
          (e) => e.mod.metadata.name == 'Generated result',
        );
        expect((generated.selection as ManagedProfileMod).enabled, isFalse);
        expect(generated.mod.versionOrigin?.outputActionId, isNotNull);
        await tap(icon('Refresh $currentView'));
        await until(
          () =>
              !outputs().loading &&
              !outputs().tools.loading &&
              outputs().snapshot?.files == 0,
        );
        await tap(find.byKey(const ValueKey('quick-theme')));
        dark = true;
        await capture('outputs-dark');
        await tap(icon('Tool output folders'));
        await capture('locations-dark');
        await tap(action('Close'));
        await view('Writable game files');
        await tap(action('Add writable file'));
        final fields = find.descendant(
          of: find.byType(AddOutputLocationDialog),
          matching: find.byType(TextFormField),
        );
        await tester.enterText(fields.at(0), 'Settings');
        await tester.enterText(fields.at(1), 'settings.txt');
        await capture('writable-declaration-light');
        await tap(find.byKey(const ValueKey('submit')));
        await until(
          () =>
              !outputs().changing &&
              find.byType(AddOutputLocationDialog).evaluate().isEmpty,
        );
        await tap(
          find.descendant(
            of: find.byType(DeploymentAction),
            matching: find.byType(McAction),
          ),
        );
        await until(() => deployment().canPrepare);
        await tap(action('Prepare deployment'));
        await until(() => deployment().prepared != null && !deployment().busy);
        await capture('prepared-light');
        await tap(action('Deploy'));
        await until(
          () =>
              !deployment().busy &&
              deployment().state?.active?.profile?.id == profile,
        );
        await capture('active-light');
        await tap(action('Close'));
        await File('$game/Data/settings.txt').writeAsString('Working settings');
        await tap(icon('Refresh $currentView'));
        await until(
          () =>
              !outputs().loading &&
              !outputs().writable.loading &&
              outputs().snapshot != null,
        );
        await tap(find.text('settings.txt').first);
        await capture('working-light');
        await review('Save copy to mod…');
        await tap(
          find.byWidgetPredicate(
            (w) => w is McChoice<String?> && w.label == 'Mod',
          ),
        );
        await tap(find.text('Settings').last);
        await until(
          () =>
              tester
                  .widget<McAction>(find.byKey(const ValueKey('submit')))
                  .onPressed !=
              null,
        );
        await capture('save-copy-light');
        await tap(find.byKey(const ValueKey('submit')));
        await until(
          () =>
              !outputs().changing &&
              find.byType(OutputPromotionDialog).evaluate().isEmpty,
        );
        expect(
          await File('$game/Data/settings.txt').readAsString(),
          'Working settings',
        );
        expect(
          await File('${source.path}/settings.txt').readAsString(),
          'Immutable settings',
        );
        await tap(icon('Refresh $currentView'));
        await until(() => !outputs().loading && !outputs().writable.loading);
        await tap(find.text('settings.txt').first);
        await review('Discard…');
        await capture('discard-light');
        await tap(find.byKey(const ValueKey('submit')));
        await until(() => !outputs().changing);
        await tap(icon('Refresh $currentView'));
        await until(() => !outputs().loading && !outputs().writable.loading);
        expect(await File('$game/Data/settings.txt').exists(), isFalse);
        await capture('absent-light');
        await tap(icon('Writable game files'));
        await tap(action('Stop using…'));
        await capture('stop-using-dark');
        await tap(find.byKey(const ValueKey('submit')));
        await until(
          () =>
              !outputs().changing &&
              outputs().scope!.locations.any(
                (location) =>
                    location.kind == OutputLocationKind.writableFile &&
                    location.status == OutputLocationStatus.stopped,
              ),
        );
        await tap(action('Close'));
        await tap(
          find.descendant(
            of: find.byType(DeploymentAction),
            matching: find.byType(McAction),
          ),
        );
        await until(() => deployment().canPrepare);
        await tap(action('Saved deployments…'));
        await until(
          () => !deployment().loadingSaved && deployment().saved.isNotEmpty,
        );
        await capture('saved-deployments-dark');
        await tap(action('Prepare').first);
        await until(() => deployment().prepared != null && !deployment().busy);
        await capture('saved-prepared-dark');
        await tap(action('Deploy'));
        await until(
          () =>
              !deployment().busy &&
              deployment().state?.active?.profile?.id == profile,
        );
        expect(
          await File('$game/Data/settings.txt').readAsString(),
          'Immutable settings',
        );
        await tap(action('Close'));

        await tap(
          find.descendant(
            of: find.byType(DeploymentAction),
            matching: find.byType(McAction),
          ),
        );
        await until(() => deployment().canPrepare);
        await tap(action('Deactivate…'));
        await tap(find.byKey(const ValueKey('submit')));
        await until(
          () =>
              !deployment().busy && deployment().state?.active?.profile == null,
        );
        await tap(action('Close'));
        final after = await owner.modOrganization!.query(
          profile,
          const ModQuery(),
        );
        expect(after.selectionRevision, inventory.selectionRevision);
        expect(
          after.entries
              .singleWhere((e) => e.mod.id == mod)
              .mod
              .currentVersionId,
          isNot(version),
        );
        await File('$output/result.json').writeAsString(
          jsonEncode({
            'createMovedAfterPublication': true,
            'createdDisabled': true,
            'saveCopyKeepsWorkingBytes': true,
            'registeredSourceUnchanged': true,
            'discardedAbsent': true,
            'configuredProfileUnchanged': true,
            'deactivated': true,
            'savedRestoreUsedOldPinAndCurrentStoppedSlot': true,
            'narrow': narrow,
            'captureWidth': boundary.currentContext!.size!.width,
            'captureHeight': boundary.currentContext!.size!.height,
          }),
        );
      } finally {
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        await owner.close();
        final normalized = await Process.run(fixture, [
          '--normalize-owned-fixture',
          area.path,
        ]);
        expect(normalized.exitCode, 0, reason: '${normalized.stderr}');
        await area.delete(recursive: true);
      }
    },
  );
}
