import 'generated/modconductor/v1/proton_contexts.pb.dart' as wire;
import 'game_context_models.dart';
import 'proton_context_models.dart';

wire.ProtonSelectionInfo encodeProtonSelection(ProtonSelection value) {
  final result = wire.ProtonSelectionInfo(
    appId: value.appId,
    compatData: value.compatData,
    runtimeDirectory: value.runtimeDirectory,
    toolId: value.toolId,
  );
  switch (value.association) {
    case ManualProtonAssociation():
      result.manual = true;
    case SteamProtonAssociation(:final steamRoot, :final library):
      result.steam = wire.ProtonSteamAssociation(
        steamRoot: steamRoot,
        library: library,
      );
  }
  return result;
}

ProtonSelection decodeProtonSelection(wire.ProtonSelectionInfo p) =>
    ProtonSelection(
      appId: p.appId,
      compatData: p.compatData,
      runtimeDirectory: p.runtimeDirectory,
      toolId: p.toolId,
      association: switch (p.whichAssociation()) {
        wire.ProtonSelectionInfo_Association.manual when p.manual =>
          const ManualProtonAssociation(),
        wire.ProtonSelectionInfo_Association.steam => SteamProtonAssociation(
          p.steam.steamRoot,
          p.steam.library,
        ),
        _ => throw const FormatException('Missing Proton association.'),
      },
    );
ProtonContextFile decodeProtonFile(wire.ProtonContextFile f) =>
    ProtonContextFile(f.path, f.nativeIdentity, f.sha256);
ProtonEvidence decodeProtonEvidence(wire.ProtonContextEvidence e) =>
    ProtonEvidence(
      selection: decodeProtonSelection(e.selection),
      prefixPath: e.prefixPath,
      prefixIdentity: e.prefixIdentity,
      compatDataIdentity: e.compatDataIdentity,
      runtimeIdentity: e.runtimeIdentity,
      runtimeName: e.runtimeName,
      runtimeVersion: e.runtimeVersion,
      prefixVersion: e.hasPrefixVersion() ? e.prefixVersion : null,
      perGameTool: e.hasPerGameTool() ? e.perGameTool : null,
      globalTool: e.hasGlobalTool() ? e.globalTool : null,
      mappingProblem: e.hasMappingProblem() ? e.mappingProblem : null,
      launcher: decodeProtonFile(e.launcher),
      metadata: List.unmodifiable(e.metadata.map(decodeProtonFile)),
      paths: List.unmodifiable(
        e.paths.map(
          (p) => ProtonUserPath(
            p.name,
            p.hasWindowsPath() ? p.windowsPath : null,
            switch (p.whichResult()) {
              wire.ProtonUserPath_Result.located => LocatedGameFolder(
                p.located.path,
                p.located.exists,
              ),
              wire.ProtonUserPath_Result.unavailableReason =>
                UnavailableGameLocation(p.unavailableReason),
              wire.ProtonUserPath_Result.notSet => throw const FormatException(
                'Missing Proton path result.',
              ),
            },
          ),
        ),
      ),
    );
