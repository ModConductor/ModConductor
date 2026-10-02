import 'package:flutter/material.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'game_editor_controller.dart';

const gameMechanisms = {
  '': 'Choose',
  'unity-mono': 'Unity · Mono · BepInEx',
  'unity-il2cpp': 'Unity · IL2CPP · BepInEx',
  'ue4ss': 'Unreal · UE4SS',
  'cooked-plugins': 'Unreal · Cooked Plugins',
};

class GameSetupFields extends StatelessWidget {
  const GameSetupFields({
    super.key,
    required this.controller,
    this.advanced = false,
  });
  final GameEditorController controller;
  final bool advanced;
  Widget field(String label, String value, ValueChanged<String> save) =>
      Padding(
        padding: const EdgeInsets.only(bottom: McSpacing.medium),
        child: TextFormField(
          initialValue: value,
          key: ValueKey((controller.draft, label)),
          enabled: !controller.busy,
          decoration: InputDecoration(labelText: label),
          onChanged: save,
        ),
      );
  bool show(String name) => advanced
      ? !controller.missing.contains(name)
      : controller.missing.contains(name);
  @override
  Widget build(BuildContext context) {
    final d = controller.draft;
    final unity = d.mechanism.startsWith('unity-');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (show('mechanism')) ...[
          McChoice(
            label: controller.detectedEngine.startsWith('unity-')
                ? 'Mod loader'
                : 'Mod setup',
            value: d.mechanism,
            choices: controller.detectedEngine.startsWith('unity-')
                ? ['', controller.detectedEngine]
                : controller.detectedEngine == 'unreal'
                ? ['', 'ue4ss', 'cooked-plugins']
                : gameMechanisms.keys.toList(),
            describe: (value) =>
                controller.detectedEngine.startsWith('unity-') && value != ''
                ? 'BepInEx'
                : gameMechanisms[value]!,
            enabled: !controller.busy,
            onChanged: (value) {
              d.mechanism = value;
              if (value.startsWith('unity-')) {
                d.windowsRuntime = value == 'unity-mono'
                    ? 'MonoBleedingEdge/EmbedRuntime/mono-2.0-bdwgc.dll'
                    : 'GameAssembly.dll';
                d.linuxRuntime = value == 'unity-mono'
                    ? 'MonoBleedingEdge/x86_64/libmonobdwgc-2.0.so'
                    : 'GameAssembly.so';
                d.metadata = value == 'unity-mono'
                    ? 'Managed/Assembly-CSharp.dll'
                    : 'il2cpp_data/Metadata/global-metadata.dat';
              }
              if (value == 'cooked-plugins') {
                d.mods = '';
                controller.missing.addAll({'mods', 'gameFeatures', 'configs'});
              } else if (value == 'ue4ss' && d.mods.isEmpty) {
                d.mods = 'ue4ss/Mods';
                controller.missing.remove('mods');
              }
              controller.changed();
            },
          ),
          const SizedBox(height: McSpacing.medium),
        ],
        if (show('executable'))
          controller.executables.length > 1 && !advanced
              ? Padding(
                  padding: const EdgeInsets.only(bottom: McSpacing.medium),
                  child: McChoice(
                    label: 'Executable',
                    value: d.executable,
                    choices: ['', ...controller.executables],
                    describe: (value) => value.isEmpty ? 'Choose' : value,
                    onChanged: (value) {
                      controller.chooseExecutable(value);
                    },
                  ),
                )
              : field('Executable', d.executable, (value) {
                  controller.chooseExecutable(value);
                }),
        if (show('content'))
          field('Content folder', d.content, (value) {
            d.content = value;
            controller.changed();
          }),
        if (unity && (show('windowsRuntime')))
          field(
            'Windows runtime',
            d.windowsRuntime,
            (value) => d.windowsRuntime = value,
          ),
        if (unity && (show('metadata')))
          field('Metadata path', d.metadata, (value) => d.metadata = value),
        if (advanced)
          field(
            'Thunderstore community',
            d.community,
            (value) => d.community = value,
          ),
        if (advanced && unity) ...[
          field(
            'Linux executable',
            d.linuxExecutable,
            (value) => d.linuxExecutable = value,
          ),
          field(
            'Linux runtime',
            d.linuxRuntime,
            (value) => d.linuxRuntime = value,
          ),
          field(
            'Unity metadata',
            d.unityMetadata,
            (value) => d.unityMetadata = value,
          ),
          field(
            'Linux wrapper',
            d.linuxWrapper,
            (value) => d.linuxWrapper = value,
          ),
          field(
            'Loader namespace',
            d.loaderNamespace,
            (value) => d.loaderNamespace = value,
          ),
          field(
            'Loader package',
            d.loaderPackage,
            (value) => d.loaderPackage = value,
          ),
          field(
            'Loader version',
            d.loaderVersion,
            (value) => d.loaderVersion = value,
          ),
          field(
            'Loader archive root',
            d.archiveRoot,
            (value) => d.archiveRoot = value,
          ),
        ],
        if (!unity && d.mechanism.isNotEmpty) ...[
          if (advanced)
            field(
              'Loader version',
              d.loaderVersion,
              (value) => d.loaderVersion = value,
            ),
          if (advanced)
            field('Loader page', d.loaderPage, (value) => d.loaderPage = value),
          if (advanced)
            field(
              'Loader download',
              d.loaderDownload,
              (value) => d.loaderDownload = value,
            ),
          if (advanced)
            field(
              'Loader license',
              d.loaderLicense,
              (value) => d.loaderLicense = value,
            ),
          if (show('mods'))
            field('Mods folder', d.mods, (value) => d.mods = value),
          if (d.mechanism == 'ue4ss' && advanced) ...[
            field('Proxy file', d.proxy, (value) => d.proxy = value),
            field('Loader folder', d.core, (value) => d.core = value),
            field(
              'Settings file',
              d.settingsFile,
              (value) => d.settingsFile = value,
            ),
            field('Log file', d.log, (value) => d.log = value),
          ] else if (d.mechanism == 'cooked-plugins') ...[
            if (show('gameFeatures'))
              field(
                'Game Features folder',
                d.gameFeatures,
                (value) => d.gameFeatures = value,
              ),
            if (show('configs'))
              field('Configs folder', d.configs, (value) => d.configs = value),
            if (advanced)
              field(
                'Game Feature field',
                d.gameFeatureField,
                (value) => d.gameFeatureField = value,
              ),
          ],
          if (advanced)
            field('Launch arguments (one per line)', d.arguments.join('\n'), (
              value,
            ) {
              d.arguments.clear();
              d.arguments.addAll(
                value.split('\n').where((row) => row.isNotEmpty),
              );
            }),
          if (advanced)
            field('Excluded paths (one per line)', d.excluded.join('\n'), (
              value,
            ) {
              d.excluded.clear();
              d.excluded.addAll(
                value.split('\n').where((row) => row.isNotEmpty),
              );
            }),
        ],
      ],
    );
  }
}
