import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';

import 'generated/modconductor/v1/artifacts.pbgrpc.dart' as wire;
import 'generated/modconductor/v1/downloads.pbgrpc.dart' as transfer;
import 'generated/modconductor/v1/download_models.pb.dart' as model;
import 'artifact_models.dart';
import 'archive_inspection_models.dart';
import 'file_plan_models.dart';
import 'file_plan_wire.dart' as filewire;
import 'generated/modconductor/v1/archive_inspection.pbgrpc.dart' as inspection;
export 'archive_inspection_models.dart';
export 'artifact_models.dart';

abstract interface class ArtifactsClient {
  ArchiveRead readContents(Artifact expected);
  FilePreviewRead previewEntry(
    Artifact expected,
    InspectedArchive manifest,
    InspectedEntry entry,
    FilePreviewRepresentation representation,
  );
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
  Future<Artifact> download(
    String workspaceId,
    String id,
    ArchiveDownloadRequest request,
  );
  Future<Artifact> controlDownload(Artifact artifact, DownloadAction action);
  Stream<Artifact> watchDownloads(String workspaceId, List<String> ids);
}

class GrpcArtifactsClient implements ArtifactsClient {
  GrpcArtifactsClient(ClientChannel channel, CallOptions options)
    : _client = wire.ArtifactLibraryClient(channel, options: options),
      _downloads = transfer.ArtifactDownloadsClient(channel, options: options),
      _inspection = inspection.ArchiveInspectionClient(
        channel,
        options: options,
      );
  final inspection.ArchiveInspectionClient _inspection;
  final wire.ArtifactLibraryClient _client;
  inspection.InspectedArchiveEntry _entry(InspectedEntry entry) =>
      inspection.InspectedArchiveEntry(
        index: entry.index,
        components: entry.components,
        directory: entry.directory,
        size: Int64(entry.size),
        compressedSize: entry.compressedSize == null
            ? null
            : Int64(entry.compressedSize!),
      );

  @override
  FilePreviewRead previewEntry(
    Artifact expected,
    InspectedArchive manifest,
    InspectedEntry entry,
    FilePreviewRepresentation representation,
  ) {
    final call = _inspection.previewArchiveEntry(
      inspection.PreviewArchiveEntryRequest(
        artifact: _ref(expected),
        sha256: manifest.sha256,
        format: manifest.format,
        entry: _entry(entry),
        representation: filewire.encodeRepresentation(representation),
      ),
      options: CallOptions(timeout: const Duration(days: 1)),
    );
    return FilePreviewRead(_call(call).then(filewire.preview), call.cancel);
  }

  @override
  ArchiveRead readContents(Artifact expected) {
    final call = _inspection.inspectArchive(
      _ref(expected),
      options: CallOptions(timeout: const Duration(days: 1)),
    );
    return ArchiveRead(
      _call(call).then(
        (reply) => InspectedArchive(reply.sha256, reply.format, [
          for (final e in reply.entries)
            InspectedEntry(
              e.index,
              List.unmodifiable(e.components),
              e.directory,
              e.size.toInt(),
              e.hasCompressedSize() ? e.compressedSize.toInt() : null,
            ),
        ], reply.totalSize.toInt()),
      ),
      call.cancel,
    );
  }

  final transfer.ArtifactDownloadsClient _downloads;
  Future<T> _call<T>(Future<T> pending) async {
    try {
      return await pending;
    } on GrpcError catch (error) {
      throw ArtifactProblem(error.message ?? 'The archive operation failed.');
    }
  }

  static ArtifactLink _link(wire.ArtifactProvenance link) => ArtifactLink(
    link.modId,
    link.versionId,
    link.modName,
    link.versionLabel,
    installed: link.installed,
  );
  static Artifact decode(wire.ArchiveArtifact a) => Artifact(
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
    download: a.hasDownload() ? _download(a.download) : null,
  );
  static ArtifactDownload _download(model.ArchiveDownload d) =>
      ArtifactDownload(
        phase: switch (d.phase) {
          model.DownloadPhase.DOWNLOAD_PHASE_QUEUED => DownloadPhase.queued,
          model.DownloadPhase.DOWNLOAD_PHASE_RUNNING => DownloadPhase.running,
          model.DownloadPhase.DOWNLOAD_PHASE_WAITING => DownloadPhase.waiting,
          model.DownloadPhase.DOWNLOAD_PHASE_PAUSED => DownloadPhase.paused,
          model.DownloadPhase.DOWNLOAD_PHASE_FAILED => DownloadPhase.failed,
          model.DownloadPhase.DOWNLOAD_PHASE_COMPLETE => DownloadPhase.complete,
          _ => throw const FormatException('Unknown download state.'),
        },
        bytes: d.bytes.toInt(),
        total: d.hasTotal() ? d.total.toInt() : null,
        source: d.source,
        expectedSha256: d.hasExpectedSha256() ? d.expectedSha256 : null,
        checksumMatched: d.checksumMatched,
        restartRequired: d.restartRequired,
        retryAt: d.hasRetryAtUnixMs()
            ? DateTime.fromMillisecondsSinceEpoch(d.retryAtUnixMs.toInt())
            : null,
      );
  @override
  Future<Artifact> download(
    String workspaceId,
    String id,
    ArchiveDownloadRequest request,
  ) async => decode(
    await _call(
      _downloads.startDownload(
        transfer.DownloadStartRequest(
          workspaceId: workspaceId,
          id: id,
          name: request.name,
          sources: request.sources,
          expectedLength: request.expectedLength == null
              ? null
              : Int64(request.expectedLength!),
          expectedSha256: request.expectedSha256,
        ),
      ),
    ),
  );
  @override
  Future<Artifact> controlDownload(
    Artifact artifact,
    DownloadAction action,
  ) async => decode(
    await _call(
      _downloads.controlDownload(
        transfer.DownloadControlRequest(
          workspaceId: artifact.workspaceId,
          id: artifact.id,
          command: switch (action) {
            DownloadAction.pause =>
              transfer.DownloadCommand.DOWNLOAD_COMMAND_PAUSE,
            DownloadAction.resume =>
              transfer.DownloadCommand.DOWNLOAD_COMMAND_RESUME,
            DownloadAction.restart =>
              transfer.DownloadCommand.DOWNLOAD_COMMAND_RESTART,
          },
        ),
      ),
    ),
  );
  @override
  Stream<Artifact> watchDownloads(String workspaceId, List<String> ids) async* {
    final call = _downloads.watchDownloads(
      transfer.DownloadWatchRequest(workspaceId: workspaceId, ids: ids),
      options: CallOptions(timeout: const Duration(days: 1)),
    );
    try {
      await for (final artifact in call) {
        yield decode(artifact);
      }
    } on GrpcError catch (error) {
      throw ArtifactProblem(
        error.message ?? 'Download progress is unavailable.',
      );
    } finally {
      await call.cancel();
    }
  }

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
      List.unmodifiable(page.entries.map(decode)),
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
  Future<Artifact> read(String workspaceId, String id) async => decode(
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
  ) async => decode(
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
      decode(await _call(_client.retryArtifact(_ref(expected))));
  @override
  Future<Artifact> locate(Artifact expected, String path) async => decode(
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
  }) async => decode(
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
      decode(await _call(_client.deleteArtifactCopy(_ref(expected))));
  @override
  Future<void> remove(Artifact expected) async {
    await _call(_client.removeArtifact(_ref(expected)));
  }
}
