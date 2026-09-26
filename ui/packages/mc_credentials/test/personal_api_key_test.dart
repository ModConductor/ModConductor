import 'dart:async';

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
  _Nexus() {
    replaceEvents();
  }

  void replaceEvents() {
    events = StreamController<NexusAccount>.broadcast(
      onListen: () => scheduleMicrotask(() => events.add(account)),
    );
  }

  NexusAccount account = const NexusAccount(false, false, null, null, null);
  late StreamController<NexusAccount> events;
  int watches = 0;
  final submitted = <String>[];
  Completer<NexusAccount>? pendingCheck;
  Object? checkError;
  int checks = 0;

  @override
  Future<NexusAccount> status() async => account;

  @override
  Stream<NexusAccount> watchStatus() {
    watches++;
    return events.stream;
  }

  @override
  Future<NexusAccount> submitPersonalApiKey(String apiKey) async {
    submitted.add(apiKey);
    return account = const NexusAccount(false, false, 'Rowan', false, null);
  }

  @override
  Future<NexusAccount> check() {
    checks++;
    if (checkError case final error?) return Future.error(error);
    return pendingCheck?.future ?? Future.value(account);
  }
}

class _Credentials extends Fake implements CredentialsClient {
  _Credentials(this.nexus);
  final _Nexus nexus;
  int statusReads = 0;

  @override
  Future<CredentialStatus> status() async {
    statusReads++;
    return _status;
  }

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
  premium: 'Premium',
  accountCurrent: 'Current',
  checkingAccount: 'Checking',
  accountCheckFailed: 'Check failed',
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
    'account watch reconnects to current status after stream failure',
    (tester) async {
      final nexus = _Nexus();
      final credentials = _Credentials(nexus);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CredentialPreferences(
              client: credentials,
              nexus: nexus,
              labels: _labels,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(nexus.watches, 1);
      nexus.events.addError(StateError('connection lost'));
      await tester.pump();
      nexus.account = const NexusAccount(false, false, 'Rowan', true, null);
      await tester.pump(const Duration(milliseconds: 1100));
      await tester.pumpAndSettle();
      expect(nexus.watches, 2);
      expect(find.byType(McIdentityCard), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1100));
      expect(nexus.watches, 2);
      await nexus.events.close();
      nexus.replaceEvents();
      await tester.pump(const Duration(milliseconds: 1100));
      await tester.pumpAndSettle();
      expect(nexus.watches, 3);
    },
  );

  testWidgets(
    'background account connection updates Preferences from an event',
    (tester) async {
      final nexus = _Nexus();
      final credentials = _Credentials(nexus);
      await tester.pumpWidget(
        MaterialApp(
          theme: mcTheme(Brightness.dark),
          home: Scaffold(
            body: CredentialPreferences(
              client: credentials,
              nexus: nexus,
              labels: _labels,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final initialReads = credentials.statusReads;

      nexus.account = const NexusAccount(false, false, 'Rowan', true, null);
      nexus.events.add(nexus.account);
      await tester.pumpAndSettle();

      expect(find.byType(McIdentityCard), findsOneWidget);
      expect(credentials.statusReads, initialReads + 1);
    },
  );

  testWidgets('old account reconnect cannot replace a new client', (
    tester,
  ) async {
    final oldNexus = _Nexus()
      ..account = const NexusAccount(false, false, 'Old account', false, null);
    final newNexus = _Nexus()
      ..account = const NexusAccount(false, false, 'New account', false, null);

    Widget app(_Nexus nexus) => MaterialApp(
      theme: mcTheme(Brightness.dark),
      home: Scaffold(
        body: CredentialPreferences(
          client: _Credentials(nexus),
          nexus: nexus,
          labels: _labels,
        ),
      ),
    );

    await tester.pumpWidget(app(oldNexus));
    await tester.pumpAndSettle();
    oldNexus.events.addError(StateError('connection lost'));
    await tester.pump();

    await tester.pumpWidget(app(newNexus));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pumpAndSettle();

    expect(oldNexus.watches, 1);
    expect(newNexus.watches, 1);
    expect(
      tester.widget<McIdentityCard>(find.byType(McIdentityCard)).name,
      'New account',
    );
  });

  testWidgets(
    'personal API key visibility and candidate live only in one Preferences instance',
    (tester) async {
      final nexus = _Nexus();
      final credentials = _Credentials(nexus);
      var instance = 0;

      Widget app() => MaterialApp(
        theme: mcTheme(Brightness.light),
        home: Scaffold(
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: CredentialPreferences(
              key: ValueKey(instance),
              client: credentials,
              nexus: nexus,
              labels: _labels,
            ),
          ),
        ),
      );

      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      final field = find.byKey(const ValueKey('nexus-personal-api-key'));
      expect(Directionality.of(tester.element(field)), TextDirection.rtl);
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

  testWidgets('account checks replace pending feedback with one result', (
    tester,
  ) async {
    final nexus = _Nexus()
      ..account = const NexusAccount(false, false, 'Rowan', true, null)
      ..pendingCheck = Completer<NexusAccount>();
    final credentials = _Credentials(nexus);
    await tester.pumpWidget(
      MaterialApp(
        theme: mcTheme(Brightness.dark),
        home: Scaffold(
          body: CredentialPreferences(
            client: credentials,
            nexus: nexus,
            labels: _labels,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(McIdentityCard), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('nexus-check-account')));
    await tester.pump();
    expect(
      tester.widget<McActionFeedback>(find.byType(McActionFeedback)).kind,
      McActionFeedbackKind.pending,
    );
    nexus.pendingCheck!.complete(nexus.account);
    await tester.pumpAndSettle();
    expect(find.byType(McActionFeedback), findsOneWidget);
    expect(
      tester.widget<McActionFeedback>(find.byType(McActionFeedback)).kind,
      McActionFeedbackKind.success,
    );
    nexus.pendingCheck = null;
    await tester.tap(find.byKey(const ValueKey('nexus-check-account')));
    await tester.pumpAndSettle();
    expect(nexus.checks, 2);
    expect(find.byType(McActionFeedback), findsOneWidget);
    nexus.checkError = const NexusProblem('connection', 'Synthetic failure');
    await tester.tap(find.byKey(const ValueKey('nexus-check-account')));
    await tester.pumpAndSettle();
    expect(nexus.checks, 3);
    expect(find.byType(McActionFeedback), findsOneWidget);
    expect(
      tester.widget<McActionFeedback>(find.byType(McActionFeedback)).kind,
      McActionFeedbackKind.failure,
    );
  });
}
