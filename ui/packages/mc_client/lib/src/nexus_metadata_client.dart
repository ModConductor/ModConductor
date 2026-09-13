import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';

import 'artifact_client.dart';
import 'nexus_client.dart';
import 'generated/modconductor/v1/nexus.pb.dart' as nexus;
import 'generated/modconductor/v1/nexus_metadata.pbgrpc.dart' as wire;
import 'generated/modconductor/v1/nexus_interactions.pbgrpc.dart'
    as interaction_wire;

class ModNexusReference {
  const ModNexusReference(
    this.workspace,
    this.mod,
    this.linkRevision,
    this.version,
    this.providerMod,
    this.modRevision,
  );
  final String workspace, mod, version;
  final int linkRevision, modRevision;
  final int? providerMod;
}

class NexusMetadataFile {
  const NexusMetadataFile(
    this.file,
    this.categoryId,
    this.uploaded,
    this.update,
  );
  final NexusFile file;
  final int categoryId;
  final DateTime? uploaded;
  final bool update;
  bool get downloadable => categoryId >= 1 && categoryId <= 3;
}

class NexusPublicMetadata {
  const NexusPublicMetadata(
    this.name,
    this.summary,
    this.version,
    this.author,
    this.uploader,
    this.categoryId,
    this.category,
    this.modified,
    this.available,
    this.allowsRating,
    this.files,
  );
  final String name, summary, version, author, uploader, category;
  final int? categoryId;
  final DateTime? modified;
  final bool available, allowsRating;
  final List<NexusMetadataFile> files;
}

class ModNexusDetails {
  const ModNexusDetails(
    this.reference,
    this.name,
    this.installedFile,
    this.installedVersion,
    this.manual,
    this.metadata,
    this.freshness,
    this.checked,
    this.problem,
    this.categoryId,
    this.category,
  );
  final ModNexusReference reference;
  final String name, installedVersion, freshness, problem, category;
  final int? installedFile;
  final bool manual;
  final NexusPublicMetadata? metadata;
  final DateTime? checked;
  final String? categoryId;
  bool get current => freshness == 'current';
}

class ModNexusInteractions {
  const ModNexusInteractions(
    this.revision,
    this.tracking,
    this.endorsement,
    this.busy,
    this.problem,
    this.accountName,
  );
  final String? accountName;
  final int revision;
  final bool? tracking;
  final String? endorsement;
  final bool busy;
  final NexusProblem? problem;
}

abstract interface class NexusMetadataClient {
  Future<ModNexusDetails> read(String workspace, String mod);
  Future<ModNexusDetails> refresh(ModNexusReference reference);
  Future<ModNexusDetails> link(
    ModNexusReference reference,
    int? mod,
    int? file,
  );
  Future<ModNexusDetails> mapCategory(
    ModNexusReference reference,
    String category,
    int providerCategory,
  );
  Future<ModNexusInteractions> interactions(ModNexusReference reference);
  Future<ModNexusInteractions> change(
    ModNexusReference reference,
    int revision,
    String action,
  );
  Future<Artifact> download(
    ModNexusReference reference,
    int file,
    bool update,
    String artifact,
  );
}

