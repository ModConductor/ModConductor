part of 'section.dart';

class _SkyrimSetupActions extends StatelessWidget {
  const _SkyrimSetupActions({
    required this.status,
    required this.selection,
    required this.busy,
    required this.locked,
    required this.failed,
    required this.skseChoiceReady,
    required this.onApply,
    required this.onClearChoices,
    required this.onRefresh,
    required this.onCancel,
    required this.onRetryOrContinue,
  });

  final SkyrimSetupStatus? status;
  final SkyrimSetupSelection selection;
  final bool busy;
  final bool locked;
  final bool failed;
  final bool skseChoiceReady;
  final VoidCallback onApply;
  final VoidCallback onClearChoices;
  final VoidCallback onRefresh;
  final VoidCallback onCancel;
  final ValueChanged<SkyrimSetupStatus> onRetryOrContinue;

  @override
  Widget build(BuildContext context) {
    final value = status;
    final canApply =
        !busy &&
        !locked &&
        skseChoiceReady &&
        (value?.canStart == true ||
            value?.phase == SkyrimSetupStatusPhase.failed) &&
        selection.canApply;
    return Wrap(
      spacing: McSpacing.medium,
      runSpacing: McSpacing.medium,
      children: [
        McAction(
          key: const ValueKey('apply-skyrim-setup'),
          label: 'Apply',
          emphasis: McActionEmphasis.primary,
          onPressed: canApply ? onApply : null,
        ),
        if (selection.hasChange && !locked)
          McAction(
            label: 'Clear choices',
            onPressed: busy ? null : onClearChoices,
          ),
        McAction(
          key: const ValueKey('refresh-skyrim-setup'),
          label: 'Refresh',
          icon: Icons.refresh,
          onPressed: busy ? null : onRefresh,
        ),
        if (value?.canCancel == true)
          McAction(label: 'Cancel setup', onPressed: busy ? null : onCancel),
        if (failed && value!.canContinue)
          McAction(
            label: value.phase == SkyrimSetupStatusPhase.recoveryRequired
                ? 'Continue recovery'
                : 'Try again',
            onPressed: busy ? null : () => onRetryOrContinue(value),
          ),
      ],
    );
  }
}
