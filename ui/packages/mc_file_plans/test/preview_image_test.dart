import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_file_plans/src/preview_image.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

Future<ui.Image> image() async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawColor(const Color(0xff336699), ui.BlendMode.src);
  return recorder.endRecording().toImage(1, 1);
}

FilePreviewImage preview(int value) =>
    FilePreviewImage(Uint8List.fromList([value]), 'PNG', 1, 1);

void main() {
  testWidgets(
    'replacement and unmount dispose each owned codec and frame image',
    (tester) async {
      final requests = <Completer<PreviewDecodedImage>>[];
      Future<PreviewDecodedImage> decoder(Uint8List _, int _, int _) {
        final request = Completer<PreviewDecodedImage>();
        requests.add(request);
        return request.future;
      }

      var firstCodec = 0, firstImage = 0, secondCodec = 0, secondImage = 0;
      final first = await image(), second = await image();

      await tester.pumpWidget(
        MaterialApp(
          theme: mcTheme(Brightness.light),
          home: FilePreviewImageView(preview: preview(1), decoder: decoder),
        ),
      );
      requests.single.complete(
        PreviewDecodedImage(
          image: first,
          disposeCodec: () => firstCodec++,
          disposeImage: () {
            firstImage++;
            first.dispose();
          },
        ),
      );
      await tester.pump();
      expect(firstCodec, 1);
      expect(firstImage, 0);

      await tester.pumpWidget(
        MaterialApp(
          theme: mcTheme(Brightness.light),
          home: FilePreviewImageView(preview: preview(2), decoder: decoder),
        ),
      );
      expect(firstImage, 1);
      requests[1].complete(
        PreviewDecodedImage(
          image: second,
          disposeCodec: () => secondCodec++,
          disposeImage: () {
            secondImage++;
            second.dispose();
          },
        ),
      );
      await tester.pump();
      expect(secondCodec, 1);
      expect(secondImage, 0);

      await tester.pumpWidget(const SizedBox());
      expect(firstCodec, 1);
      expect(firstImage, 1);
      expect(secondCodec, 1);
      expect(secondImage, 1);
    },
  );

  testWidgets('a superseded decode releases its late codec and image', (
    tester,
  ) async {
    final requests = <Completer<PreviewDecodedImage>>[];
    Future<PreviewDecodedImage> decoder(Uint8List _, int _, int _) {
      final request = Completer<PreviewDecodedImage>();
      requests.add(request);
      return request.future;
    }

    var codecDisposed = 0, imageDisposed = 0;
    final late = await image();
    await tester.pumpWidget(
      MaterialApp(
        home: FilePreviewImageView(preview: preview(1), decoder: decoder),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: FilePreviewImageView(preview: preview(2), decoder: decoder),
      ),
    );
    requests.first.complete(
      PreviewDecodedImage(
        image: late,
        disposeCodec: () => codecDisposed++,
        disposeImage: () {
          imageDisposed++;
          late.dispose();
        },
      ),
    );
    await tester.pump();
    expect(codecDisposed, 1);
    expect(imageDisposed, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('malformed image bytes have an ordinary bounded error surface', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: mcTheme(Brightness.dark),
        home: FilePreviewImageView(preview: preview(0)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('This image cannot be decoded safely.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
