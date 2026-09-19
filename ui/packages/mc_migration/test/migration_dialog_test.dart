import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_migration/mc_migration.dart';

final class _Client implements MigrationClient {
  final events = StreamController<MigrationEvent>();
  int calls = 0;

  @override
  Stream<MigrationEvent> migrate(
    String workspaceId,
    MigrationManager manager,
    String sourceFolder,
  ) {
    calls++;
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
}
