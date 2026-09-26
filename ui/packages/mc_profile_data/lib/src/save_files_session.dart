part of 'save_files.dart';

class _SaveFilesSession extends ChangeNotifier {
  _SaveFilesSession(this.config) : current = config.expected {
    model.addListener(_modelChanged);
    unawaited(read());
  }

  void _modelChanged() => notifyListeners();

  ProfileSaveFiles config;
  final model = McCollectionModel<String, ProfileSaveGroupEntry>(
    idOf: (entry) => entry.id,
    labelOf: (entry) => entry.name,
  );
  ProfileSaveSource source = ProfileSaveSource.profile;
  ProfileSavePath? path;
  ProfileSaveInspection? inspection;
  ProfileDataRef? current;
  StreamSubscription<ProfileDataEvent>? action;
  Completer<void>? actionDone;
  String? next, problem;
  bool busy = false;
  int request = 0;
  bool _disposed = false;

  String _describe(Object error, String fallback) => error is ProfileDataProblem
      ? error.detail
      : error is FormatException
      ? error.message
      : fallback;

  Future<void> read({bool more = false}) async {
    if (busy) return;
    final epoch = ++request;
    busy = true;
    problem = null;
    if (!more) inspection = null;
    notifyListeners();
    try {
      final page = await config.client.saveGroups(
        config.workspace,
        config.profile.id,
        source,
        after: more ? next : null,
      );
      if (_disposed || epoch != request) return;
      if (!more) model.clear();
      model.apply(upserts: page.entries);
      path = page.path;
      next = page.next;
    } on Exception catch (error) {
      if (!_disposed && epoch == request) {
        problem = _describe(error, 'The save groups could not be read.');
      }
    } finally {
      if (!_disposed && epoch == request) {
        busy = false;
        notifyListeners();
      }
    }
  }

  void chooseSource(ProfileSaveSource value) {
    if (busy || value == source) return;
    source = value;
    model.clear();
    path = null;
    next = null;
    inspection = null;
    unawaited(read());
  }

  Future<void> inspect(ProfileSaveGroupEntry entry) async {
    inspection = null;
    problem = null;
    if (entry.kind != ProfileSaveEntryKind.save) {
      notifyListeners();
      return;
    }
    final epoch = ++request;
    busy = true;
    notifyListeners();
    try {
      final value = await config.client.inspectSave(
        config.workspace,
        config.profile.id,
        source,
        entry.name,
        headersId: config.headersId,
      );
      if (!_disposed && epoch == request) inspection = value;
    } on Exception catch (error) {
      if (!_disposed && epoch == request) {
        problem = _describe(error, 'The save could not be inspected.');
      }
    } finally {
      if (!_disposed && epoch == request) {
        busy = false;
        notifyListeners();
      }
    }
  }

  List<String> get selected {
    if (model.selectedIds.isEmpty ||
        model.selectedIds.any((id) => model[id]?.actionable != true)) {
      return const [];
    }
    return model.selectedIds.toList(growable: false);
  }

  Future<ProfileSaveActionPreview?> preview() async {
    final names = selected;
    if (busy || names.isEmpty || current == null) return null;
    final kind = source == ProfileSaveSource.global
        ? ProfileSaveAction.copyToProfile
        : ProfileSaveAction.deleteFromProfile;
    busy = true;
    problem = null;
    notifyListeners();
    try {
      return await config.client.previewSaveAction(current!, kind, names);
    } on Exception catch (error) {
      if (!_disposed) {
        problem = _describe(error, 'The save action could not be previewed.');
      }
      return null;
    } finally {
      if (!_disposed) {
        busy = false;
        notifyListeners();
      }
    }
  }

  Future<void> apply(ProfileSaveActionPreview preview) async {
    final done = Completer<void>();
    actionDone = done;
    busy = true;
    problem = null;
    notifyListeners();
    var received = false;
    void finish() {
      if (!done.isCompleted) done.complete();
    }

    action = config.client
        .applySaveAction(newOperationId(), preview.id, preview.expected)
        .listen(
          (event) {
            if (_disposed) return;
            if (event case ProfileDataResult()) {
              received = true;
              current = event.state.reference;
              problem = event.problem;
            }
            notifyListeners();
          },
          onError: (Object error) {
            if (!_disposed) {
              problem = _describe(
                error,
                'The save action could not be completed.',
              );
            }
            finish();
          },
          onDone: finish,
          cancelOnError: true,
        );
    if (!_disposed) notifyListeners();
    await done.future;
    action = null;
    actionDone = null;
    if (_disposed) return;
    if (!received && problem == null) {
      problem =
          'The action result is unavailable. Read again before continuing.';
    }
    config.onChanged();
    busy = false;
    notifyListeners();
    if (received && problem == null) await read();
  }

  Future<void> cancel() async {
    ++request;
    config.onChanged();
    await action?.cancel();
    action = null;
    if (actionDone case final done? when !done.isCompleted) done.complete();
    if (_disposed) return;
    busy = false;
    problem = 'The action was cancelled. Read again before continuing.';
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    ++request;
    unawaited(action?.cancel());
    if (actionDone case final done? when !done.isCompleted) done.complete();
    model.removeListener(_modelChanged);
    model.dispose();
    super.dispose();
  }
}
