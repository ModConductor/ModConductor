import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

import 'run_presentation.dart';

void showExecutableRunDetails(BuildContext context, ExecutableRun run) =>
    showDialog<void>(
      context: context,
      builder: (context) => McDialog(
        title: '${run.name} run',
        children: [
          McStatus(title: executableRunLabel(run), detail: run.problem),
          const SizedBox(height: 16),
          McFactGroup(
            title: 'Run',
            rows: [
              McFact(
                run.game?.files != null
                    ? 'Files at start'
                    : 'Configured profile at start',
                run.profileName ?? 'No profile',
              ),
              if (run.game?.files case final files?) ...[
                McFact('Saved deployment', files.generationId),
                McFact('File plan', files.fingerprint),
              ],
              McFact('Requested', run.requestedAt.toLocal().toString()),
              McFact(
                'Root process',
                run.rootExitCode != null
                    ? 'Exited ${run.rootExitCode}'
                    : run.processId != null
                    ? 'Last observed PID ${run.processId}'
                    : 'Not observed',
              ),
              McFact(
                'Observed process count',
                run.observedProcessCount?.toString() ?? 'Unknown',
              ),
            ],
          ),
          const SizedBox(height: 16),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('Saved launch'),
            children: [
              McFactGroup(
                title: 'Command',
                rows: [
                  McFact('Executable', run.executable, path: true),
                  McFact('Working directory', run.workingDirectory, path: true),
                  for (var index = 0; index < run.arguments.length; index++)
                    McFact(
                      'Argument ${index + 1}',
                      run.arguments[index].isEmpty
                          ? '(empty)'
                          : run.arguments[index],
                    ),
                  for (final row in run.environment)
                    McFact(row.name, row.value ?? 'Remove child variable'),
                ],
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
