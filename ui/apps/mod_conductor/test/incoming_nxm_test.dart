import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_desktop/mc_desktop.dart';
import 'package:mod_conductor/src/app.dart';

class _NxmFake extends Fake implements NxmClient {
  int downloads = 0;
  final dismissed = <String>[];

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

  @override
  Future<void> dismiss(String reference) async => dismissed.add(reference);
}

class _DesktopFake extends Fake implements DesktopClient {
  @override
  Future<DesktopIntent> resolve(List<String> arguments) async =>
      const DesktopIntent(DesktopIntentKind.workspace, '/older', 'older', 0);
}

class _WorkspacesFake extends Fake implements WorkspacesClient {
  final opened = Completer<WorkspacePage>();
  String? openedPath;

  @override
  Future<WorkspaceList> recent({String? after}) async =>
      const WorkspaceList([], null);

  @override
  Future<WorkspacePage> open(String path) {
    openedPath = path;
    return opened.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dev.modconductor/desktop');
  late Map<String, Object?> nativeState;
  late DesktopRequests requests;
  late _NxmFake nxm;
  late List<int> dismissed;

  Future<void> mount(
    WidgetTester tester, {
    bool attachAfterFirstFrame = false,
    DesktopClient? desktop,
    WorkspacesClient? workspaces,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    requests = DesktopRequests();
    nxm = _NxmFake();
    if (!attachAfterFirstFrame) requests.attach(desktop, nxm: nxm);
    await tester.pumpWidget(
      ModConductorApp(desktopRequests: requests, workspaces: workspaces),
    );
    await tester.pumpAndSettle();
    if (attachAfterFirstFrame) {
      expect(find.text('Nexus Mods download'), findsOneWidget);
      requests.attach(desktop, nxm: nxm);
      await tester.pumpAndSettle();
    }
  }

  setUp(() {
    nativeState = {'available': true, 'count': 0, 'processId': 42};
    dismissed = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'state') return nativeState;
          if (call.method == 'configureNxm') return null;
          if (call.method == 'dismiss') {
            final id = call.arguments as int;
            dismissed.add(id);
            if (nativeState['id'] == id) {
              nativeState = {'available': true, 'count': 0, 'processId': 42};
            } else {
              nativeState = {
                ...nativeState,
                'count': (nativeState['count'] as int) - 1,
              };
            }
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

  testWidgets('new NXM waits for a preempted workspace action, then opens', (
    tester,
  ) async {
    nativeState = {
      'available': true,
      'count': 1,
      'id': 1,
      'arguments': ['--workspace', '/older'],
      'processId': 42,
    };
    final workspaces = _WorkspacesFake();
    await mount(tester, desktop: _DesktopFake(), workspaces: workspaces);
    await tester.tap(find.byKey(const ValueKey('open-requests')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open workspace').last);
    await tester.pump(const Duration(milliseconds: 300));
    expect(workspaces.openedPath, '/older');
    expect(workspaces.opened.isCompleted, isFalse);

    nativeState = {
      'available': true,
      'count': 2,
      'id': 2,
      'nxmReference': 'newer',
      'processId': 42,
    };
    await requests.refresh();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Request newer'), findsNothing);

    workspaces.opened.complete(
      const WorkspacePage(
        WorkspaceInfo(id: 'older', name: 'Older', path: '/older', revision: 1),
        [],
        null,
      ),
    );
    await tester.pumpAndSettle();
    expect(dismissed, [1]);
    expect(requests.id, 2);
    expect(requests.count, 1);
    expect(find.text('Request newer'), findsOneWidget);
    expect(nxm.downloads, 0);

    await tester.pumpWidget(const SizedBox.shrink());
    requests.dispose();
  });

  test('preempted Nexus choice dismisses its own private reference', () async {
    nativeState = {
      'available': true,
      'count': 1,
      'id': 1,
      'nxmReference': 'older',
      'processId': 42,
    };
    requests = DesktopRequests();
    nxm = _NxmFake();
    requests.attach(null, nxm: nxm);
    await requests.refresh();
    nativeState = {
      'available': true,
      'count': 2,
      'id': 2,
      'nxmReference': 'newer',
      'processId': 42,
    };
    await requests.refresh();
    await requests.dismiss(1, nexusReference: 'older');
    expect(nxm.dismissed, ['older']);
    expect(dismissed, [1]);
    expect(requests.id, 2);
    expect(requests.count, 1);
    requests.dispose();
  });
}
