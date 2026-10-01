class ThunderstorePackageRef {
  const ThunderstorePackageRef(this.community, this.namespace, this.name);
  final String community, namespace, name;
  String get key => '$community/$namespace/$name';
}

class ThunderstoreVersionRef {
  const ThunderstoreVersionRef(this.package, this.version);
  final ThunderstorePackageRef package;
  final String version;
}

class ThunderstoreProblem {
  const ThunderstoreProblem(this.message, [this.retryAt]);
  final String message;
  final DateTime? retryAt;
}

sealed class ThunderstoreReply<T> {
  const ThunderstoreReply();
}

class ThunderstoreValue<T> extends ThunderstoreReply<T> {
  const ThunderstoreValue(this.value);
  final T value;
}

class ThunderstoreRefusal<T> extends ThunderstoreReply<T> {
  const ThunderstoreRefusal(this.problem);
  final ThunderstoreProblem problem;
}

class ThunderstoreInstalled {
  const ThunderstoreInstalled(this.reference, this.modId);
  final ThunderstoreVersionRef reference;
  final String modId;
}

class ThunderstorePreview {
  const ThunderstorePreview(
    this.package,
    this.description,
    this.icon,
    this.deprecated,
    this.installed,
  );
  final ThunderstorePackageRef package;
  final String description;
  final Uri? icon;
  final bool deprecated;
  final List<ThunderstoreInstalled> installed;
}

class ThunderstorePage {
  const ThunderstorePage(this.entries, this.count, this.next);
  final List<ThunderstorePreview> entries;
  final int count;
  final int? next;
}

class ThunderstoreDependency {
  const ThunderstoreDependency(
    this.reference,
    this.available,
    this.installed,
    this.icon,
  );
  final ThunderstoreVersionRef reference;
  final bool available;
  final List<ThunderstoreInstalled> installed;
  final Uri? icon;
}

class ThunderstorePackageInfo {
  const ThunderstorePackageInfo({
    required this.reference,
    required this.latestVersion,
    required this.description,
    required this.icon,
    required this.deprecated,
    required this.categories,
    required this.bytes,
    required this.versions,
    required this.dependencies,
    required this.installed,
  });
  final ThunderstoreVersionRef reference;
  final String latestVersion, description;
  final Uri? icon;
  final bool deprecated;
  final int bytes;
  final List<String> categories, versions;
  final List<ThunderstoreDependency> dependencies;
  final List<ThunderstoreInstalled> installed;
}

class ThunderstoreProgress {
  const ThunderstoreProgress({
    required this.reference,
    required this.stage,
    required this.bytes,
    this.total,
    required this.completed,
    required this.packages,
    this.modId,
    this.problem,
  });
  final ThunderstoreVersionRef reference;
  final String stage;
  final int bytes, completed, packages;
  final int? total;
  final String? modId;
  final ThunderstoreProblem? problem;
}

class ThunderstoreAcquisition {
  const ThunderstoreAcquisition(this.progress, this.cancel);
  final Stream<ThunderstoreProgress> progress;
  final Future<void> Function() cancel;
}
