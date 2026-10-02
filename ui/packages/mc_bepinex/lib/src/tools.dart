import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_file_plans/mc_file_plans.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

class LoaderTools extends StatelessWidget {
  const LoaderTools({super.key, required this.client, required this.state});
  final BepInExClient client;
  final BepInExState state;
  @override
  Widget build(BuildContext context) => LoaderFilesDialog(
    name: 'BepInEx',
    settingsFiles: state.settingsAvailable ? ['BepInEx.cfg'] : [],
    logAvailable: state.logAvailable,
    settingsLabel: 'Edit loader settings',
    logLabel: 'Open loader log',
    details: ExpansionTile(
      title: const Text('Package details'),
      children: [
        McFactGroup(
          title: 'Package',
          rows: [
            if (state.package case final package?)
              McFact(
                'Package',
                '${package.package.namespace}-${package.package.name}-${package.version}',
              )
            else
              const McFact('Source', 'Mod library archive'),
          ],
        ),
      ],
    ),
    readSettings: (_) => client.settings(state.workspace, state.profile),
    saveSettings: (_, original, content) =>
        client.saveSettings(state.workspace, state.profile, original, content),
    readLog: () => client.log(state.workspace, state.profile),
  );
}
