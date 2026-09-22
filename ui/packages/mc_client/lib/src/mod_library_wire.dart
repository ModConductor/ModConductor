import 'generated/modconductor/v1/mod_library.pbgrpc.dart' as wire;
import 'mod_library_models.dart';

ModKind modKind(wire.InventoryModKind value) => switch (value) {
  wire.InventoryModKind.INVENTORY_MOD_KIND_REGULAR => ModKind.regular,
  wire.InventoryModKind.INVENTORY_MOD_KIND_SEPARATOR => ModKind.separator,
  wire.InventoryModKind.INVENTORY_MOD_KIND_BACKUP => ModKind.backup,
  wire.InventoryModKind.INVENTORY_MOD_KIND_UNMANAGED => ModKind.unmanaged,
  wire.InventoryModKind.INVENTORY_MOD_KIND_GENERATED_OUTPUT =>
    ModKind.generatedOutput,
  _ => throw const FormatException('Unsupported library modKind.'),
};

InventoryStatus inventoryStatus(wire.ModInventoryStatus value) =>
    switch (value) {
      wire.ModInventoryStatus.MOD_INVENTORY_STATUS_READY =>
        InventoryStatus.ready,
      wire.ModInventoryStatus.MOD_INVENTORY_STATUS_DETACHED =>
        InventoryStatus.detached,
      wire.ModInventoryStatus.MOD_INVENTORY_STATUS_CHANGED =>
        InventoryStatus.changed,
      wire.ModInventoryStatus.MOD_INVENTORY_STATUS_UNPROVED =>
        InventoryStatus.unproved,
      wire.ModInventoryStatus.MOD_INVENTORY_STATUS_PUBLISHING =>
        InventoryStatus.publishing,
      wire.ModInventoryStatus.MOD_INVENTORY_STATUS_DELETING =>
        InventoryStatus.deleting,
      _ => throw const FormatException('Unsupported library inventoryStatus.'),
    };

ModAction modAction(wire.InventoryModAction value) => switch (value) {
  wire.InventoryModAction.INVENTORY_MOD_ACTION_EDIT_METADATA =>
    ModAction.editMetadata,
  wire.InventoryModAction.INVENTORY_MOD_ACTION_PUBLISH => ModAction.publish,
  wire.InventoryModAction.INVENTORY_MOD_ACTION_READ_VERSION =>
    ModAction.readVersion,
  _ => throw const FormatException('Unsupported library modAction.'),
};

PublicationPhase publicationPhase(wire.ModPublicationPhase value) =>
    switch (value) {
      wire.ModPublicationPhase.MOD_PUBLICATION_PHASE_INTENT =>
        PublicationPhase.intent,
      wire.ModPublicationPhase.MOD_PUBLICATION_PHASE_OBSERVED =>
        PublicationPhase.observed,
      wire.ModPublicationPhase.MOD_PUBLICATION_PHASE_COMPLETE =>
        PublicationPhase.complete,
      wire.ModPublicationPhase.MOD_PUBLICATION_PHASE_INTERRUPTED =>
        PublicationPhase.interrupted,
      wire.ModPublicationPhase.MOD_PUBLICATION_PHASE_CANCELLED =>
        PublicationPhase.cancelled,
      _ => throw const FormatException('Unsupported library publicationPhase.'),
    };

LibraryFault libraryFault(wire.ModLibraryFaultCode value) => switch (value) {
  wire.ModLibraryFaultCode.MOD_LIBRARY_FAULT_CODE_NOT_FOUND =>
    LibraryFault.notFound,
  wire.ModLibraryFaultCode.MOD_LIBRARY_FAULT_CODE_STALE_REVISION =>
    LibraryFault.staleRevision,
  wire.ModLibraryFaultCode.MOD_LIBRARY_FAULT_CODE_IDENTITY_CONFLICT =>
    LibraryFault.identityConflict,
  wire.ModLibraryFaultCode.MOD_LIBRARY_FAULT_CODE_INVALID_METADATA =>
    LibraryFault.invalidMetadata,
  wire.ModLibraryFaultCode.MOD_LIBRARY_FAULT_CODE_INVALID_SOURCE =>
    LibraryFault.invalidSource,
  wire.ModLibraryFaultCode.MOD_LIBRARY_FAULT_CODE_UNPROVED_OWNERSHIP =>
    LibraryFault.unprovedOwnership,
  wire.ModLibraryFaultCode.MOD_LIBRARY_FAULT_CODE_SOURCE_CHANGED =>
    LibraryFault.sourceChanged,
  wire.ModLibraryFaultCode.MOD_LIBRARY_FAULT_CODE_UNSUPPORTED_ACTION =>
    LibraryFault.unsupportedAction,
  wire.ModLibraryFaultCode.MOD_LIBRARY_FAULT_CODE_BUSY => LibraryFault.busy,
  wire.ModLibraryFaultCode.MOD_LIBRARY_FAULT_CODE_LIMIT_EXCEEDED =>
    LibraryFault.limitExceeded,
  wire.ModLibraryFaultCode.MOD_LIBRARY_FAULT_CODE_FILE_UNAVAILABLE =>
    LibraryFault.fileUnavailable,
  wire.ModLibraryFaultCode.MOD_LIBRARY_FAULT_CODE_CANCELLED =>
    LibraryFault.cancelled,
  _ => throw const FormatException('Unsupported library libraryFault.'),
};

