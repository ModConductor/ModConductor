import 'package:mc_client/mc_client.dart';

class SteamDiagnosticGroup {
  const SteamDiagnosticGroup({
    required this.id,
    required this.kind,
    required this.path,
    required this.details,
    required this.origins,
  });

  final String id;
  final SteamDiscoveryProblem kind;
  final String path;
  final List<String> details;
  final List<String> origins;
}

String _pathIdentity(String value) {
  var normalized = value.replaceAll('\\', '/');
  while (normalized.length > 1 && normalized.endsWith('/')) {
    normalized = normalized.substring(0, normalized.length - 1);
  }
  if (RegExp(r'^[A-Za-z]:/').hasMatch(normalized)) {
    normalized = normalized.toLowerCase();
  }
  return normalized;
}

List<SteamDiagnosticGroup> groupSteamDiagnostics(SteamSearchResult report) {
  final groups =
      <(SteamDiscoveryProblem, String), List<SteamSearchDiagnostic>>{};
  for (final diagnostic in report.diagnostics) {
    final key = (diagnostic.kind, _pathIdentity(diagnostic.path));
    groups.putIfAbsent(key, () => []).add(diagnostic);
  }

  final rootOrigins = <String, List<String>>{};
  for (final root in report.roots) {
    rootOrigins.putIfAbsent(root.path, () => []).add(root.origin);
  }

  return [
    for (final entry in groups.entries)
      SteamDiagnosticGroup(
        id: '${entry.key.$1.name}:${entry.key.$2}',
        kind: entry.key.$1,
        path: entry.value.first.path,
        details: entry.value.map((value) => value.detail).toSet().toList(),
        origins: entry.value
            .expand((value) => rootOrigins[value.rootPath] ?? [value.rootPath])
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList(),
      ),
  ];
}
