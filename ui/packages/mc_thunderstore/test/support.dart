import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mc_client/mc_client.dart';

const jotunn = ThunderstorePackageRef('valheim', 'ValheimModding', 'Jotunn');
const bep = ThunderstorePackageRef(
  'valheim',
  'denikson',
  'BepInExPack_Valheim',
);
const selected = ThunderstoreVersionRef(jotunn, '2.30.2');
const dependency = ThunderstoreVersionRef(bep, '5.4.2333');
const row = ThunderstorePreview(
  jotunn,
  'Provider description',
  null,
  false,
  [],
);
const page = ThunderstorePage([row], 1, null);

ThunderstorePackageInfo info({
  String version = '2.30.2',
  bool available = true,
  bool installed = false,
  bool deprecated = false,
}) => ThunderstorePackageInfo(
  reference: ThunderstoreVersionRef(jotunn, version),
  latestVersion: '2.30.2',
  description: 'Provider description',
  icon: null,
  deprecated: deprecated,
  categories: const ['Libraries'],
  bytes: 835193,
  versions: const ['2.9.0', '2.30.2', '2.30.1'],
  dependencies: [ThunderstoreDependency(dependency, available, const [], null)],
  installed: installed
      ? [const ThunderstoreInstalled(selected, 'mod')]
      : const [],
);

class Client extends Fake implements ThunderstoreClient {
  final searches = <(String, String, int)>[];
  final reads = <String?>[];
  final acquired = <ThunderstoreVersionRef>[];
  StreamController<ThunderstoreProgress>? stream;
  bool installed = false, cancelled = false;
  Future<ThunderstoreReply<ThunderstorePage>> Function(String)? searchReply;
  Future<ThunderstoreReply<ThunderstorePackageInfo>> Function(String?)?
  packageReply;
  @override
  Future<ThunderstoreReply<ThunderstorePage>> search(
    String workspace,
    String community,
    String query,
    String ordering,
    int index,
  ) {
    searches.add((query, ordering, index));
    return searchReply?.call(query) ??
        Future.value(const ThunderstoreValue(page));
  }

  @override
  Future<ThunderstoreReply<ThunderstorePackageInfo>> package(
    String workspace,
    ThunderstorePackageRef reference, {
    String? version,
  }) {
    reads.add(version);
    return packageReply?.call(version) ??
        Future.value(
          ThunderstoreValue(
            info(version: version ?? "2.30.2", installed: installed),
          ),
        );
  }

  @override
  ThunderstoreAcquisition acquire(
    String workspace,
    ThunderstoreVersionRef reference,
  ) {
    acquired.add(reference);
    stream = StreamController<ThunderstoreProgress>();
    return ThunderstoreAcquisition(stream!.stream, () async {
      cancelled = true;
      await stream!.close();
    });
  }

  @override
  Future<ThunderstoreProblem?> openPage(
    ThunderstorePackageRef reference,
  ) async => null;
}
