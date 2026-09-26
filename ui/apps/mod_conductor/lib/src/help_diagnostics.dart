part of 'app.dart';

Future<void> _previewDiagnosticChange(
  BuildContext context,
  DiagnosticsController controller,
  DiagnosticFinding finding,
) async {
  final opener = FocusManager.instance.primaryFocus;
  final preview = await controller.previewChange(finding);
  if (!context.mounted || preview == null) return;
  final deployment = finding.code == 'deployment-incomplete';
  final apply = await showDialog<bool>(
    context: context,
    builder: (context) => McDialog(
      title: deployment
          ? 'Continue the deployment restore?'
          : 'Hide this file copy?',
      actions: [
        McAction(
          label: 'Cancel',
          onPressed: () => Navigator.pop(context, false),
        ),
        McAction(
          key: const ValueKey('apply-diagnostic-change'),
          label: deployment ? 'Continue restore' : 'Hide this copy',
          emphasis: McActionEmphasis.primary,
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
      children: [
        Text(
          deployment
              ? 'These managed paths will change:'
              : 'This change affects these items:',
        ),
        const SizedBox(height: 12),
        McFactGroup(
          title: 'Affected items',
          rows: [
            for (final item in preview.items) McFact(item.label, item.value),
          ],
        ),
        const SizedBox(height: 12),
        McStatus(
          title: deployment
              ? '${preview.items.length} managed paths will change'
              : '1 profile setting will change',
          detail: deployment
              ? null
              : 'Mod Conductor will not delete a mod file or a game file.',
        ),
        if (preview.identifiers.isNotEmpty)
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('Technical details'),
            children: [
              for (final item in preview.identifiers)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.label),
                  subtitle: SelectableText(item.value),
                ),
            ],
          ),
      ],
    ),
  );
  if (apply == true) await controller.applyChange();
  opener?.requestFocus();
}

class _HelpDiagnosticInspector extends StatelessWidget {
  const _HelpDiagnosticInspector({
    required this.controller,
    required this.finding,
    required this.settingsDiagnostic,
    required this.onClose,
    required this.previewFocus,
    required this.onPreview,
    required this.onExport,
  });

  final DiagnosticsController controller;
  final DiagnosticFinding? finding;
  final String? settingsDiagnostic;
  final VoidCallback onClose;
  final FocusNode previewFocus;
  final ValueChanged<DiagnosticFinding> onPreview;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final finding = this.finding;
    if (finding == null) {
      return McInspector(
        title: 'Diagnostics',
        onClose: onClose,
        footer: Align(
          alignment: Alignment.centerRight,
          child: McAction(
            label: 'Check again',
            onPressed: controller.busy ? null : controller.refresh,
          ),
        ),
        children: [
          if (settingsDiagnostic case final detail?) ...[
            const McStatus(
              title: 'Settings need attention.',
              tone: McStatusTone.error,
            ),
            ExpansionTile(
              title: const Text('Technical details'),
              children: [SelectableText(detail)],
            ),
            const SizedBox(height: McSpacing.medium),
          ],
          if (settingsDiagnostic == null ||
              controller.busy ||
              controller.problem != null)
            McStatus(
              title:
                  controller.problem ??
                  (controller.busy ? 'Diagnostics is active' : 'No problems'),
              tone: controller.problem == null
                  ? McStatusTone.neutral
                  : McStatusTone.error,
            ),
        ],
      );
    }
    return McInspector(
      title: finding.title,
      onClose: onClose,
      footer: Wrap(
        alignment: WrapAlignment.end,
        spacing: 8,
        runSpacing: 8,
        children: [
          if (finding.fixability == DiagnosticFixability.previewAvailable)
            McAction(
              key: const ValueKey('preview-diagnostic-change'),
              focusNode: previewFocus,
              label: finding.code == 'deployment-incomplete'
                  ? 'Preview paths'
                  : 'Preview change',
              emphasis: McActionEmphasis.primary,
              onPressed: controller.busy ? null : () => onPreview(finding),
            )
          else
            McAction(
              label: 'Check again',
              onPressed: controller.busy ? null : controller.refresh,
            ),
        ],
      ),
      children: [
        McStatus(
          title: controller.result?.result ?? finding.summary,
          detail: controller.result?.detail ?? finding.detail,
          tone:
              controller.result == null &&
                  finding.severity == DiagnosticSeverity.error
              ? McStatusTone.error
              : McStatusTone.neutral,
        ),
        const SizedBox(height: 20),
        McFactGroup(
          title: 'Applies to',
          rows: [
            McFact('Workspace', finding.workspaceName),
            McFact('Profile', finding.profileName),
            for (final item in finding.evidence.where(
              (item) => item.label != 'Workspace' && item.label != 'Profile',
            ))
              McFact(item.label, item.value),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'Next action',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(finding.nextAction),
        if (finding.fixDetail.isNotEmpty) ...[
          const SizedBox(height: 16),
          McStatus(title: finding.fixDetail),
        ],
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text('Technical details'),
          children: [
            for (final value in finding.correlations)
              Align(
                alignment: Alignment.centerLeft,
                child: SelectableText(
                  '${_correlationLabel(value.kind)}: ${value.id}${value.revision == null ? '' : ' · ${value.revision}'}',
                ),
              ),
          ],
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            key: const ValueKey('export-support'),
            onPressed: controller.busy ? null : onExport,
            child: const McIconLabel(
              icon: Icon(Icons.save_alt, size: 18),
              label: 'Export support report',
            ),
          ),
        ),
      ],
    );
  }

  String _correlationLabel(String value) => switch (value) {
    'launch' => 'Launch ID',
    'mod-files' => 'Mod file check ID',
    'game-setup' => 'Game setup ID',
    'deployment' => 'Deployment restore ID',
    'profile' => 'Profile ID',
    'action' => 'Action ID',
    'plugin-snapshot' => 'Plugin check ID',
    _ => 'Support ID',
  };
}
