import 'package:mc_client/mc_client.dart';

String executableRunLabel(ExecutableRun? run) => run == null
    ? 'Not run'
    : switch (run.phase) {
        ExecutableRunPhase.starting => 'Starting…',
        ExecutableRunPhase.running => 'Running',
        ExecutableRunPhase.waitingForChildren => 'Waiting for children',
        ExecutableRunPhase.finished =>
          run.rootExitCode != null && run.rootExitCode != 0
              ? 'Exit ${run.rootExitCode}'
              : 'Closed',
        ExecutableRunPhase.failed => 'Could not start',
        ExecutableRunPhase.cancelled => 'Canceled',
        ExecutableRunPhase.detached => 'Stopped waiting',
        ExecutableRunPhase.trackingUnavailable => 'Tracking unavailable',
      };
