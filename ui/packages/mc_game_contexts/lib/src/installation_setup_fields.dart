import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'installation_dialog.dart' show GameDirectoryChooser;
import 'proton_selection_field.dart';

class InstallationSetupFields extends StatefulWidget {
  const InstallationSetupFields({
    super.key,
    required this.gameName,
    required this.source,
    required this.onSourceChanged,
    required this.folder,
    required this.wineExecutable,
    required this.winePrefix,
    required this.chooseDirectory,
    required this.onBrowse,
    this.chooseExecutable,
    this.onFindSteam,
    this.onSelectProton,
    this.proton,
    this.busy = false,
    this.gameChoices,
    this.onGameChanged,
    this.candidates = const [],
    this.onCandidateChanged,
    this.onProblem,
  });

  final String gameName;
  final List<String>? gameChoices;
  final ValueChanged<String>? onGameChanged;
  final GameInstallationSource source;
  final ValueChanged<GameInstallationSource> onSourceChanged;
  final TextEditingController folder, wineExecutable, winePrefix;
  final GameDirectoryChooser chooseDirectory;
  final GameDirectoryChooser? chooseExecutable;
  final Future<void> Function() onBrowse;
  final VoidCallback? onFindSteam, onSelectProton;
  final ProtonSelection? proton;
  final bool busy;
  final List<String> candidates;
  final ValueChanged<String>? onCandidateChanged;
  final ValueChanged<String>? onProblem;

  @override
  State<InstallationSetupFields> createState() =>
      _InstallationSetupFieldsState();
}

class _InstallationSetupFieldsState extends State<InstallationSetupFields> {
  bool choosing = false;
  bool get busy => widget.busy || choosing;
  final folderFocus = FocusNode(debugLabel: 'Choose game folder');

  @override
  void dispose() {
    folderFocus.dispose();
    super.dispose();
  }

  Future<void> _choose(
    TextEditingController controller,
    GameDirectoryChooser chooser,
  ) async {
    if (busy) return;
    final source = widget.source;
    setState(() => choosing = true);
    try {
      final selected = await chooser(
        controller.text.isEmpty ? null : controller.text,
      );
      if (mounted && widget.source == source && selected != null) {
        controller.text = selected;
      }
    } on Exception {
      if (mounted) widget.onProblem?.call('The file selector could not open.');
    } finally {
      if (mounted) setState(() => choosing = false);
    }
  }

  Widget _path(
    String label,
    String key,
    TextEditingController controller,
    IconData icon,
    VoidCallback? onChoose, {
    FocusNode? focusNode,
  }) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: TextFormField(
          key: ValueKey(key),
          controller: controller,
          enabled: !busy,
          decoration: InputDecoration(
            labelText: label,
            hintText: 'Not selected',
          ),
          minLines: 1,
          maxLines: 2,
        ),
      ),
      const SizedBox(width: McSpacing.small),
      Padding(
        padding: const EdgeInsets.only(top: 3),
        child: McIconAction(
          key: ValueKey('choose-$key'),
          label: 'Choose $label',
          icon: Icon(icon),
          focusNode: focusNode,
          onPressed: busy ? null : onChoose,
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      McChoice<String>(
        label: 'Game',
        value: widget.gameName,
        choices: widget.gameChoices ?? [widget.gameName],
        describe: (value) => value,
        onChanged: widget.onGameChanged ?? (_) {},
        enabled: !busy,
      ),
      const SizedBox(height: McSpacing.large),
      McChoice<GameInstallationSource>(
        label: 'Installation',
        value: widget.source,
        choices: GameInstallationSource.values,
        describe: (value) => value.label,
        onChanged: widget.onSourceChanged,
        enabled: !busy,
      ),
      const SizedBox(height: McSpacing.medium),
      _path(
        'Game folder',
        'installation-folder',
        widget.folder,
        Icons.folder_open,
        () async {
          await widget.onBrowse();
          if (mounted) folderFocus.requestFocus();
        },
        focusNode: folderFocus,
      ),
      if (widget.source == GameInstallationSource.steam) ...[
        const SizedBox(height: McSpacing.small),
        McAction(
          key: const ValueKey('find-profile-installation'),
          label: 'Find in Steam…',
          icon: Icons.search,
          onPressed: busy ? null : widget.onFindSteam,
        ),
        if (widget.candidates.length > 1) ...[
          const SizedBox(height: McSpacing.medium),
          McChoice<String>(
            label: 'Steam folder',
            value: widget.candidates.contains(widget.folder.text)
                ? widget.folder.text
                : widget.candidates.first,
            choices: widget.candidates,
            describe: (value) => value,
            onChanged: widget.onCandidateChanged ?? (_) {},
            enabled: !busy,
          ),
        ],
      ],
      if (Platform.isLinux) ...[
        const SizedBox(height: McSpacing.large),
        const Divider(height: 1),
        const SizedBox(height: McSpacing.large),
        Text(
          widget.source == GameInstallationSource.steam
              ? 'Steam Proton'
              : 'Wine',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: McSpacing.medium),
        if (widget.source == GameInstallationSource.steam)
          ProtonSelectionField(
            selection: widget.proton,
            onSelect: busy ? null : widget.onSelectProton,
          )
        else ...[
          _path(
            'Wine executable',
            'wine-executable',
            widget.wineExecutable,
            Icons.insert_drive_file_outlined,
            widget.chooseExecutable == null
                ? null
                : () =>
                      _choose(widget.wineExecutable, widget.chooseExecutable!),
          ),
          const SizedBox(height: McSpacing.medium),
          _path(
            'Wine prefix',
            'wine-prefix',
            widget.winePrefix,
            Icons.folder_open,
            () => _choose(widget.winePrefix, widget.chooseDirectory),
          ),
        ],
      ],
    ],
  );
}
