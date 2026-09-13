import 'package:grpc/grpc.dart';

import 'generated/modconductor/v1/bethesda_plugins.pbgrpc.dart' as wire;
import 'file_plan_wire.dart' as faults;

class PluginSource {
  const PluginSource(
    this.name,
    this.version,
    this.path,
    this.modId,
    this.versionId,
    this.gameFile,
  );
  final String name, version, path, modId, versionId;
  final bool gameFile;
  String get label => version.isEmpty ? name : '$name · $version';
}

class PluginMaster {
  const PluginMaster(this.name, this.status, this.source);
  final String name, status;
  final PluginSource? source;
}

class PluginHeader {
  const PluginHeader(
    this.extension,
    this.flags,
    this.formVersion,
    this.headerVersion,
    this.records,
    this.author,
    this.description,
    this.flagLabels,
  );
  final String extension, author, description, flagLabels;
  final int flags, formVersion, records;
  final double headerVersion;
}

class PluginEntry {
  const PluginEntry(
    this.name,
    this.kind,
    this.status,
    this.problem,
    this.hasIssues,
    this.winner,
    this.alternatives,
    this.header,
    this.masters,
  );
  final String name, kind, status, problem;
  final bool hasIssues;
  final PluginSource? winner;
  final List<PluginSource> alternatives;
  final PluginHeader? header;
  final List<PluginMaster> masters;
}

class PluginSnapshot {
  const PluginSnapshot(
    this.id,
    this.workspaceId,
    this.profileId,
    this.observedAt,
    this.stale,
    this.entries,
    this.problems,
  );
  final String id, workspaceId, profileId;
  final DateTime observedAt;
  final bool stale;
  final List<PluginEntry> entries;
  final List<String> problems;
}

abstract interface class BethesdaClient {
  Future<PluginSnapshot> scan(String profile);
  Future<PluginSnapshot> read(String snapshot);
}

class GrpcBethesdaClient implements BethesdaClient {
  GrpcBethesdaClient(ClientChannel channel, CallOptions options)
    : _client = wire.BethesdaPluginsClient(channel, options: options);
  final wire.BethesdaPluginsClient _client;
  @override
  Future<PluginSnapshot> scan(String profile) async => _reply(
    await _client.scanPlugins(wire.ScanPluginsRequest(profileId: profile)),
  );
  @override
  Future<PluginSnapshot> read(String snapshot) async => _reply(
    await _client.readPlugins(wire.ReadPluginsRequest(snapshotId: snapshot)),
  );
  static PluginSource _source(wire.BethesdaPluginSource s) =>
      PluginSource(s.name, s.version, s.path, s.modId, s.versionId, s.gameFile);
  static PluginSnapshot _reply(wire.BethesdaPluginsReply reply) {
    switch (reply.whichOutcome()) {
      case wire.BethesdaPluginsReply_Outcome.fault:
        faults.reject(reply.fault);
      case wire.BethesdaPluginsReply_Outcome.notSet:
        throw const FormatException('Missing plugin scan response.');
      case wire.BethesdaPluginsReply_Outcome.snapshot:
        final s = reply.snapshot;
        return PluginSnapshot(
          s.snapshotId,
          s.workspaceId,
          s.profileId,
          DateTime.fromMillisecondsSinceEpoch(
            s.observedAtUnixMs.toInt(),
            isUtc: true,
          ),
          s.stale,
          List.unmodifiable(
            s.plugins.map(
              (p) => PluginEntry(
                p.name,
                p.kind,
                p.status,
                p.problem,
                p.hasIssues,
                p.hasWinner() ? _source(p.winner) : null,
                List.unmodifiable(p.alternatives.map(_source)),
                p.hasHeader()
                    ? PluginHeader(
                        p.header.extension_1,
                        p.header.flags,
                        p.header.formVersion,
                        p.header.headerVersion,
                        p.header.declaredRecords,
                        p.header.author,
                        p.header.description,
                        p.header.flagLabels,
                      )
                    : null,
                List.unmodifiable(
                  p.masters.map(
                    (m) => PluginMaster(
                      m.name,
                      m.status,
                      m.hasSource() ? _source(m.source) : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
          List.unmodifiable(s.problems),
        );
    }
  }
}
