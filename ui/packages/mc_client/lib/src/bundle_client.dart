import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';

import 'artifact_models.dart';
import 'installation_models.dart';
import 'installation_client.dart' show installationDraft, installationStatus;
import 'bundle_models.dart';
import 'generated/modconductor/v1/bundles.pbgrpc.dart' as wire;
import 'generated/modconductor/v1/artifacts.pb.dart' as artifacts;
import 'generated/modconductor/v1/archive_installation.pb.dart' as install;
export 'bundle_models.dart';

abstract interface class BundlesClient {
  Future<BundlePlan?> find(String workspace, String artifact);
  Future<BundleDiscovery> discover(Artifact artifact);
  Future<BundlePlan> create(InstallationDraft draft, List<int> entries);
  Future<BundlePlan> read(BundleReference reference);
  Future<BundleConfiguration> configure(BundleReference reference, String item);
  Future<BundlePlan> chooseNested(
    BundleReference reference,
    String item,
    InstallationDraft draft,
    List<int> entries,
  );
  Future<BundlePlan> rename(
    BundleReference reference,
    String item,
    String name,
  );
  Future<BundlePlan> move(BundleReference reference, String item, bool earlier);
  Future<BundlePlan> retry(BundleReference reference, String item);
  Future<InstallationStatus> status(BundleReference reference, String item);
  Future<void> delete(BundleReference reference);
}

class GrpcBundlesClient implements BundlesClient {
  GrpcBundlesClient(ClientChannel channel, CallOptions options)
    : _client = wire.BundleInstallationClient(channel, options: options);
  final wire.BundleInstallationClient _client;
  Future<T> _call<T>(Future<T> value) async {
    try {
      return await value;
    } on GrpcError catch (error) {
      throw ArtifactProblem(error.message ?? 'The bundle operation failed.');
    }
  }

  wire.BundleReference _reference(BundleReference r) => wire.BundleReference(
    workspaceId: r.workspaceId,
    id: r.id,
    revision: Int64(r.revision),
  );
  wire.BundleModRequest _item(BundleReference r, String item) =>
      wire.BundleModRequest(reference: _reference(r), mod: item);
  install.InstallationDraftReference _draft(InstallationDraft d) =>
      install.InstallationDraftReference(
        workspaceId: d.workspaceId,
        id: d.id,
        revision: Int64(d.revision),
      );
  BundlePlan _bundle(wire.ModBundle b) => BundlePlan(
    reference: BundleReference(
      b.reference.workspaceId,
      b.reference.id,
      b.reference.revision.toInt(),
    ),
    artifactId: b.artifact.id,
    archiveName: b.archiveName,
    temporaryBytes: b.temporaryBytes.toInt(),
    problem: b.hasProblem() ? b.problem : null,
    items: [
      for (final m in b.mods)
        BundleItem(
          id: m.id,
          sourceId: m.sourceId,
          modId: m.modId,
          name: m.name,
          order: m.order,
          archives: [
            for (final a in m.archives) List.unmodifiable(a.components),
          ],
          bytes: m.bytes.toInt(),
          incompleteArchive: m.incompleteArchive,
          state: switch (m.state) {
            wire.BundleModState.BUNDLE_MOD_STATE_NEEDS_REVIEW =>
              BundleItemState.needsReview,
            wire.BundleModState.BUNDLE_MOD_STATE_INSTALLED =>
              BundleItemState.installed,
            wire.BundleModState.BUNDLE_MOD_STATE_FAILED =>
              BundleItemState.failed,
            wire.BundleModState.BUNDLE_MOD_STATE_INSTALLING =>
              BundleItemState.installing,
            _ => throw const ArtifactProblem(
              'The engine returned an unknown bundle state.',
            ),
          },
          attemptId: m.hasAttemptId() ? m.attemptId : null,
          problem: m.hasProblem() ? m.problem : null,
        ),
    ],
  );
  BundleDiscovery _discovery(wire.BundleDiscovery d) =>
      BundleDiscovery(installationDraft(d.draft), [
        for (final a in d.archives)
          BundleArchive(a.index, List.unmodifiable(a.path), a.bytes.toInt()),
      ]);
  @override
  Future<BundlePlan?> find(String workspace, String artifact) async {
    final r = await _call(
      _client.findBundle(
        artifacts.ArtifactReadRequest(workspaceId: workspace, id: artifact),
      ),
    );
    return r.hasBundle() ? _bundle(r.bundle) : null;
  }

  @override
  Future<BundleDiscovery> discover(Artifact artifact) async => _discovery(
    await _call(
      _client.discoverBundle(
        artifacts.ArtifactReference(
          workspaceId: artifact.workspaceId,
          id: artifact.id,
          revision: Int64(artifact.revision),
        ),
      ),
    ),
  );
  @override
  Future<BundlePlan> create(InstallationDraft draft, List<int> entries) async =>
      _bundle(
        await _call(
          _client.createBundle(
            wire.BundleSelection(draft: _draft(draft), entries: entries),
          ),
        ),
      );
  @override
  Future<BundlePlan> read(BundleReference reference) async =>
      _bundle(await _call(_client.readBundle(_reference(reference))));
  @override
  Future<BundleConfiguration> configure(
    BundleReference reference,
    String item,
  ) async {
    final r = await _call(_client.configureBundleMod(_item(reference, item)));
    return BundleConfiguration(_bundle(r.bundle), _discovery(r.prepared));
  }

  @override
  Future<BundlePlan> chooseNested(
    BundleReference reference,
    String item,
    InstallationDraft draft,
    List<int> entries,
  ) async => _bundle(
    await _call(
      _client.chooseNestedArchives(
        wire.NestedBundleSelection(
          target: _item(reference, item),
          draft: _draft(draft),
          entries: entries,
        ),
      ),
    ),
  );
  @override
  Future<BundlePlan> rename(
    BundleReference reference,
    String item,
    String name,
  ) async => _bundle(
    await _call(
      _client.renameBundleMod(
        wire.BundleModRename(target: _item(reference, item), name: name),
      ),
    ),
  );
  @override
  Future<BundlePlan> move(
    BundleReference reference,
    String item,
    bool earlier,
  ) async => _bundle(
    await _call(
      _client.moveBundleMod(
        wire.BundleModMove(target: _item(reference, item), earlier: earlier),
      ),
    ),
  );
  @override
  Future<BundlePlan> retry(BundleReference reference, String item) async =>
      _bundle(await _call(_client.retryBundleMod(_item(reference, item))));
  @override
  Future<InstallationStatus> status(
    BundleReference reference,
    String item,
  ) async => installationStatus(
    await _call(_client.readBundleModStatus(_item(reference, item))),
  );
  @override
  Future<void> delete(BundleReference reference) async {
    await _call(_client.deleteBundleTemporaryFiles(_reference(reference)));
  }
}
