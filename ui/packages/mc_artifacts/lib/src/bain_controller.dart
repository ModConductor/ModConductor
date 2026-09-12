import 'package:flutter/foundation.dart';
import 'package:mc_client/mc_client.dart';

class BainController extends ChangeNotifier {
  BainController(this.client, InstallationDraft draft)
    : _initial = draft.reference;
  final BainClient client;
  final InstallationDraftReference _initial;
  BainChoices? value;
  String? problem;
  bool busy = false, _disposed = false;
  InstallationDraftReference get reference => value?.reference ?? _initial;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _run(Future<BainChoices> Function() action) async {
    if (busy || _disposed) return;
    busy = true;
    problem = null;
    _notify();
    try {
      final next = await action();
      if (!_disposed) value = next;
    } on Exception catch (error) {
      if (!_disposed)
        problem = error is ArtifactProblem
            ? error.detail
            : 'The package operation failed.';
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> open() => _run(() => client.open(reference));
  Future<void> choose(BainPackage package, bool selected) =>
      _run(() => client.choose(reference, package.index, selected));
  Future<void> chooseAll(bool selected) =>
      _run(() => client.chooseAll(reference, selected));
  Future<void> include(InstallationReviewedFile file, bool included) =>
      _run(() => client.include(reference, file.destination, included));
  Future<void> review() => _run(() => client.review(reference));
  Future<void> back() => _run(() => client.back(reference));
  Future<InstallationDraft?> useInstaller(InstallationMode mode) async {
    if (busy || _disposed) return null;
    busy = true;
    problem = null;
    _notify();
    try {
      return await client.useInstaller(reference, mode);
    } on Exception catch (error) {
      if (!_disposed)
        problem = error is ArtifactProblem
            ? error.detail
            : 'The installer could not be changed.';
      return null;
    } finally {
      busy = false;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
