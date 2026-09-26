part of 'app.dart';

class _PreferencesPage extends StatelessWidget {
  const _PreferencesPage({
    required this.labels,
    required this.credentials,
    required this.nexus,
    required this.linkSetup,
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
  final CredentialsClient? credentials;
  final NexusClient? nexus;
  final LinkSetupClient? linkSetup;
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

  @override
  Widget build(BuildContext context) => McPage(
    key: const PageStorageKey('preferences'),
    title: labels.preferences,
    children: [
      Semantics(
        container: true,
        explicitChildNodes: true,
        child: Column(
          children: [
            _DisplayPreferencesSection(
              labels: labels,
              scope: scope,
              onScope: onScope,
              workspaceAvailable: workspaceAvailable,
              inheritsApplication: inheritsApplication,
              inheritsApplicationApplied: inheritsApplicationApplied,
              onInheritsApplication: onInheritsApplication,
              applied: applied,
              draft: draft,
              loaded: loaded,
              loading: loading,
              busy: busy,
              problem: problem,
              savedAt: savedAt,
              onDraft: onDraft,
              onSave: onSave,
              onCancel: onCancel,
              onRetry: onRetry,
              detailsFocus: detailsFocus,
            ),
            const SizedBox(height: McSpacing.medium),
            Semantics(
              container: true,
              explicitChildNodes: true,
              sortKey: const OrdinalSortKey(1, name: 'preferences-sections'),
              child: CredentialPreferences(
                client: credentials,
                nexus: nexus,
                labels: _credentialLabels(labels),
              ),
            ),
            const SizedBox(height: McSpacing.medium),
            Semantics(
              container: true,
              explicitChildNodes: true,
              sortKey: const OrdinalSortKey(2, name: 'preferences-sections'),
              child: NexusLinkPreferences(
                client: linkSetup,
                labels: _nexusLinkLabels(labels),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
