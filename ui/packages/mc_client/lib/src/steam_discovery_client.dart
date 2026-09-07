import 'package:grpc/grpc.dart';

import 'generated/modconductor/v1/steam_discovery.pbgrpc.dart' as wire;
import 'steam_discovery_models.dart';
export 'steam_discovery_models.dart';

abstract interface class SteamDiscoveryClient {
  SteamSearch search(String definitionId, List<String> additionalRoots);
}

class GrpcSteamDiscoveryClient implements SteamDiscoveryClient {
  GrpcSteamDiscoveryClient(ClientChannel channel, CallOptions options)
    : _client = wire.SteamDiscoveryOperationsClient(channel, options: options);
  final wire.SteamDiscoveryOperationsClient _client;
  @override
  SteamSearch search(String definitionId, List<String> additionalRoots) {
    final call = _client.searchInstallations(
      wire.SteamSearchRequest(
        definitionId: definitionId,
        additionalRoots: additionalRoots,
      ),
      options: CallOptions(timeout: const Duration(seconds: 30)),
    );
    return SteamSearch(call.then(_result), call.cancel);
  }
}

SteamSearchRoot _root(wire.SteamSearchRoot r) =>
    SteamSearchRoot(r.path, r.origin);
SteamDirectory _directory(wire.SteamDirectory d) => SteamDirectory(
  d.declaredPath,
  d.canonicalPath,
  d.hasNativeIdentity() ? d.nativeIdentity : null,
);
SteamInstallationOrigin _origin(wire.SteamInstallationOrigin o) {
  final m = o.manifest;
  return SteamInstallationOrigin(
    root: _root(o.root),
    steamRoot: _directory(o.steamRoot),
    library: _directory(o.library),
    libraryEntry: o.hasLibraryEntry() ? o.libraryEntry : null,
    manifest: SteamManifestEvidence(
      path: m.path,
      nativeIdentity: m.nativeIdentity,
      sha256: m.sha256,
      appId: m.appId,
      installDirectory: m.installDirectory,
      name: m.hasName() ? m.name : null,
      buildId: m.hasBuildId() ? m.buildId : null,
      stateFlags: m.hasStateFlags() ? m.stateFlags.toString() : null,
    ),
  );
}

SteamDiscoveryProblem _problem(
  wire.SteamDiscoveryProblem value,
) => switch (value) {
  wire.SteamDiscoveryProblem.STEAM_DISCOVERY_PROBLEM_ROOT_UNAVAILABLE =>
    SteamDiscoveryProblem.rootUnavailable,
  wire.SteamDiscoveryProblem.STEAM_DISCOVERY_PROBLEM_LIBRARIES_UNREADABLE =>
    SteamDiscoveryProblem.librariesUnreadable,
  wire.SteamDiscoveryProblem.STEAM_DISCOVERY_PROBLEM_LIBRARIES_MALFORMED =>
    SteamDiscoveryProblem.librariesMalformed,
  wire.SteamDiscoveryProblem.STEAM_DISCOVERY_PROBLEM_LIBRARY_PATH_INVALID =>
    SteamDiscoveryProblem.libraryPathInvalid,
  wire.SteamDiscoveryProblem.STEAM_DISCOVERY_PROBLEM_MANIFEST_UNREADABLE =>
    SteamDiscoveryProblem.manifestUnreadable,
  wire.SteamDiscoveryProblem.STEAM_DISCOVERY_PROBLEM_MANIFEST_MALFORMED =>
    SteamDiscoveryProblem.manifestMalformed,
  wire.SteamDiscoveryProblem.STEAM_DISCOVERY_PROBLEM_STALE_ENTRY =>
    SteamDiscoveryProblem.staleEntry,
  wire.SteamDiscoveryProblem.STEAM_DISCOVERY_PROBLEM_APP_ID_MISMATCH =>
    SteamDiscoveryProblem.appIdMismatch,
  wire.SteamDiscoveryProblem.STEAM_DISCOVERY_PROBLEM_UNSAFE_INSTALL_DIRECTORY =>
    SteamDiscoveryProblem.unsafeInstallDirectory,
  wire.SteamDiscoveryProblem.STEAM_DISCOVERY_PROBLEM_INSTALLATION_UNAVAILABLE =>
    SteamDiscoveryProblem.installationUnavailable,
  wire.SteamDiscoveryProblem.STEAM_DISCOVERY_PROBLEM_LIMIT_REACHED =>
    SteamDiscoveryProblem.limitReached,
  _ => throw const FormatException('Unknown Steam search problem.'),
};
SteamSearchResult _result(wire.SteamSearchResult r) => SteamSearchResult(
  appId: r.appId,
  roots: List.unmodifiable(r.roots.map(_root)),
  candidates: List.unmodifiable(
    r.candidates.map(
      (c) => SteamInstallationCandidate(
        c.candidateId,
        _directory(c.directory),
        List.unmodifiable(c.origins.map(_origin)),
      ),
    ),
  ),
  diagnostics: List.unmodifiable(
    r.diagnostics.map(
      (d) =>
          SteamSearchDiagnostic(d.rootPath, d.path, _problem(d.kind), d.detail),
    ),
  ),
  limited: r.limited,
);
