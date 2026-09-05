import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mod_conductor/src/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'desktop launches published engine and completes unary plus stream',
    (tester) async {
      const executable = String.fromEnvironment('MC_ENGINE_PATH');
      if (executable.isEmpty) {
        throw StateError(
          'Pass --dart-define=MC_ENGINE_PATH=<published engine>.',
        );
      }
      final stateDirectory = await Directory.systemTemp.createTemp(
        'mc-native-ui-',
      );
      await tester.pumpWidget(
        DesktopHost(
          engineExecutable: executable,
          stateDirectory: stateDirectory.path,
        ),
      );
      await tester.tap(find.byKey(const ValueKey('nav-preferences')));
      await tester.pump();
      final deadline = DateTime.now().add(const Duration(seconds: 20));
      DesktopStatus? status;
      while (DateTime.now().isBefore(deadline)) {
        await tester.pump(const Duration(milliseconds: 100));
        status = tester
            .widget<ModConductorApp>(find.byType(ModConductorApp))
            .status;
        if (status is DesktopConnected || status is DesktopFailure) break;
      }
      expect(status, isA<DesktopConnected>());
      final report = (status as DesktopConnected).report;
      expect(report.runtime.nativeAot, isTrue);
      expect(report.heartbeats, greaterThan(0));
      await tester.tap(find.byKey(const ValueKey('nav-preferences')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
      await stateDirectory.delete(recursive: true);
    },
  );
}
