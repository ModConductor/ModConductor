import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'preferences_labels.dart';

class CredentialAccountContent extends StatelessWidget {
  const CredentialAccountContent({
    super.key,
    required this.labels,
    required this.status,
    required this.account,
    required this.hasNexus,
    required this.enabled,
    required this.checkingAccount,
    required this.accountChecked,
    required this.accountCheckFailed,
    required this.showPersonalApiKey,
    required this.personalApiKey,
    required this.onCancelSignIn,
    required this.onCheckAccount,
    required this.onDisconnect,
    required this.onConnect,
    required this.onSignIn,
    required this.onSubmitPersonalApiKey,
    required this.onTogglePersonalApiKey,
  });

  final CredentialPreferencesLabels labels;
  final CredentialStatus? status;
  final NexusAccount? account;
  final bool hasNexus, enabled, checkingAccount, accountChecked;
  final bool accountCheckFailed, showPersonalApiKey;
  final TextEditingController personalApiKey;
  final VoidCallback onCancelSignIn, onCheckAccount, onDisconnect;
  final VoidCallback onConnect, onSignIn, onSubmitPersonalApiKey;
  final VoidCallback onTogglePersonalApiKey;

  bool get reconnect =>
      status?.saved == SavedCredentials.present &&
      status?.mode != CredentialMode.sessionOnly &&
      account?.problem?.code != 'sign_in_required';

  Widget identity() {
    if (account?.waiting == true) {
      return McActionFeedback(
        kind: McActionFeedbackKind.pending,
        message: labels.waitingSignIn,
      );
    }
    final name =
        account?.name ??
        (status?.saved == SavedCredentials.present
            ? labels.notConnected
            : labels.notSignedIn);
    return McIdentityCard(
      key: const ValueKey('nexus-identity'),
      name: name,
      provider: labels.nexusMods,
      semanticLabel:
          '$name, ${labels.nexusMods}${account?.premium == true ? ', ${labels.premium}' : ''}',
      image: account?.profileImage == null
          ? null
          : NetworkImage(account!.profileImage!.toString()),
      fallbackIcon: account?.name == null ? Icons.person_outline : Icons.person,
      badges: [
        if (account?.premium == true)
          Chip(
            avatar: const Icon(Icons.workspace_premium_outlined, size: 17),
            label: Text(labels.premium),
          ),
      ],
    );
  }

  Widget accountActions() => Wrap(
    spacing: 12,
    runSpacing: 12,
    children: [
      if (account?.waiting == true)
        McAction(
          label: labels.cancelSignIn,
          onPressed: enabled ? onCancelSignIn : null,
        )
      else if (account?.name != null) ...[
        McAction(
          key: const ValueKey('nexus-check-account'),
          label: labels.checkAccount,
          icon: Icons.refresh,
          onPressed: enabled ? onCheckAccount : null,
        ),
        McAction(
          label: labels.disconnect,
          icon: Icons.logout,
          onPressed: enabled ? onDisconnect : null,
        ),
      ] else
        McAction(
          label: account?.problem?.code == 'sign_in_required'
              ? labels.signInAgain
              : reconnect
              ? labels.connect
              : labels.signIn,
          icon: Icons.login,
          emphasis: McActionEmphasis.primary,
          onPressed: enabled ? (reconnect ? onConnect : onSignIn) : null,
        ),
    ],
  );

  Widget accountFeedback() => McActionFeedback(
    key: const ValueKey('nexus-account-feedback'),
    kind: checkingAccount
        ? McActionFeedbackKind.pending
        : accountCheckFailed
        ? McActionFeedbackKind.failure
        : McActionFeedbackKind.success,
    message: checkingAccount
        ? labels.checkingAccount
        : accountCheckFailed
        ? labels.accountCheckFailed
        : labels.accountCurrent,
    detail: !accountCheckFailed
        ? null
        : account?.problem?.message ?? labels.checkEngine,
  );

  Widget keyEntry() => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 480),
    child: TextField(
      key: const ValueKey('nexus-personal-api-key'),
      controller: personalApiKey,
      obscureText: !showPersonalApiKey,
      enableSuggestions: false,
      autocorrect: false,
      textInputAction: TextInputAction.done,
      onSubmitted: enabled ? (_) => onSubmitPersonalApiKey() : null,
      decoration: InputDecoration(
        labelText: labels.personalApiKey,
        suffixIcon: McIconAction(
          label: showPersonalApiKey
              ? labels.hidePersonalApiKey
              : labels.showPersonalApiKey,
          icon: Icon(
            showPersonalApiKey ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: enabled ? onTogglePersonalApiKey : null,
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final accountProblem = account?.problem;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        identity(),
        if (!accountChecked && accountProblem != null) ...[
          const SizedBox(height: McSpacing.medium),
          McStatus(
            title: accountProblem.code == 'storage'
                ? labels.notSaved
                : accountProblem.message,
            detail: accountProblem.code == 'storage'
                ? accountProblem.message
                : null,
            tone: McStatusTone.error,
          ),
        ],
        if (hasNexus &&
            (account?.configured == true ||
                account?.name != null ||
                reconnect)) ...[
          const SizedBox(height: McSpacing.medium),
          accountActions(),
        ],
        if (checkingAccount || accountChecked) ...[
          const SizedBox(height: McSpacing.medium),
          accountFeedback(),
        ],
        if (account?.name == null && hasNexus) ...[
          const SizedBox(height: McSpacing.medium),
          keyEntry(),
          const SizedBox(height: McSpacing.medium),
          McAction(
            key: const ValueKey('submit-nexus-personal-api-key'),
            label: labels.submitPersonalApiKey,
            icon: Icons.key,
            onPressed: enabled ? onSubmitPersonalApiKey : null,
          ),
        ],
      ],
    );
  }
}
