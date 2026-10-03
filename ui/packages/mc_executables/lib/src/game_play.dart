import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'game_play_controller.dart';
import 'run_details.dart';

class GamePlayActions extends StatelessWidget {
  const GamePlayActions({
    super.key,
    required this.controller,
    this.additionalMenuItems = const [],
  });
  final GamePlayController controller;
  final List<PopupMenuEntry<VoidCallback>> additionalMenuItems;
  void details(BuildContext context) => showDialog<void>(
    context: context,
    builder: (_) => GamePlayDialog(controller: controller),
  );
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => McSplitAction<VoidCallback>(
      label: controller.workspace?.selectedProfile == null
          ? 'Play'
          : 'Play · ${controller.workspace!.selectedProfile!.name}',
      icon: Icons.play_arrow,
      onPressed: controller.canPlay
          ? () {
              unawaited(controller.play());
              details(context);
            }
          : null,
      menuLabel: 'Play options',
      menuEnabled:
          controller.connected ||
          additionalMenuItems.any(
            (item) => item is PopupMenuItem<VoidCallback> && item.enabled,
          ),
      itemBuilder: (_) => [
        ...additionalMenuItems,
        if (additionalMenuItems.isNotEmpty) const PopupMenuDivider(),
        PopupMenuItem(
          enabled: controller.connected,
          value: () => details(context),
          child: const McIconLabel(
            icon: Icon(Icons.info_outline, size: 18),
            label: 'Run details',
          ),
        ),
        if (controller.uncertain)
          PopupMenuItem(
            enabled: controller.connected,
            value: () {
              unawaited(controller.readResult());
              details(context);
            },
            child: const McIconLabel(
              icon: Icon(Icons.refresh, size: 18),
              label: 'Read result',
            ),
          ),
      ],
      onSelected: (action) => action(),
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
            ),
          if (!c.active &&
              c.state?.fnisStale == true &&
              c.state?.canRunFnis == true)
            McAction(
              label: 'Run FNIS',
              icon: Icons.play_arrow,
              emphasis: McActionEmphasis.primary,
              onPressed: c.changing ? null : () => unawaited(c.runFnis()),
            ),
          if (!c.active && c.state?.fnisStale == true)
            McAction(
              label: 'Continue without FNIS',
              onPressed: c.canPlay
                  ? () => unawaited(c.play(continueStaleFnis: true))
                  : null,
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
            McFactGroup(
              title: 'Launch',
              rows: [
                McFact('Game folder', game.gameDirectory, path: true),
                McFact('Runtime', game.runtime),
              ],
            ),
            const SizedBox(height: 16),
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
