import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'preferences_labels.dart';

class CredentialStorageContent extends StatelessWidget {
  const CredentialStorageContent({
    super.key,
    required this.labels,
    required this.status,
    required this.accountName,
    required this.clientAvailable,
    required this.connectionProblem,
    required this.enabled,
    required this.busy,
    required this.onMode,
    required this.onRefresh,
    required this.onRemove,
    required this.onDetails,
  });

  final CredentialPreferencesLabels labels;
  final CredentialStatus? status;
  final String? accountName;
  final bool clientAvailable, connectionProblem, enabled, busy;
  final ValueChanged<CredentialMode> onMode;
  final VoidCallback onRefresh, onRemove, onDetails;

  List<Widget> problemStatus() {
    if (!clientAvailable || connectionProblem) {
      return [
        McStatus(
          title: labels.storageCheckFailed,
          detail: labels.checkEngine,
          tone: McStatusTone.error,
        ),
        const SizedBox(height: McSpacing.medium),
      ];
    }
    final removalProblem = status?.removalProblem;
    if (removalProblem != null) {
      return [
        McStatus(
          title: labels.savedNotRemoved,
          detail: removalProblem == CredentialProblem.locked
              ? labels.unlockKeyring
              : labels.problem(removalProblem),
          tone: McStatusTone.error,
        ),
        const SizedBox(height: McSpacing.medium),
      ];
    }
    final problem = status?.problem;
    if (problem == null) return [];
    return [
      McStatus(title: labels.problem(problem)),
      const SizedBox(height: McSpacing.medium),
    ];
  }

  String get savedLabel => switch (status?.saved) {
    SavedCredentials.present => labels.saved,
    SavedCredentials.absent => labels.noneSaved,
    SavedCredentials.unknown || null => labels.cannotCheckSaved,
  };

  bool get canRemove =>
      accountName == null &&
      status != null &&
      (status!.saved == SavedCredentials.present ||
          status!.hasSession ||
          status!.removalProblem != null);

  String get removeLabel {
    if (status!.removalProblem != null) return labels.retryRemoval;
    return status!.saved == SavedCredentials.absent
        ? labels.clearSignIn
        : labels.removeSignIn;
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ...problemStatus(),
      Text(savedLabel),
      const SizedBox(height: McSpacing.medium),
      if (status != null)
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: McChoice<CredentialMode>(
            label: labels.newSignIns,
            value: status!.mode,
            choices: CredentialMode.values,
            enabled: enabled,
            describe: (mode) => switch (mode) {
              CredentialMode.secure => labels.saveOnComputer,
              CredentialMode.sessionOnly => labels.sessionOnly,
            },
            onChanged: onMode,
          ),
        ),
      const SizedBox(height: McSpacing.medium),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          McAction(
            label: labels.checkStorage,
            icon: Icons.refresh,
            onPressed: enabled ? onRefresh : null,
          ),
          if (canRemove)
            McAction(
              label: removeLabel,
              icon: Icons.delete_outline,
              onPressed: enabled ? onRemove : null,
            ),
          McIconAction(
            label: labels.storageDetails,
            icon: const Icon(Icons.info_outline),
            onPressed: status == null || busy ? null : onDetails,
          ),
        ],
      ),
    ],
  );
}
