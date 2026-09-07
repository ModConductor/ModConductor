import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_ui_collections/mc_ui_collections.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

typedef Item = ({int id, String name, int? parent, bool folder});
Item item(int id, {String? name, int? parent, bool folder = false}) =>
    (id: id, name: name ?? 'Item $id', parent: parent, folder: folder);
McCollectionModel<int, Item> model() => McCollectionModel(
  idOf: (row) => row.id,
  labelOf: (row) => row.name,
  parentOf: (row) => row.parent,
  isBranch: (row) => row.folder,
);

void main() {
  test('selection and focus survive filtered pages, reorder, and tree collapse without selecting a replacement', () {
    final rows = model();
    addTearDown(rows.dispose);
    rows.apply(upserts: [item(1, folder: true), item(2, parent: 1), item(3)]);
    rows.toggle(1);
    rows.select(2);
    rows.toggle(1);
    expect(rows.position(2), isNull);
    expect(rows.focusedId, 2);
    expect(rows.selectedId, 2);
    rows.filter('Item 2');
    expect(rows.visible, [1, 2]);
    rows.filter('absent');
    rows.apply(upserts: [item(4)]);
    rows.sort((a, b) => a.name.compareTo(b.name), descending: true);
    rows.filter('');
    rows.toggle(1);
    expect(rows.selectedId, 2);
    expect(rows.visible, [4, 3, 1, 2]);
    rows.apply(evicted: [2]);
    expect(rows.selected, isNull);
    expect(rows.focusedId, 2);
    rows.apply(upserts: [item(2, name: 'Returned', parent: 1)]);
    expect(rows.selected!.name, 'Returned');
    expect(rows.position(2), isNotNull);
    rows.apply(removed: [2]);
    expect(rows.focusedId, isNull);
    expect(rows.selectedId, isNull);
  });

  test(
    'moving a selected row keeps its sort position in the destination branch',
    () {
      final rows = model();
      addTearDown(rows.dispose);
      rows.apply(
        upserts: [
          item(10, name: 'Group A', folder: true),
          item(20, name: 'Group B', folder: true),
          item(1, name: 'Bravo', parent: 10),
          item(2, name: 'Alpha', parent: 20),
          item(3, name: 'Charlie', parent: 20),
        ],
      );
      rows.sort((a, b) => a.name.compareTo(b.name));
      rows.toggle(10);
      rows.toggle(20);
      rows.select(1);

      rows.apply(upserts: [item(1, name: 'Bravo', parent: 20)]);

      expect(rows.visible, [10, 20, 2, 1, 3]);
      expect(rows.selectedId, 1);
      expect(rows.focusedId, 1);
      expect(rows.selected!.parent, 20);
    },
  );

  for (final scale in [1.0, 1.5]) {
    testWidgets(
      'keyboard follows stable IDs across virtual pages and preserves dialog focus at $scale text',
      (tester) async {
        tester.view.physicalSize = const Size(720, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final rows = model();
        final focus = FocusNode();
        final semantics = tester.ensureSemantics();
        addTearDown(rows.dispose);
        addTearDown(focus.dispose);
        try {
          rows.apply(upserts: [for (var i = 0; i < 1000; i++) item(i)]);
          var activated = -1;
          await tester.pumpWidget(
            MaterialApp(
              theme: mcTheme(scale == 1 ? Brightness.dark : Brightness.light),
              home: Builder(
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(scale)),
                  child: Scaffold(
                    body: McCollection<int, Item>(
                      model: rows,
                      title: 'Items',
                      filterLabel: 'Filter items',
                      countLabel: '1000 items',
                      focusNode: focus,
                      columns: [
                        McColumn(
                          'Name',
                          (row) => Text(row.name),
                          compare: (a, b) => a.id.compareTo(b.id),
                        ),
                      ],
                      onActivate: (row) {
                        activated = row.id;
                        showDialog<void>(
                          context: context,
                          builder: (_) =>
                              const McNameDialog(title: 'Edit', action: 'Save'),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          );
          focus.requestFocus();
          await tester.pump();
          await tester.sendKeyEvent(LogicalKeyboardKey.end);
          await tester.pumpAndSettle();
          expect(rows.selectedId, 999);
          expect(
            tester
                    .getSemantics(find.byKey(const ValueKey<int>(999)))
                    .getSemanticsData()
                    .flagsCollection
                    .isSelected ==
                Tristate.isTrue,
            isTrue,
          );
          expect(
            tester
                    .getSemantics(find.byKey(const ValueKey<int>(999)))
                    .getSemanticsData()
                    .flagsCollection
                    .isFocused ==
                Tristate.isTrue,
            isTrue,
          );
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pumpAndSettle();
          expect(activated, 999);
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await tester.pumpAndSettle();
          expect(focus.hasFocus, isTrue);
          rows.apply(upserts: [item(1000)]);
          rows.sort((a, b) => b.id.compareTo(a.id));
          await tester.pumpAndSettle();
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
          await tester.pumpAndSettle();
          expect(rows.selectedId, 998);
          expect(focus.hasFocus, isTrue);
          expect(
            tester
                    .getSemantics(find.byKey(const ValueKey<int>(998)))
                    .getSemanticsData()
                    .flagsCollection
                    .isSelected ==
                Tristate.isTrue,
            isTrue,
          );
          expect(tester.takeException(), isNull);
        } finally {
          semantics.dispose();
        }
      },
    );
  }

  testWidgets(
    'tree arrows expand and return to the parent without losing the selected hidden child',
    (tester) async {
      final rows = model();
      final focus = FocusNode();
      addTearDown(rows.dispose);
      addTearDown(focus.dispose);
      rows.apply(
        upserts: [
          item(1, folder: true),
          item(2, parent: 1),
          item(3, parent: 1),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: McCollection<int, Item>(
              model: rows,
              title: 'Files',
              filterLabel: 'Filter files',
              countLabel: '2 files',
              focusNode: focus,
              columns: [McColumn('Name', (row) => Text(row.name))],
            ),
          ),
        ),
      );
      focus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(rows.selectedId, 2);
      rows.toggle(1);
      await tester.pump();
      expect(rows.selectedId, 2);
      rows.toggle(1);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(rows.selectedId, 1);
      expect(rows.expanded(1), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(rows.expanded(1), isFalse);
    },
  );
}
