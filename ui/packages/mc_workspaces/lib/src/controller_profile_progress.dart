part of 'controller.dart';

class _ProfileChangeProgress {
  _ProfileChangeProgress(this._notify);

  final VoidCallback _notify;
  StreamSubscription<ProfileChangeEvent>? _subscription;
  Completer<ProfileChange>? _result;
  ProfileCopyProgress? copyProgress;
  bool get canCancel => _subscription != null;

  Future<ProfileChange> observe(
    Stream<ProfileChangeEvent> events, {
    required bool Function() active,
  }) {
    final done = Completer<ProfileChange>();
    _result = done;
    copyProgress = null;
    _subscription = events.listen(
      (event) {
        if (!active()) return;
        switch (event) {
          case ProfileCopyProgress():
            copyProgress = event;
            _notify();
          case ProfileChangeComplete():
            if (!done.isCompleted) done.complete(event.change);
        }
      },
      onError: (Object error) {
        if (!done.isCompleted) done.completeError(error);
      },
      onDone: () {
        if (!done.isCompleted) {
          done.completeError(
            const WorkspaceException(
              WorkspaceFault.profileData,
              'The profile action did not return a result. Read Settings and saves to continue.',
            ),
          );
        }
      },
    );
    return done.future.whenComplete(() {
      if (identical(_result, done)) {
        _subscription = null;
        _result = null;
        copyProgress = null;
      }
    });
  }

  Future<void> cancel() async {
    final pending = _result;
    final subscription = _subscription;
    await subscription?.cancel();
    if (pending != null && !pending.isCompleted) {
      pending.completeError(
        const WorkspaceException(
          WorkspaceFault.profileData,
          'The profile action was cancelled. Read Settings and saves to see any remaining action.',
        ),
      );
    }
  }
}
