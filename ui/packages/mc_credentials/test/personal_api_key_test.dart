import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_credentials/mc_credentials.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

const _status = CredentialStatus(
  mode: CredentialMode.secure,
  saved: SavedCredentials.absent,
  hasSession: false,
  problem: null,
  removalProblem: null,
  diagnosticReport: 'Storage available',
);

class _Nexus extends Fake implements NexusClient {
  NexusAccount account = const NexusAccount(false, false, null, null, null);
  final submitted = <String>[];

  @override
  Future<NexusAccount> status() async => account;

  @override
  Future<NexusAccount> submitPersonalApiKey(String apiKey) async {
    submitted.add(apiKey);
    return account = const NexusAccount(false, false, 'Rowan', false, null);
  }
}

class _Credentials extends Fake implements CredentialsClient {
  _Credentials(this.nexus);
  final _Nexus nexus;

  @override
  Future<CredentialStatus> status() async => _status;

  @override
  Future<CredentialStatus> remove() async {
    nexus.account = const NexusAccount(false, false, null, null, null);
    return _status;
  }
}

CredentialPreferencesLabels get _labels => CredentialPreferencesLabels(
  nexusMods: 'Nexus Mods',
  disconnectTitle: 'Disconnect?',
  disconnect: 'Disconnect',
  disconnectPause: 'Downloads pause.',
  disconnectRemovesSaved: 'Sign-in is removed.',
  sessionOnlyTitle: 'Session only?',
  sessionOnly: 'Session only',
  sessionOnlyLost: 'Lost on close.',
  sessionOnlyKeepsSaved: 'Saved details stay.',
  clearSessionTitle: 'Clear?',
  removeSavedTitle: 'Remove?',
  clearSignIn: 'Clear',
  removeSignIn: 'Remove',
  clearsSessionToo: 'Clears this session.',
  storageDetails: 'Storage details',
  close: 'Close',
  problem: (_) => 'Storage problem',
  waitingSignIn: 'Waiting',
  connectedAs: (name) => 'Connected as $name',
  premium: 'Premium',
  notConnected: 'Not connected',
  notSignedIn: 'Not signed in',
  notSaved: 'Not saved',
  cancelSignIn: 'Cancel',
  checkAccount: 'Check',
  signInAgain: 'Sign in again',
  connect: 'Connect',
  signIn: 'Sign in',
  personalApiKey: 'Enter personal API key',
  showPersonalApiKey: 'Show personal API key',
  hidePersonalApiKey: 'Hide personal API key',
  submitPersonalApiKey: 'Connect with API key',
  storageCheckFailed: 'Storage check failed',
  checkEngine: 'Check engine',
  savedNotRemoved: 'Not removed',
  unlockKeyring: 'Unlock keyring',
  saved: 'Saved',
  noneSaved: 'None saved',
  cannotCheckSaved: 'Cannot check',
  newSignIns: 'New sign-ins',
  saveOnComputer: 'Save on computer',
  checkStorage: 'Check storage',
  retryRemoval: 'Retry removal',
);

void main() {
  testWidgets(
    'personal API key visibility and candidate live only in one Preferences instance',
    (tester) async {
      final nexus = _Nexus();
      final credentials = _Credentials(nexus);
      var instance = 0;

      Widget app() => MaterialApp(
        theme: mcTheme(Brightness.light),
        home: Scaffold(
          body: CredentialPreferences(
            key: ValueKey(instance),
            client: credentials,
            nexus: nexus,
            labels: _labels,
          ),
        ),
      );

      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      final field = find.byKey(const ValueKey('nexus-personal-api-key'));
      expect(tester.widget<TextField>(field).obscureText, isTrue);

      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pump();
      expect(tester.widget<TextField>(field).obscureText, isFalse);

      await tester.enterText(field, 'synthetic-personal-key');
      await tester.tap(
        find.byKey(const ValueKey('submit-nexus-personal-api-key')),
      );
      await tester.pumpAndSettle();
      expect(nexus.submitted, ['synthetic-personal-key']);

      await tester.tap(find.text('Disconnect'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Disconnect').last);
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(field).controller!.text,
        'synthetic-personal-key',
      );

      instance++;
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(field).controller!.text, isEmpty);
      expect(nexus.submitted, ['synthetic-personal-key']);
    },
  );
}
