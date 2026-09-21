import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_desktop/mc_desktop.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

const _labels = NexusLinkPreferencesLabels(
  title: 'Link title',
  description: 'Link description',
  removeWindowsTitle: 'Remove Windows title',
  removeTitle: 'Remove title',
  removeWindows: 'Remove Windows',
  remove: 'Remove',
  chooseOtherDefault: 'Choose another default',
  restoreDefault: 'Restore default',
  availableWindows: 'Available on Windows',
  available: 'Available',
  notAddedWindows: 'Not added on Windows',
  off: 'Off',
  cannotCheck: 'Cannot check',
  defaultApp: _defaultApp,
  modConductor: 'Mod Conductor',
  anotherApp: 'Another app',
  notSet: 'Not set',
  cannotCheckDefault: 'Cannot check default',
  chooseDefaultWindows: 'Choose default on Windows',
  defaultChanged: 'Default changed',
  checkFailed: 'Check failed',
  addWindows: 'Add on Windows',
  useModConductor: 'Use Mod Conductor',
  openWindows: 'Open Windows settings',
  checkDefault: 'Check default',
);

String _defaultApp(String value) => 'Default: $value';

void main() {
  testWidgets('link preferences remain operable in right-to-left layouts', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: mcTheme(Brightness.light),
        home: const Scaffold(
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: NexusLinkPreferences(client: null, labels: _labels),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final preferences = find.byType(NexusLinkPreferences);
    expect(Directionality.of(tester.element(preferences)), TextDirection.rtl);
    final action = find.widgetWithText(McAction, 'Check default');
    expect(tester.getSemantics(action).getSemanticsData().label, isNotEmpty);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}
