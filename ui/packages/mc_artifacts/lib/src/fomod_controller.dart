import 'package:flutter/foundation.dart';
import 'package:mc_client/mc_client.dart';

class FomodController extends ChangeNotifier {
  FomodController(this.client, InstallationDraft draft)
    : _initial = InstallationDraftReference(
        draft.workspaceId,
        draft.id,
        draft.revision,
      );
  final FomodClient client;
  final InstallationDraftReference _initial;
  FomodChoices? value;
  String? problem;
  bool busy = false, _disposed = false;
  InstallationDraftReference get reference => value?.reference ?? _initial;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  String _message(Object error) => error is ArtifactProblem
      ? error.detail
      : 'The installer operation failed.';
  Future<void> _run(Future<FomodChoices> Function() action) async {
    if (busy || _disposed) return;
    busy = true;
    problem = null;
    _notify();
    try {
      final next = await action();
      if (!_disposed) value = next;
    } on Exception catch (error) {
      if (!_disposed) problem = _message(error);
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> open(String? profileId) async {
    if (profileId == null) {
      problem = 'Select a profile or use the manual layout.';
      _notify();
      return;
    }
    await _run(() => client.open(reference, profileId));
  }

  Future<void> choose(FomodOption option, bool selected) =>
      _run(() => client.choose(reference, option.id, selected));
  Future<void> next() => _run(() => client.next(reference));
  Future<void> back() => _run(() => client.back(reference));
  Future<InstallationDraft?> manual() => _leave(() => client.manual(reference));
  Future<InstallationDraft?> packages(BainClient packages) =>
      _leave(() => packages.useInstaller(reference, InstallationMode.bain));
  Future<InstallationDraft?> _leave(
    Future<InstallationDraft> Function() action,
  ) async {
    if (busy || _disposed) return null;
    busy = true;
    problem = null;
    _notify();
    try {
      return await action();
    } on Exception catch (error) {
      if (!_disposed) problem = _message(error);
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