LibraryOperationKind libraryOperationKind(wire.ModLibraryOperationKind value) =>
    switch (value) {
      wire.ModLibraryOperationKind.MOD_LIBRARY_OPERATION_KIND_PUBLICATION =>
        LibraryOperationKind.publication,
      wire.ModLibraryOperationKind.MOD_LIBRARY_OPERATION_KIND_INSTALLATION =>
        LibraryOperationKind.installation,
      wire.ModLibraryOperationKind.MOD_LIBRARY_OPERATION_KIND_UPGRADE =>
        LibraryOperationKind.upgrade,
      wire.ModLibraryOperationKind.MOD_LIBRARY_OPERATION_KIND_DELETION =>
        LibraryOperationKind.deletion,
      _ => throw const FormatException('Unsupported library operation type.'),
    };

LibraryOperationAction libraryOperationAction(
  wire.ModLibraryOperationAction value,
) => switch (value) {
  wire.ModLibraryOperationAction.MOD_LIBRARY_OPERATION_ACTION_WAIT =>
    LibraryOperationAction.wait,
  wire.ModLibraryOperationAction.MOD_LIBRARY_OPERATION_ACTION_RESUME =>
    LibraryOperationAction.resume,
  wire.ModLibraryOperationAction.MOD_LIBRARY_OPERATION_ACTION_CANCEL =>
    LibraryOperationAction.cancel,
  _ => throw const FormatException('Unsupported library operation action.'),
};

wire.InventoryModKind encodeModKind(ModKind value) => switch (value) {
  ModKind.regular => wire.InventoryModKind.INVENTORY_MOD_KIND_REGULAR,
  ModKind.separator => wire.InventoryModKind.INVENTORY_MOD_KIND_SEPARATOR,
  ModKind.backup => wire.InventoryModKind.INVENTORY_MOD_KIND_BACKUP,
  ModKind.unmanaged => wire.InventoryModKind.INVENTORY_MOD_KIND_UNMANAGED,
  ModKind.generatedOutput =>
    wire.InventoryModKind.INVENTORY_MOD_KIND_GENERATED_OUTPUT,
};

Never reject(wire.ModLibraryFault fault) => throw LibraryException(
  libraryFault(fault.code),
  fault.detail,
  activeOperation: fault.hasActiveOperation()
      ? LibraryOperation(
          id: fault.activeOperation.operationId,
          workspaceId: fault.activeOperation.workspaceId,
          kind: libraryOperationKind(fault.activeOperation.kind),
          actions: List.unmodifiable(
            fault.activeOperation.actions.map(libraryOperationAction),
          ),
        )
      : null,
);
wire.InventoryModMetadata encodeMetadata(ModMetadata value) =>
    wire.InventoryModMetadata(
      name: value.name,
      notes: value.notes,
      comment: value.comment,
      version: value.version,
      source: value.source,
      categories: value.categories.map(encodeCategory),
    );
ModVersionOrigin origin(wire.ModVersionOrigin value) => ModVersionOrigin(
  bundle: value.hasBundle()
      ? BundleVersionOrigin(value.bundle.parentSha256, [
          for (final archive in value.bundle.archives)
            BundleArchiveOrigin(
              List.unmodifiable(archive.path),
              archive.sha256,
            ),
        ])
      : null,
  outputActionId: value.hasOutputActionId() ? value.outputActionId : null,
  archiveArtifactId: value.hasArchiveArtifactId()
      ? value.archiveArtifactId
      : null,
  editedFromVersionId: value.hasEditedFromVersionId()
      ? value.editedFromVersionId
      : null,
  editedPath: value.hasEditedPath()
      ? List.unmodifiable(value.editedPath.components)
      : null,
);

ModEntry entry(wire.InventoryMod value) => ModEntry(
  id: value.modId,
  workspaceId: value.workspaceId,
  kind: modKind(value.kind),
  metadata: ModMetadata(
    name: value.metadata.name,
    notes: value.metadata.notes,
    comment: value.metadata.comment,
    version: value.metadata.version,
    source: value.metadata.source,
    categories: List.unmodifiable(value.metadata.categories.map(category)),
  ),
  revision: value.revision.toInt(),
  status: inventoryStatus(value.status),
  actions: List.unmodifiable(value.actions.map(modAction)),
  sourcePath: value.hasSourcePath()
      ? List.unmodifiable(value.sourcePath.components)
      : null,
  currentVersionId: value.hasCurrentVersionId() ? value.currentVersionId : null,
  versionOrigin: value.hasVersionOrigin() ? origin(value.versionOrigin) : null,
);
ModEntry modReply(wire.ModReply value) => switch (value.whichOutcome()) {
  wire.ModReply_Outcome.mod => entry(value.mod),
  wire.ModReply_Outcome.fault => reject(value.fault),
  wire.ModReply_Outcome.notSet => throw const FormatException(
    'Missing mod result.',
  ),
};
PublicationReceipt publication(wire.PublicationReply value) =>
    switch (value.whichOutcome()) {
      wire.PublicationReply_Outcome.receipt => PublicationReceipt(
        value.receipt.versionId,
        value.receipt.modId,
        value.receipt.expectedRevision.toInt(),
        publicationPhase(value.receipt.phase),
      ),
      wire.PublicationReply_Outcome.fault => reject(value.fault),
      wire.PublicationReply_Outcome.notSet => throw const FormatException(
        'Missing publication result.',
      ),
    };

wire.ModCategoryReference encodeCategory(CategoryReference value) =>
    wire.ModCategoryReference(
      categoryId: value.id,
      label: value.label,
      missing: value.missing,
    );
CategoryReference category(wire.ModCategoryReference value) =>
    CategoryReference(value.categoryId, value.label, missing: value.missing);
