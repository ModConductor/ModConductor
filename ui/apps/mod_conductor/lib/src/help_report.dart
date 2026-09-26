part of 'app.dart';

Future<void> _exportSupportReport(
  BuildContext context,
  DiagnosticsController controller,
) async {
  final opener = FocusManager.instance.primaryFocus;
  final save = await showDialog<bool>(
    context: context,
    builder: (context) => McDialog(
      title: 'Export support report?',
      actions: [
        McAction(
          label: 'Cancel',
          onPressed: () => Navigator.pop(context, false),
        ),
        McAction(
          label: 'Choose save location',
          emphasis: McActionEmphasis.primary,
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
      children: const [
        Text('The report contains:'),
        SizedBox(height: 8),
        _HelpBullets(
          values: [
            'Problems and their result types',
            'Launch, mod file, game setup, deployment, profile, and action IDs',
            'Report format, operating system, and processor architecture',
          ],
        ),
        SizedBox(height: 14),
        Text('The report does not contain:'),
        SizedBox(height: 8),
        _HelpBullets(
          values: [
            'Credentials, sign-in details or access tokens',
            'File contents or command lines',
            'Full personal, game, Steam, Proton, or temporary paths',
          ],
        ),
        SizedBox(height: 12),
        McStatus(
          title: 'Mod Conductor writes no report until you select a location',
        ),
      ],
    ),
  );
  if (save == true) await controller.exportReport();
  opener?.requestFocus();
}

class _HelpBullets extends StatelessWidget {
  const _HelpBullets({required this.values});
  final List<String> values;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final value in values)
        Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('•  '),
              Expanded(child: Text(value)),
            ],
          ),
        ),
    ],
  );
}
