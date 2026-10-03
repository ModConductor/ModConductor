import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_ui_collections/mc_ui_collections.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

class _Row {
  const _Row(this.id, this.name);
  final int id;
  final String name;
}

Future<Uint8List> _pixels(WidgetTester tester, GlobalKey scene) async =>
    (await tester.runAsync(() async {
      final boundary =
          scene.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage();
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      image.dispose();
      return data!.buffer.asUint8List();
    }))!;

int _changedPixels(Uint8List before, Uint8List after, int width, Rect region) {
  var changed = 0;
  for (var y = region.top.ceil(); y < region.bottom.floor(); y++) {
    for (var x = region.left.ceil(); x < region.right.floor(); x++) {
      final offset = (y * width + x) * 4;
      if (before[offset] != after[offset] ||
          before[offset + 1] != after[offset + 1] ||
          before[offset + 2] != after[offset + 2] ||
          before[offset + 3] != after[offset + 3]) {
        changed++;
      }
    }
  }
  return changed;
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
      'portrait card feedback stays in the scrolled viewport $brightness',
      (tester) async {
        tester.view.physicalSize = const Size(650, 850);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final scene = GlobalKey();
        final grid = GlobalKey<McCardGridState<int, _Row>>();
        final model = McCollectionModel<int, _Row>(
          idOf: (row) => row.id,
          labelOf: (row) => row.name,
        );
        addTearDown(model.dispose);
        model.apply(
          upserts: const [_Row(1, 'One'), _Row(2, 'Two'), _Row(3, 'Three')],
        );
        final activated = <int>[];
        var actionCalls = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: mcTheme(brightness),
            home: RepaintBoundary(
              key: scene,
              child: Scaffold(
                body: Column(
                  children: [
                    const SizedBox(
                      height: 64,
                      child: Center(child: Text('Workspace tabs')),
                    ),
                    Expanded(
                      child: McCardGrid<int, _Row>(
                        key: grid,
                        model: model,
                        filterLabel: 'Filter cards',
                        onActivate: (row) => activated.add(row.id),
                        card: (row) => McPortraitCard(
                          name: row.name,
                          selected: model.selectedId == row.id,
                          actions: [
                            McAction(
                              label: 'Card action',
                              onPressed: () => actionCalls++,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 64,
                      child: Center(child: Text('Workspace footer')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        grid.currentState!.scroll.jumpTo(220);
        await tester.pumpAndSettle();
        final viewport = tester.getRect(find.byType(GridView));
        final header = Rect.fromLTRB(0, 0, 650, viewport.top);
        final footer = Rect.fromLTRB(0, viewport.bottom, 650, 850);
        final before = await _pixels(tester, scene);
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: const Offset(640, 20));
        addTearDown(mouse.removePointer);
        await mouse.moveTo(Offset(300, viewport.top + 70));
        await tester.pumpAndSettle();
        final hovered = await _pixels(tester, scene);
        expect(_changedPixels(before, hovered, 650, header), 0);
        expect(_changedPixels(before, hovered, 650, footer), 0);
        final cardFace = Rect.fromCenter(
          center: Offset(300, viewport.top + 70),
          width: 120,
          height: 60,
        );
        expect(_changedPixels(before, hovered, 650, cardFace), greaterThan(0));
        final nextCard = tester
            .getRect(find.byKey(const ValueKey(2)))
            .intersect(viewport);
        expect(_changedPixels(before, hovered, 650, nextCard), 0);

        await tester.tapAt(Offset(300, viewport.top + 70));
        await tester.pumpAndSettle();
        expect(model.selectedId, 1);
        expect(activated, [1]);
        await mouse.moveTo(const Offset(640, 20));
        grid.currentState!.focusSelected();
        await tester.pumpAndSettle();
        final focused = await _pixels(tester, scene);
        expect(_changedPixels(before, focused, 650, header), 0);
        expect(_changedPixels(before, focused, 650, footer), 0);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(activated, [1, 1]);
        await tester.tap(find.text('Card action').first);
        await tester.pumpAndSettle();
        expect(actionCalls, 1);
        expect(activated, [1, 1]);
        await mouse.moveTo(const Offset(640, 20));
        await tester.pumpAndSettle();
        final beforeLowerHover = await _pixels(tester, scene);
        await mouse.moveTo(Offset(300, viewport.bottom - 70));
        await tester.pumpAndSettle();
        final lowerHover = await _pixels(tester, scene);
        expect(_changedPixels(beforeLowerHover, lowerHover, 650, header), 0);
        expect(_changedPixels(beforeLowerHover, lowerHover, 650, footer), 0);
        expect(
          _changedPixels(beforeLowerHover, lowerHover, 650, viewport),
          greaterThan(0),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('keyboard movement retains collection selection and activation', (
    tester,
  ) async {
    final model = McCollectionModel<int, _Row>(
      idOf: (row) => row.id,
      labelOf: (row) => row.name,
    );
    addTearDown(model.dispose);
    model.apply(upserts: const [_Row(1, 'One'), _Row(2, 'Two')]);
    final activated = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: McCardGrid<int, _Row>(
            model: model,
            filterLabel: 'Filter shown mods',
            card: (row) => Center(child: Text(row.name)),
            onActivate: (row) => activated.add(row.id),
          ),
        ),
      ),
    );

    Focus.of(tester.element(find.text('One'))).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(model.selectedId, 2);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(activated, [2]);
  });
}
