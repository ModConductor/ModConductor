import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_mod_library/mc_mod_library.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';
import 'package:mod_conductor/src/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'category drafts filters and group context use the actual engine without changing profile selection',
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
          fixture = await Directory.systemTemp.createTemp(
            'mc-organization-ui-',
          );
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

      Future<void> tap(Finder finder) async {
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      ModLibraryController library() => tester
          .widget<ModLibraryBrowser>(
            find.byType(ModLibraryBrowser, skipOffstage: false),
          )
          .controller;
      Future<void> loaded() => until(
        () => !library().inventory.loading && !library().inventory.changing,
      );
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
        final workspace = newOperationId(),
            profile = newOperationId(),
            textures = newOperationId(),
            lighting = newOperationId();
        await owner.workspaces!.create(workspace, 'Weekend', root);
        await owner.workspaces!.createProfile(
          workspace,
          0,
          ProfileInfo(profile, 'Everyday'),
        );
        final organization = owner.modOrganization!;
        final revision = (await organization.categories(workspace)).revision;
        final changed = await organization.createCategory(
          workspace,
          revision,
          textures,
          'Textures',
        );
        await organization.createCategory(
          workspace,
          changed,
          lighting,
          'Lighting',
        );
        final group = await owner.modLibrary!.register(
          workspace,
          newOperationId(),
          const ModMetadata(name: 'Visuals'),
          const SeparatorMod(),
        );
        final ids = <String>[];
        for (final (name, category) in [
          ('Stonework', textures),
          ('Lamp', lighting),
        ]) {
          final id = newOperationId();
          ids.add(id);
          await Directory('$root/$id').create();
          await owner.modLibrary!.register(
            workspace,
            id,
            ModMetadata(
              name: name,
              version: '1.0',
              categories: [
                CategoryReference(
                  category,
                  category == textures ? 'Textures' : 'Lighting',
                ),
              ],
            ),
            DirectoryMod(ModKind.regular, [id]),
          );
        }
        final unselected = await organization.query(profile, const ModQuery());
        await owner.profileMods!.enable(profile, unselected.selectionRevision, [
          ids[1],
        ], true);
        final initial = await organization.query(profile, const ModQuery());
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundary,
            child: ModConductorApp(
              workspaces: owner.workspaces,
              modLibrary: owner.modLibrary,
              profileMods: owner.profileMods,
              modOrganization: organization,
              status: DesktopConnected((owner.state as EngineConnected).report),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tap(find.byKey(ValueKey('workspace-$workspace')));
        await tap(find.text('Mods').last);
        await loaded();
        await tap(find.byKey(ValueKey((modId: ids[0]))));
        await tap(
          find.byWidgetPredicate(
            (widget) =>
                widget is McIconAction && widget.label == 'Edit mod details',
          ),
        );
        await tap(find.widgetWithText(TextButton, 'Categories'));
        await tap(
          find.descendant(
            of: find.byKey(ValueKey(lighting)),
            matching: find.byType(Checkbox),
          ),
        );
        await capture('category-draft-light');
        await tap(find.byKey(const ValueKey('submit')).last);
        await tap(find.widgetWithText(McAction, 'Cancel').last);
        final draft = await organization.query(
          profile,
          const ModQuery(),
          inspectedId: ids[0],
        );
        expect(
          draft.inspected!.mod.metadata.categories.map((value) => value.id),
          [textures],
        );
        expect(draft.catalogueRevision, initial.catalogueRevision);
        await tap(find.widgetWithText(TextButton, 'Filters'));
        await tap(find.text('Add filter'));
        await tap(find.text('Category').last);
        await tap(find.byKey(ValueKey(textures)));
        await tap(find.widgetWithText(McAction, 'Choose'));
        await tap(find.text('Add filter'));
        await tap(find.widgetWithText(MenuItemButton, 'Enabled'));
        await capture('filters-all-light');
        await tap(find.byKey(const ValueKey('submit')).last);
        await loaded();
        expect(library().mods.visible, isEmpty);
        final table = find.byKey(const ValueKey('installed-mods'));
        await tap(
          find.descendant(
            of: table,
            matching: find.widgetWithText(TextButton, 'Filters (2)'),
          ),
        );
        await tap(
          find.byWidgetPredicate(
            (widget) => widget is McChoice && widget.label == 'Match',
          ),
        );
        await tap(find.text('Any filter').last);
        await tap(find.byKey(const ValueKey('submit')).last);
        await loaded();
        await tap(
          find.byWidgetPredicate(
            (widget) =>
                widget is McIconMenu &&
                widget.label == 'Installed mods options',
          ),
        );
        await tap(find.text('Group by separators').last);
        await loaded();
        expect(library().inventory.matchingMods, 2);
        expect(library().inventory.matchingSeparators, 0);
        expect(library().mods[(modId: group.id)]!.groupSize!.matching, 2);
        expect(library().mods.visible.toSet(), {
          (modId: group.id),
          (modId: ids[0]),
          (modId: ids[1]),
        });
        await capture('groups-light');
        await tap(
          find.descendant(
            of: table,
            matching: find.widgetWithText(TextButton, 'Name'),
          ),
        );
        await loaded();
        expect(library().inventory.canMove, isFalse);
        await tester.enterText(
          find.descendant(of: table, matching: find.byType(TextField)),
          'no matching metadata',
        );
        await tester.pump(const Duration(milliseconds: 300));
        await loaded();
        expect(library().mods.visible, isEmpty);
        expect(library().mods.selectedId, (modId: ids[0]));
        expect(library().inventory.loaded, 0);
        await capture('filtered-empty-light');
        await tap(find.byKey(const ValueKey('quick-theme')));
        await tap(find.byKey(const ValueKey('nav-preferences')));
        await tap(find.byKey(const ValueKey('preferences-scale')));
        await tap(find.text('150%').last);
        await tap(find.byKey(const ValueKey('apply-preferences')));
        await tap(find.byKey(const ValueKey('nav-workspaces')));
        await tester.binding.setSurfaceSize(const Size(720, 900));
        await tester.pumpAndSettle();
        await capture('filtered-empty-dark-narrow150');
        await tap(find.widgetWithText(TextButton, 'Filters (2)'));
        await capture('filters-dark-narrow150');
        await tap(find.widgetWithText(McAction, 'Cancel').last);
        await tap(
          find.byWidgetPredicate(
            (widget) =>
                widget is McIconMenu &&
                widget.label == 'Installed mods options',
          ),
        );
        await tap(find.text('Manage categories').last);
        await capture('categories-dark-narrow150');
        await tap(find.widgetWithText(McAction, 'Close'));
        final finalState = await organization.query(profile, const ModQuery());
        expect(finalState.catalogueRevision, initial.catalogueRevision);
        expect(finalState.selectionRevision, initial.selectionRevision);
        expect(
          finalState.entries.map(
            (row) => (
              row.mod.id,
              row.selection.priority,
              row.selection is ManagedProfileMod
                  ? (row.selection as ManagedProfileMod).enabled
                  : null,
            ),
          ),
          initial.entries.map(
            (row) => (
              row.mod.id,
              row.selection.priority,
              row.selection is ManagedProfileMod
                  ? (row.selection as ManagedProfileMod).enabled
                  : null,
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      } finally {
        tester.testTextInput.unregister();
        await tester.binding.setSurfaceSize(null);
        await tester.pumpWidget(const SizedBox.shrink());
        expect(await owner.close(), isTrue);
        await fixture.delete(recursive: true);
      }
    },
  );
}
