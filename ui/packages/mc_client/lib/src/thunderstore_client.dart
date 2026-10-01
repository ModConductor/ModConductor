import 'package:grpc/grpc.dart';

import 'generated/modconductor/v1/thunderstore.pbgrpc.dart' as wire;
import 'thunderstore_models.dart';
export 'thunderstore_models.dart';

abstract interface class ThunderstoreClient {
  Future<ThunderstoreReply<ThunderstorePage>> search(
    String workspace,
    String community,
    String query,
    String ordering,
    int page,
  );
  Future<ThunderstoreReply<ThunderstorePackageInfo>> package(
    String workspace,
    ThunderstorePackageRef package, {
    String? version,
  });
  ThunderstoreAcquisition acquire(
    String workspace,
    ThunderstoreVersionRef reference,
  );
  Future<ThunderstoreProblem?> openPage(ThunderstorePackageRef reference);
}

class GrpcThunderstoreClient implements ThunderstoreClient {
  GrpcThunderstoreClient(ClientChannel channel, CallOptions options)
    : _client = wire.ThunderstoreClient(channel, options: options);
  final wire.ThunderstoreClient _client;
  wire.ThunderstorePackageReference _package(ThunderstorePackageRef value) =>
      wire.ThunderstorePackageReference(
        community: value.community,
        namespace: value.namespace,
        name: value.name,
      );
  ThunderstorePackageRef _readPackage(
    wire.ThunderstorePackageReference value,
  ) => ThunderstorePackageRef(value.community, value.namespace, value.name);
  ThunderstoreVersionRef _reference(wire.ThunderstoreVersionReference value) =>
      ThunderstoreVersionRef(_readPackage(value.package), value.version);
  ThunderstoreProblem _problem(wire.ThunderstoreFailure value) =>
      ThunderstoreProblem(
        value.message,
        value.hasRetryAtUnixMs()
            ? DateTime.fromMillisecondsSinceEpoch(value.retryAtUnixMs.toInt())
            : null,
      );
  List<ThunderstoreInstalled> _installed(
    List<wire.ThunderstoreInstalled> values,
  ) => values
      .map(
        (value) =>
            ThunderstoreInstalled(_reference(value.reference), value.modId),
      )
      .toList();
  ThunderstorePreview _preview(wire.ThunderstorePackagePreview value) =>
      ThunderstorePreview(
        _readPackage(value.package),
        value.description,
        value.hasIconUrl() ? Uri.tryParse(value.iconUrl) : null,
        value.deprecated,
        _installed(value.installed),
      );
  ThunderstorePackageInfo _details(wire.ThunderstorePackageDetails value) =>
      ThunderstorePackageInfo(
        reference: _reference(value.reference),
        latestVersion: value.latestVersion,
        description: value.description,
        icon: value.hasIconUrl() ? Uri.tryParse(value.iconUrl) : null,
        deprecated: value.deprecated,
        categories: value.categories.toList(),
        bytes: value.bytes.toInt(),
        versions: value.versions.toList(),
        dependencies: value.dependencies
            .map(
              (dependency) => ThunderstoreDependency(
                _reference(dependency.reference),
                dependency.available,
                _installed(dependency.installed),
                dependency.hasIconUrl()
                    ? Uri.tryParse(dependency.iconUrl)
                    : null,
              ),
            )
            .toList(),
        installed: _installed(value.installed),
      );
  Future<ThunderstoreReply<T>> _call<T>(
    Future<ThunderstoreReply<T>> Function() action,
  ) async {
    try {
      return await action();
    } on GrpcError catch (error) {
      return ThunderstoreRefusal(
        ThunderstoreProblem(
          error.message ?? 'The engine connection could not complete the Thunderstore request.',
        ),
      );
    }
  }

  @override
  Future<ThunderstoreReply<ThunderstorePage>> search(
    String workspace,
    String community,
    String query,
    String ordering,
    int page,
  ) => _call(() async {
    final reply = await _client.searchThunderstore(
      wire.ThunderstoreSearchRequest(
        workspaceId: workspace,
        community: community,
        query: query,
        ordering: ordering,
        page: page,
      ),
    );
    if (reply.hasFailure()) return ThunderstoreRefusal(_problem(reply.failure));
    final value = reply.packages;
    return ThunderstoreValue(
      ThunderstorePage(
        value.entries.map(_preview).toList(),
        value.count,
        value.hasNextPage() ? value.nextPage : null,
      ),
    );
  });
  @override
  Future<ThunderstoreReply<ThunderstorePackageInfo>> package(
    String workspace,
    ThunderstorePackageRef package, {
    String? version,
  }) => _call(() async {
    final reply = await _client.readThunderstorePackage(
      wire.ThunderstorePackageRequest(
        workspaceId: workspace,
        package: _package(package),
        version: version,
      ),
    );
    return reply.hasFailure()
        ? ThunderstoreRefusal(_problem(reply.failure))
        : ThunderstoreValue(_details(reply.package));
  });
  ThunderstoreProgress _progress(wire.ThunderstoreAcquisition value) =>
      ThunderstoreProgress(
        reference: _reference(value.reference),
        stage: value.stage,
        bytes: value.bytes.toInt(),
        total: value.hasTotal() ? value.total.toInt() : null,
        completed: value.completed,
        packages: value.packages,
        modId: value.hasModId() ? value.modId : null,
        problem: value.hasFailure() ? _problem(value.failure) : null,
      );
  @override
  ThunderstoreAcquisition acquire(
    String workspace,
    ThunderstoreVersionRef reference,
  ) {
    final call = _client.acquireThunderstorePackage(
      wire.ThunderstoreAcquireRequest(
        workspaceId: workspace,
        reference: wire.ThunderstoreVersionReference(
          package: _package(reference.package),
          version: reference.version,
        ),
      ),
      options: CallOptions(timeout: const Duration(days: 1)),
    );
    return ThunderstoreAcquisition(call.map(_progress), call.cancel);
  }

  @override
  Future<ThunderstoreProblem?> openPage(
    ThunderstorePackageRef reference,
  ) async {
    try {
      await _client.openThunderstorePage(_package(reference));
      return null;
    } on GrpcError catch (error) {
      return ThunderstoreProblem(
        error.message ?? 'The package page could not be opened.',
      );
    }
  }
}
