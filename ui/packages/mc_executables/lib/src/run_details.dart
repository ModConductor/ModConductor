import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'run_presentation.dart';

Widget runDetail(BuildContext context, String label, String value) => Padding(
  padding: const EdgeInsets.only(bottom: 16),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: 4),
      SelectableText(value),
    ],
  ),
);
void showExecutableRunDetails(BuildContext context, ExecutableRun run) =>
    showDialog<void>(
      context: context,
      builder: (context) => McDialog(
        title: '${run.name} run',
        children: [
          McStatus(title: executableRunLabel(run), detail: run.problem),
          const SizedBox(height: 16),
          runDetail(
            context,
            run.game?.files != null
                ? 'Files at start'
                : 'Configured profile at start',
            run.profileName ?? 'No profile',
          ),
          if (run.game?.files case final files?) ...[
            runDetail(context, 'Saved deployment', files.generationId),
            runDetail(context, 'File plan', files.fingerprint),
          ],
          runDetail(context, 'Requested', run.requestedAt.toLocal().toString()),
          runDetail(
            context,
            'Root process',
            run.rootExitCode != null
                ? 'Exited ${run.rootExitCode}'
                : run.processId != null
                ? 'Last observed PID ${run.processId}'
                : 'Not observed',
          ),
          runDetail(
            context,
            'Observed process count',
            run.observedProcessCount?.toString() ?? 'Unknown',
          ),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('Saved launch'),
            children: [
              runDetail(context, 'Executable', run.executable),
              runDetail(context, 'Working directory', run.workingDirectory),
              for (var i = 0; i < run.arguments.length; i++)
                runDetail(
                  context,
                  'Argument ${i + 1}',
                  run.arguments[i].isEmpty ? '(empty)' : run.arguments[i],
                ),
              for (final row in run.environment)
                runDetail(
                  context,
                  row.name,
                  row.value ?? 'Remove child variable',
                ),
            ],
          ),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('Tracking scope'),
            children: [
              Text(
                run.scope == null
                    ? 'Tracking did not start.'
                    : run.scope!.contains('job')
                    ? 'This run observes its Windows job. Processes outside that job are not tracked.'
                    : 'This run observes its native process group. Processes that leave the group are not tracked.',
              ),
              const SizedBox(height: 12),
              const Text(
                'Stopping waiting or closing Mod Conductor does not stop the tool or remove deployed files.',
              ),
              const SizedBox(height: 12),
              const Text('Interactive terminal programs are not supported.'),
              const SizedBox(height: 12),
            ],
          ),
        ],
      ),
    );
