import 'proton_context_models.dart';

final class GameCapabilityId {
  const GameCapabilityId._(this.value);

  static const gameInstallationValidation = GameCapabilityId._(
    'game-installation-validation',
  );
  static const skyrimSpecialEdition = GameCapabilityId._(
    'skyrim-special-edition',
  );
  static const bethesdaGame = GameCapabilityId._('bethesda-game');
  static const unreal = GameCapabilityId._('unreal');
  static const unityMono = GameCapabilityId._('unity-mono');
  static const unityIl2Cpp = GameCapabilityId._('unity-il2cpp');
  static const archiveInspection = GameCapabilityId._('archive-inspection');
  static const individualSaveEditing = GameCapabilityId._(
    'individual-save-editing',
  );
  static const legacyExtensionAbi = GameCapabilityId._('legacy-extension-abi');

  factory GameCapabilityId.fromWire(String value) => switch (value) {
    'game-installation-validation' => gameInstallationValidation,
    'skyrim-special-edition' => skyrimSpecialEdition,
    'archive-inspection' => archiveInspection,
    'bethesda-game' => bethesdaGame,
    'unity-mono' => unityMono,
    'unity-il2cpp' => unityIl2Cpp,
    'unreal' => unreal,
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
    this.thunderstoreCommunity = '',
    this.artworkUrl = '',
    this.settingsIni = '',
    this.pluginOrdering = '',
    this.saveExtension = '',
    this.extenderName = '',
    this.extenderLoader = '',
    this.supportsLight = false,
    this.supportsMedium = false,
    this.archiveInvalidation = false,
  });
  final String id;
  final int revision;
  final String name;
  final String storefront;
  final String thunderstoreCommunity;
  final int declaredSteamAppId;
  final List<GameCapability> capabilities;
  final String artworkUrl, settingsIni, pluginOrdering, saveExtension;
  final String extenderName, extenderLoader;
  final bool supportsLight, supportsMedium, archiveInvalidation;

  GameCapability? capability(GameCapabilityId id) {
    for (final capability in capabilities) {
      if (capability.id == id) return capability;
    }
    return null;
  }

  String get variantGroupId {
    if (id.startsWith('custom-')) return id;
    for (final suffix in const ['-steam', '-gog', '-direct', '-epic']) {
      if (id.endsWith(suffix)) {
        return id.substring(0, id.length - suffix.length);
      }
    }
    return id;
  }

  String selectionLabel(Iterable<GameDefinitionInfo> choices) =>
      choices
          .where(
            (row) => row.name == name && row.variantGroupId != variantGroupId,
          )
          .isEmpty
      ? name
      : '$name · $storefront · ${id.substring(id.length > 8 ? id.length - 8 : 0)}';
  bool get nativeLinux => capabilities.any(
    (capability) => capability.supports(id, GameContextPlatform.nativeLinux),
  );

  bool unavailable(GameCapabilityId id) {
    final value = capability(id);
    return value != null &&
        value.disposition != GameCapabilityDisposition.available;
  }
}

enum GameContextPlatform { windows, proton, wine, nativeLinux }

enum GameInstallationSource {
  steam('Steam'),
  gog('GOG Windows'),
  direct('DRM-free Windows'),
  epic('Epic Windows'),
  folder('Folder');

  const GameInstallationSource(this.label);
  final String label;

  static GameInstallationSource fromDefinition(GameDefinitionInfo game) =>
      switch (game.storefront) {
        'Folder' => folder,
        'GOG Windows' => gog,
        'Epic Windows' => epic,
        'DRM-free Windows' => direct,
        _ => steam,
      };
  static GameInstallationSource fromGameId(String? id) => switch (id) {
    final String value when value.endsWith('-gog') => gog,
    final String value when value.endsWith('-direct') => direct,
    final String value when value.endsWith('-epic') => epic,
    _ => steam,
  };
}

class WineSelection {
  const WineSelection({required this.executable, required this.prefix});
  final String executable;
  final String prefix;

  bool get complete => executable.isNotEmpty && prefix.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      other is WineSelection &&
      executable == other.executable &&
      prefix == other.prefix;
  @override
  int get hashCode => Object.hash(executable, prefix);
}

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
    this.wine,
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
  final WineSelection? wine;

  bool get runtimeReady => switch (platform) {
    GameContextPlatform.windows || GameContextPlatform.nativeLinux => true,
    GameContextPlatform.proton => proton != null,
    GameContextPlatform.wine => wine != null,
  };
}

class GameBindingInfo {
  const GameBindingInfo({
    required this.id,
    required this.path,
    required this.evidence,
    required this.needsCheck,
    this.failure,
    this.proton,
    this.wine,
  });
  final String id;
  final String path;
  final GameInstallationEvidence evidence;
  final bool needsCheck;
  final String? failure;
  final ProtonSelection? proton;
  final WineSelection? wine;
}

class GameContextState {
  const GameContextState({
    required this.workspaceId,
    required this.profileId,
    required this.revision,
    required this.definition,
    this.binding,
  });
  final String workspaceId;
  final String profileId;
  final int revision;
  final GameDefinitionInfo? definition;
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
