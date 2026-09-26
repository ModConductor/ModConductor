part of 'controller.dart';

sealed class _ProfileChangeOutcome {
  const _ProfileChangeOutcome();
}

final class _ProfileChangeDone extends _ProfileChangeOutcome {
  const _ProfileChangeDone(this.change);
  final ProfileChange change;
}

final class _ProfileChangeProblem extends _ProfileChangeOutcome {
  const _ProfileChangeProblem(this.detail);
  final String detail;
}

Future<_ProfileChangeOutcome> _completedProfileChange(
  Future<ProfileChange> action,
) async => _ProfileChangeDone(await action);

class _ProfileChangeProgress {
  _ProfileChangeProgress(this._notify);

  final VoidCallback _notify;
  StreamSubscription<ProfileChangeEvent>? _subscription;
  Completer<_ProfileChangeOutcome>? _result;
  ProfileCopyProgress? copyProgress;
  bool get canCancel => _subscription != null;

  Future<_ProfileChangeOutcome> observe(
    Stream<ProfileChangeEvent> events, {
    required bool Function() active,
  }) {
    final done = Completer<_ProfileChangeOutcome>();
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
            if (!done.isCompleted) {
              done.complete(_ProfileChangeDone(event.change));
            }
        }
      },
      onError: (Object error) {
        if (!done.isCompleted) done.completeError(error);
      },
      onDone: () {
        if (!done.isCompleted) {
          done.complete(
            const _ProfileChangeProblem(
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
      pending.complete(
        const _ProfileChangeProblem(
          'The profile action was cancelled. Read Settings and saves to see any remaining action.',
        ),
      );
    }
  }
}
