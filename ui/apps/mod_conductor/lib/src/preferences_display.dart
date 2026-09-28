part of 'app.dart';

class _DisplayPreferencesSection extends StatelessWidget {
  const _DisplayPreferencesSection({
    required this.labels,
    required this.scope,
    required this.onScope,
    required this.workspaceAvailable,
    required this.inheritsApplication,
    required this.inheritsApplicationApplied,
    required this.onInheritsApplication,
    required this.applied,
    required this.draft,
    required this.loaded,
    required this.loading,
    required this.busy,
    required this.problem,
    required this.savedAt,
    required this.onDraft,
    required this.onSave,
    required this.onCancel,
    required this.onRetry,
    required this.detailsFocus,
  });

  final AppLocalizations labels;
  final _PreferenceScope scope;
  final ValueChanged<_PreferenceScope> onScope;
  final bool workspaceAvailable;
  final bool inheritsApplication;
  final bool inheritsApplicationApplied;
  final ValueChanged<bool> onInheritsApplication;
  final _Preferences applied;
  final _Preferences draft;
  final bool loaded;
  final bool loading;
  final bool busy;
  final String? problem;
  final DateTime? savedAt;
  final ValueChanged<_Preferences> onDraft;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final VoidCallback onRetry;
  final FocusNode detailsFocus;

  Widget? _feedback() {
    if (loading) {
      return McActionFeedback(
        key: const ValueKey('preferences-feedback'),
        kind: McActionFeedbackKind.pending,
        message: labels.settingsLoading,
      );
    }
    if (busy) {
      return McActionFeedback(
        key: const ValueKey('preferences-feedback'),
        kind: McActionFeedbackKind.pending,
        message: labels.settingsSaving,
      );
    }
    if (problem != null) {
      return McActionFeedback(
        key: const ValueKey('preferences-feedback'),
        kind: McActionFeedbackKind.failure,
        message: problem == 'load'
            ? labels.settingsLoadFailed
            : labels.settingsSaveFailed,
        detail: labels.settingsHelpDiagnostics,
      );
    }
    if (savedAt case final saved?) {
      return McActionFeedback(
        key: const ValueKey('preferences-feedback'),
        kind: McActionFeedbackKind.success,
        message: labels.preferencesSaved(saved),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final feedback = _feedback();
    return Semantics(
      container: true,
      explicitChildNodes: true,
      sortKey: const OrdinalSortKey(1, name: 'preferences-sections'),
      child: McSection(
        title: labels.display,
        children: [
          ?feedback,
          if (feedback != null) const SizedBox(height: McSpacing.large),
          _PreferencesDisplayControls(
            labels: labels,
            scope: scope,
            onScope: onScope,
            workspaceAvailable: workspaceAvailable,
            inheritsApplication: inheritsApplication,
            onInheritsApplication: onInheritsApplication,
            draft: draft,
            loaded: loaded,
            busy: busy,
            onDraft: onDraft,
          ),
          const SizedBox(height: McSpacing.large),
          _PreferencesActions(
            labels: labels,
            scope: scope,
            inheritsApplication: inheritsApplication,
            inheritsApplicationApplied: inheritsApplicationApplied,
            applied: applied,
            draft: draft,
            loaded: loaded,
            busy: busy,
            problem: problem,
            onSave: onSave,
            onCancel: onCancel,
            onRetry: onRetry,
            detailsFocus: detailsFocus,
          ),
        ],
      ),
    );
  }
}
