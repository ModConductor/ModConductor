import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';
import 'package:mod_conductor/src/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  testWidgets('saved settings drive the compiled accessible shell', (
    tester,
  ) async {
    const executable = String.fromEnvironment('MC_ENGINE_PATH');
    const output = String.fromEnvironment('MC_SETTINGS_OUTPUT');
    const atSpiPause = int.fromEnvironment('MC_ATSPI_PAUSE_SECONDS');
    if (executable.isEmpty || output.isEmpty) {
      throw StateError(
        'Select the native engine and an owned output directory.',
      );
    }
    final evidence = await Directory(output).create(recursive: true);
    final fixture = await Directory.systemTemp.createTemp(
      'mc-settings-ui-native-',
    );
    final owner = EngineOwner(
      executable,
      launch: (path) =>
          Process.start(path, ['--state-directory', '${fixture.path}/state']),
    );
    final boundary = GlobalKey();
    final semantics = tester.ensureSemantics();

    Future<void> capture(String name) async {
      await tester.pumpAndSettle();
      final render =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await render.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('${evidence.path}/$name.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    }

    Future<void> choose(String key, String label) async {
      await tester.tap(find.byKey(ValueKey(key)));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
    }

    Future<void> apply() async {
      await tester.tap(find.byKey(const ValueKey('apply-preferences')));
      await tester.pumpAndSettle();
    }

    try {
      tester.platformDispatcher.localesTestValue = const [Locale('en')];
      await owner.connect();
      expect(owner.state, isA<EngineConnected>());
      expect((owner.state as EngineConnected).report.runtime.nativeAot, isTrue);
      await tester.binding.setSurfaceSize(const Size(960, 820));
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundary,
          child: ModConductorApp(
            settings: owner.settings,
            status: DesktopConnected((owner.state as EngineConnected).report),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('nav-preferences')));
      await tester.pumpAndSettle();
      await choose('preferences-theme', 'Light');
      await apply();
      await capture('preferences-light');

      if (atSpiPause > 0) {
        await Future<void>.delayed(Duration(seconds: atSpiPause));
      }

      await choose('preferences-theme', 'Dark');
      await apply();
      await capture('preferences-dark');

      await choose('preferences-contrast', 'High contrast');
      await apply();
      expect(
        MediaQuery.highContrastOf(
          tester.element(find.byKey(const ValueKey('quit'))),
        ),
        isTrue,
      );
      await capture('preferences-high-contrast');

      await choose('preferences-theme', 'Light');
      await choose('preferences-scale', '150%');
      await choose('preferences-contrast', 'Standard');
      await apply();
      await tester.binding.setSurfaceSize(const Size(720, 820));
      await tester.pumpAndSettle();
      await capture('preferences-large-text');

      final details = tester
          .widget<McAction>(find.byKey(const ValueKey('session-details')))
          .focusNode!;
      details.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(details.hasFocus, isTrue);

      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
      tester.platformDispatcher.clearLocalesTestValue();
      await tester.binding.setSurfaceSize(null);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(await owner.close(), isTrue);
      await fixture.delete(recursive: true);
    }
  });
}
