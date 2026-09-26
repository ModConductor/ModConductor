part of 'app.dart';

Future<void> _showActivePreferences(
  BuildContext context,
  AppLocalizations labels,
  _Preferences applied,
  String Function(AppearancePreference) appearance,
  String Function(ContrastPreference) contrast,
) async {
  final previous = FocusManager.instance.primaryFocus;
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(labels.activePreferences),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                labels.appearance,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: McSpacing.small),
              Text(appearance(applied.appearance)),
              const SizedBox(height: McSpacing.large),
              Text(
                labels.interfaceSize,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: McSpacing.small),
              Text(
                labels.textScalePercent((applied.interfaceScale * 100).round()),
              ),
              const SizedBox(height: McSpacing.large),
              Text(
                labels.textSize,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: McSpacing.small),
              Text(labels.textScalePercent((applied.textScale * 100).round())),
              const SizedBox(height: McSpacing.large),
              Text(
                labels.contrast,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: McSpacing.small),
              Text(contrast(applied.contrast)),
            ],
          ),
        ),
      ),
      actions: [
        McAction(label: labels.close, onPressed: () => Navigator.pop(context)),
      ],
    ),
  );
  if (previous?.context != null) previous!.requestFocus();
}
