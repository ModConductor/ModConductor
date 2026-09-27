part of 'browser.dart';

extension _ModDeletionView on _ModLibraryBrowserState {
  Future<void> _delete(ModEntry target) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => McFormDialog(
        title: 'Delete ${target.metadata.name}?',
        action: 'Delete',
        onSubmit: () => Navigator.pop(context, true),
        children: [
          const Text(
            'This deletes the mod and its Mod Conductor files. Original archives, source folders, and saves stay unchanged.',
          ),
          const SizedBox(height: 12),
          const Text(
            'Profiles that use this mod will be undeployed. Other mods stay installed.',
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    widget.onMaintenanceOpen?.call();
    await deletion.open(target);
  }

  Widget _deletionView() {
    final target = deletion.target!;
    final name = target.metadata.name;
    final feedback = deletion.busy
        ? McActionFeedback(
            kind: McActionFeedbackKind.pending,
            message: 'Deleting $name',
          )
        : deletion.complete
        ? McActionFeedback(
            kind: McActionFeedbackKind.success,
            message: '$name deleted',
          )
        : McActionFeedback(
            kind: McActionFeedbackKind.failure,
            message: '$name was not deleted',
            detail: deletion.problem,
          );

    return PopScope(
      canPop: !deletion.busy,
      child: Align(
        key: const ValueKey('mod-deletion-status'),
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 670),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 20, 4, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                feedback,
                const SizedBox(height: 24),
                if (deletion.complete)
                  McAction(
                    label: 'Open Mods',
                    icon: Icons.layers_outlined,
                    onPressed: deletion.back,
                  )
                else if (!deletion.busy)
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      McAction(
                        key: const ValueKey('retry-delete-mod'),
                        label: 'Try again',
                        icon: Icons.refresh,
                        emphasis: McActionEmphasis.primary,
                        onPressed: () => unawaited(deletion.run()),
                      ),
                      McAction(
                        label: 'Back to mod',
                        icon: Icons.arrow_back,
                        onPressed: deletion.back,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
