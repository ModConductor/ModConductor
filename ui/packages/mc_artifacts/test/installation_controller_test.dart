import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_artifacts/src/installation_controller.dart';

const artifact = Artifact(
  id: 'archive',
  workspaceId: 'workspace',
  revision: 1,
  originalName: 'archive.zip',
  originalPath: '/fixture/archive.zip',
  path: '/fixture/archive.zip',
  storage: ArtifactStorage.reference,
  state: ArtifactState.ready,
  links: [],
  canRetry: false,
  canLocate: true,
  canDeleteCopy: false,
  canRemove: true,
);
const draft = InstallationDraft(
  id: 'draft',
  workspaceId: 'workspace',
  revision: 0,
  artifactId: 'archive',
  archiveName: 'archive.zip',
  manifest: InspectedArchive('digest', 'ZIP', [], 4),
  root: [],
  files: [
    InstallationFile(0, ['file']),
  ],
  name: 'Mod',
  version: '',
  bytes: 4,
  canInstall: true,
);
InstallationStatus status(String id, InstallationPhase phase) =>
    InstallationStatus(
      id: id,
      workspaceId: 'workspace',
      artifactId: 'archive',
      archiveName: 'archive.zip',
      name: 'Mod',
      version: '',
      phase: phase,
      files: phase == InstallationPhase.complete ? 1 : 0,
      totalFiles: 1,
      bytes: phase == InstallationPhase.complete ? 4 : 0,
      totalBytes: 4,
    );

class Client implements InstallationsClient {
  final starting = Completer<InstallationStatus>(),
      cancelling = Completer<InstallationStatus>();
  final events = StreamController<InstallationStatus>();
  final closed = <String>[];
  String? job;
  List<InstallationStatus> saved = [];
  @override
  InstallationPreparation prepare(Artifact artifact) =>
      InstallationPreparation(Future.value(draft), () async {});
  @override
  Future<List<InstallationStatus>> recent(String workspaceId) async => saved;
  @override
  Future<InstallationStatus> start(InstallationDraft draft, String id) {
    job = id;
    return starting.future;
  }

  @override
  Future<void> closeDraft(InstallationDraft draft) async {
    closed.add(draft.id);
  }

  @override
  Stream<InstallationStatus> watch(InstallationStatus status) => events.stream;
  @override
  Future<InstallationStatus> cancel(InstallationStatus status) =>
      cancelling.future;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('leaving installation view hands running job to app observer', () async {
    final client = Client();
    final detached = <InstallationStatus>[];
    final completed = <String>[];
    StreamSubscription<InstallationStatus>? appWatch;
    final controller = InstallationController(
      client,
      artifact,
      () => fail('disposed view must not publish completion'),
      onDetached: (running) {
        detached.add(running);
        appWatch = client.watch(running).listen((next) {
          if (next.phase == InstallationPhase.complete) completed.add(next.id);
        });
      },
    );
    await controller.open();
    final starting = controller.install();
    final job = client.job!;
    controller.dispose();
    client.starting.complete(status(job, InstallationPhase.running));
    await starting;
    expect(detached.map((entry) => entry.id), [job]);
    expect(client.closed, [draft.id]);
    client.events.add(status(job, InstallationPhase.complete));
    await Future<void>.delayed(Duration.zero);
    expect(completed, [job]);
    await appWatch!.cancel();
    await client.events.close();
  });

  test('completed start response after navigation still reaches app observer', () async {
    final client = Client();
    final detached = <InstallationStatus>[];
    final controller = InstallationController(
      client,
      artifact,
      () => fail('disposed view must not publish completion'),
      onDetached: detached.add,
    );
    await controller.open();
    final starting = controller.install();
    final job = client.job!;
    controller.dispose();
    client.starting.complete(status(job, InstallationPhase.complete));
    await starting;
    expect(detached.single.phase, InstallationPhase.complete);
    expect(detached.single.id, job);
  });

  test('navigation during start retains the job and late cancellation cannot undo completion', () async {
    final client = Client();
    var notifications = 0;
    final first = InstallationController(
      client,
      artifact,
      () => notifications++,
    );
    await first.open();
    final pending = first.install();
    final job = client.job!;
    first.dispose();
    expect(client.closed, isEmpty);
    client.saved = [status(job, InstallationPhase.running)];
    client.starting.complete(client.saved.single);
    await pending;
    expect(notifications, 0);
    final reopened = InstallationController(
      client,
      artifact,
      () => notifications++,
    );
    await reopened.open();
    expect(reopened.status?.id, job);
    final cancel = reopened.control(discard: false);
    client.events.add(status(job, InstallationPhase.complete));
    await Future<void>.delayed(Duration.zero);
    client.cancelling.complete(status(job, InstallationPhase.running));
    await cancel;
    expect(reopened.status?.phase, InstallationPhase.complete);
    expect(notifications, 1);
    reopened.dispose();
    await client.events.close();
  });
}
