import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

typedef ProfileOptionsChoice = ({
  ProfileDataOptions options,
  InitialProfileSaves initial,
});

Future<ProfileOptionsChoice?> chooseProfileOptions(
  BuildContext context,
  ProfileDataState current,
  String profileName,
) {
  var settings = current.options.settings, saves = current.options.saves;
  var initial = InitialProfileSaves.empty;
  return showDialog<ProfileOptionsChoice>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, update) => McFormDialog(
        title: '$profileName settings',
        action: 'Save',
        onSubmit: () => Navigator.pop(context, (
          options: ProfileDataOptions(settings: settings, saves: saves),
          initial: initial,
        )),
        children: [
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Local game settings'),
            value: settings,
            onChanged: (value) => update(() => settings = value!),
          ),
          if (settings && !current.settingsInitialized)
            const Padding(
              padding: EdgeInsets.only(left: 16, bottom: 12),
              child: Text('Starts from the global game settings.'),
            ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Local saves'),
            value: saves,
            onChanged: (value) => update(() => saves = value!),
          ),
          if (saves && !current.savesInitialized) ...[
            const SizedBox(height: 8),
            McChoice<InitialProfileSaves>(
              label: 'Initial saves',
              value: initial,
              choices: InitialProfileSaves.values,
              describe: (value) => value == InitialProfileSaves.empty
                  ? 'Start empty'
                  : 'Copy existing global saves',
              onChanged: (value) => update(() => initial = value),
            ),
            if (initial == InitialProfileSaves.empty)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text('Global saves are not moved or deleted.'),
              ),
          ],
          const SizedBox(height: 16),
          const McStatus(
            title: 'Applied on Play',
            detail: 'The settings stay in use for direct Steam launches until restored.',
          ),
        ],
      ),
    ),
  );
}

Future<DisabledProfileFiles?> chooseDisabledFiles(
  BuildContext context,
  ProfileDataState current,
  ProfileDataOptions next,
  ProfileInfo profile,
) {
  var choice = DisabledProfileFiles.keep;
  final settings = current.options.settings && !next.settings;
  final saves = current.options.saves && !next.saves;
  final subject = settings && saves
      ? 'local settings and saves'
      : settings
      ? 'local game settings'
      : 'local saves';
  final count =
      (settings ? current.settingsFiles : 0) + (saves ? current.saveFiles : 0);
  return showDialog<DisabledProfileFiles>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, update) => McDialog(
        title: 'Turn off $subject?',
        actions: [
          McAction(label: 'Cancel', onPressed: () => Navigator.pop(context)),
          McAction(
            label: choice == DisabledProfileFiles.delete
                ? 'Turn off and delete'
                : 'Turn off',
            emphasis: McActionEmphasis.primary,
            onPressed: () => Navigator.pop(context, choice),
          ),
        ],
        children: [
          if (current.inUseProfileId == profile.id)
            Text(
              '${profile.name} is in use. The affected global settings or save location will be restored first.',
            ),
          const SizedBox(height: 16),
          McChoice<DisabledProfileFiles>(
            label: 'Local files',
            value: choice,
            choices: DisabledProfileFiles.values,
            describe: (value) => value == DisabledProfileFiles.keep
                ? 'Keep local files'
                : 'Delete local files',
            onChanged: (value) => update(() => choice = value),
          ),
          const SizedBox(height: 16),
          Text(
            choice == DisabledProfileFiles.keep
                ? 'Keep $count ${count == 1 ? 'file' : 'files'} for a later re-enable.'
                : 'Delete $count ${count == 1 ? 'file' : 'files'} from ${profile.name}. Global saves are not deleted.',
          ),
        ],
      ),
    ),
  );
}

Future<bool?> confirmProfileRestore(
  BuildContext context,
  String activeName,
) => showDialog<bool>(
  context: context,
  builder: (context) => McDialog(
    title: 'Restore settings, saves and plugin order?',
    actions: [
      McAction(label: 'Cancel', onPressed: () => Navigator.pop(context)),
      McAction(
        label: 'Restore',
        emphasis: McActionEmphasis.primary,
        onPressed: () => Navigator.pop(context, true),
      ),
    ],
    children: [
      Text(
        'Keep $activeName’s profile data and restore the global settings, save location and any applied plugin order.',
      ),
      const SizedBox(height: 16),
      const Text('Local options stay enabled. Play can apply them again.'),
    ],
  ),
);
