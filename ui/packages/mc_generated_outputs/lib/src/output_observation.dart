part of 'output_controller.dart';

extension _OutputObservation on OutputController {
  Future<void> _readScope({String? contextId}) async {
    if (reading) return _read?.future;
    final api = client, workspace = workspaceId, profile = profileId;
    if (!connected ||
        api == null ||
        workspace == null ||
        profile == null ||
        reading ||
        changing) {
      return;
    }
    final epoch = _epoch, readEpoch = _readEpoch;
    final done = Completer<void>();
    _read = done;
    reading = true;
    problem = null;
    _notify();
    try {
      final value = await api.read(workspace, profile, contextId: contextId);
      if (_disposed || epoch != _epoch || readEpoch != _readEpoch) return;
      if (scope?.reference.contextId != value.reference.contextId ||
          scope?.reference.revision != value.reference.revision ||
          scope?.reference.contextRevision != value.reference.contextRevision) {
        snapshot = null;
        inspected = null;
        tools.attach(api, null);
        writable.attach(api, null);
      }
      scope = value;
      needsRead = false;
    } on Exception catch (error) {
      if (!_disposed && epoch == _epoch && readEpoch == _readEpoch) {
        problem = _message(error);
        needsRead = true;
      }
    } finally {
      if (!done.isCompleted) done.complete();
      if (!_disposed && epoch == _epoch) {
        _read = null;
        reading = false;
        _notify();
      }
    }
  }

  Future<void> _refreshObservation() async {
    if (!connected || changing || loading) return;
    final epoch = _epoch;
    await read(contextId: scope?.reference.contextId);
    final api = client, reference = scope?.reference;
    if (api == null ||
        reference == null ||
        needsRead ||
        _disposed ||
        epoch != _epoch) {
      return;
    }
    final observationEpoch = ++_observationEpoch;
    loading = true;
    problem = null;
    progress = null;
    _notify();
    final done = Completer<void>();
    _observed = done;
    var finished = false;
    _observation = api
        .observe(reference)
        .listen(
          (event) {
            if (_disposed ||
                epoch != _epoch ||
                observationEpoch != _observationEpoch) {
              return;
            }
            switch (event) {
              case OutputLoadProgress():
                progress = event;
              case OutputsObserved():
                finished = true;
                snapshot = event.snapshot;
                scope = event.snapshot.scope;
                inspected = null;
                tools.attach(api, snapshot);
                writable.attach(api, snapshot);
            }
            _notify();
          },
          cancelOnError: true,
          onError: (Object error) {
            if (!_disposed &&
                epoch == _epoch &&
                observationEpoch == _observationEpoch) {
              problem = _message(error);
              needsRead = true;
            }
            if (!done.isCompleted) done.complete();
          },
          onDone: () {
            if (!_disposed &&
                epoch == _epoch &&
                observationEpoch == _observationEpoch &&
                !finished &&
                problem == null) {
              problem = 'The output observation did not finish.';
            }
            if (!done.isCompleted) done.complete();
          },
        );
    await done.future;
    if (!_disposed &&
        epoch == _epoch &&
        observationEpoch == _observationEpoch) {
      loading = false;
      _observation = null;
      _observed = null;
      _notify();
    }
  }

  Future<void> _cancelObservation() async {
    ++_observationEpoch;
    final old = _observation;
    _observation = null;
    if (!(_observed?.isCompleted ?? true)) _observed!.complete();
    loading = false;
    progress = null;
    _notify();
    await old?.cancel();
  }
}
