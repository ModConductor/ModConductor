enum OutputLocationKind { toolFolder, writableFile }

enum OutputLocationStatus { uninitialized, ready, stopped }

enum OutputFileStatus { newFile, changed, kept, absent }

enum OutputDisposition { kept, discarded, moved, copied, changed, pending }

enum OutputFailure {
  notFound,
  busy,
  stale,
  cancelled,
  invalid,
  unavailable,
  limitExceeded,
}

class OutputException implements Exception {
  const OutputException(this.failure, this.detail);
  final OutputFailure failure;
  final String detail;
}

class OutputScopeRef {
  const OutputScopeRef(
    this.workspaceId,
    this.contextId,
    this.revision,
    this.contextRevision,
  );
  final String workspaceId, contextId;
  final int revision, contextRevision;
}

class OutputLocation {
  const OutputLocation({
    required this.id,
    required this.workspaceId,
    required this.contextId,
    required this.name,
    required this.kind,
    required this.revision,
    required this.status,
    required this.physicalPath,
    this.target,
  });
  final String id, workspaceId, contextId, name, physicalPath;
  final OutputLocationKind kind;
  final List<String>? target;
  final int revision;
  final OutputLocationStatus status;
}

class OutputContext {
  const OutputContext(this.id, this.installation, this.current);
  final String id, installation;
  final bool current;
}

class OutputScope {
  const OutputScope(
    this.reference,
    this.installation,
    this.locations,
    this.contexts,
    this.pendingActions,
  );
  final OutputScopeRef reference;
  final String installation;
  final List<OutputLocation> locations;
  final List<OutputContext> contexts;
  final List<String> pendingActions;
}

class OutputFile {
  const OutputFile(
    this.locationId,
    this.path,
    this.status,
    this.length,
    this.sha256,
    this.observedAt,
    this.deploymentId,
  );
  final String locationId, sha256;
  final List<String> path;
  final OutputFileStatus status;
  final int length;
  final DateTime observedAt;
  final String? deploymentId;
  OutputSelection get selection => OutputSelection(locationId, path);
}

class OutputSnapshot {
  const OutputSnapshot(
    this.id,
    this.scope,
    this.observedAt,
    this.files,
    this.entries,
    this.unreviewed,
  );
  final String id;
  final OutputScope scope;
  final DateTime observedAt;
  final int files, entries, unreviewed;
}

class OutputPage {
  const OutputPage(
    this.snapshot,
    this.entries,
    this.matching,
    this.nextCursor,
    this.files,
    this.unreviewed,
  );
  final OutputSnapshot snapshot;
  final List<OutputFile> entries;
  final int matching, files, unreviewed;
  final String? nextCursor;
}

class OutputSelection {
  const OutputSelection(this.locationId, this.path);
  final String locationId;
  final List<String> path;
}

sealed class OutputDestination {
  const OutputDestination();
}

class ExistingOutputMod extends OutputDestination {
  const ExistingOutputMod(this.id, this.revision, this.versionLabel);
  final String id, versionLabel;
  final int revision;
}

class NewOutputMod extends OutputDestination {
  const NewOutputMod(this.id, this.name, this.versionLabel);
  final String id, name, versionLabel;
}

sealed class OutputAction {
  const OutputAction();
}

class KeepOutput extends OutputAction {
  const KeepOutput();
}

class DiscardOutput extends OutputAction {
  const DiscardOutput();
}

class MoveOutputToMod extends OutputAction {
  const MoveOutputToMod(this.destination);
  final OutputDestination destination;
}

class SaveOutputCopy extends OutputAction {
  const SaveOutputCopy(this.destination);
  final OutputDestination destination;
}

class OutputPromotionPreview {
  const OutputPromotionPreview(
    this.selected,
    this.replaced,
    this.previousVersion,
    this.registeredSource,
  );
  final int selected;
  final List<List<String>> replaced;
  final String? previousVersion;
  final bool registeredSource;
}

class OutputActionEntry {
  const OutputActionEntry(this.file, this.disposition);
  final OutputSelection file;
  final OutputDisposition disposition;
}

class OutputActionResult {
  const OutputActionResult(
    this.id,
    this.versionId,
    this.published,
    this.entries,
    this.complete,
  );
  final String id;
  final String? versionId;
  final bool published, complete;
  final List<OutputActionEntry> entries;
}

sealed class OutputLoadEvent {
  const OutputLoadEvent();
}

class OutputLoadProgress extends OutputLoadEvent {
  const OutputLoadProgress(this.files, this.bytes);
  final int files, bytes;
}

class OutputsObserved extends OutputLoadEvent {
  const OutputsObserved(this.snapshot);
  final OutputSnapshot snapshot;
}
