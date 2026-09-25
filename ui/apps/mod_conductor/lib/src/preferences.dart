part of 'app.dart';

CredentialPreferencesLabels _credentialLabels(AppLocalizations labels) =>
    CredentialPreferencesLabels(
      nexusMods: labels.credentialNexusMods,
      disconnectTitle: labels.credentialDisconnectTitle,
      disconnect: labels.credentialDisconnect,
      disconnectPause: labels.credentialDisconnectPause,
      disconnectRemovesSaved: labels.credentialDisconnectRemovesSaved,
      sessionOnlyTitle: labels.credentialSessionOnlyTitle,
      sessionOnly: labels.credentialSessionOnly,
      sessionOnlyLost: labels.credentialSessionOnlyLost,
      sessionOnlyKeepsSaved: labels.credentialSessionOnlyKeepsSaved,
      clearSessionTitle: labels.credentialClearSessionTitle,
      removeSavedTitle: labels.credentialRemoveSavedTitle,
      clearSignIn: labels.credentialClearSignIn,
      removeSignIn: labels.credentialRemoveSignIn,
      clearsSessionToo: labels.credentialClearsSessionToo,
      storageDetails: labels.credentialStorageDetails,
      close: labels.close,
      problem: (problem) => switch (problem) {
        CredentialProblem.locked => labels.credentialStorageLocked,
        CredentialProblem.unavailable => labels.credentialStorageUnavailable,
        CredentialProblem.denied => labels.credentialStorageDenied,
        CredentialProblem.timedOut => labels.credentialStorageTimedOut,
        CredentialProblem.cancelled => labels.credentialStorageCancelled,
        CredentialProblem.tooLarge => labels.credentialStorageTooLarge,
        CredentialProblem.failed => labels.credentialStorageFailed,
      },
      waitingSignIn: labels.credentialWaitingSignIn,
      premium: labels.credentialPremium,
      accountCurrent: labels.credentialAccountCurrent,
      checkingAccount: labels.credentialCheckingAccount,
      accountCheckFailed: labels.credentialAccountCheckFailed,
      notConnected: labels.credentialNotConnected,
      notSignedIn: labels.credentialNotSignedIn,
      notSaved: labels.credentialNotSaved,
      cancelSignIn: labels.credentialCancelSignIn,
      checkAccount: labels.credentialCheckAccount,
      signInAgain: labels.credentialSignInAgain,
      connect: labels.credentialConnect,
      signIn: labels.credentialSignIn,
      personalApiKey: labels.credentialPersonalApiKey,
      showPersonalApiKey: labels.credentialShowPersonalApiKey,
      hidePersonalApiKey: labels.credentialHidePersonalApiKey,
      submitPersonalApiKey: labels.credentialSubmitPersonalApiKey,
      storageCheckFailed: labels.credentialStorageCheckFailed,
      checkEngine: labels.credentialCheckEngine,
      savedNotRemoved: labels.credentialSavedNotRemoved,
      unlockKeyring: labels.credentialUnlockKeyring,
      saved: labels.credentialSaved,
      noneSaved: labels.credentialNoneSaved,
      cannotCheckSaved: labels.credentialCannotCheckSaved,
      newSignIns: labels.credentialNewSignIns,
      saveOnComputer: labels.credentialSaveOnComputer,
      checkStorage: labels.credentialCheckStorage,
      retryRemoval: labels.credentialRetryRemoval,
    );

