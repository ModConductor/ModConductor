import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_thunderstore/mc_thunderstore.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'support.dart';

Future<void> mount(WidgetTester tester, Client client, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: mcTheme(Brightness.dark),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: ThunderstoreBrowser(
            client: client,
            workspaceId: 'workspace',
            visible: true,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Jotunn'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'selected provider version and exact dependency remain visible on narrow screen',
    (tester) async {
      await mount(tester, Client(), const Size(380, 900));
      expect(find.text('denikson · 5.4.2333'), findsOneWidget);
      expect(find.text('2.30.2 (latest)'), findsOneWidget);
      expect(find.text('Add to library'), findsOneWidget);
      expect(tester.takeException(), isNull);
      final version = tester.widget<McChoice<String>>(
        find.byWidgetPredicate(
          (widget) => widget is McChoice<String> && widget.label == 'Version',
        ),
      );
      expect(version.choices, ['2.30.2', '2.30.1', '2.9.0']);
    },
  );
  testWidgets(
    'direct acquisition keeps cancel enabled and restores close when settled',
    (tester) async {
      final client = Client();
      await mount(tester, client, const Size(1440, 900));
      await tester.tap(find.text('Add to library'));
      await tester.pump();
      client.stream!.add(
        const ThunderstoreProgress(
          reference: dependency,
          stage: 'download',
          bytes: 4096,
          total: 8192,
          completed: 0,
          packages: 2,
        ),
      );
      await tester.pump();
      expect(client.acquired.single.version, '2.30.2');
      final inspector = tester.widget<McInspector>(find.byType(McInspector));
      expect(inspector.onClose, isNull);
      expect(find.text('Cancel'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(client.cancelled, isTrue);
      expect(
        tester.widget<McInspector>(find.byType(McInspector)).onClose,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
