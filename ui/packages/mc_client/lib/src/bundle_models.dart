import 'installation_models.dart';

enum BundleItemState { needsReview, installed, failed, installing }

class BundleReference {
  const BundleReference(this.workspaceId, this.id, this.revision);
  final String workspaceId, id;
  final int revision;
}

class BundleArchive {
  const BundleArchive(this.index, this.path, this.bytes);
  final int index, bytes;
  final List<String> path;
}

class BundleDiscovery {
  const BundleDiscovery(this.draft, this.archives);
  final InstallationDraft draft;
  final List<BundleArchive> archives;
}

class BundleItem {
  const BundleItem({
    required this.id,
    required this.sourceId,
    required this.modId,
    required this.name,
    required this.order,
    required this.archives,
    required this.bytes,
    required this.state,
    required this.incompleteArchive,
    this.attemptId,
    this.problem,
  });
  final String id, sourceId, modId, name;
  final int order, bytes;
  final List<List<String>> archives;
  final BundleItemState state;
  final bool incompleteArchive;
  final String? attemptId, problem;
}

class BundlePlan {
  const BundlePlan({
    required this.reference,
    required this.artifactId,
    required this.archiveName,
    required this.items,
    required this.temporaryBytes,
    this.problem,
  });
  final BundleReference reference;
  final String artifactId, archiveName;
  final List<BundleItem> items;
  final int temporaryBytes;
  final String? problem;
}

class BundleConfiguration {
  const BundleConfiguration(this.bundle, this.prepared);
  final BundlePlan bundle;
  final BundleDiscovery prepared;
}
