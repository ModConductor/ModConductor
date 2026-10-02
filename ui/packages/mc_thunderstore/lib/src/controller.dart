import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_collections/mc_ui_collections.dart';

class ThunderstoreController extends ChangeNotifier {
  ThunderstoreController(
    this.client,
    this.workspace, {
    this.community = 'valheim',
  });
  final String community;
  final ThunderstoreClient client;
  final String workspace;
  final model = McCollectionModel<String, ThunderstorePreview>(
    idOf: (row) => row.package.key,
    labelOf: (row) => '${row.package.name} ${row.package.namespace}',
  );
  String query = '', ordering = 'most-downloaded';
  int count = 0;
  int? next;
  bool loading = false, detailLoading = false, running = false;
  ThunderstorePackageRef? selected;
  ThunderstorePackageInfo? details;
  ThunderstoreProgress? progress;
  ThunderstoreProblem? problem, detailProblem;
  Timer? _searchTimer;
  int _searchRevision = 0, _detailRevision = 0;
  bool _disposed = false, _cancelled = false;
  ThunderstoreAcquisition? _acquisition;
  StreamSubscription<ThunderstoreProgress>? _updates;

  void changeQuery(String value) {
    query = value;
    _searchRevision++;
    _searchTimer?.cancel();
    _searchTimer = Timer(
      const Duration(milliseconds: 250),
      () => unawaited(search()),
    );
    notifyListeners();
  }

  void changeOrdering(String value) {
    if (ordering == value) return;
    ordering = value;
    _searchTimer?.cancel();
    unawaited(search());
  }

  Future<void> search({bool more = false}) async {
    if (more && (loading || next == null)) return;
    final revision = ++_searchRevision;
    loading = true;
    problem = null;
    notifyListeners();
    final result = await client.search(
      workspace,
      community,
      query,
      ordering,
      more ? next! : 1,
    );
    if (_disposed || revision != _searchRevision) return;
    loading = false;
    switch (result) {
      case ThunderstoreRefusal(:final problem):
        this.problem = problem;
      case ThunderstoreValue(:final value):
        count = value.count;
        next = value.next;
        model.apply(
          upserts: value.entries,
          evicted: more ? const [] : model.ids.toList(),
          removed: more
              ? const []
              : model.ids
                    .where(
                      (id) =>
                          !value.entries.any((row) => row.package.key == id),
                    )
                    .toList(),
        );
    }
    notifyListeners();
  }

  Future<void> inspect(
    ThunderstorePackageRef package, {
    String? version,
  }) async {
    if (running) return;
    final revision = ++_detailRevision;
    if (selected?.key != package.key) details = null;
    selected = package;
    model.select(package.key);
    detailLoading = true;
    detailProblem = null;
    notifyListeners();
    final result = await client.package(workspace, package, version: version);
    if (_disposed || revision != _detailRevision) return;
    detailLoading = false;
    switch (result) {
      case ThunderstoreRefusal(:final problem):
        details = null;
        detailProblem = problem;
      case ThunderstoreValue(:final value):
        details = value;
    }
    notifyListeners();
  }

  void closeDetails() {
    if (running) return;
    _detailRevision++;
    selected = null;
    details = null;
    detailProblem = null;
    detailLoading = false;
    model.clearSelection();
    notifyListeners();
  }

  bool get alreadyAdded =>
      details?.installed.any(
        (entry) => entry.reference.version == details?.reference.version,
      ) ==
      true;
  bool get canAdd =>
      !running &&
      !detailLoading &&
      details != null &&
      !alreadyAdded &&
      details!.dependencies.every((dependency) => dependency.available);
  String status(ThunderstorePreview row) {
    if (row.deprecated) return 'Deprecated';
    final installed = selected?.key == row.package.key && details != null
        ? details!.installed
        : row.installed;
    if (installed.isEmpty) return '';
    if (selected?.key == row.package.key &&
        details != null &&
        !installed.any(
          (entry) => entry.reference.version == details!.latestVersion,
        ))
      return 'Update available';
    return 'In library';
  }

  void add() {
    if (!canAdd) return;
    running = true;
    _cancelled = false;
    progress = null;
    detailProblem = null;
    _acquisition = client.acquire(workspace, details!.reference);
    _updates = _acquisition!.progress.listen(
      (value) {
        if (_disposed) return;
        progress = value;
        if (value.problem != null) detailProblem = value.problem;
        notifyListeners();
      },
      onError: (Object error) {
        if (_disposed || _cancelled) return;
        detailProblem = const ThunderstoreProblem(
          'The package acquisition stopped.',
        );
        notifyListeners();
      },
      onDone: () => unawaited(_finished()),
    );
    notifyListeners();
  }

  Future<void> _finished() async {
    if (_disposed) return;
    running = false;
    if (!_cancelled && progress?.stage != 'complete' && detailProblem == null) {
      detailProblem = const ThunderstoreProblem(
        'The package acquisition stopped.',
      );
    }
    _acquisition = null;
    if (_cancelled)
      detailProblem = const ThunderstoreProblem(
        'Acquisition cancelled. Completed packages remain in the library.',
      );
    final failure = detailProblem;
    final package = selected, version = details?.reference.version;
    if (package != null) await inspect(package, version: version);
    if (_disposed) return;
    detailProblem = _cancelled
        ? const ThunderstoreProblem(
            'Acquisition cancelled. Completed packages remain in the library.',
          )
        : failure ?? detailProblem;
    notifyListeners();
  }

  Future<void> openPage() async {
    final reference = selected;
    if (reference == null) return;
    final failure = await client.openPage(reference);
    if (_disposed || selected?.key != reference.key || failure == null) return;
    detailProblem = failure;
    notifyListeners();
  }

  Future<void> cancel() async {
    _cancelled = true;
    await _acquisition?.cancel();
  }

  @override
  void dispose() {
    _disposed = true;
    _searchTimer?.cancel();
    unawaited(_acquisition?.cancel());
    unawaited(_updates?.cancel());
    model.dispose();
    super.dispose();
  }
}
