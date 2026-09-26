part of 'profile_setup.dart';

class _ProfileSetupChoiceTile<T> extends StatelessWidget {
  const _ProfileSetupChoiceTile({
    required this.radioKey,
    required this.value,
    required this.selected,
    required this.enabled,
    required this.title,
    required this.subtitle,
    required this.selectedFillOpacity,
    this.secondary,
  });

  final Key radioKey;
  final T value;
  final bool selected;
  final bool enabled;
  final Widget title;
  final Widget subtitle;
  final double selectedFillOpacity;
  final Widget? secondary;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: McSpacing.small),
      child: Material(
        color: selected
            ? colors.primary.withValues(alpha: selectedFillOpacity)
            : Colors.transparent,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: selected ? colors.primary : colors.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: RadioListTile<T>(
          key: radioKey,
          value: value,
          enabled: enabled,
          title: title,
          subtitle: subtitle,
          secondary: secondary,
        ),
      ),
    );
  }
}
