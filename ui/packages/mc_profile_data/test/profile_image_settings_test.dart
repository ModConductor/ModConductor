import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_profile_data/src/profile_image_settings.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

class Images implements ProfileImagesClient {
  String? image;
  int reads = 0;
  int writes = 0;

  @override
  Future<String?> readProfileImage(String workspace, String profile) async {
    reads++;
    return image;
  }

  @override
  Future<void> setProfileImage(
    String workspace,
    String profile,
    String? value,
  ) async {
    writes++;
    image = value;
  }
}

void main() {
  testWidgets(
    'image replacement and removal update only the selected profile',
    (tester) async {
      final client = Images()..image = '/owned/first.image';
      var changed = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: mcTheme(Brightness.light),
          home: Scaffold(
            body: ProfileImageSettings(
              workspace: 'workspace',
              profile: 'first',
              client: client,
              chooseImage: () async => '/chosen/image.png',
              onChanged: () => changed++,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(OutlinedButton, 'Remove image'),
        findsOneWidget,
      );
      await tester.tap(find.text('Choose image'));
      await tester.pumpAndSettle();
      expect(client.image, '/chosen/image.png');
      expect(changed, 1);
      await tester.tap(find.text('Remove image'));
      await tester.pumpAndSettle();
      expect(client.image, isNull);
      expect(changed, 2);
      expect(client.writes, 2);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('unreadable override uses the question mark without game art', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: mcTheme(Brightness.dark),
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 190,
            child: McPortraitArtwork(
              imagePath: File('${Directory.systemTemp.path}/missing-image')
                  .path,
              questionFallback: true,
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
    expect(find.text('?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
