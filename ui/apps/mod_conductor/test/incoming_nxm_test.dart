import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_desktop/mc_desktop.dart';
import 'package:mod_conductor/src/app.dart';

class _NxmFake extends Fake implements NxmClient {
  int downloads = 0;

  @override
  Future<NexusIngress> configure(int processId) async =>
      NexusIngress('local', Uint8List(0), processId);

  @override
  Future<NexusLink> read(
    String reference,
    String? workspace, {
    String? profile,
    bool download = false,
  }) async {
    if (download) downloads++;
    return NexusLink(
      'Skyrim',
      NexusFile(1, 'Request $reference', '', '', '', null),
      null,
      false,
      null,
      '',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dev.modconductor/desktop');
  late Map<String, Object?> nativeState;
  late DesktopRequests requests;
  late _NxmFake nxm;

  Future<void> mount(
    WidgetTester tester, {
    bool attachAfterFirstFrame = false,
  }) async {
    requests = DesktopRequests();
    nxm = _NxmFake();
    if (!attachAfterFirstFrame) requests.attach(null, nxm: nxm);
    await tester.pumpWidget(ModConductorApp(desktopRequests: requests));
    await tester.pumpAndSettle();
    if (attachAfterFirstFrame) {
      expect(find.text('Nexus Mods download'), findsOneWidget);
      requests.attach(null, nxm: nxm);
      await tester.pumpAndSettle();
    }
  }

  setUp(() {
    nativeState = {'available': true, 'count': 0, 'processId': 42};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'state') return nativeState;
          if (call.method == 'configureNxm') return null;
          if (call.method == 'dismiss') {
            nativeState = {'available': true, 'count': 0, 'processId': 42};
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets('cold-start NXM appears without a request click or download', (
    tester,
  ) async {
    nativeState = {
      'available': true,
      'count': 1,
      'id': 1,
      'nxmReference': 'cold',
      'processId': 42,
    };
    await mount(tester, attachAfterFirstFrame: true);

    expect(find.text('Request cold'), findsOneWidget);
    expect(nxm.downloads, 0);
    await tester.tap(find.text('Close').last);
    await tester.pumpAndSettle();
    expect(find.text('Request cold'), findsNothing);
    await requests.refresh();
    await tester.pumpAndSettle();
    expect(find.text('Request cold'), findsNothing);
    expect(requests.count, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    requests.dispose();
  });

  testWidgets('running app defers new NXM until an existing modal closes', (
    tester,
  ) async {
    await mount(tester);
    nativeState = {
      'available': true,
      'count': 1,
      'id': 1,
      'arguments': ['--workspace', '/older'],
      'processId': 42,
    };
    await requests.refresh();
    await tester.pumpAndSettle();
    final context = tester.element(
      find.byKey(const ValueKey('nav-workspaces')),
    );
    final modal = showDialog<void>(
      context: context,
      builder: (_) => const AlertDialog(title: Text('Current work')),
    );
    await tester.pumpAndSettle();

    nativeState = {
      'available': true,
      'count': 2,
      'id': 2,
      'nxmReference': 'newest',
      'processId': 42,
    };
    await requests.refresh();
    await tester.pumpAndSettle();
    expect(find.text('Current work'), findsOneWidget);
    expect(find.text('Request newest'), findsNothing);
    Navigator.of(context).pop();
    await modal;
    await tester.pumpAndSettle();
    expect(find.text('Request newest'), findsOneWidget);
    expect(requests.count, 2);
    expect(nxm.downloads, 0);

    await tester.pumpWidget(const SizedBox.shrink());
    requests.dispose();
  });
}
