import 'proton_context_models.dart';

final class GameCapabilityId {
  const GameCapabilityId._(this.value);

  static const gameInstallationValidation = GameCapabilityId._(
    'game-installation-validation',
  );
  static const skyrimSpecialEdition = GameCapabilityId._(
    'skyrim-special-edition',
  );
  static const archiveInspection = GameCapabilityId._('archive-inspection');
  static const individualSaveEditing = GameCapabilityId._(
    'individual-save-editing',
  );
  static const legacyExtensionAbi = GameCapabilityId._('legacy-extension-abi');

  factory GameCapabilityId.fromWire(String value) => switch (value) {
    'game-installation-validation' => gameInstallationValidation,
    'skyrim-special-edition' => skyrimSpecialEdition,
    'archive-inspection' => archiveInspection,
    'individual-save-editing' => individualSaveEditing,
    'legacy-extension-abi' => legacyExtensionAbi,
    _ => GameCapabilityId._(value),
  };

  final String value;

  @override
  bool operator ==(Object other) =>
      other is GameCapabilityId && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

enum GameCapabilityKind {
  coreOutcome,
  gameAdapter,
  optionalLegacy,
  obsolete,
  unknown,
}

enum GameCapabilityDisposition { available, unavailable, unsupported }

class GameCapabilityContext {
  const GameCapabilityContext({
    required this.definitionId,
    required this.platforms,
  });

  final String definitionId;
  final List<GameContextPlatform> platforms;
}

class GameCapability {
  const GameCapability({
    required this.id,
    required this.revision,
    required this.name,
    required this.kind,
    required this.contexts,
    required this.disposition,
    this.reason,
  });

  final GameCapabilityId id;
  final int revision;
  final String name;
  final GameCapabilityKind kind;
  final List<GameCapabilityContext> contexts;
  final GameCapabilityDisposition disposition;
  final String? reason;

  bool supports(String definitionId, GameContextPlatform platform) =>
      contexts.any(
        (context) =>
            context.definitionId == definitionId &&
            context.platforms.contains(platform),
      );
}

class GameDefinitionInfo {
  const GameDefinitionInfo({
    required this.id,
    required this.revision,
    required this.name,
    required this.storefront,
    required this.declaredSteamAppId,
    required this.capabilities,
  });
  final String id;
  final int revision;
  final String name;
  final String storefront;
  final int declaredSteamAppId;
  final List<GameCapability> capabilities;

  GameCapability? capability(GameCapabilityId id) {
    for (final capability in capabilities) {
      if (capability.id == id) return capability;
    }
    return null;
  }

  bool unavailable(GameCapabilityId id) {
    final value = capability(id);
    return value != null &&
        value.disposition != GameCapabilityDisposition.available;
  }
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
