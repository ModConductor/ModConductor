import 'package:grpc/grpc.dart';

import 'generated/modconductor/v1/proton_contexts.pbgrpc.dart' as wire;
import 'game_context_models.dart';
import 'proton_context_models.dart';
import 'proton_context_wire.dart';
import 'steam_discovery_client.dart' show decodeSteamOrigin;
export 'proton_context_models.dart';

abstract interface class ProtonContextsClient {
  ProtonSearch search(
    String definitionId,
    String gamePath,
    List<String> additionalRoots,
  );
}

class GrpcProtonContextsClient implements ProtonContextsClient {
  GrpcProtonContextsClient(ClientChannel channel, CallOptions options)
    : _client = wire.ProtonContextOperationsClient(channel, options: options);
  final wire.ProtonContextOperationsClient _client;
  @override
  ProtonSearch search(
    String definitionId,
    String gamePath,
    List<String> additionalRoots,
  ) {
    final call = _client.searchProtonContexts(
      wire.SearchProtonContextsRequest(
        definitionId: definitionId,
        gamePath: gamePath,
        additionalRoots: additionalRoots,
      ),
      options: CallOptions(timeout: const Duration(seconds: 30)),
    );
    return ProtonSearch(
      call.then(
        (r) => ProtonSearchResult(
          prefixes: List.unmodifiable(
            r.prefixes.map(
              (p) => ProtonPrefixCandidate(
                p.candidateId,
                p.compatData,
                p.prefixPath,
                List.unmodifiable(p.origins.map(decodeSteamOrigin)),
              ),
            ),
          ),
          tools: List.unmodifiable(
            r.tools.map(
              (t) => ProtonInstalledTool(
                t.toolId,
                t.name,
                t.directory,
                decodeProtonFile(t.source),
              ),
            ),
          ),
          mappings: List.unmodifiable(
            r.mappings.map(
              (m) => ProtonToolMapping(
                m.hasPerGame() ? m.perGame : null,
                m.hasGlobalDefault() ? m.globalDefault : null,
                decodeProtonFile(m.source),
              ),
            ),
          ),
          problems: List.unmodifiable(
            r.problems.map((p) => GameValidationProblem(p.path, p.detail)),
          ),
          limited: r.limited,
        ),
      ),
      call.cancel,
    );
  }
}
