import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mc_client/mc_client.dart';

class DeploymentController extends ChangeNotifier {
  DeploymentsClient? client;
  String? profileId;
  String? configuredName;
  bool _available = false, _disposed = false;
  int _epoch = 0, _readEpoch = 0;
  StreamSubscription<DeploymentEvent>? _operation;
  Completer<void>? _done;
  DeploymentState? state;
  PreparedDeployment? prepared;
  DeploymentReceipt? receipt;
  DeploymentProgress? progress;
  String? problem;
  bool reading = false, busy = false, needsRead = false, preparing = false;
  final saved = <SavedDeployment>[];
  int? _before;
  bool _savedLoaded = false, loadingSaved = false;
  bool get canLoadSaved => !_savedLoaded || _before != null;
  VoidCallback? onChanged;
  bool get connected => client != null && profileId != null && _available;
  bool get stale =>
      needsRead ||
      (prepared != null && state?.sourceToken != prepared?.sourceToken);
  bool get canPrepare =>
      connected &&
      !busy &&
      !reading &&
      !needsRead &&
      state != null &&
      state!.pendingReceipt == null;
  bool get canDeploy => canPrepare && prepared != null && !stale;
  String get activeName {
    final active = state?.active;
    if (active == null || active.known && active.profile == null) {
      return 'Not deployed';
    }
    return active.known
        ? 'Active: ${active.profile!.name}'
        : 'Active deployment · profile unavailable';
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void attach(
    DeploymentsClient? api,
    String? id,
    String? name, {
    required bool available,
  }) {
    configuredName = name;
    final newlyAvailable = !_available && available;
    _available = available;
    if (identical(api, client) && id == profileId) {
      if (newlyAvailable && state == null && connected) unawaited(read());
      return;
    }
    ++_epoch;
    unawaited(_operation?.cancel());
    if (!(_done?.isCompleted ?? true)) _done!.complete();
    _operation = null;
    client = api;
    profileId = id;
    state = null;
    prepared = null;
    receipt = null;
    progress = null;
    problem = null;
    busy = preparing = reading = needsRead = false;
    saved.clear();
    _before = null;
    _savedLoaded = false;
    loadingSaved = false;
    if (connected) unawaited(read());
    _notify();
  }

  void invalidate() {
    if (state != null) {
      needsRead = true;
      ++_readEpoch;
      reading = false;
      _notify();
      if (!busy) unawaited(read());
    }
  }

  Future<void> read() async {
    final api = client, id = profileId;
    if (!connected || api == null || id == null || reading || busy) return;
    final epoch = _epoch, readEpoch = ++_readEpoch;
    reading = true;
    problem = null;
    _notify();
    try {
      final value = await api.read(id);
      if (_disposed || (epoch != _epoch || readEpoch != _readEpoch)) return;
      final pending = value.pendingReceipt == null
          ? null
          : await api.receipt(value.pendingReceipt!);
      if (_disposed || epoch != _epoch || readEpoch != _readEpoch) return;
      state = value;
      receipt = pending;
      needsRead = false;
    } on Exception catch (error) {
      if (!_disposed && epoch == _epoch && readEpoch == _readEpoch) {
        needsRead = true;
        problem = _message(error);
      }
    } finally {
      if (!_disposed && epoch == _epoch && readEpoch == _readEpoch) {
        reading = false;
        _notify();
      }
    }
  }

  Future<void> loadSaved({bool reset = false}) async {
    final api = client, id = profileId;
    if (api == null || id == null || loadingSaved) return;
    if (reset) {
      saved.clear();
      _before = null;
      _savedLoaded = false;
    }
    if (!canLoadSaved) return;
    final epoch = _epoch;
    loadingSaved = true;
    _notify();
    try {
      final page = await api.saved(id, before: _before);
      if (!_disposed && epoch == _epoch) {
        saved.addAll(page.entries);
        _before = page.nextBefore;
        _savedLoaded = true;
      }
    } on Exception catch (error) {
      if (!_disposed && epoch == _epoch) problem = _message(error);
    } finally {
      if (!_disposed && epoch == _epoch) {
        loadingSaved = false;
        _notify();
      }
    }
  }

  Future<void> prepare({bool retained = false, String? generationId}) async {
    if (!canPrepare) return;
    prepared = null;
    await _run(
      client!.prepare(
        newOperationId(),
        profileId!,
        state!.sourceToken,
        retained: retained,
        generationId: generationId,
      ),
      isPreparation: true,
    );
  }

  Future<void> activate() async {
    if (!canDeploy) return;
    final value = prepared!;
    await _run(
      client!.activate(value.id, profileId!, value.sourceToken),
      isPreparation: false,
    );
  }

  Future<void> recover({required bool restore}) async {
    final value = receipt, api = client;
    if (value == null || api == null || busy) return;
    await _run(
      api.recover(value.id, value.revision, restore: restore),
      isPreparation: false,
    );
  }

  Future<void> _run(
    Stream<DeploymentEvent> events, {
    required bool isPreparation,
  }) async {
    final epoch = _epoch;
    busy = true;
    preparing = isPreparation;
    problem = null;
    progress = null;
    _notify();
    var finished = false;
    final done = Completer<void>();
    _done = done;
    _operation = events.listen(
      (event) {
        if (_disposed || epoch != _epoch) return;
        switch (event) {
          case DeploymentProgress():
            progress = event;
          case DeploymentPrepared():
            prepared = event.prepared;
            finished = true;
          case DeploymentFinished():
            receipt = event.receipt;
            prepared = null;
            needsRead = true;
            finished = true;
            onChanged?.call();
        }
        _notify();
      },
      cancelOnError: true,
      onError: (Object error) {
        if (!_disposed && epoch == _epoch) {
          problem = _message(error);
          needsRead = true;
        }
        if (!done.isCompleted) done.complete();
      },
      onDone: () {
        if (!_disposed && epoch == _epoch && !finished) {
          problem ??= 'The deployment response did not finish. Read the current deployment.';
          needsRead = true;
        }
        if (!done.isCompleted) done.complete();
      },
    );
    await done.future;
    if (!_disposed && epoch == _epoch) {
      busy = preparing = false;
      _operation = null;
      _done = null;
      _notify();
      if (!isPreparation && finished) await read();
    }
  }

  Future<void> cancelPreparation() async {
    if (!preparing) return;
    await _operation?.cancel();
    _operation = null;
    if (!(_done?.isCompleted ?? true)) _done!.complete();
    prepared = null;
    busy = preparing = false;
    needsRead = true;
    _notify();
    await read();
  }

  String _message(Object error) => error is DeploymentException
      ? error.detail
      : 'The engine response is unavailable. Read the current deployment before continuing.';
  @override
  void dispose() {
    _disposed = true;
    ++_epoch;
    unawaited(_operation?.cancel());
    if (!(_done?.isCompleted ?? true)) _done!.complete();
    super.dispose();
  }
}
