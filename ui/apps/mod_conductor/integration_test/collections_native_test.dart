import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_mod_library/mc_mod_library.dart';
import 'package:mc_workspaces/mc_workspaces.dart';
import 'package:mod_conductor/src/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets(
    'profiles and installed mods use stable collections with real paged saved files',
    (tester) async {
      tester.testTextInput.register();
      const executable = String.fromEnvironment('MC_ENGINE_PATH');
      const fixtureTool = String.fromEnvironment('MC_NATIVE_FIXTURE');
      const output = String.fromEnvironment('MC_COLLECTION_OUTPUT');
      if (executable.isEmpty || fixtureTool.isEmpty || output.isEmpty) {
        throw StateError(
          'Select the native engine, fixture, and an owned output directory.',
        );
      }
      final evidence = await Directory(output).create(recursive: true);
      final fixture = await Directory('${evidence.path}/s').create();
      final workspacePath = '${fixture.path}/workspace';
      final sourcePath = '$workspacePath/source';
      final inputs = '${fixture.path}/inputs';
      final game =
          '$inputs/Second library/steamapps/common/Skyrim Special Edition';
      final prepared = await Process.run(fixtureTool, [
        '--proton-files',
        inputs,
      ]);
      expect(prepared.exitCode, 0, reason: '${prepared.stderr}');
      await Directory('$sourcePath/textures').create(recursive: true);
      for (var i = 0; i < 70; i++) {
        await File(
          '$sourcePath/textures/file-${i.toString().padLeft(3, '0')}.txt',
        ).writeAsString('Original $i');
      }
      final owner = EngineOwner(
        executable,
        launch: (path) =>
            Process.start(path, ['--state-directory', '${fixture.path}/state']),
      );
      final boundary = GlobalKey();
      Future<void> until(bool Function() condition) async {
        final end = DateTime.now().add(const Duration(seconds: 30));
        while (!condition() && DateTime.now().isBefore(end)) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(condition(), isTrue);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      Future<void> tap(Key key) async {
        await tester.tap(find.byKey(key));
        await tester.pumpAndSettle();
      }

      ModLibraryController library() => tester
          .widget<ModLibraryBrowser>(
            find.byType(ModLibraryBrowser, skipOffstage: false),
          )
          .controller;
      WorkspaceController workspaces() => tester
          .widget<WorkspaceBrowser>(find.byType(WorkspaceBrowser))
          .controller;
      Future<void> capture(String name) async {
        await tester.pumpAndSettle();
        final render =
            boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await render.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('${evidence.path}/$name.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      }

      try {
        await owner.connect();
        expect(owner.state, isA<EngineConnected>());
        expect(
          (owner.state as EngineConnected).report.runtime.nativeAot,
          isTrue,
        );
        final workspaceId = newOperationId(), profileId = newOperationId();
        await owner.workspaces!.create(workspaceId, 'Weekend', workspacePath);
        await owner.workspaces!.createProfile(
          workspaceId,
          0,
          ProfileInfo(profileId, 'Everyday'),
        );
        await owner.gameContexts!.save(
          workspaceId,
          profileId,
          'skyrim-se-steam',
          0,
          game,
          proton: Platform.isLinux
              ? ProtonSelection(
                  appId: 489830,
                  association: SteamProtonAssociation(
                    '$inputs/Steam',
                    '$inputs/Second library',
                  ),
                  compatData:
                      '$inputs/Second library/steamapps/compatdata/489830',
                  runtimeDirectory:
                      '$inputs/Steam/compatibilitytools.d/Custom Ω Proton',
                  toolId: 'fixture_tool',
                )
              : null,
        );
        for (var i = 0; i < 34; i++) {
          await owner.modLibrary!.register(
            workspaceId,
            newOperationId(),
            ModMetadata(name: 'Separator $i'),
            const SeparatorMod(),
          );
        }
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundary,
            child: ModConductorApp(
              workspaces: owner.workspaces,
              modLibrary: owner.modLibrary,
              profileMods: owner.profileMods,
              modOrganization: owner.modOrganization,
              gameContexts: owner.gameContexts,
              settings: owner.settings,
              status: DesktopConnected((owner.state as EngineConnected).report),
              chooseDirectory: (_) async => sourcePath,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tap(ValueKey('workspace-$workspaceId'));
        await until(() => workspaces().canEdit && !library().inventory.loading);
        await tap(ValueKey((profileId: profileId)));
        expect(workspaces().workspace!.selectedProfile!.id, profileId);
        await capture('profiles-light');
        await tester.tap(find.text('Mods'));
        await tester.pumpAndSettle();
        await tap(const ValueKey('add-mod'));
        await tester.enterText(
          find.byKey(const ValueKey('name')),
          'Weathered stonework — textures and local notes',
        );
        await tester.tap(find.byIcon(Icons.folder_open).last);
        await tester.pumpAndSettle();
        await capture('folder-selected-light');
        await tap(const ValueKey('submit'));
        await capture('after-submit-light');
        await until(
          () =>
              library().mods.ids.any(
                (id) => library().mods[id]!.mod.kind == ModKind.regular,
              ) ||
              library().actionProblem != null,
        );
        expect(library().actionProblem, isNull);
        await capture('added-mod-light');
        while (!library().inventory.complete) {
          final more = find.descendant(
            of: find.byKey(const ValueKey('installed-mods')),
            matching: find.text('Load more'),
          );
          await tester.tap(more);
          await until(() => !library().inventory.loading);
        }
        final registered = (await owner.modOrganization!.query(
          profileId,
          const ModQuery(),
        )).entries;
        expect(registered, isNotEmpty);
        final entry = library().mods.ids
            .map((id) => library().mods[id]!)
            .singleWhere((row) => row.mod.kind == ModKind.regular);
        final installedMods = find.byKey(const ValueKey('installed-mods'));
        final modFilter = find.descendant(
          of: installedMods,
          matching: find.byType(TextField),
        );
        if (modFilter.evaluate().isEmpty) {
          await tester.tap(
            find.descendant(
              of: installedMods,
              matching: find.byTooltip('Filter mods'),
            ),
          );
          await tester.pumpAndSettle();
        }
        expect(modFilter, findsOneWidget);
        await tester.enterText(modFilter, 'Weathered');
        await tester.pumpAndSettle();
        await tap(ValueKey((modId: entry.mod.id)));
        expect(library().mods.selected!.mod.id, entry.mod.id);
        await tester.tap(find.text('Save version'));
        await until(
          () => library().activity == null && !library().loadingFiles,
        );
        expect(library().actionProblem, isNull);
        expect(library().fileCount, 64);
        expect(library().filesComplete, isFalse);
        await capture('partial-light');
        await tester.tap(
          find.descendant(
            of: find.byKey(const ValueKey('saved-files')),
            matching: find.text('Load more'),
          ),
        );
        await until(() => !library().loadingFiles);
        expect(library().fileCount, 70);
        expect(library().filesComplete, isTrue);
        final pinned = library().selectedVersionId;
        final fileId = library().files.visible.last;
        final fileFinder = find.byKey(ValueKey(fileId));
        await tester.scrollUntilVisible(
          fileFinder,
          300,
          scrollable: find
              .descendant(
                of: find.byKey(const ValueKey('saved-files')),
                matching: find.byType(Scrollable),
              )
              .last,
        );
        await tester.tap(fileFinder);
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(
          LogicalKeyboardKey.home,
          physicalKey: PhysicalKeyboardKey.home,
        );
        await tester.pumpAndSettle();
        final focused = library().files.focusedId;
        await library().inventory.load(refresh: true);
        await tester.pumpAndSettle();
        expect(library().selectedVersionId, pinned);
        expect(library().files.focusedId, focused);
        await capture('mods-light');
        await tap(const ValueKey('quick-theme'));
        await capture('mods-dark');
        await tap(const ValueKey('nav-preferences'));
        await tap(const ValueKey('preferences-scale'));
        await tester.tap(find.text('150%').last);
        await tester.pumpAndSettle();
        await tap(const ValueKey('apply-preferences'));
        await tap(const ValueKey('nav-workspaces'));
        await tester.binding.setSurfaceSize(const Size(720, 900));
        await tester.pumpAndSettle();
        await capture('mods-dark-narrow150');
        await tester.tap(find.text('Saved files').last);
        await tester.pumpAndSettle();
        expect(library().selectedVersionId, pinned);
        expect(library().files.focusedId, focused);
        await capture('files-dark-narrow150');
        await tap(const ValueKey('quick-theme'));
        await capture('files-light-narrow150');
        expect(
          await File('$sourcePath/textures/file-000.txt').readAsString(),
          'Original 0',
        );
        expect(tester.takeException(), isNull);
      } finally {
        tester.testTextInput.unregister();
        await tester.binding.setSurfaceSize(null);
        await tester.pumpWidget(const SizedBox.shrink());
        expect(await owner.close(), isTrue);
        if (Platform.isWindows) {
          await Process.run('attrib', ['-R', '$workspacePath/*.payload', '/S']);
        }
        await fixture.delete(recursive: true);
      }
    },
  );
}
