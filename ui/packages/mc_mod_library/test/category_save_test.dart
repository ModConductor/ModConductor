import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_mod_library/src/category_manager.dart';
import 'package:mc_mod_library/src/category_picker.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

class SavingCategories extends Fake implements ModOrganizationClient {
  static const parent = ModCategory(
    'parent',
    'workspace',
    null,
    'Textures',
    false,
    0,
    true,
  );
  static const selected = ModCategory(
    'selected',
    'workspace',
    'parent',
    'Stone',
    false,
    0,
    false,
  );
  static const sibling = ModCategory(
    'sibling',
    'workspace',
    'parent',
    'Moss',
    false,
    0,
    false,
  );
  static final roots = [
    parent,
    for (var i = 0; i < 8; i++)
      ModCategory(
        'root-$i',
        'workspace',
        null,
        'Z category $i',
        false,
        0,
        false,
      ),
  ];
  final ancestor = Completer<CategoriesPage>();
  final reveals = <Completer<CategoriesPage>>[];
  String? savedId, savedName;
  int creates = 0;
  int get revision => savedId == null ? 1 : 2;

  CategoriesPage get ancestorPage =>
      CategoriesPage(revision, const [selected, sibling], const [parent], null);
  CategoriesPage get revealedPage => CategoriesPage(revision, const [], [
    ModCategory(savedId!, 'workspace', null, savedName!, false, 0, false),
  ], null);

  @override
  Future<int> createCategory(
    String workspaceId,
    int revision,
    String id,
    String label, {
    String? parentId,
  }) async {
    creates++;
    savedId = id;
    savedName = label;
    return 2;
  }

  @override
  Future<CategoriesPage> categories(
    String workspaceId, {
    String? parentId,
    String? afterId,
    int? expectedRevision,
  }) async {
    if (afterId != null) throw StateError('Unrequested root continuation.');
    if (parentId == null) {
      return CategoriesPage(revision, roots, const [], 'remaining-roots');
    }
    if (parentId == 'selected') {
      return CategoriesPage(revision, const [], const [parent, selected], null);
    }
    if (parentId == 'parent') {
      return savedId == null ? ancestorPage : ancestor.future;
    }
    if (parentId == savedId) {
      final response = Completer<CategoriesPage>();
      reveals.add(response);
      return response.future;
    }
    throw StateError('Unrequested category subtree.');
  }
}

void main() {
  for (final failFirstRead in [false, true]) {
    testWidgets(
      'Save reveals an off-page category before closing${failFirstRead ? ' and retries its read without another Create' : ''} despite a delayed ancestor',
      (tester) async {
        final client = SavingCategories();
        await tester.pumpWidget(
          MaterialApp(
            theme: mcTheme(Brightness.light),
            home: Builder(
              builder: (context) => Scaffold(
                body: McAction(
                  label: 'Categories',
                  onPressed: () =>
                      manageCategories(context, client, 'workspace'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.widgetWithText(McAction, 'Categories'));
        await tester.pumpAndSettle();
        final expander = find
            .widgetWithIcon(IconButton, Icons.chevron_right)
            .first;
        await tester.ensureVisible(expander);
        await tester.pumpAndSettle();
        await tester.tap(expander);
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('selected')),
          60,
          scrollable: find.descendant(
            of: find.byType(CategoryPicker),
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Scrollable &&
                  widget.axisDirection == AxisDirection.down,
            ),
          ),
        );
        await tester.ensureVisible(find.byKey(const ValueKey('selected')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('selected')));
        await tester.pumpAndSettle();
        final controller = tester
            .widget<CategoryPicker>(find.byType(CategoryPicker))
            .controller;
        final opener = find.text('New category');
        final openerFocus = Focus.of(tester.element(opener));
        openerFocus.requestFocus();
        await tester.pump();
        await tester.tap(find.widgetWithText(McAction, 'New category'));
        await tester.pumpAndSettle();
        if (!failFirstRead) {
          await tester.tap(find.widgetWithText(McAction, 'Cancel'));
          await tester.pumpAndSettle();
          expect(openerFocus.hasPrimaryFocus, isTrue);
          await tester.tap(find.widgetWithText(McAction, 'New category'));
          await tester.pumpAndSettle();
        }
        await tester.enterText(
          find.byKey(const ValueKey('name')),
          'ZZ created category',
        );
        await tester.tap(find.byKey(const ValueKey('submit')));
        await tester.pump();
        expect(client.savedId, isNotNull);
        expect(client.reveals, isNotEmpty);
        expect(controller.model.selectedId, 'selected');
        expect(find.byKey(const ValueKey('submit')), findsOneWidget);

        if (failFirstRead) {
          client.reveals.last.completeError(Exception('Read connection lost'));
          await tester.pump();
          expect(controller.problem, isNotNull);
          expect(controller.model[client.savedId!], isNull);
          expect(find.byKey(const ValueKey('submit')), findsOneWidget);
          await tester.tap(find.byKey(const ValueKey('submit')));
          await tester.pump();
        }
        client.reveals.last.complete(client.revealedPage);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();
        expect(client.creates, 1);
        expect(controller.model.selectedId, client.savedId);
        expect(controller.model.selected?.label, 'ZZ created category');
        expect(controller.model.position(client.savedId!), isNotNull);
        expect(find.byKey(const ValueKey('submit')), findsNothing);
        expect(
          find.byKey(ValueKey(client.savedId!)).hitTestable(),
          findsOneWidget,
        );
        expect(controller.loading, isTrue);
        client.ancestor.complete(client.ancestorPage);
        await tester.pumpAndSettle();
        expect(controller.model.selectedId, client.savedId);
        expect(controller.model.focusedId, client.savedId);
        expect(controller.canLoad, isTrue);
        expect(client.creates, 1);
        await tester.tap(find.widgetWithText(McAction, 'Close'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }
}
