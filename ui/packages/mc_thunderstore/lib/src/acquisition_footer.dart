part of 'browser.dart';

extension _ThunderstoreFooter on _ThunderstoreBrowserState {
  String _bytes(int value) => value >= 1024 * 1024
      ? '${(value / (1024 * 1024)).toStringAsFixed(1)} MiB'
      : '${(value / 1024).toStringAsFixed(1)} KiB';
  Widget _acquisitionFooter(BuildContext context) {
    if (!controller.running)
      return McAction(
        label: controller.alreadyAdded ? 'In library' : 'Add to library',
        icon: Icons.add,
        emphasis: McActionEmphasis.primary,
        onPressed: controller.canAdd ? controller.add : null,
      );
    final progress = controller.progress;
    final total = progress?.total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        McActionFeedback(
          kind: McActionFeedbackKind.pending,
          message: 'Add to library',
          detail: progress == null || progress.stage == 'resolve'
              ? 'Required dependencies'
              : '${progress.reference.package.name} · ${progress.stage == 'install' ? 'Install' : _bytes(progress.bytes)}${total == null || progress.stage == 'install' ? '' : ' of ${_bytes(total)}'}',
        ),
        LinearProgressIndicator(
          value: total == null || total == 0
              ? null
              : (progress!.bytes / total).clamp(0, 1),
        ),
        const SizedBox(height: 12),
        McAction(
          label: 'Cancel',
          onPressed: () => unawaited(controller.cancel()),
        ),
      ],
    );
  }
}
