import 'proton_context_models.dart';

class UnavailableGameCapability {
  const UnavailableGameCapability(this.name, this.reason);
  final String name;
  final String reason;
}

class GameDefinitionInfo {
  const GameDefinitionInfo({
    required this.id,
    required this.revision,
    required this.name,
    required this.storefront,
    required this.declaredSteamAppId,
    required this.unavailableCapabilities,
  });
  final String id;
  final int revision;
  final String name;
  final String storefront;
  final int declaredSteamAppId;
  final List<UnavailableGameCapability> unavailableCapabilities;
}

enum GameContextPlatform { windows, proton }

sealed class GameLocation {
  const GameLocation();
}

final class LocatedGameFolder extends GameLocation {
  const LocatedGameFolder(this.path, this.exists);
  final String path;
  final bool exists;
}

final class UnavailableGameLocation extends GameLocation {
  const UnavailableGameLocation(this.reason);
  final String reason;
}

class GameExecutableEvidence {
  const GameExecutableEvidence({
    required this.path,
    required this.sha256,
    required this.length,
    required this.fileVersion,
    required this.productVersion,
  });
  final String path;
  final String sha256;
  final int length;
  final String fileVersion;
  final String productVersion;
}

class GameValidationProblem {
  const GameValidationProblem(this.path, this.detail);
  final String path;
  final String detail;
}

class GameInstallationEvidence {
  const GameInstallationEvidence({
    required this.definitionId,
    required this.definitionRevision,
    required this.platform,
    required this.rootPath,
    required this.dataPath,
    required this.executable,
    required this.launcherPath,
    required this.documents,
    required this.saves,
    required this.localAppData,
    required this.problems,
    required this.checkedAt,
    required this.fingerprint,
    this.proton,
  });
  final String definitionId;
  final int definitionRevision;
  final GameContextPlatform platform;
  final String rootPath;
  final String? dataPath;
  final GameExecutableEvidence? executable;
  final String? launcherPath;
  final GameLocation documents;
  final GameLocation saves;
  final GameLocation localAppData;
  final List<GameValidationProblem> problems;
  final DateTime checkedAt;
  final String fingerprint;
  final ProtonEvidence? proton;
}

class GameBindingInfo {
  const GameBindingInfo({
    required this.id,
    required this.path,
    required this.evidence,
    required this.needsCheck,
    this.failure,
    this.proton,
  });
  final String id;
  final String path;
  final GameInstallationEvidence evidence;
  final bool needsCheck;
  final String? failure;
  final ProtonSelection? proton;
}

class GameContextState {
  const GameContextState({
    required this.workspaceId,
    required this.revision,
    required this.definition,
    this.binding,
  });
  final String workspaceId;
  final int revision;
  final GameDefinitionInfo definition;
  final GameBindingInfo? binding;
}

enum GameContextFailure {
  notFound,
  stale,
  workspaceUnavailable,
  invalidInstallation,
  busy,
}

class GameContextException implements Exception {
  const GameContextException(this.code, this.detail, {this.candidate});
  final GameContextFailure code;
  final String detail;
  final GameInstallationEvidence? candidate;
}
