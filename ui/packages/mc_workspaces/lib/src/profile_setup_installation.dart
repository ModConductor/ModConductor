part of 'profile_setup.dart';

extension _ProfileSetupInstallation on _ProfileSetupSurfaceState {
  Widget installationChoice(
    BuildContext context,
    String path, {
    required String title,
    String? note,
  }) => _ProfileSetupChoiceTile<String>(
    radioKey: ValueKey(('profile-installation', path)),
    value: path,
    selected: selectedInstallation == path,
    enabled: !busy,
    title: Text(title),
    selectedFillOpacity: .07,
    subtitle: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(path, maxLines: 2, overflow: TextOverflow.ellipsis),
        if (note != null)
          Text(
            note,
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
      ],
    ),
  );

  Widget folderOverride({required bool primary}) => primary
      ? McAction(
          key: const ValueKey('choose-profile-game-folder'),
          label: 'Choose folder…',
          icon: Icons.folder_open,
          focusNode: folderFocus,
          onPressed: busy ? null : chooseFolder,
        )
      : TextButton.icon(
          key: const ValueKey('choose-another-profile-game-folder'),
          focusNode: folderFocus,
          onPressed: busy ? null : chooseFolder,
          icon: const Icon(Icons.folder_open, size: 18),
          label: const Text('Choose another folder…'),
        );

  Widget installationSection(BuildContext context) {
    if (!searched) return const SizedBox.shrink();
    if (searching) {
      return const McActionFeedback(
        kind: McActionFeedbackKind.pending,
        message: 'Finding installations',
        detail: 'Steam folders',
      );
    }
    final manualPath = manualSelection ? selectedInstallation : null;
    if (manualPath != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Installation', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: McSpacing.small),
          RadioGroup<String>(
            groupValue: manualPath,
            onChanged: (_) {},
            child: installationChoice(
              context,
              manualPath,
              title: 'Selected folder',
              note: 'Selected manually',
            ),
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: folderOverride(primary: false),
          ),
        ],
      );
    }
    if (candidates.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const McStatus(
            title: 'No installation found',
            detail: 'Select the folder that contains SkyrimSE.exe.',
          ),
          const SizedBox(height: McSpacing.small),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: folderOverride(primary: true),
          ),
        ],
      );
    }
    final one = candidates.length == 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          one ? 'Installation' : 'Choose an installation',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: McSpacing.small),
        RadioGroup<String>(
          groupValue: selectedInstallation,
          onChanged: busy
              ? (_) {}
              : (value) => _change(() => selectedInstallation = value),
          child: Column(
            children: [
              for (final candidate in candidates)
                installationChoice(
                  context,
                  candidate.directory.canonicalPath,
                  title: one ? 'Steam installation' : 'Steam library',
                  note: one ? 'Selected automatically' : null,
                ),
            ],
          ),
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: folderOverride(primary: false),
        ),
      ],
    );
  }
}
