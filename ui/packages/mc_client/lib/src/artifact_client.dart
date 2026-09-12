import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';

import 'generated/modconductor/v1/artifacts.pbgrpc.dart' as wire;
import 'artifact_models.dart';
export 'artifact_models.dart';

abstract interface class ArtifactsClient {
  Future<ArtifactPage> list(
    String workspaceId, {
    String? after,
    bool refresh = false,
  });
  Future<ArtifactLinkPage> linkOptions(String workspaceId, {String? after});
  Future<Artifact> read(String workspaceId, String id);
  Future<Artifact> add(
    String workspaceId,
    String id,
    String path,
    ArtifactStorage storage,
  );
  Future<Artifact> retry(Artifact expected);
  Future<Artifact> locate(Artifact expected, String path);
  Future<Artifact> link(
    Artifact expected,
    ArtifactLink link, {
    bool remove = false,
  });
  Future<Artifact> deleteCopy(Artifact expected);
  Future<void> remove(Artifact expected);
}

class GrpcArtifactsClient implements ArtifactsClient {
  GrpcArtifactsClient(ClientChannel channel, CallOptions options)
    : _client = wire.ArtifactLibraryClient(channel, options: options);
  final wire.ArtifactLibraryClient _client;
  Future<T> _call<T>(Future<T> pending) async {
    try {
      return await pending;
    } on GrpcError catch (error) {
      throw ArtifactProblem(error.message ?? 'The archive operation failed.');
    }
  }

  ArtifactLink _link(wire.ArtifactProvenance link) =>
      ArtifactLink(link.modId, link.versionId, link.modName, link.versionLabel);
  Artifact _artifact(wire.ArchiveArtifact a) => Artifact(
    id: a.id,
    workspaceId: a.workspaceId,
    revision: a.revision.toInt(),
    originalName: a.originalName,
    originalPath: a.originalPath,
    path: a.path,
    canRetry: a.canRetry,
    canLocate: a.canLocate,
    canDeleteCopy: a.canDeleteCopy,
    canRemove: a.canRemove,
    storage: switch (a.storage) {
      wire.ArchiveStorage.ARCHIVE_STORAGE_REFERENCE =>
        ArtifactStorage.reference,
      wire.ArchiveStorage.ARCHIVE_STORAGE_COPY => ArtifactStorage.copy,
      _ => throw const FormatException('Unknown archive storage.'),
    },
    state: switch (a.state) {
      wire.ArchiveState.ARCHIVE_STATE_INCOMPLETE => ArtifactState.incomplete,
      wire.ArchiveState.ARCHIVE_STATE_READY => ArtifactState.ready,
      wire.ArchiveState.ARCHIVE_STATE_DETACHED => ArtifactState.detached,
      wire.ArchiveState.ARCHIVE_STATE_INSTALLED => ArtifactState.installed,
      _ => throw const FormatException('Unknown archive state.'),
    },
    length: a.hasLength() ? a.length.toInt() : null,
    sha256: a.hasSha256() ? a.sha256 : null,
    problem: a.hasProblem() ? a.problem : null,
    links: List.unmodifiable(a.links.map(_link)),
  );
  wire.ArtifactReference _ref(Artifact a) => wire.ArtifactReference(
    workspaceId: a.workspaceId,
    id: a.id,
    revision: Int64(a.revision),
  );
  @override
  Future<ArtifactPage> list(
    String workspaceId, {
    String? after,
    bool refresh = false,
  }) async {
    final page = await _call(
      _client.listArtifacts(
        wire.ArtifactListRequest(
          workspaceId: workspaceId,
          after: after,
          refresh: refresh,
        ),
      ),
    );
    return ArtifactPage(
      List.unmodifiable(page.entries.map(_artifact)),
      page.hasNext() ? page.next : null,
    );
  }

  @override
  Future<ArtifactLinkPage> linkOptions(
    String workspaceId, {
    String? after,
  }) async {
    final page = await _call(
      _client.listArtifactLinkOptions(
        wire.ArtifactListRequest(workspaceId: workspaceId, after: after),
      ),
    );
    return ArtifactLinkPage(
      List.unmodifiable(page.entries.map(_link)),
      page.hasNext() ? page.next : null,
    );
  }

  @override
  Future<Artifact> read(String workspaceId, String id) async => _artifact(
    await _call(
      _client.readArtifact(
        wire.ArtifactReadRequest(workspaceId: workspaceId, id: id),
      ),
    ),
  );
  @override
  Future<Artifact> add(
    String workspaceId,
    String id,
    String path,
    ArtifactStorage storage,
  ) async => _artifact(
    await _call(
      _client.addArtifact(
        wire.ArtifactAddRequest(
          workspaceId: workspaceId,
          id: id,
          path: path,
          storage: storage == ArtifactStorage.reference
              ? wire.ArchiveStorage.ARCHIVE_STORAGE_REFERENCE
              : wire.ArchiveStorage.ARCHIVE_STORAGE_COPY,
        ),
      ),
    ),
  );
  @override
  Future<Artifact> retry(Artifact expected) async =>
      _artifact(await _call(_client.retryArtifact(_ref(expected))));
  @override
  Future<Artifact> locate(Artifact expected, String path) async => _artifact(
    await _call(
      _client.locateArtifact(
        wire.ArtifactLocateRequest(expected: _ref(expected), path: path),
      ),
    ),
  );
  @override
  Future<Artifact> link(
    Artifact expected,
    ArtifactLink link, {
    bool remove = false,
  }) async => _artifact(
    await _call(
      _client.linkArtifact(
        wire.ArtifactLinkRequest(
          expected: _ref(expected),
          modId: link.modId,
          versionId: link.versionId,
          remove: remove,
        ),
      ),
    ),
  );
  @override
  Future<Artifact> deleteCopy(Artifact expected) async =>
      _artifact(await _call(_client.deleteArtifactCopy(_ref(expected))));
  @override
  Future<void> remove(Artifact expected) async {
    await _call(_client.removeArtifact(_ref(expected)));
  }
}
