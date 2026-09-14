import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'game_play_controller.dart';
import 'run_details.dart';

class GamePlayActions extends StatelessWidget {
  const GamePlayActions({super.key, required this.controller});
  final GamePlayController controller;
  void details(BuildContext context) => showDialog<void>(
    context: context,
    builder: (_) => GamePlayDialog(controller: controller),
  );
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => Wrap(
      spacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        McAction(
          label: 'Play',
          icon: Icons.play_arrow,
          emphasis: McActionEmphasis.primary,
          onPressed: controller.canPlay
              ? () {
                  unawaited(controller.play());
                  details(context);
                }
              : null,
        ),
        McIconMenu<String>(
          label: 'Game launch options',
          enabled: controller.connected,
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'details', child: Text('Run details')),
            if (controller.uncertain)
              const PopupMenuItem(value: 'read', child: Text('Read result')),
          ],
          onSelected: (value) {
            if (value == 'read') unawaited(controller.readResult());
            details(context);
          },
        ),
      ],
    ),
  );
}

class GamePlayDialog extends StatelessWidget {
  const GamePlayDialog({super.key, required this.controller});
  final GamePlayController controller;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final c = controller, run = c.run, game = run?.game;
      final preparing = c.starting || c.preparing;
      final name = preparing
          ? c.state?.name ?? 'game'
          : run?.name ?? c.state?.name ?? 'Game';
      final profile =
          run?.profileName ??
          c.workspace?.selectedProfile?.name ??
          'selected profile';
      final String title;
      String? detail;
      if (c.problem != null) {
        title = c.problem!;
      } else if (c.starting) {
        title = 'Starting $name…';
      } else if (run == null) {
        title = 'Not run';
      } else {
        title = switch (run.phase) {
          ExecutableRunPhase.starting =>
            game?.preparation == GamePreparationPhase.profileData
                ? 'Applying $profile…'
                : game?.preparation == GamePreparationPhase.applying
                ? 'Applying $profile…'
                : 'Preparing $profile…',
          ExecutableRunPhase.running => 'Running',
          ExecutableRunPhase.waitingForChildren =>
            'Waiting for child processes',
          ExecutableRunPhase.finished => 'Finished',
          ExecutableRunPhase.failed => '$name did not start',
          ExecutableRunPhase.cancelled => '$name launch was canceled',
          ExecutableRunPhase.detached => 'Stopped waiting',
          ExecutableRunPhase.trackingUnavailable => 'Tracking unavailable',
        };
        detail = switch (run.phase) {
          ExecutableRunPhase.starting =>
            game != null && game.total > 0
                ? '${game.completed} of ${game.total} ${game.preparation == GamePreparationPhase.applying ? 'paths applied' : 'files checked'}.'
                : null,
          ExecutableRunPhase.running =>
            'Requested ${TimeOfDay.fromDateTime(run.requestedAt.toLocal()).format(context)} · $profile',
          ExecutableRunPhase.waitingForChildren =>
            'Root exited ${run.rootExitCode}. ${run.observedProcessCount?.toString() ?? 'Unknown number of'} observed processes remain.',
          ExecutableRunPhase.finished =>
            'Root exit code ${run.rootExitCode ?? 'unknown'}.',
          ExecutableRunPhase.failed => run.problem,
          ExecutableRunPhase.cancelled => run.problem,
          ExecutableRunPhase.detached => 'The game can still be running.',
          ExecutableRunPhase.trackingUnavailable =>
            '${run.problem ?? 'The app no longer tracks this run.'} The game can still be active.',
        };
        if (game?.files != null &&
            [
              ExecutableRunPhase.failed,
              ExecutableRunPhase.cancelled,
              ExecutableRunPhase.detached,
            ].contains(run.phase)) {
          detail = '${detail ?? ''} $profile remains deployed.';
        }
      }
      return McDialog(
        title: preparing ? 'Starting $name' : '$name run',
        actions: [
          McAction(label: 'Close', onPressed: () => Navigator.pop(context)),
          if (c.uncertain)
            McAction(
              label: 'Read result',
              onPressed: c.changing ? null : () => unawaited(c.readResult()),
            )
          else if (c.active)
            McAction(
              label: c.preparing ? 'Cancel' : 'Stop waiting',
              icon: c.preparing ? null : Icons.link_off,
              onPressed: c.changing ? null : () => unawaited(c.stop()),
            )
          else if (run != null || c.problem != null)
            McAction(
              label: 'Play',
              icon: Icons.play_arrow,
              emphasis: McActionEmphasis.primary,
              onPressed: c.canPlay ? () => unawaited(c.play()) : null,
            ),
        ],
        children: [
          McStatus(
            title: title,
            detail: detail,
            tone: c.problem != null || run?.phase == ExecutableRunPhase.failed
                ? McStatusTone.error
                : McStatusTone.neutral,
          ),
          if (preparing) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: !c.starting && game != null && game.total > 0
                  ? game.completed / game.total
                  : null,
            ),
          ],
          if (game != null && !preparing) ...[
            const SizedBox(height: 16),
            runDetail(context, 'Game folder', game.gameDirectory),
            runDetail(context, 'Runtime', game.runtime),
            McAction(
              label: 'Run details',
              onPressed: () => showExecutableRunDetails(context, run!),
            ),
          ],
        ],
      );
    },
  );
}
