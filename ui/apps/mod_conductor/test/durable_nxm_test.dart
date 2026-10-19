import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_artifacts/mc_artifacts.dart';
import 'package:mc_artifacts/src/artifact_inspector.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_desktop/mc_desktop.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';
import 'package:mc_workspaces/mc_workspaces.dart';

class _Inbox extends Fake implements NxmClient {
  List<PendingNexusLink> saved = const [
    PendingNexusLink('canonical', ['canonical', 'native-alias']),
  ];
  final opened = <String>[],
      dismissed = <String>[],
      readWorkspaces = <String?>[];
  int downloads = 0;
  bool handled = false;

  @override
  Future<NexusIngress> configure(int processId) async =>
      NexusIngress('isolated', Uint8List(0), processId);

  @override
  Future<List<PendingNexusLink>> pending() async => saved;

  @override
  Future<NexusLink> read(
    String reference,
    String? workspace, {
    String? profile,
    bool download = false,
  }) async {
    if (download) downloads++;
    readWorkspaces.add(workspace);
    return NexusLink(
      'Skyrim Special Edition',
      null,
      'A new download link is needed',
      false,
      null,
      'Use Mod Manager Download on Nexus Mods again.',
      sourcePage: 'https://www.nexusmods.com/skyrimspecialedition/mods/64012',
      modId: 64012,
      fileId: 501,
      freshLinkRequired: true,
      handled: handled,
    );
  }

  @override
  Future<void> openPage(String reference) async => opened.add(reference);

  @override
  Future<void> dismiss(String reference) async {
    dismissed.add(reference);
    saved = const [];
  }
}

class _Archives extends Fake implements ArtifactsClient {
  final opened = <Artifact>[];
  @override
  Future<void> openModPage(Artifact artifact) async => opened.add(artifact);
}

