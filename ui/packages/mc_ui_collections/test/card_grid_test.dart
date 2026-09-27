import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_ui_collections/mc_ui_collections.dart';

class _Row {
  const _Row(this.id, this.name);
  final int id;
  final String name;
}

void main() {
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
