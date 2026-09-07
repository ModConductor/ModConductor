import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_mod_library/mc_mod_library.dart';
import 'package:mod_conductor/src/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'profile checkboxes and multi moves use the real engine without persisting display filters',
    (tester) async {
      tester.testTextInput.register();
      const engine = String.fromEnvironment('MC_ENGINE_PATH'),
          output = String.fromEnvironment('MC_COLLECTION_OUTPUT');
      if (engine.isEmpty || output.isEmpty) {
        throw StateError(
          'Select the native engine and owned output directory.',
        );
      }
      final evidence = await Directory(output).create(recursive: true),
          fixture = await Directory.systemTemp.createTemp('mc-profile-ui-');
      final root = '${fixture.path}/root';
      await Directory(root).create();
      final owner = EngineOwner(
        engine,
        launch: (path) =>
            Process.start(path, ['--state-directory', '${fixture.path}/state']),
      );
      final boundary = GlobalKey();
      Future<void> until(bool Function() condition) async {
        final deadline = DateTime.now().add(const Duration(seconds: 30));
        while (!condition() && DateTime.now().isBefore(deadline)) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(condition(), isTrue);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      ModLibraryController library() => tester
          .widget<ModLibraryBrowser>(
            find.byType(ModLibraryBrowser, skipOffstage: false),
          )
          .controller;
      Future<void> tap(Finder finder) async {
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      Future<void> capture(String name) async {
        await tester.pumpAndSettle();
        final image =
            await (boundary.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('${evidence.path}/$name.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      }

      try {
        await owner.connect();
        expect(
          (owner.state as EngineConnected).report.runtime.nativeAot,
          isTrue,
        );
        final workspace = newOperationId(), profile = newOperationId();
        await owner.workspaces!.create(workspace, 'Weekend', root);
        await owner.workspaces!.createProfile(
          workspace,
          0,
          ProfileInfo(profile, 'Everyday'),
        );
        final ids = <String>[];
        for (final name in [
          'Verdant paths',
          'Weathered stonework',
          'Hearthlight interiors',
          'Wild skies',
          'Mountain textures',
        ]) {
          final id = newOperationId();
          ids.add(id);
          await Directory('$root/$id/textures').create(recursive: true);
          await File('$root/$id/textures/stone.txt')
              .writeAsString('Original file');
          await owner.modLibrary!.register(
            workspace,
            id,
            ModMetadata(name: name, version: '1.0'),
            DirectoryMod(ModKind.regular, [id]),
          );
        }
        await owner.modLibrary!.publish(ids[1], 0, newOperationId());
        await owner.modLibrary!.register(
          workspace,
          newOperationId(),
          const ModMetadata(name: 'Landscape'),
          const SeparatorMod(),
        );
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundary,
            child: ModConductorApp(
              workspaces: owner.workspaces,
              modLibrary: owner.modLibrary,
              profileMods: owner.profileMods,
              status: DesktopConnected((owner.state as EngineConnected).report),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tap(find.byKey(ValueKey('workspace-$workspace')));
        await tap(find.text('Mods').last);
        await until(() => !library().inventory.loading);
        final table = find.byKey(const ValueKey('installed-mods'));
        Finder row(int index) => find.byKey(ValueKey((modId: ids[index])));
        await tap(find.descendant(of: row(0), matching: find.byType(Checkbox)));
        await until(() => !library().inventory.changing);
        expect(
          (await owner.profileMods!.find(profile, ids[0])).entry.selection,
          isA<ManagedProfileMod>().having((s) => s.enabled, 'enabled', isTrue),
        );
        await tap(row(1));
        await until(() => !library().loadingFiles);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tap(row(2));
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        expect(library().mods.selectedIds, {(modId: ids[1]), (modId: ids[2])});
        final revision = library().inventory.revision!;
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await until(() => !library().inventory.changing);
        expect(library().inventory.revision, revision + 1);
        expect(
          (await owner.profileMods!.find(
            profile,
            ids[1],
          )).entry.selection.priority,
          0,
        );
        expect(
          (await owner.profileMods!.find(
            profile,
            ids[2],
          )).entry.selection.priority,
          1,
        );
        await tap(find.descendant(of: table, matching: find.text('Enable')));
        await until(() => !library().inventory.changing);
        expect(library().inventory.enabledCount, 3);
        await tester.enterText(
          find.descendant(of: table, matching: find.byType(TextField)),
          'Hearthlight',
        );
        await tester.pumpAndSettle();
        expect(library().inventory.hiddenSelected, 1);
        final filteredRevision = library().inventory.revision!;
        await tap(row(2));
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await until(() => !library().inventory.changing);
        expect(library().inventory.revision, filteredRevision + 1);
        expect(
          (await owner.profileMods!.find(
            profile,
            ids[2],
          )).entry.selection.priority,
          2,
        );
        await capture('profile-mods-filtered-light');
        await tester.enterText(
          find.descendant(of: table, matching: find.byType(TextField)),
          '',
        );
        await tester.pumpAndSettle();
        await tap(row(1));
        await until(() => !library().loadingFiles);
        expect(library().fileCount, 1);
        await capture('profile-mods-light');
        await tap(find.byKey(const ValueKey('quick-theme')));
        await capture('profile-mods-dark');
        await tap(find.byKey(const ValueKey('nav-preferences')));
        await tap(find.byKey(const ValueKey('preferences-scale')));
        await tap(find.text('150%').last);
        await tap(find.byKey(const ValueKey('apply-preferences')));
        await tap(find.byKey(const ValueKey('nav-workspaces')));
        await tester.binding.setSurfaceSize(const Size(720, 900));
        await tester.pumpAndSettle();
        await capture('profile-mods-dark-narrow150');
        await tap(find.text('Saved files').last);
        await capture('profile-files-dark-narrow150');
        await tap(find.byKey(const ValueKey('quick-theme')));
        await capture('profile-files-light-narrow150');
        expect(
          await File('$root/${ids[1]}/textures/stone.txt').readAsString(),
          'Original file',
        );
      } finally {
        tester.testTextInput.unregister();
        await tester.binding.setSurfaceSize(null);
        await tester.pumpWidget(const SizedBox.shrink());
        expect(await owner.close(), isTrue);
        if (Platform.isWindows) {
          await Process.run('attrib', ['-R', '$root/*.payload', '/S']);
        }
        await fixture.delete(recursive: true);
      }
    },
  );
}
