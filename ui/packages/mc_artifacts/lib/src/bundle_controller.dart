import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mc_client/mc_client.dart';

class BundleController extends ChangeNotifier {
  BundleController(this.client, this.installations, this.artifact);
  final BundlesClient client;
  final InstallationsClient installations;
  final Artifact artifact;
  BundlePlan? bundle;
  BundleDiscovery? discovery;
  BundleItem? nested;
  InstallationDraft? prepared;
  InstallationStatus? status;
  bool busy = false, _disposed = false;
  String? problem;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<bool> run(Future<void> Function() action) async {
    if (busy || _disposed) return false;
    busy = true;
    problem = null;
    _notify();
    try {
      await action();
      return !_disposed;
    } on Exception catch (e) {
      problem = e is ArtifactProblem
          ? e.detail
          : 'The bundle operation failed.';
      // Preparation can leave a failed source or stopped installation behind.
      final current = bundle;
      if (current != null && !_disposed) {
        try {
          bundle = await client.read(current.reference);
        } on Exception {
          /* Keep the primary operation error. */
        }
      }
      return false;
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> open() => run(() async {
    bundle = await client.find(artifact.workspaceId, artifact.id);
    if (bundle == null) discovery = await client.discover(artifact);
    if (_disposed) _closeDraft(discovery?.draft);
  });
  Future<void> select(List<int> entries) => run(() async {
    final source = discovery!;
    bundle = nested == null
        ? await client.create(source.draft, entries)
        : await client.chooseNested(
            bundle!.reference,
            nested!.id,
            source.draft,
            entries,
          );
    discovery = null;
    nested = null;
  });
  Future<void> configure(BundleItem item, {bool contained = false}) => run(
    () async {
      if (item.attemptId != null && item.state != BundleItemState.needsReview) {
        status = await client.status(bundle!.reference, item.id);
        return;
      }
      final value = await client.configure(bundle!.reference, item.id);
      bundle = value.bundle;
      if (_disposed) {
        _closeDraft(value.prepared.draft);
        return;
      }
      final source = value.prepared;
      if (contained ||
          (!source.draft.canInstall &&
              source.draft.installer == InstallationMode.manual &&
              source.archives.isNotEmpty)) {
        discovery = source;
        nested = item;
      } else {
        prepared = source.draft;
      }
    },
  );
  Future<void> back() => run(() async {
    _closeDraft(discovery?.draft);
    discovery = null;
    nested = null;
    prepared = null;
    status = null;
    if (bundle != null) bundle = await client.read(bundle!.reference);
  });
  Future<void> rename(BundleItem item, String name) => run(() async {
    bundle = await client.rename(bundle!.reference, item.id, name);
  });
  Future<void> move(BundleItem item, bool earlier) => run(() async {
    bundle = await client.move(bundle!.reference, item.id, earlier);
  });
  Future<bool> retry(BundleItem item) => run(() async {
    bundle = await client.retry(bundle!.reference, item.id);
  });
  Future<bool> delete() => run(() async {
    await client.delete(bundle!.reference);
  });
  void _closeDraft(InstallationDraft? d) {
    if (d != null)
      unawaited(installations.closeDraft(d).onError<Exception>((_, _) {}));
  }

  @override
  void dispose() {
    _disposed = true;
    _closeDraft(discovery?.draft);
    super.dispose();
  }
}