class GrpcNexusMetadataClient implements NexusMetadataClient {
  GrpcNexusMetadataClient(ClientChannel channel, CallOptions options)
    : _client = wire.NexusMetadataClient(channel, options: options),
      _interactions = interaction_wire.NexusInteractionsClient(
        channel,
        options: options,
      );
  final wire.NexusMetadataClient _client;
  final interaction_wire.NexusInteractionsClient _interactions;
  wire.ModNexusReference _reference(ModNexusReference r) =>
      wire.ModNexusReference(
        workspaceId: r.workspace,
        modId: r.mod,
        linkRevision: Int64(r.linkRevision),
        versionId: r.version,
        providerMod: r.providerMod == null ? null : Int64(r.providerMod!),
        modRevision: Int64(r.modRevision),
      );
  NexusProblem _problem(nexus.NexusFailure p) => NexusProblem(
    p.code,
    p.message,
    p.hasRetryAtUnixMs()
        ? DateTime.fromMillisecondsSinceEpoch(p.retryAtUnixMs.toInt())
        : null,
  );
  Future<T> _call<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on NexusProblem {
      rethrow;
    } catch (_) {
      throw const NexusProblem(
        'connection',
        'The engine connection could not complete the Nexus request.',
      );
    }
  }

  ModNexusDetails _details(wire.ModNexusReply reply) {
    if (reply.hasFailure()) throw _problem(reply.failure);
    if (!reply.hasDetails()) {
      throw const NexusProblem(
        'response',
        'The engine returned incomplete mod details.',
      );
    }
    final d = reply.details, r = d.reference, m = d.metadata;
    return ModNexusDetails(
      ModNexusReference(
        r.workspaceId,
        r.modId,
        r.linkRevision.toInt(),
        r.versionId,
        r.hasProviderMod() ? r.providerMod.toInt() : null,
        r.modRevision.toInt(),
      ),
      d.localName,
      d.hasInstalledFile() ? d.installedFile.toInt() : null,
      d.installedVersion,
      d.linkedManually,
      d.hasMetadata()
          ? NexusPublicMetadata(
              m.name,
              m.summary,
              m.version,
              m.author,
              m.uploader,
              m.hasCategoryId() ? m.categoryId.toInt() : null,
              m.category,
              m.hasModifiedUnixMs()
                  ? DateTime.fromMillisecondsSinceEpoch(
                      m.modifiedUnixMs.toInt(),
                    )
                  : null,
              m.available,
              m.allowsRating,
              [
                for (final entry in m.files)
                  NexusMetadataFile(
                    NexusFile(
                      entry.file.id.toInt(),
                      entry.file.name,
                      entry.file.version,
                      entry.file.category,
                      entry.file.description,
                      entry.file.hasBytes() ? entry.file.bytes.toInt() : null,
                    ),
                    entry.categoryId,
                    entry.hasUploadedUnixMs()
                        ? DateTime.fromMillisecondsSinceEpoch(
                            entry.uploadedUnixMs.toInt(),
                          )
                        : null,
                    entry.updateCandidate,
                  ),
              ],
            )
          : null,
      d.freshness,
      d.hasCheckedUnixMs()
          ? DateTime.fromMillisecondsSinceEpoch(d.checkedUnixMs.toInt())
          : null,
      d.problem,
      d.hasCategoryId() ? d.categoryId : null,
      d.category,
    );
  }

  ModNexusInteractions _state(
    interaction_wire.ModNexusInteractionsReply reply,
  ) {
    if (reply.hasFailure()) throw _problem(reply.failure);
    if (!reply.hasState()) {
      throw const NexusProblem(
        'response',
        'The engine returned incomplete account details.',
      );
    }
    final s = reply.state;
    return ModNexusInteractions(
      s.revision.toInt(),
      s.hasTracking() ? s.tracking : null,
      s.hasEndorsement() ? s.endorsement : null,
      s.busy,
      s.hasFailure() ? _problem(s.failure) : null,
      s.hasAccountName() ? s.accountName : null,
    );
  }

  @override
  Future<ModNexusDetails> read(String workspace, String mod) => _call(
    () async => _details(
      await _client.readModNexus(
        wire.ModNexusRequest(workspaceId: workspace, modId: mod),
      ),
    ),
  );
  @override
  Future<ModNexusDetails> refresh(ModNexusReference reference) => _call(
    () async => _details(await _client.refreshModNexus(_reference(reference))),
  );
  @override
  Future<ModNexusDetails> link(
    ModNexusReference reference,
    int? mod,
    int? file,
  ) => _call(
    () async => _details(
      await _client.linkModNexus(
        wire.LinkModNexusRequest(
          reference: _reference(reference),
          providerMod: mod == null ? null : Int64(mod),
          fileId: file == null ? null : Int64(file),
        ),
      ),
    ),
  );
  @override
  Future<ModNexusDetails> mapCategory(
    ModNexusReference reference,
    String category,
    int providerCategory,
  ) => _call(
    () async => _details(
      await _client.mapModNexusCategory(
        wire.MapModNexusCategoryRequest(
          reference: _reference(reference),
          categoryId: category,
          providerCategoryId: Int64(providerCategory),
        ),
      ),
    ),
  );
  @override
  Future<ModNexusInteractions> interactions(ModNexusReference reference) =>
      _call(
        () async => _state(
          await _interactions.readModNexusInteractions(_reference(reference)),
        ),
      );
  @override
  Future<ModNexusInteractions> change(
    ModNexusReference reference,
    int revision,
    String action,
  ) => _call(
    () async => _state(
      await _interactions.changeModNexusInteraction(
        interaction_wire.ChangeModNexusInteractionRequest(
          reference: _reference(reference),
          revision: Int64(revision),
          action: action,
        ),
      ),
    ),
  );
  @override
  Future<Artifact> download(
    ModNexusReference reference,
    int file,
    bool update,
    String artifact,
  ) => _call(() async {
    final reply = await _client.downloadModNexusFile(
      wire.DownloadModNexusFileRequest(
        reference: _reference(reference),
        fileId: Int64(file),
        updateOnly: update,
        artifactId: artifact,
      ),
    );
    if (reply.hasFailure()) throw _problem(reply.failure);
    if (!reply.hasArtifact()) {
      throw const NexusProblem(
        'response',
        'The engine returned an incomplete download response.',
      );
    }
    return GrpcArtifactsClient.decode(reply.artifact);
  });
}
