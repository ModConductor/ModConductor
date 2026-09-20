import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_skse/mc_skse.dart';

class _SkseFixtureClient extends SkseClient {
  _SkseFixtureClient(this.current)
    : super(ClientChannel('127.0.0.1', port: 1), CallOptions());

  SkseStatus current;
  int starts = 0;

  @override
  Future<SkseStatus> read(String workspace, String profile) async => current;

  @override
  Future<SkseStatus> start(String workspace, String profile) async {
    starts++;
    return current;
  }
}

Widget _section(_SkseFixtureClient client) => MaterialApp(
  home: Scaffold(
    body: SkseSection(
      client: client,
      workspaceId: 'workspace',
      profileId: 'profile',
    ),
  ),
);

void main() {
  testWidgets('an available update keeps the working version until accepted', (
    tester,
  ) async {
    final client = _SkseFixtureClient(
      const SkseStatus(
        SkseStatusPhase.updateAvailable,
        '1.7.104.0',
        '2.3.0',
        'SKSE update available',
        'The installed version remains selected.',
      ),
    );

    await tester.pumpWidget(_section(client));
    await tester.pumpAndSettle();
    expect(client.starts, 0);

    await tester.tap(find.byIcon(Icons.download));
    await tester.pumpAndSettle();
    expect(client.starts, 1);
  });

  testWidgets(
    'an incompatible installation cannot start replacement implicitly',
    (tester) async {
      final client = _SkseFixtureClient(
        const SkseStatus(
          SkseStatusPhase.incompatible,
          '1.8.0.0',
          '2.2.0',
          'Installed SKSE is incompatible',
          'No compatible author release is available.',
        ),
      );

      await tester.pumpWidget(_section(client));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.download), findsNothing);
      expect(client.starts, 0);
    },
  );
}
