import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mod_conductor/src/app.dart';

import '../../../packages/mc_game_contexts/test/support/game_registration_fake.dart';

void main() {
  final output = Platform.environment['MC_GAME_CAPTURES'];
  final fonts = Platform.environment['MC_MATERIAL_FONTS'];
  testWidgets(
    'the production Games journey renders at desktop and compact sizes',
    (tester) async {
      for (final (family, file) in [
        ('packages/mc_ui_foundation/Roboto', 'Roboto-Regular.ttf'),
        ('MaterialIcons', 'MaterialIcons-Regular.otf'),
      ]) {
        final loader = FontLoader(family)
          ..addFont(
            Future.value(
              ByteData.sublistView(File('$fonts/$file').readAsBytesSync()),
            ),
          );
        await loader.load();
      }
      final boundary = GlobalKey();
      Future<void> capture(String name) async {
        expect(tester.takeException(), isNull);
        await tester.runAsync(() async {
          final image =
              await (boundary.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage(pixelRatio: 1);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File('$output/$name.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }

      Future<GameRegistrationFake> mount(
        Size size,
        Brightness brightness,
      ) async {
        await tester.pumpWidget(const SizedBox.shrink());
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.platformBrightnessTestValue = brightness;
        final fake = GameRegistrationFake();
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundary,
            child: ModConductorApp(
              status: const DesktopConnected((
                runtime: (
                  architecture: 'x64',
                  nativeAot: true,
                  sqliteVersion: '3',
                ),
                heartbeats: 1,
              )),
              gameCatalogue: fake,
              chooseGameDirectory: (_) async => GameRegistrationFake.path,
            ),
          ),
        );
        await tester.runAsync(
          () => precacheImage(
            const AssetImage(
              'assets/brand/modconductor.png',
              package: 'mc_ui_foundation',
            ),
            boundary.currentContext!,
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('nav-games')));
        await tester.pumpAndSettle();
        return fake;
      }

      Directory(output!).createSync(recursive: true);
      await mount(const Size(1440, 900), Brightness.light);
      await capture('games-desktop-light');
      await mount(const Size(1440, 900), Brightness.dark);
      await tester.tap(find.text('Add game'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Example Game').first);
      await tester.pumpAndSettle();
      await capture('steam-selected-desktop-dark');
      await mount(const Size(640, 960), Brightness.dark);
      await tester.tap(find.text('Add game'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Example Game').first);
      await tester.pumpAndSettle();
      await capture('detected-compact-dark');
      final fake = await mount(const Size(640, 960), Brightness.light);
      fake.manual = true;
      await tester.tap(find.text('Add game'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('game-source')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Folder').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('choose-game-folder')));
      await tester.pumpAndSettle();
      await capture('manual-folder-compact-light');
      await mount(const Size(1440, 900), Brightness.light);
      await tester.tap(find.text('Add game'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('game-source')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Folder').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('choose-game-folder')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Advanced'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Search Thunderstore'));
      await tester.tap(find.text('Search Thunderstore'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Search Thunderstore games'),
        'Example',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('register-game')));
      await capture('thunderstore-game-search-desktop-light');
      await tester.pumpWidget(const SizedBox.shrink());
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearPlatformBrightnessTestValue();
    },
    skip: output == null || fonts == null,
  );
}
