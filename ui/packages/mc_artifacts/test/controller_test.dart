import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_artifacts/mc_artifacts.dart';

Artifact archive(
  String workspace,
  String id, {
  ArtifactDownload? download,
  int revision = 0,
}) => Artifact(
  id: id,
  workspaceId: workspace,
  revision: revision,
  download: download,
  originalName: '$id.zip',
  originalPath: '/$id.zip',
  path: '/$id.zip',
  storage: ArtifactStorage.reference,
  state: ArtifactState.ready,
  links: const [],
  canRetry: false,
  canLocate: true,
  canDeleteCopy: false,
  canRemove: true,
);

class Client implements ArtifactsClient {
  @override
  Future<Artifact> download(
    String workspaceId,
    String id,
    ArchiveDownloadRequest request,
  ) => throw UnimplementedError();
  @override
  Future<Artifact> controlDownload(Artifact artifact, DownloadAction action) =>
      throw UnimplementedError();
  final feeds = <StreamController<Artifact>>[];
  @override
  Stream<Artifact> watchDownloads(String workspaceId, List<String> ids) {
    final feed = StreamController<Artifact>();
    feeds.add(feed);
    return feed.stream;
  }

  final pages = <Completer<ArtifactPage>>[];
  final added = Completer<Artifact>();
  final known = <String, Artifact>{};
  @override
  Future<ArtifactPage> list(
    String workspaceId, {
    String? after,
    bool refresh = false,
  }) {
    final page = Completer<ArtifactPage>();
    pages.add(page);
    return page.future;
  }

  @override
  Future<Artifact> add(
    String workspaceId,
    String id,
    String path,
    ArtifactStorage storage,
  ) => added.future;
  @override
  Future<ArtifactLinkPage> linkOptions(String workspaceId, {String? after}) =>
      throw UnimplementedError();
  @override
  Future<Artifact> read(String workspaceId, String id) async => known[id]!;
  @override
  Future<Artifact> retry(Artifact expected) => throw UnimplementedError();
  @override
  Future<Artifact> locate(Artifact expected, String path) =>
      throw UnimplementedError();
  @override
  Future<Artifact> link(
    Artifact expected,
    ArtifactLink link, {
    bool remove = false,
  }) => throw UnimplementedError();
  @override
  Future<Artifact> deleteCopy(Artifact expected) => throw UnimplementedError();
  @override
  Future<void> remove(Artifact expected) => throw UnimplementedError();
}

void main() {
  test('download observations preserve newer state and cannot cross workspace navigation', () async {
    final client = Client(), controller = ArtifactController();
    addTearDown(() async {
      controller.dispose();
      for (final feed in client.feeds) {
        await feed.close();
      }
    });
    const download = ArtifactDownload(
      phase: DownloadPhase.running,
      bytes: 64,
      source: 'https://example.test/file',
      checksumMatched: false,
      restartRequired: false,
    );
    controller.attach(client, 'first');
    client.pages.single.complete(
      ArtifactPage([archive('first', 'transfer', download: download)], null),
    );
    await Future<void>.delayed(Duration.zero);
    controller.model.select('transfer');
    final old = client.feeds.single;
    old.add(archive('first', 'transfer', download: download, revision: 2));
    old.add(archive('first', 'transfer', download: download, revision: 1));
    await Future<void>.delayed(Duration.zero);
    expect(controller.selected!.revision, 2);
    old.addError(const ArtifactProblem('Observation lost'));
    await Future<void>.delayed(Duration.zero);
    expect(controller.progressProblem, isNotNull);
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    client.feeds.last.add(
      archive('first', 'transfer', download: download, revision: 2),
    );
    await Future<void>.delayed(Duration.zero);
    expect(controller.progressProblem, isNull);
    controller.attach(client, 'second');
    client.pages.last.complete(
      ArtifactPage([archive('second', 'other')], null),
    );
    old.add(archive('first', 'transfer', download: download, revision: 3));
    await Future<void>.delayed(Duration.zero);
    expect(controller.workspaceId, 'second');
    expect(controller.model.ids, ['other']);
  });

  test(
    'refresh retains a selected archive outside the first page by stable ID',
    () async {
      final client = Client(), controller = ArtifactController();
      addTearDown(controller.dispose);
      controller.attach(client, 'workspace');
      client.pages.single.complete(
        ArtifactPage([archive('workspace', 'first')], 'first'),
      );
      await Future<void>.delayed(Duration.zero);
      final more = controller.load(more: true);
      client.pages.last.complete(
        ArtifactPage([archive('workspace', 'last')], null),
      );
      await more;
      controller.model.select('last');
      client.known['last'] = archive('workspace', 'last');
      final refreshed = controller.load();
      client.pages.last.complete(
        ArtifactPage([archive('workspace', 'first')], 'first'),
      );
      await refreshed;
      expect(controller.selected!.id, 'last');
      expect(controller.model.ids, ['first', 'last']);
    },
  );
  test(
    'a late workspace page cannot replace the current archive list',
    () async {
      final client = Client(), controller = ArtifactController();
      addTearDown(controller.dispose);
      controller.attach(client, 'first');
      controller.attach(client, 'second');
      client.pages[1].complete(ArtifactPage([archive('second', 'new')], null));
      await Future<void>.delayed(Duration.zero);
      client.pages[0].complete(ArtifactPage([archive('first', 'old')], null));
      await Future<void>.delayed(Duration.zero);
      expect(controller.model.ids, ['new']);
      expect(controller.workspaceId, 'second');
    },
  );
  test(
    'failed continuation retains rows selection and the retry cursor',
    () async {
      final client = Client(), controller = ArtifactController();
      addTearDown(controller.dispose);
      controller.attach(client, 'workspace');
      client.pages.single.complete(
        ArtifactPage([archive('workspace', 'first')], 'first'),
      );
      await Future<void>.delayed(Duration.zero);
      controller.model.select('first');
      final failed = controller.load(more: true);
      client.pages.last.completeError(const ArtifactProblem('Unavailable'));
      await failed;
      expect(controller.model.selectedId, 'first');
      expect(controller.model.ids, ['first']);
      expect(controller.next, 'first');
      final retried = controller.load(more: true);
      client.pages.last.complete(
        ArtifactPage([archive('workspace', 'second')], null),
      );
      await retried;
      expect(controller.model.ids, ['first', 'second']);
      expect(controller.model.selectedId, 'first');
    },
  );
  test(
    'an unknown write outcome requires refresh before another mutation',
    () async {
      final client = Client(), controller = ArtifactController();
      addTearDown(controller.dispose);
      controller.attach(client, 'workspace');
      client.pages.single.complete(const ArtifactPage([], null));
      await Future<void>.delayed(Duration.zero);
      final write = controller.change(
        'Add',
        (c, w) => c.add(w, 'new', '/new.zip', ArtifactStorage.reference),
      );
      client.added.completeError(const ArtifactProblem('Reply lost'));
      expect(await write, isFalse);
      expect(controller.canEdit, isFalse);
      final refresh = controller.load();
      client.pages.last.complete(
        ArtifactPage([archive('workspace', 'new')], null),
      );
      await refresh;
      expect(controller.canEdit, isTrue);
      expect(controller.model.ids, ['new']);
    },
  );
}
