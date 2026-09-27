part of 'section.dart';

class _SkyrimSetupView extends StatelessWidget {
  const _SkyrimSetupView({
    required this.status,
    required this.selection,
    required this.busy,
    required this.problem,
    required this.updateEvidenceFresh,
    required this.skseReview,
    required this.skseReviewProblem,
    required this.reviewingSkse,
    required this.useLatestSkse,
    required this.skseChoiceReady,
    required this.onApply,
    required this.onClearChoices,
    required this.onRefresh,
    required this.onCancel,
    required this.onRetryOrContinue,
    required this.onSelectAction,
    required this.onChooseEnbArchive,
    required this.onClearEnbArchive,
    required this.onOpenProjectPage,
    required this.onChooseLatestSkse,
  });

  final SkyrimSetupStatus? status;
  final SkyrimSetupSelection selection;
  final bool busy;
  final String? problem;
  final bool updateEvidenceFresh;
  final SkseReleaseReview? skseReview;
  final String? skseReviewProblem;
  final bool reviewingSkse, useLatestSkse, skseChoiceReady;
  final VoidCallback onApply;
  final VoidCallback onClearChoices;
  final VoidCallback onRefresh;
  final VoidCallback onCancel;
  final ValueChanged<SkyrimSetupStatus> onRetryOrContinue;
  final void Function(String, SkyrimSetupAction) onSelectAction;
  final VoidCallback onChooseEnbArchive;
  final VoidCallback onClearEnbArchive;
  final ValueChanged<String> onOpenProjectPage;
  final VoidCallback onChooseLatestSkse;

  Widget skseReleaseReview() {
    if (reviewingSkse) {
      return const McStatus(title: 'Checking SKSE releases');
    }
    if (skseReviewProblem case final problem?) {
      return McStatus(
        title: 'SKSE release check failed',
        detail: problem,
        tone: McStatusTone.error,
      );
    }
    final review = skseReview;
    if (review == null) return const SizedBox.shrink();
    final supported = review.supportedRuntime == null
        ? 'The author does not state a supported runtime.'
        : 'Author-supported runtime: ${review.supportedRuntime}.';
    if (review.compatible) {
      return McStatus(
        title: 'Selected SKSE ${review.componentVersion}',
        detail: 'Detected Skyrim runtime: ${review.gameVersion}. $supported',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        McStatus(
          title: 'Compatibility warning',
          detail:
              'Detected Skyrim runtime: ${review.gameVersion}. '
              'Latest SKSE: ${review.componentVersion}. $supported '
              'This release may not work with your game.',
        ),
        const SizedBox(height: McSpacing.small),
        McAction(
          label: useLatestSkse
              ? 'Do not use latest SKSE'
              : 'Install latest SKSE',
          onPressed: busy ? null : onChooseLatestSkse,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final value = status;
    final locked =
        value?.active == true ||
        (value?.canCancel == true &&
            value?.phase != SkyrimSetupStatusPhase.failed);
    final components =
        value?.components
            .where((item) => const ['skse', 'enb', 'fnis'].contains(item.id))
            .toList() ??
        [];
    final failed =
        value != null &&
        (value.phase == SkyrimSetupStatusPhase.failed ||
            value.phase == SkyrimSetupStatusPhase.recoveryRequired);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (problem != null) ...[
          McStatus(title: problem!, tone: McStatusTone.error),
          const SizedBox(height: McSpacing.medium),
        ],
        if (value != null &&
            value.status.isNotEmpty &&
            !(value.phase == SkyrimSetupStatusPhase.cancelled &&
                selection.hasChange) &&
            value.status != 'Choose an ENBSeries archive') ...[
          McStatus(
            title: value.status,
            detail: value.detail.isEmpty ? null : value.detail,
            tone: failed ? McStatusTone.error : McStatusTone.neutral,
          ),
          const SizedBox(height: McSpacing.medium),
        ],
        _SkyrimSetupActions(
          status: value,
          selection: selection,
          busy: busy,
          locked: locked,
          failed: failed,
          skseChoiceReady: skseChoiceReady,
          onApply: onApply,
          onClearChoices: onClearChoices,
          onRefresh: onRefresh,
          onCancel: onCancel,
          onRetryOrContinue: onRetryOrContinue,
        ),
        if (components.isNotEmpty) ...[
          const SizedBox(height: McSpacing.medium),
          LayoutBuilder(
            builder: (_, bounds) => bounds.maxWidth < 680
                ? const SizedBox.shrink()
                : const Padding(
                    padding: EdgeInsets.symmetric(vertical: McSpacing.small),
                    child: Row(
                      children: [
                        Expanded(flex: 33, child: Text('Component')),
                        Expanded(flex: 24, child: Text('Current')),
                        Expanded(flex: 43, child: Text('Install')),
                      ],
                    ),
                  ),
          ),
          for (final item in components)
            _SkyrimSetupComponentRow(
              item: item,
              selection: selection,
              updateVersion: updateEvidenceFresh ? item.updateVersion : null,
              busy: busy,
              locked: locked,
              onSelectAction: onSelectAction,
              onChooseEnbArchive: onChooseEnbArchive,
              onClearEnbArchive: onClearEnbArchive,
              onOpenProjectPage: onOpenProjectPage,
            ),
          if (selection.skse == SkyrimSetupAction.install ||
              selection.skse == SkyrimSetupAction.update) ...[
            const SizedBox(height: McSpacing.medium),
            skseReleaseReview(),
          ],
        ],
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) => McSection(
        title: 'Skyrim setup',
        children: [
          if (constraints.hasBoundedHeight)
            Flexible(child: SingleChildScrollView(child: content))
          else
            content,
        ],
      ),
    );
  }
}
