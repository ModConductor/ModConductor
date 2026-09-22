import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

void main() {
  testWidgets('a path can be selected and copied at a narrow width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(420, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map<Object?, Object?>)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: mcTheme(Brightness.light),
        home: const Scaffold(
          body: McFactGroup(
            title: 'Game',
            rows: [
              McFact(
                'Installation folder',
                '/games/SteamLibrary/steamapps/common/Skyrim Special Edition',
                path: true,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.byType(McIconAction));
    await tester.pump();

    expect(
      copied,
      '/games/SteamLibrary/steamapps/common/Skyrim Special Edition',
    );
    expect(find.byType(SelectionArea), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        'Installation folder, /games/SteamLibrary/steamapps/common/Skyrim Special Edition',
      ),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Copy path'), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('a diagnostic row exposes its evidence', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: mcTheme(Brightness.light),
        home: const Scaffold(
          body: McDiagnosticTable(
            title: 'Search problems',
            diagnostics: [
              McDiagnosticItem(
                id: 'missing-root',
                title: 'The Steam library folder is unavailable',
                affected: '/games/SteamLibrary',
                origins: ['Default Steam data folder', 'Steam home link'],
                evidence: [McFact('Problem', 'The folder is not mounted.')],
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byType(McIconAction));
    await tester.pump();

    expect(find.text('The folder is not mounted.'), findsOneWidget);
    expect(
      tester.widget<McIconAction>(find.byType(McIconAction)).label,
      'Hide evidence',
    );
  });
}
