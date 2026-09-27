import 'dart:async';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

typedef ProfileImageChooser = Future<String?> Function();

Future<String?> chooseProfileImage() async {
  final file = await openFile(
    acceptedTypeGroups: const [
      XTypeGroup(
        label: 'Images',
        extensions: ['png', 'jpg', 'jpeg', 'webp', 'gif'],
      ),
    ],
  );
  return file?.path;
}

class ProfileImageSettings extends StatefulWidget {
  const ProfileImageSettings({
    super.key,
    required this.workspace,
    required this.profile,
    required this.client,
    required this.onChanged,
    this.gameImage,
    this.chooseImage = chooseProfileImage,
  });

  final String workspace, profile;
  final ProfileImagesClient? client;
  final Uri? gameImage;
  final VoidCallback onChanged;
  final ProfileImageChooser chooseImage;

  @override
  State<ProfileImageSettings> createState() => _ProfileImageSettingsState();
}

class _ProfileImageSettingsState extends State<ProfileImageSettings> {
  String? _image;
  bool _busy = false;
  String? _problem;
  int _epoch = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_read());
  }

  @override
  void didUpdateWidget(ProfileImageSettings oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile != widget.profile ||
        oldWidget.workspace != widget.workspace ||
        oldWidget.client != widget.client) {
      _image = null;
      _busy = false;
      _problem = null;
      unawaited(_read());
    }
  }

  Future<void> _read() async {
    final epoch = ++_epoch;
    try {
      final image = await widget.client?.readProfileImage(
        widget.workspace,
        widget.profile,
      );
      if (mounted && epoch == _epoch) setState(() => _image = image);
    } on Exception {
      if (mounted && epoch == _epoch) setState(() => _image = null);
    }
  }

  Future<void> _change(bool remove) async {
    final client = widget.client;
    if (client == null || _busy) return;
    final epoch = _epoch;
    setState(() {
      _busy = true;
      _problem = null;
    });
    try {
      final source = remove ? null : await widget.chooseImage();
      if (!remove && source == null) return;
      if (!mounted || epoch != _epoch) return;
      final oldImage = _image;
      await client.setProfileImage(widget.workspace, widget.profile, source);
      if (!mounted || epoch != _epoch) return;
      if (oldImage != null) await FileImage(File(oldImage)).evict();
      if (!mounted || epoch != _epoch) return;
      widget.onChanged();
      String? image;
      try {
        image = await client.readProfileImage(widget.workspace, widget.profile);
      } on Exception {
        image = null;
      }
      if (!mounted || epoch != _epoch) return;
      setState(() => _image = image);
    } on Exception catch (error) {
      if (mounted && epoch == _epoch) {
        setState(
          () => _problem = error is WorkspaceException
              ? error.detail
              : 'The profile image could not be saved.',
        );
      }
    } finally {
      if (mounted && epoch == _epoch) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    ++_epoch;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Profile image', style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 12),
      ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          height: 175,
          width: double.infinity,
          child: McPortraitArtwork(
            image: widget.gameImage,
            imagePath: _image,
            questionFallback: true,
          ),
        ),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          McAction(
            label: 'Choose image',
            icon: Icons.image_outlined,
            onPressed: widget.client == null || _busy
                ? null
                : () => _change(false),
          ),
          McAction(
            label: 'Remove image',
            icon: Icons.delete_outline,
            onPressed: widget.client == null || _busy || _image == null
                ? null
                : () => _change(true),
          ),
        ],
      ),
      if (_problem != null) ...[
        const SizedBox(height: 12),
        McStatus(title: _problem!, tone: McStatusTone.error),
      ],
      const SizedBox(height: 12),
      const Text('Removing this image restores the game image.'),
      const SizedBox(height: 20),
      const Divider(),
      const SizedBox(height: 16),
    ],
  );
}
