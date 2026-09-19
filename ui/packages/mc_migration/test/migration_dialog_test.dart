import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_migration/mc_migration.dart';

final class _Client implements MigrationClient {
  final events = StreamController<MigrationEvent>();
  int calls = 0;

  MigrationManager? manager;
  String? sourcePath, profileId, stagingRoot, downloadRoot;

  @override
  Future<List<BackupProfile>> profiles(
    MigrationManager manager,
    String sourceFile,
  ) async => const [
    BackupProfile(id: 'profile-b', name: 'Second profile', gameId: 'game'),
    BackupProfile(id: 'profile-a', name: 'First profile', gameId: 'game'),
  ];

  @override
  Stream<MigrationEvent> migrate(
    String workspaceId,
    MigrationManager manager,
    String sourcePath, {
    String profileId = '',
    String stagingRoot = '',
    String downloadRoot = '',
  }) {
    calls++;
    this.manager = manager;
    this.sourcePath = sourcePath;
    this.profileId = profileId;
    this.stagingRoot = stagingRoot;
    this.downloadRoot = downloadRoot;
    return events.stream;
  }
}

void main() {
  testWidgets('the action should select a source and finish one migration', (
    tester,
  ) async {
    final client = _Client();
    var completed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: MigrationAction(
          client: client,
          workspaceId: 'workspace',
          chooseDirectory: (_) async => '/source',
          onComplete: () async => completed++,
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('migrate-from-manager')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('source-manager')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mod Organizer').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('choose-source-folder')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('submit')));
    await tester.pump();
    expect(client.calls, 1);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    client.events.add(const MigrationProgress(1, 2, 'Copying'));
    await tester.pump();
    client.events.add(const MigrationResult('workspace'));
    await client.events.close();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('close-migration')));
    await tester.pumpAndSettle();
    expect(completed, 1);
  });

  testWidgets('a migration error should keep the selected source available', (
    tester,
  ) async {
    final client = _Client();
    await tester.pumpWidget(
      MaterialApp(
        home: MigrationDialog(
          client: client,
          workspaceId: 'workspace',
          chooseDirectory: (_) async => '/source',
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('source-manager')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mod Organizer').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('choose-source-folder')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('submit')));
    await tester.pump();
    client.events.add(const MigrationFailure('Not supported'));
    await client.events.close();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('choose-source-folder')), findsOneWidget);
    expect(find.byKey(const ValueKey('submit')), findsOneWidget);
  });

  testWidgets('Vortex controls should submit the selected profile and roots', (
    tester,
  ) async {
    final client = _Client();
    final directories = ['/staging', '/downloads'].iterator;
    await tester.pumpWidget(
      MaterialApp(
        home: MigrationDialog(
          client: client,
          workspaceId: 'workspace',
          chooseFile: (_) async => '/backup.json',
          chooseDirectory: (_) async {
            directories.moveNext();
            return directories.current;
          },
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('source-manager')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vortex').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('choose-backup-file')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('source-profile')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Second profile').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('choose-staging-root')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('choose-download-root')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('submit')));
    await tester.pump();

    expect(client.calls, 1);
    expect(client.manager, MigrationManager.vortex);
    expect(client.sourcePath, '/backup.json');
    expect(client.profileId, 'profile-b');
    expect(client.stagingRoot, '/staging');
    expect(client.downloadRoot, '/downloads');
  });
}
