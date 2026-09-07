import 'game_context_models.dart';
import 'steam_discovery_models.dart';

sealed class ProtonAssociation {
  const ProtonAssociation();
}

final class ManualProtonAssociation extends ProtonAssociation {
  const ManualProtonAssociation();
}

final class SteamProtonAssociation extends ProtonAssociation {
  const SteamProtonAssociation(this.steamRoot, this.library);
  final String steamRoot, library;
}

class ProtonSelection {
  const ProtonSelection({
    required this.appId,
    required this.association,
    required this.compatData,
    required this.runtimeDirectory,
    required this.toolId,
  });
  final int appId;
  final ProtonAssociation association;
  final String compatData, runtimeDirectory, toolId;
}

class ProtonContextFile {
  const ProtonContextFile(this.path, this.nativeIdentity, this.sha256);
  final String path, nativeIdentity, sha256;
}

class ProtonUserPath {
  const ProtonUserPath(this.name, this.windowsPath, this.location);
  final String name;
  final String? windowsPath;
  final GameLocation location;
}

class ProtonEvidence {
  const ProtonEvidence({
    required this.selection,
    required this.prefixPath,
    required this.prefixIdentity,
    required this.compatDataIdentity,
    required this.runtimeIdentity,
    required this.runtimeName,
    required this.runtimeVersion,
    required this.launcher,
    required this.metadata,
    required this.paths,
    this.prefixVersion,
    this.perGameTool,
    this.globalTool,
    this.mappingProblem,
  });
  final ProtonSelection selection;
  final String prefixPath, prefixIdentity, compatDataIdentity, runtimeIdentity;
  final String runtimeName, runtimeVersion;
  final String? prefixVersion, perGameTool, globalTool, mappingProblem;
  final ProtonContextFile launcher;
  final List<ProtonContextFile> metadata;
  final List<ProtonUserPath> paths;
}

class ProtonPrefixCandidate {
  const ProtonPrefixCandidate(
    this.id,
    this.compatData,
    this.prefixPath,
    this.origins,
  );
  final String id, compatData, prefixPath;
  final List<SteamInstallationOrigin> origins;
}

class ProtonInstalledTool {
  const ProtonInstalledTool(this.id, this.name, this.directory, this.source);
  final String id, name, directory;
  final ProtonContextFile source;
}

class ProtonToolMapping {
  const ProtonToolMapping(this.perGame, this.globalDefault, this.source);
  final String? perGame, globalDefault;
  final ProtonContextFile source;
}

class ProtonSearchResult {
  const ProtonSearchResult({
    required this.prefixes,
    required this.tools,
    required this.mappings,
    required this.problems,
    required this.limited,
  });
  final List<ProtonPrefixCandidate> prefixes;
  final List<ProtonInstalledTool> tools;
  final List<ProtonToolMapping> mappings;
  final List<GameValidationProblem> problems;
  final bool limited;
}

class ProtonSearch {
  const ProtonSearch(this.result, this.cancel);
  final Future<ProtonSearchResult> result;
  final Future<void> Function() cancel;
}
