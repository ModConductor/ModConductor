part of 'controller.dart';

class _ExecutableRuns {
  _ExecutableRuns(this.owner);
  final ExecutablesController owner;
  final latest = <String, ExecutableRun>{};
  final history = <ExecutableRun>[];
  ExecutableRunRequest? pendingLaunch;
  String? pendingStop;
  bool readingHistory = false, _historyLoaded = false;
  String? _historyNext;
  StreamSubscription<ExecutableRun>? _watch;
  String? _watchId;
  bool get hasMoreHistory => !_historyLoaded || _historyNext != null;

  void reset() {
    unawaited(_watch?.cancel());
    _watch = null;
    _watchId = null;
    latest.clear();
    history.clear();
    pendingLaunch = null;
    pendingStop = null;
    readingHistory = _historyLoaded = false;
    _historyNext = null;
  }

  void dispose() => unawaited(_watch?.cancel());

  void applyRun(ExecutableRun value) {
    if (value.preset == null) return;
    final previous = latest[value.preset!.id];
    if (previous == null ||
        (previous.id == value.id && value.revision >= previous.revision) ||
        (previous.id != value.id &&
            value.requestedAt.isAfter(previous.requestedAt))) {
      latest[value.preset!.id] = value;
    }
    final index = history.indexWhere((row) => row.id == value.id);
    if (index >= 0 && value.revision >= history[index].revision) {
      history[index] = value;
    }
  }

  void observeSelected() {
    final run = owner.selectedRun, api = owner.client;
    if (run == null || run.terminal || api == null) {
      unawaited(_watch?.cancel());
      _watch = null;
      _watchId = null;
      return;
    }
    if (_watchId == run.id) return;
    unawaited(_watch?.cancel());
    _watchId = run.id;
    final epoch = owner._epoch, id = run.id;
    _watch = api
        .observe(run.workspaceId, id)
        .listen(
          (value) {
            if (epoch != owner._epoch || _watchId != id) return;
            applyRun(value);
            owner._notify();
          },
          onError: (Object error) {
            if (epoch != owner._epoch || _watchId != id) return;
            unawaited(_watch?.cancel());
            _watch = null;
            _watchId = null;
            owner.needsRead = true;
            owner.problem =
                'The run status is unavailable. Read it again to reconnect.';
            owner._notify();
          },
          onDone: () {
            if (epoch == owner._epoch && _watchId == id) {
              _watch = null;
              _watchId = null;
              if (owner.selectedRun?.terminal == false) {
                owner.needsRead = true;
                owner.problem = "The run status ended before completion was confirmed. Read it again.";
                owner._notify();
              }
            }
          },
        );
  }

  Future<void> run() async {
    final tool = owner.selected, ws = owner.workspace;
    if (tool == null || ws == null || !owner.canChange || owner.uncertain) {
      return;
    }
    final request = ExecutableRunRequest(
      id: newOperationId(),
      workspaceId: ws.id,
      workspaceRevision: ws.revision,
      presetId: tool.id,
      presetRevision: tool.revision,
    );
    pendingLaunch = request;
    await continueLaunch();
  }

  Future<void> continueLaunch() async {
    final request = pendingLaunch, api = owner.client;
    if (request == null || api == null || !owner.connected || owner.changing) {
      return;
    }
    final epoch = owner._epoch;
    owner.changing = true;
    owner.problem = null;
    owner._notify();
    try {
      final value = await api.begin(request);
      if (epoch != owner._epoch) return;
      applyRun(value);
      pendingLaunch = null;
      owner.needsRead = false;
      _historyLoaded = false;
      observeSelected();
    } on ExecutableException catch (error) {
      if (epoch == owner._epoch) {
        pendingLaunch = null;
        owner.needsRead = error.failure == ExecutableFailure.staleRevision;
        owner.problem = error.detail;
      }
    } on Object {
      if (epoch == owner._epoch) {
        owner.needsRead = true;
        owner.problem = 'The launch result is unknown. Read the result before starting another run.';
      }
    } finally {
      if (epoch == owner._epoch) {
        owner.changing = false;
        owner._notify();
      }
    }
  }

  Future<void> stopWaiting() async {
    final run = owner.selectedRun, api = owner.client;
    if (run == null ||
        run.terminal ||
        api == null ||
        !owner.connected ||
        owner.changing ||
        owner.uncertain) {
      return;
    }
    final epoch = owner._epoch;
    owner.changing = true;
    pendingStop = run.id;
    owner.problem = null;
    owner._notify();
    try {
      final value = await api.stopWaiting(run.workspaceId, run.id);
      if (epoch != owner._epoch) return;
      applyRun(value);
      pendingStop = null;
      owner.needsRead = false;
      observeSelected();
    } on Object {
      if (epoch == owner._epoch) {
        owner.needsRead = true;
        owner.problem =
            'The stop-waiting result is unknown. Read the run status.';
      }
    } finally {
      if (epoch == owner._epoch) {
        owner.changing = false;
        owner._notify();
      }
    }
  }

  Future<void> readRun() async {
    final id = pendingLaunch?.id ?? pendingStop ?? owner.selectedRun?.id,
        api = owner.client,
        ws = owner.workspace?.id;
    if (id == null ||
        api == null ||
        ws == null ||
        !owner.connected ||
        owner.changing) {
      return;
    }
    final epoch = owner._epoch;
    owner.changing = true;
    owner.problem = null;
    owner._notify();
    try {
      final value = await api.read(ws, id);
      if (epoch != owner._epoch) return;
      applyRun(value);
      pendingLaunch = null;
      pendingStop = null;
      owner.needsRead = false;
      observeSelected();
    } on ExecutableException catch (error) {
      if (epoch == owner._epoch) {
        owner.problem =
            error.failure == ExecutableFailure.notFound && pendingLaunch != null
            ? 'The launch is not recorded. Continue uses the same request.'
            : error.detail;
        owner.needsRead = true;
      }
    } on Object {
      if (epoch == owner._epoch) {
        owner.problem = 'The run status is unavailable.';
        owner.needsRead = true;
      }
    } finally {
      if (epoch == owner._epoch) {
        owner.changing = false;
        owner._notify();
      }
    }
  }

  Future<void> loadHistory() async {
    final api = owner.client, id = owner.workspace?.id;
    if (!owner.canLoadHistory || api == null || id == null) return;
    final epoch = owner._epoch;
    readingHistory = true;
    owner._notify();
    try {
      final page = await api.recent(
        id,
        after: _historyLoaded ? _historyNext : null,
      );
      if (epoch != owner._epoch) return;
      if (!_historyLoaded) history.clear();
      for (final run in page.runs) {
        if (!history.any((v) => v.id == run.id)) {
          history.add(run);
        }
      }
      _historyNext = page.next;
      _historyLoaded = true;
    } on Object catch (error) {
      if (epoch == owner._epoch) {
        owner.problem = ExecutablesController.errorMessage(error);
      }
    } finally {
      if (epoch == owner._epoch) {
        readingHistory = false;
        owner._notify();
      }
    }
  }
}
