class SteamSearchRoot {
  const SteamSearchRoot(this.path, this.origin);
  final String path, origin;
}

class SteamDirectory {
  const SteamDirectory(
    this.declaredPath,
    this.canonicalPath,
    this.nativeIdentity,
  );
  final String declaredPath, canonicalPath;
  final String? nativeIdentity;
}

class SteamManifestEvidence {
  const SteamManifestEvidence({
    required this.path,
    required this.nativeIdentity,
    required this.sha256,
    required this.appId,
    required this.installDirectory,
    this.name,
    this.buildId,
    this.stateFlags,
  });
  final String path, nativeIdentity, sha256, installDirectory;
  final int appId;
  final String? name, buildId, stateFlags;
}

class SteamInstallationOrigin {
  const SteamInstallationOrigin({
    required this.root,
    required this.steamRoot,
    required this.library,
    required this.manifest,
    this.libraryEntry,
  });
  final SteamSearchRoot root;
  final SteamDirectory steamRoot, library;
  final SteamManifestEvidence manifest;
  final String? libraryEntry;
}

class SteamInstallationCandidate {
  const SteamInstallationCandidate(this.id, this.directory, this.origins);
  final String id;
  final SteamDirectory directory;
  final List<SteamInstallationOrigin> origins;
}

enum SteamDiscoveryProblem {
  rootUnavailable,
  librariesUnreadable,
  librariesMalformed,
  libraryPathInvalid,
  manifestUnreadable,
  manifestMalformed,
  staleEntry,
  appIdMismatch,
  unsafeInstallDirectory,
  installationUnavailable,
  limitReached,
}

class SteamSearchDiagnostic {
  const SteamSearchDiagnostic(this.rootPath, this.path, this.kind, this.detail);
  final String rootPath, path, detail;
  final SteamDiscoveryProblem kind;
}

class SteamSearchResult {
  const SteamSearchResult({
    required this.appId,
    required this.roots,
    required this.candidates,
    required this.diagnostics,
    required this.limited,
  });
  final int appId;
  final List<SteamSearchRoot> roots;
  final List<SteamInstallationCandidate> candidates;
  final List<SteamSearchDiagnostic> diagnostics;
  final bool limited;
}

class SteamSearch {
  const SteamSearch(this.result, this.cancel);
  final Future<SteamSearchResult> result;
  final Future<void> Function() cancel;
}