NexusLinkPreferencesLabels _nexusLinkLabels(AppLocalizations labels) =>
    NexusLinkPreferencesLabels(
      title: labels.nexusLinks,
      description: labels.nexusOpenLinks,
      removeWindowsTitle: labels.nexusRemoveWindowsTitle,
      removeTitle: labels.nexusRemoveTitle,
      removeWindows: labels.nexusRemoveWindows,
      remove: labels.nexusRemove,
      chooseOtherDefault: labels.nexusChooseOtherDefault,
      restoreDefault: labels.nexusRestoreDefault,
      availableWindows: labels.nexusAvailableWindows,
      available: labels.nexusAvailable,
      notAddedWindows: labels.nexusNotAddedWindows,
      off: labels.nexusOff,
      cannotCheck: labels.nexusCannotCheck,
      defaultApp: labels.nexusDefaultApp,
      modConductor: labels.nexusModConductor,
      anotherApp: labels.nexusAnotherApp,
      notSet: labels.nexusNotSet,
      cannotCheckDefault: labels.nexusCannotCheckDefault,
      chooseDefaultWindows: labels.nexusChooseDefaultWindows,
      defaultChanged: labels.nexusDefaultChanged,
      checkFailed: labels.nexusCheckFailed,
      addWindows: labels.nexusAddWindows,
      useModConductor: labels.nexusUseModConductor,
      openWindows: labels.nexusOpenWindows,
      checkDefault: labels.nexusCheckDefault,
    );

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

  String _appearance(AppearancePreference value) => switch (value) {
    AppearancePreference.system => labels.systemAppearance,
    AppearancePreference.light => labels.light,
    AppearancePreference.dark => labels.dark,
  };

  String _contrast(ContrastPreference value) => switch (value) {
    ContrastPreference.system => labels.systemContrast,
    ContrastPreference.standard => labels.standardContrast,
    ContrastPreference.high => labels.highContrast,
  };

  @override
  Widget build(BuildContext context) {
    final workspaceScope = scope == _PreferenceScope.workspace;
    final changed =
        draft != applied ||
        (workspaceScope && inheritsApplication != inheritsApplicationApplied);
    final enabled = loaded && !busy && !(workspaceScope && inheritsApplication);
    return McPage(
      key: const PageStorageKey('preferences'),
      title: labels.preferences,
      children: [
        Semantics(
          container: true,
          explicitChildNodes: true,
          child: Column(
            children: [
              Semantics(
                container: true,
                explicitChildNodes: true,
                sortKey: const OrdinalSortKey(0, name: 'preferences-sections'),
                child: McSection(
                  title: labels.display,
                  children: [
                    if (loading)
                      McActionFeedback(
                        key: const ValueKey('preferences-feedback'),
                        kind: McActionFeedbackKind.pending,
                        message: labels.settingsLoading,
                      )
                    else if (busy)
                      McActionFeedback(
                        key: const ValueKey('preferences-feedback'),
                        kind: McActionFeedbackKind.pending,
                        message: labels.settingsSaving,
                      )
                    else if (problem != null)
                      McActionFeedback(
                        key: const ValueKey('preferences-feedback'),
                        kind: McActionFeedbackKind.failure,
                        message: problem == 'load'
                            ? labels.settingsLoadFailed
                            : labels.settingsSaveFailed,
                        detail: labels.settingsHelpDiagnostics,
                      )
                    else if (savedAt case final saved?)
                      McActionFeedback(
                        key: const ValueKey('preferences-feedback'),
                        kind: McActionFeedbackKind.success,
                        message: labels.preferencesSaved(saved),
                      ),
                    if (loading || busy || problem != null || savedAt != null)
                      const SizedBox(height: McSpacing.large),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Column(
                        children: [
                          McChoice<_PreferenceScope>(
                            key: const ValueKey('preferences-scope'),
                            label: labels.scope,
                            value: scope,
                            choices: workspaceAvailable
                                ? _PreferenceScope.values
                                : const [_PreferenceScope.application],
                            describe: (value) =>
                                value == _PreferenceScope.application
                                ? labels.application
                                : labels.currentWorkspace,
                            onChanged: onScope,
                          ),
                          if (!workspaceAvailable)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: McSpacing.small,
                              ),
                              child: Text(labels.workspaceSettingsUnavailable),
                            ),
                          if (loaded && workspaceScope) ...[
                            const SizedBox(height: McSpacing.large),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(labels.useApplicationSettings),
                              value: inheritsApplication,
                              onChanged: busy ? null : onInheritsApplication,
                            ),
                          ],
                          if (loaded) ...[
                            const SizedBox(height: McSpacing.large),
                            McChoice<AppearancePreference>(
                              key: const ValueKey('preferences-theme'),
                              label: labels.appearance,
                              value: draft.appearance,
                              choices: AppearancePreference.values,
                              describe: _appearance,
                              enabled: enabled,
                              onChanged: (value) => onDraft((
                                appearance: value,
                                textScale: draft.textScale,
                                interfaceScale: draft.interfaceScale,
                                contrast: draft.contrast,
                              )),
                            ),
                            const SizedBox(height: McSpacing.large),
                            McChoice<double>(
                              key: const ValueKey(
                                'preferences-interface-scale',
                              ),
                              label: labels.interfaceSize,
                              value: draft.interfaceScale,
                              choices: const [0.9, 1],
                              describe: (value) => labels.textScalePercent(
                                (value * 100).round(),
                              ),
                              enabled: enabled,
                              onChanged: (value) => onDraft((
                                appearance: draft.appearance,
                                textScale: draft.textScale,
                                interfaceScale: value,
                                contrast: draft.contrast,
                              )),
                            ),
                            const SizedBox(height: McSpacing.large),
                            McChoice<double>(
                              key: const ValueKey('preferences-scale'),
                              label: labels.textSize,
                              value: draft.textScale,
                              choices: const [1, 1.25, 1.5],
                              describe: (value) => labels.textScalePercent(
                                (value * 100).round(),
                              ),
                              enabled: enabled,
                              onChanged: (value) => onDraft((
                                appearance: draft.appearance,
                                textScale: value,
                                interfaceScale: draft.interfaceScale,
                                contrast: draft.contrast,
                              )),
                            ),
                            const SizedBox(height: McSpacing.large),
                            McChoice<ContrastPreference>(
                              key: const ValueKey('preferences-contrast'),
                              label: labels.contrast,
                              value: draft.contrast,
                              choices: ContrastPreference.values,
                              describe: _contrast,
                              enabled: enabled,
                              onChanged: (value) => onDraft((
                                appearance: draft.appearance,
                                textScale: draft.textScale,
                                interfaceScale: draft.interfaceScale,
                                contrast: value,
                              )),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: McSpacing.large),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        if (problem == 'load')
                          McAction(
                            key: const ValueKey('retry-preferences'),
                            label: labels.retry,
                            icon: Icons.refresh,
                            onPressed: onRetry,
                          ),
                        McAction(
                          key: const ValueKey('apply-preferences'),
                          label: labels.apply,
                          emphasis: McActionEmphasis.primary,
                          icon: Icons.check,
                          onPressed: loaded && changed && !busy ? onSave : null,
                        ),
                        McAction(
                          key: const ValueKey('cancel-preferences'),
                          label: labels.cancel,
                          onPressed: loaded && changed && !busy
                              ? onCancel
                              : null,
                        ),
                        McAction(
                          key: const ValueKey('session-details'),
                          label: labels.activePreferences,
                          focusNode: detailsFocus,
                          onPressed: !loaded
                              ? null
                              : () => _showActivePreferences(
                                  context,
                                  labels,
                                  applied,
                                  _appearance,
                                  _contrast,
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
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
}

Future<void> _showActivePreferences(
  BuildContext context,
  AppLocalizations labels,
  _Preferences applied,
  String Function(AppearancePreference) appearance,
  String Function(ContrastPreference) contrast,
) async {
  final previous = FocusManager.instance.primaryFocus;
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(labels.activePreferences),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                labels.appearance,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: McSpacing.small),
              Text(appearance(applied.appearance)),
              const SizedBox(height: McSpacing.large),
              Text(
                labels.interfaceSize,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: McSpacing.small),
              Text(
                labels.textScalePercent((applied.interfaceScale * 100).round()),
              ),
              const SizedBox(height: McSpacing.large),
              Text(
                labels.textSize,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: McSpacing.small),
              Text(labels.textScalePercent((applied.textScale * 100).round())),
              const SizedBox(height: McSpacing.large),
              Text(
                labels.contrast,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: McSpacing.small),
              Text(contrast(applied.contrast)),
            ],
          ),
        ),
      ),
      actions: [
        McAction(label: labels.close, onPressed: () => Navigator.pop(context)),
      ],
    ),
  );
  if (previous?.context != null) previous!.requestFocus();
}
