import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

class PreviewDecodedImage {
  PreviewDecodedImage({
    required this.image,
    required this.disposeCodec,
    required this.disposeImage,
  });

  final ui.Image image;
  final VoidCallback disposeCodec;
  final VoidCallback disposeImage;
  bool _codecDisposed = false, _imageDisposed = false;

  void releaseCodec() {
    if (_codecDisposed) return;
    _codecDisposed = true;
    disposeCodec();
  }

  void releaseImage() {
    if (_imageDisposed) return;
    _imageDisposed = true;
    disposeImage();
  }
}

typedef PreviewImageDecoder = Future<PreviewDecodedImage> Function(
  Uint8List bytes,
  int width,
  int height,
);

Future<PreviewDecodedImage> decodePreviewImage(
  Uint8List bytes,
  int width,
  int height,
) async {
  ui.Codec? codec;
  try {
    codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: width,
      targetHeight: height,
      allowUpscaling: false,
    );
    final frame = await codec.getNextFrame();
    return PreviewDecodedImage(
      image: frame.image,
      disposeCodec: codec.dispose,
      disposeImage: frame.image.dispose,
    );
  } catch (_) {
    codec?.dispose();
    rethrow;
  }
}

class FilePreviewImageView extends StatefulWidget {
  const FilePreviewImageView({
    super.key,
    required this.preview,
    this.decoder = decodePreviewImage,
  });

  final FilePreviewImage preview;
  final PreviewImageDecoder decoder;

  @override
  State<FilePreviewImageView> createState() => _FilePreviewImageViewState();
}

class _FilePreviewImageViewState extends State<FilePreviewImageView> {
  PreviewDecodedImage? _decoded;
  int _epoch = 0;
  bool _loading = false;
  String? _problem;

  @override
  void initState() {
    super.initState();
    _startDecode();
  }

  @override
  void didUpdateWidget(FilePreviewImageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.preview, widget.preview) ||
        oldWidget.decoder != widget.decoder) {
      _startDecode();
    }
  }

  void _release() {
    final decoded = _decoded;
    _decoded = null;
    if (decoded != null) {
      decoded.releaseCodec();
      decoded.releaseImage();
    }
  }

  void _startDecode() {
    final epoch = ++_epoch;
    _release();
    _loading = true;
    _problem = null;
    final preview = widget.preview;
    final decoder = widget.decoder;
    () async {
      PreviewDecodedImage? decoded;
      try {
        decoded = await decoder(preview.content, preview.width, preview.height);
        if (!mounted || epoch != _epoch) {
          decoded.releaseCodec();
          decoded.releaseImage();
          return;
        }
        decoded.releaseCodec();
        setState(() {
          _decoded = decoded;
          _loading = false;
        });
      } catch (_) {
        decoded?.releaseCodec();
        decoded?.releaseImage();
        if (mounted && epoch == _epoch) {
          setState(() {
            _loading = false;
            _problem = 'This image cannot be decoded safely.';
          });
        }
      }
    }();
  }

  @override
  void dispose() {
    ++_epoch;
    _release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LinearProgressIndicator();
    if (_problem != null) {
      return McStatus(title: _problem!, tone: McStatusTone.error);
    }
    final decoded = _decoded;
    if (decoded == null) {
      return const McStatus(
        title: 'This image cannot be decoded safely.',
        tone: McStatusTone.error,
      );
    }
    final preview = widget.preview;
    return Semantics(
      label:
          '${preview.format} image, ${preview.width} by ${preview.height} pixels',
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 420),
        child: RawImage(
          image: decoded.image,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}
