import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';

import 'generated/modconductor/v2/engine_probe.pbgrpc.dart' as wire;
import 'mod_library_models.dart';
import 'mod_library_wire.dart' as mapping;
export 'mod_library_models.dart';

/// Typed transport only. Allowed actions and all inventory policy come from the engine.
class ModLibraryClient {
  ModLibraryClient(ClientChannel channel, CallOptions options)
    : _client = wire.ModLibraryOperationsClient(channel, options: options);
  final wire.ModLibraryOperationsClient _client;

  Future<ModEntry> register(
    String workspaceId,
    String modId,
    ModMetadata metadata,
    ModRegistration registration,
  ) async {
    final request = wire.RegisterModRequest(
      workspaceId: workspaceId,
      modId: modId,
      metadata: mapping.encodeMetadata(metadata),
    );
    switch (registration) {
      case DirectoryMod(:final kind, :final path):
        request.kind = mapping.encodeModKind(kind);
        request.sourcePath = wire.ModLogicalPath(components: path);
      case SeparatorMod():
        request.kind = wire.InventoryModKind.INVENTORY_MOD_KIND_SEPARATOR;
      case BackupMod(:final versionId):
        request.kind = wire.InventoryModKind.INVENTORY_MOD_KIND_BACKUP;
        request.backupVersionId = versionId;
    }
    return mapping.modReply(await _client.registerMod(request));
  }

  Future<ModEntry> edit(
    String modId,
    int revision,
    ModMetadata metadata,
  ) async => mapping.modReply(
    await _client.editMod(
      wire.EditModRequest(
        modId: modId,
        expectedRevision: Int64(revision),
        metadata: mapping.encodeMetadata(metadata),
      ),
    ),
  );
  Future<InventoryPage> inventory(
    String profileId, {
    String? afterModId,
  }) async {
    final reply = await _client.readInventory(
      wire.ReadInventoryRequest(profileId: profileId, afterModId: afterModId),
    );
    return switch (reply.whichOutcome()) {
      wire.InventoryReply_Outcome.page => InventoryPage(
        List.unmodifiable(reply.page.entries.map(mapping.entry)),
        reply.page.hasNextModId() ? reply.page.nextModId : null,
      ),
      wire.InventoryReply_Outcome.fault => mapping.reject(reply.fault),
      wire.InventoryReply_Outcome.notSet => throw const FormatException(
        'Missing inventory result.',
      ),
    };
  }

  Future<InventoryScan> scan(
    String workspaceId, {
    required int candidateLimit,
  }) async {
    final reply = await _client.scanInventory(
      wire.ScanInventoryRequest(
        workspaceId: workspaceId,
        candidateLimit: candidateLimit,
      ),
    );
    return switch (reply.whichOutcome()) {
      wire.InventoryScanReply_Outcome.scan => InventoryScan(
        List.unmodifiable(reply.scan.entries.map(mapping.entry)),
        List.unmodifiable(
          reply.scan.unmanaged.map(
            (item) => UnmanagedModPath(
              List.unmodifiable(item.path.components),
              item.directory,
              item.unsupported,
            ),
          ),
        ),
        reply.scan.limited,
      ),
      wire.InventoryScanReply_Outcome.fault => mapping.reject(reply.fault),
      wire.InventoryScanReply_Outcome.notSet => throw const FormatException(
        'Missing scan result.',
      ),
    };
  }

  Future<ModEntry> publish(
    String modId,
    int revision,
    String versionId,
  ) async => mapping.modReply(
    await _client.publishMod(
      wire.PublishModRequest(
        modId: modId,
        expectedRevision: Int64(revision),
        versionId: versionId,
      ),
    ),
  );
  Future<PublicationReceipt> publication(String versionId) async =>
      mapping.publication(
        await _client.readPublication(
          wire.PublicationRequest(versionId: versionId),
        ),
      );
  Future<PublicationReceipt> cancelPublication(String versionId) async =>
      mapping.publication(
        await _client.cancelPublication(
          wire.PublicationRequest(versionId: versionId),
        ),
      );
  Future<ModVersionPage> version(String versionId, {int offset = 0}) async {
    final reply = await _client.readModVersion(
      wire.ReadModVersionRequest(versionId: versionId, offset: offset),
    );
    return switch (reply.whichOutcome()) {
      wire.ModVersionReply_Outcome.version => ModVersionPage(
        reply.version.versionId,
        reply.version.modId,
        List.unmodifiable(
          reply.version.entries.map(
            (item) => ManifestEntry(
              List.unmodifiable(item.path.components),
              ModPayload(
                item.payload.payloadId,
                item.payload.length.toInt(),
                item.payload.sha256,
              ),
            ),
          ),
        ),
        reply.version.hasNextOffset() ? reply.version.nextOffset : null,
      ),
      wire.ModVersionReply_Outcome.fault => mapping.reject(reply.fault),
      wire.ModVersionReply_Outcome.notSet => throw const FormatException(
        'Missing version result.',
      ),
    };
  }

  Future<List<int>> readPayload(
    String versionId,
    String payloadId, {
    int offset = 0,
    int count = 65536,
  }) async {
    final reply = await _client.readModPayload(
      wire.ReadModPayloadRequest(
        versionId: versionId,
        payloadId: payloadId,
        offset: Int64(offset),
        count: count,
      ),
    );
    return switch (reply.whichOutcome()) {
      wire.ModPayloadReply_Outcome.data => List.unmodifiable(reply.data),
      wire.ModPayloadReply_Outcome.fault => mapping.reject(reply.fault),
      wire.ModPayloadReply_Outcome.notSet => throw const FormatException(
        'Missing payload result.',
      ),
    };
  }
}
