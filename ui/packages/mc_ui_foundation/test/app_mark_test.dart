import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

void main() {
  for (final brightness in [Brightness.light, Brightness.dark]) {
    testWidgets('app mark loads in $brightness', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: const Scaffold(body: McAppMark(size: 48)),
        ),
      );
      await tester.runAsync(() async {
        await precacheImage(
          const AssetImage(
            'assets/brand/modconductor.png',
            package: 'mc_ui_foundation',
          ),
          tester.element(find.byType(McAppMark)),
        );
      });
      await tester.pumpAndSettle();

      expect(tester.widget<RawImage>(find.byType(RawImage)).image, isNotNull);
      expect(tester.takeException(), isNull);
    });
  }
}