Artifact _archive({String? page}) => Artifact(
  id: 'retained-archive',
  workspaceId: 'origin-workspace',
  revision: 1,
  originalName: 'Quiet rivers.7z',
  originalPath: 'https://payload.example/expired-download',
  path: '/synthetic/download.partial',
  storage: ArtifactStorage.copy,
  state: ArtifactState.incomplete,
  links: const [],
  canRetry: false,
  canLocate: false,
  canDeleteCopy: true,
  canRemove: false,
  problem: 'Get a new Mod Manager Download link from Nexus Mods.',
  download: ArtifactDownload(
    phase: DownloadPhase.paused,
    bytes: 65536,
    total: 1048576,
    source: 'Nexus Mods',
    checksumMatched: false,
    restartRequired: false,
    modPage: page,
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dev.modconductor/desktop');
  late Map<String, Object?> native;
  late List<int> nativeDismissed;
  setUp(() {
    native = {'available': true, 'count': 0, 'processId': 42};
    nativeDismissed = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'state') return native;
          if (call.method == 'dismiss') {
            nativeDismissed.add(call.arguments as int);
            native = {'available': true, 'count': 0, 'processId': 42};
          }
          return null;
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('empty native queue restores intent without choosing workspace or downloading', () async {
    final requests = DesktopRequests(), inbox = _Inbox();
    addTearDown(requests.dispose);
    requests.attach(null, nxm: inbox);
    await requests.refresh();
    expect(requests.nexusReference, 'canonical');
    expect(requests.id, isNegative);
    expect(requests.count, 1);
    expect(requests.workspaceId, isNull);
    expect(inbox.downloads, 0);
    expect(inbox.readWorkspaces, everyElement(isNull));
    await requests.dismiss(requests.id!);
    expect(inbox.dismissed, ['canonical']);
    expect(nativeDismissed, isEmpty);
    expect(requests.id, isNull);
  });

  test('backend reconnect merges already delivered alias and drops durable handled intent', () async {
    native = {
      'available': true,
      'count': 1,
      'id': 7,
      'nxmReference': 'native-alias',
      'processId': 42,
    };
    final requests = DesktopRequests(),
        first = _Inbox(),
        reconnected = _Inbox();
    addTearDown(requests.dispose);
    requests.attach(null, nxm: first);
    await requests.refresh();
    expect(requests.nexusReference, 'canonical');
    expect(requests.count, 1);
    requests.attach(null, nxm: reconnected);
    await requests.connectNexus();
    await requests.refresh();
    expect(requests.id, 7);
    expect(requests.count, 1);
    expect(reconnected.downloads, 0);
    reconnected.saved = const [];
    reconnected.handled = true;
    await requests.refresh();
    expect(nativeDismissed, [7]);
    expect(requests.id, isNull);
    expect(reconnected.downloads, 0);
  });

  setUpAll(() async {
    for (final (family, asset) in [
      (
        'packages/mc_ui_foundation/Roboto',
        'packages/mc_ui_foundation/assets/fonts/Roboto-Regular.ttf',
      ),
      ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
    ]) {
      await (FontLoader(family)..addFont(rootBundle.load(asset))).load();
    }
  });

  for (final width in [420.0, 1280.0]) {
    for (final brightness in Brightness.values) {
      testWidgets('source actions keep consent at $width ${brightness.name}', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 900);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        final key = GlobalKey();
        final requests = DesktopRequests(), inbox = _Inbox();
        final workspaces = WorkspaceController();
        addTearDown(requests.dispose);
        addTearDown(workspaces.dispose);
        requests.attach(null, nxm: inbox);
        await requests.refresh();
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: MaterialApp(
              theme: mcTheme(brightness),
              home: Scaffold(
                body: OpenRequestsDialog(
                  requests: requests,
                  workspaces: workspaces,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await _capture(
          tester,
          key,
          'request-${width.toInt()}-${brightness.name}',
        );
        await tester.tap(find.text('Get a fresh download link'));
        await tester.pumpAndSettle();
        expect(inbox.opened, ['canonical']);
        final staleOpen = tester
            .widget<McAction>(
              find.ancestor(
                of: find.text('Get a fresh download link'),
                matching: find.byType(McAction),
              ),
            )
            .onPressed!;
        inbox.saved = const [
          PendingNexusLink('new-request', ['new-request']),
        ];
        await requests.refresh();
        staleOpen();
        await tester.pumpAndSettle();
        expect(inbox.opened, ['canonical']);
        expect(inbox.downloads, 0);
        expect(requests.workspaceId, isNull);
        expect(workspaces.workspace, isNull);
        expect(tester.takeException(), isNull);

        final controller = ArtifactController(), client = _Archives();
        addTearDown(controller.dispose);
        final artifact = _archive(
          page: 'https://www.nexusmods.com/fallout4/mods/9',
        );
        controller.client = client;
        controller.workspaceId = 'different-current-workspace';
        controller.model.apply(upserts: [artifact]);
        controller.model.select(artifact.id);
        var installations = 0;
        Widget inspector() => RepaintBoundary(
          key: key,
          child: MaterialApp(
            theme: mcTheme(brightness),
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: width > 600 ? 520 : width,
                  child: ArtifactInspector(
                    controller: controller,
                    onClose: () {},
                    onRead: (_) {},
                    onInstall: (_) => installations++,
                    onLocate: (_) async {},
                    onLink: (_) async {},
                    onCleanup: (_, _) async {},
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpWidget(inspector());
        await tester.pumpAndSettle();
        await _capture(
          tester,
          key,
          'archive-${width.toInt()}-${brightness.name}',
        );
        await tester.tap(find.text('Open mod page'));
        await tester.pumpAndSettle();
        expect(client.opened.single, same(artifact));
        expect(installations, 0);
        controller.model.apply(upserts: [_archive()]);
        await tester.pumpWidget(inspector());
        await tester.pumpAndSettle();
        expect(find.text('Open mod page'), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }
}

Future<void> _capture(WidgetTester tester, GlobalKey key, String name) async {
  final directory = Platform.environment['MC128_RENDER_DIR'];
  if (directory == null) return;
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory(directory).create(recursive: true);
    await File('$directory/$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}
