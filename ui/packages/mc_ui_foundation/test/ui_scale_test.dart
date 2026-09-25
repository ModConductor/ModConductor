import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

void main() {
  testWidgets('interface scale includes routes, menus, and hit targets', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 650);
    tester.platformDispatcher.textScaleFactorTestValue = 1.25;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    var selected = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: mcTheme(Brightness.light),
        builder: (context, child) => McUiScale(scale: 0.9, child: child!),
        home: Scaffold(
          body: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: TextButton(
                  onPressed: () => showDialog<void>(
                    context: tester.element(
                      find.byKey(const ValueKey('open-dialog')),
                    ),
                    builder: (context) => AlertDialog(
                      title: const Text('Details'),
                      content: const Text('The settings are active.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  ),
                  key: const ValueKey('open-dialog'),
                  child: const Text('Open details'),
                ),
              ),
              const Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  tooltip: 'Information',
                  onPressed: null,
                  icon: Icon(Icons.info_outline),
                ),
              ),
              const Spacer(),
              Align(
                alignment: Alignment.bottomRight,
                child: PopupMenuButton<String>(
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'select', child: Text('Select')),
                  ],
                  onSelected: (_) => selected = true,
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Open menu'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byKey(const ValueKey('open-dialog')));
    expect(MediaQuery.textScalerOf(context).scale(1), 1.25);
    expect(MediaQuery.sizeOf(context), const Size(1000, 650 / 0.9));

    await tester.longPress(find.byTooltip('Information'));
    await tester.pumpAndSettle();
    expect(find.text('Information'), findsOneWidget);
    final tooltipEnd = tester.getBottomRight(find.text('Information'));
    expect(tooltipEnd.dx, lessThanOrEqualTo(900));
    expect(tooltipEnd.dy, lessThanOrEqualTo(650));

    await tester.tap(find.text('Open details'));
    await tester.pumpAndSettle();
    final dialog = tester.getTopLeft(find.byType(AlertDialog));
    final dialogEnd = tester.getBottomRight(find.byType(AlertDialog));
    expect(dialog.dx, greaterThanOrEqualTo(0));
    expect(dialog.dy, greaterThanOrEqualTo(0));
    expect(dialogEnd.dx, lessThanOrEqualTo(900));
    expect(dialogEnd.dy, lessThanOrEqualTo(650));
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);

    await tester.tap(find.text('Open menu'));
    await tester.pumpAndSettle();
    final menu = tester.getTopLeft(find.byType(PopupMenuItem<String>));
    final menuEnd = tester.getBottomRight(find.byType(PopupMenuItem<String>));
    expect(menu.dx, greaterThanOrEqualTo(0));
    expect(menu.dy, greaterThanOrEqualTo(0));
    expect(menuEnd.dx, lessThanOrEqualTo(900));
    expect(menuEnd.dy, lessThanOrEqualTo(650));
    await tester.tap(find.text('Select'));
    await tester.pumpAndSettle();
    expect(selected, isTrue);
    expect(tester.takeException(), isNull);
  });
}
