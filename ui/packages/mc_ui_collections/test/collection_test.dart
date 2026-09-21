import 'dart:ui' show SemanticsAction, Tristate;

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

  testWidgets(
    'accessible row actions keep their names, state and independent child controls',
    (tester) async {
      final rows = model();
      final focus = FocusNode();
      final semantics = tester.ensureSemantics();
      addTearDown(rows.dispose);
      addTearDown(focus.dispose);
      try {
        rows.apply(upserts: [item(1, folder: true), item(2, parent: 1)]);
        var activated = 0, refreshed = 0;
        String summary(Item row) => '${row.name}, record ${row.id}';
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: McCollection<int, Item>(
                model: rows,
                title: 'Records',
                filterLabel: 'Filter',
                countLabel: '2 records',
                focusNode: focus,
                semanticLabel: summary,
                actions: [
                  McIconAction(
                    key: const ValueKey('refresh-action'),
                    label: 'Reload records',
                    icon: const Icon(Icons.refresh),
                    onPressed: () => refreshed++,
                  ),
                ],
                columns: [
                  McColumn('Name', (row) => Text(row.name)),
                  McColumn(
                    'Action',
                    (row) => McIconMenu<String>(
                      key: ValueKey('menu-${row.id}'),
                      label: 'Options for ${row.name}',
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'act', child: Text('Act')),
                      ],
                      onSelected: (_) {
                        activated = row.id;
                        rows.select(row.id);
                        focus.requestFocus();
                      },
                    ),
                    width: 48,
                    interactive: true,
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final branch = find.byKey(const ValueKey<int>(1));
        final branchNode = tester.getSemantics(branch);
        branchNode.owner!.performAction(branchNode.id, SemanticsAction.focus);
        await tester.pump();
        expect(rows.selectedId, 1);
        final collapsed = tester.getSemantics(branch).getSemanticsData();
        expect(collapsed.flagsCollection.isExpanded, Tristate.isFalse);
        final expander = find.descendant(
          of: branch,
          matching: find.byType(McIconAction),
        );
        final expanderWidget = tester.widget<McIconAction>(expander);
        final expanderNode = tester.getSemantics(expander);
        expect(expanderNode.getSemanticsData().label, expanderWidget.label);
        expect(expanderNode.getSemanticsData().tooltip, isEmpty);
        expanderNode.owner!.performAction(expanderNode.id, SemanticsAction.tap);
        await tester.pumpAndSettle();
        final expanded = tester.getSemantics(branch).getSemanticsData();
        expect(expanded.flagsCollection.isExpanded, Tristate.isTrue);
        expect(expanded.label, isNot(collapsed.label));
        expect(expanded.label, contains(summary(rows[1]!)));
        final child = tester.getSemantics(find.byKey(const ValueKey<int>(2)));
        expect(child.getSemanticsData().label, summary(rows[2]!));
        final menu = find.byKey(const ValueKey('menu-2'));
        final menuNode = tester.getSemantics(menu);
        expect(
          menuNode.getSemanticsData().label,
          tester.widget<McIconMenu<String>>(menu).label,
        );
        expect(menuNode.getSemanticsData().tooltip, isEmpty);
        menuNode.owner!.performAction(menuNode.id, SemanticsAction.tap);
        await tester.pumpAndSettle();
        final choice = tester.getSemantics(find.text('Act'));
        choice.owner!.performAction(choice.id, SemanticsAction.tap);
        await tester.pumpAndSettle();
        expect(activated, 2);
        expect(rows.selectedId, 2);
        expect(rows.focusedId, 2);
        expect(focus.hasFocus, isTrue);
        final refresh = find.byKey(const ValueKey('refresh-action'));
        final refreshNode = tester.getSemantics(refresh);
        expect(
          refreshNode.getSemanticsData().label,
          tester.widget<McIconAction>(refresh).label,
        );
        refreshNode.owner!.performAction(refreshNode.id, SemanticsAction.tap);
        await tester.pump();
        expect(refreshed, 1);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets('RTL tree keys expand and collapse in the reading direction', (
    tester,
  ) async {
    final rows = model();
    final focus = FocusNode();
    addTearDown(rows.dispose);
    addTearDown(focus.dispose);
    rows.apply(upserts: [item(1, folder: true), item(2, parent: 1)]);
    rows.select(1);
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: McCollection<int, Item>(
              model: rows,
              title: 'Records',
              filterLabel: 'Filter',
              countLabel: '2 records',
              focusNode: focus,
              columns: [McColumn('Name', (row) => Text(row.name))],
            ),
          ),
        ),
      ),
    );
    focus.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(rows.expanded(1), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(rows.expanded(1), isFalse);
  });

  for (final direction in TextDirection.values) {
    testWidgets(
      'sortable headers keep the icon and label together in $direction',
      (tester) async {
        tester.view.physicalSize = const Size(320, 480);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.5;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final rows = model();
        final semantics = tester.ensureSemantics();
        addTearDown(rows.dispose);
        rows.apply(upserts: [item(2), item(1)]);
        await tester.pumpWidget(
          MaterialApp(
            home: Directionality(
              textDirection: direction,
              child: Scaffold(
                body: McCollection<int, Item>(
                  model: rows,
                  title: 'Items',
                  filterLabel: 'Filter items',
                  countLabel: '2 items',
                  columns: [
                    McColumn(
                      'Order',
                      (row) => Text(row.name),
                      compare: (a, b) => a.id.compareTo(b.id),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final header = find.byType(McSortHeader);
        final icon = find.descendant(
          of: header,
          matching: find.byIcon(Icons.unfold_more),
        );
        final label = find.descendant(of: header, matching: find.text('Order'));
        expect(icon, findsOneWidget);
        expect(label, findsOneWidget);
        final sortSemantics = tester
            .getSemantics(
              find.descendant(of: header, matching: find.byType(TextButton)),
            )
            .getSemanticsData();
        semantics.dispose();
        expect(sortSemantics.hasAction(SemanticsAction.tap), isTrue);
        expect(
          tester.getCenter(icon).dy,
          closeTo(tester.getCenter(label).dy, 1),
        );
        expect(
          tester.getCenter(icon).dx < tester.getCenter(label).dx,
          direction == TextDirection.ltr,
        );

        await tester.tap(header);
        await tester.pump();
        expect(rows.visible, [1, 2]);
        expect(
          find.descendant(
            of: header,
            matching: find.byIcon(Icons.arrow_upward),
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

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
    'multi selection keeps stable IDs across modifiers and deltas while checkbox Space changes only its row',
    (tester) async {
      final rows = model(), focus = FocusNode(), checkFocus = FocusNode();
      addTearDown(rows.dispose);
      addTearDown(focus.dispose);
      addTearDown(checkFocus.dispose);
      rows.apply(upserts: [for (var id = 1; id <= 80; id++) item(id)]);
      var enabled = false;
      Set<int>? moved;
      await tester.pumpWidget(
        MaterialApp(
          theme: mcTheme(Brightness.light),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, update) => McCollection<int, Item>(
                model: rows,
                title: 'Mods',
                filterLabel: 'Filter mods',
                countLabel: '80 mods',
                focusNode: focus,
                multiSelect: true,
                onMoveUp: () => moved = rows.selectedIds.toSet(),
                columns: [
                  McColumn(
                    'Enabled',
                    (row) => row.id == 3
                        ? Checkbox(
                            key: const ValueKey('enabled'),
                            focusNode: checkFocus,
                            value: enabled,
                            onChanged: (value) =>
                                update(() => enabled = value!),
                          )
                        : const SizedBox.shrink(),
                    width: 80,
                    interactive: true,
                  ),
                  McColumn('Name', (row) => Text(row.name)),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<int>(1)));
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.tap(find.byKey(const ValueKey<int>(3)));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
      expect(rows.selectedIds, {1, 3});
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.tap(find.byKey(const ValueKey<int>(5)));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();
      expect(rows.selectedIds, {3, 4, 5, 6});
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
      expect(rows.selectedIds, {3, 4, 5});
      expect(moved, {3, 4, 5});
      expect(rows.focusedId, 6);
      checkFocus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(enabled, isTrue);
      expect(rows.selectedIds, {3, 4, 5});
      focus.requestFocus();
      rows.apply(upserts: [item(81)]);
      rows.sort((a, b) => b.id.compareTo(a.id));
      await tester.pumpAndSettle();
      expect(rows.focusedId, 6);
      expect(rows.selectedIds, {3, 4, 5});
      expect(
        tester
            .getRect(find.byKey(const ValueKey<int>(6)))
            .overlaps(tester.getRect(find.byType(ListView))),
        isTrue,
      );
      rows.filter('Item 4');
      await tester.pump();
      expect(rows.selectedIds, {3, 4, 5});
      rows.apply(evicted: [3]);
      expect(rows.selectedIds, {3, 4, 5});
      rows.apply(upserts: [item(3)]);
      rows.filter('');
      await tester.pumpAndSettle();
      expect(rows.selectedIds, {3, 4, 5});
      expect(tester.takeException(), isNull);
    },
  );

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
