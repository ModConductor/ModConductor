import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_artifacts/src/installation_controller.dart';
import 'package:mc_artifacts/src/installation_file_collection.dart';
import 'package:mc_artifacts/src/installation_tree.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_collections/mc_ui_collections.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'support/manual_archive.dart';

Finder row(String path) => find.byKey(ValueKey(path));
Finder checkbox(String path) =>
    find.descendant(of: row(path), matching: find.byType(Checkbox));

Future<void> collapse(WidgetTester tester, String path) async {
  final expander = find.descendant(
    of: row(path),
    matching: find.byType(McCollectionExpander<String, InstallationRow>),
  );
  await tester.ensureVisible(expander);
  await tester.pumpAndSettle();
  await tester.tap(expander);
  // Rows also support double-click expansion; let that gesture resolve.
  await tester.pump(const Duration(milliseconds: 350));
  await tester.pumpAndSettle();
  expect(manualCollection(tester).tree.model.expanded(path), isFalse);
}

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;

  for (final size in [const Size(1400, 900), const Size(640, 900)]) {
    testWidgets('checkbox reply retains nested expansion at ${size.width}', (
      tester,
    ) async {
      final client = ManualInstallations();
      await openManualArchive(tester, client, size: size);
      final model = manualCollection(tester).tree.model;
      await collapse(tester, 'Data/meshes/actors');
      await collapse(tester, 'Data/textures');
      expect(model.expanded('Data/meshes'), isTrue);
      expect(model.expanded('Data/meshes/armor'), isTrue);
      expect(checkbox('Data/meshes/armor/armor.nif'), findsOneWidget);
      await tester.tap(checkbox('Data/meshes/armor/armor.nif'));
      await tester.pump();
      final change =
          client.changes.single.change as InstallationInclusionChange;
      expect(change.source, ['Data', 'meshes', 'armor', 'armor.nif']);
      expect(change.included, isTrue);
      expect(
        tester.widget<McAction>(manualAction('Select all')).onPressed,
        isNull,
      );
      expect(
        tester
            .widget<Checkbox>(checkbox('Data/meshes/armor/armor.nif'))
            .onChanged,
        isNull,
      );
      final reply = manualDraft(
        revision: 1,
        files: const [
          InstallationFile(0, ['custom', 'body.nif']),
          InstallationFile(1, ['meshes', 'armor', 'armor.nif']),
          InstallationFile(2, ['textures', 'skin.dds']),
        ],
      );
      client.replies.single.complete(reply);
      await tester.pumpAndSettle();
      expect(manualCollection(tester).draft, same(reply));
      expect(manualCollection(tester).tree.model, same(model));
      expect(model.expanded('Data/meshes/actors'), isFalse);
      expect(model.expanded('Data/textures'), isFalse);
      expect(model.expanded('Data/meshes'), isTrue);
      expect(model.expanded('Data/meshes/armor'), isTrue);
      expect(checkbox('Data/meshes/actors/body.nif'), findsNothing);
      expect(checkbox('Data/textures/skin.dds'), findsNothing);
      expect(
        tester.widget<Checkbox>(checkbox('Data/meshes/armor/armor.nif')).value,
        isTrue,
      );
      expect(client.starts, isEmpty);
      expect(tester.takeException(), isNull);

      // A review/manual round trip also must not reopen an evicted source ID.
      await tester.tap(manualAction('Review'));
      await tester.pumpAndSettle();
      expect(manualAction('Select all'), findsNothing);
      await tester.tap(manualAction('Change layout'));
      await tester.pumpAndSettle();
      expect(model.expanded('Data/meshes/actors'), isFalse);
      expect(model.expanded('Data/textures'), isFalse);
    });

    testWidgets('Select all edits the whole archive at ${size.width}', (
      tester,
    ) async {
      final client = ManualInstallations();
      await openManualArchive(tester, client, size: size);
      final model = manualCollection(tester).tree.model;
      await collapse(tester, 'Data/meshes');
      await collapse(tester, 'Extras');
      if (size.width < 1100) {
        await tester.tap(manualAction('Filter files'));
        await tester.pumpAndSettle();
      }
      await tester.enterText(find.byType(TextField), 'skin.dds');
      await tester.pumpAndSettle();
      expect(model.visible, [
        'Data',
        'Data/textures',
        'Data/textures/skin.dds',
      ]);
      await tester.tap(manualAction('Select all'));
      await tester.pump();
      final sent = client.changes.single;
      final change = sent.change as InstallationInclusionChange;
      expect(change.source, isEmpty);
      expect(change.included, isTrue);
      expect(sent.draft.files.first.destination, ['custom', 'body.nif']);
      // Busy clicks cannot duplicate the archive-wide operation.
      await tester.tap(manualAction('Select all'));
      await tester.pump();
      expect(client.changes, hasLength(1));
      final reply = manualDraft(
        revision: 1,
        files: const [
          InstallationFile(0, ['custom', 'body.nif']),
          InstallationFile(1, ['meshes', 'armor', 'armor.nif']),
          InstallationFile(2, ['textures', 'skin.dds']),
          InstallationFile(3, ['readme.txt']),
          InstallationFile(4, ['Extras', 'license.txt']),
        ],
      );
      client.replies.single.complete(reply);
      await tester.pumpAndSettle();
      expect(manualCollection(tester).draft, same(reply));
      expect(
        model.ids
            .where((id) => !model.branch(id))
            .map((id) => model[id]!.included),
        everyElement(isTrue),
      );
      expect(model['Data/meshes/actors/body.nif']!.destination, [
        'custom',
        'body.nif',
      ]);
      expect(model['Extras/license.txt']!.destination, [
        'Extras',
        'license.txt',
      ]);
      expect(model.query, 'skin.dds');
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();
      expect(model.expanded('Data/meshes'), isFalse);
      expect(model.expanded('Extras'), isFalse);
      expect(checkbox('Data/meshes/armor/armor.nif'), findsNothing);
      expect(checkbox('Extras/license.txt'), findsNothing);
      expect(client.starts, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('an admitted operation blocks manual archive edits', (
    tester,
  ) async {
    final client = ManualInstallations();
    final draft = manualDraft();
    final controller = InstallationController(client, manualArchive, () {})
      ..draft = draft
      ..startId = 'admitted';
    final tree = InstallationTree()
      ..apply(draft, manual: true, excluded: false);
    addTearDown(controller.dispose);
    addTearDown(tree.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: mcTheme(Brightness.dark),
        home: Scaffold(
          body: InstallationFileCollection(
            draft: draft,
            tree: tree,
            controller: controller,
            manual: true,
            excluded: false,
            narrow: true,
            onLayout: (_) {},
            onExcluded: (_) {},
            onInspect: () {},
          ),
        ),
      ),
    );
    expect(
      tester.widget<McAction>(manualAction('Select all')).onPressed,
      isNull,
    );
    expect(tester.widget<Checkbox>(checkbox('Data')).onChanged, isNull);
    await tester.tap(manualAction('Select all'));
    await tester.tap(checkbox('Data'));
    await tester.pumpAndSettle();
    expect(client.changes, isEmpty);
    expect(client.starts, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
