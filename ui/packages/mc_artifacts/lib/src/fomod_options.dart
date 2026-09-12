import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

String? fomodOptionLabel(FomodOptionKind kind) => switch (kind) {
  FomodOptionKind.required => 'Required',
  FomodOptionKind.recommended => 'Recommended',
  FomodOptionKind.optional => null,
  FomodOptionKind.notUsable => 'Not available',
  FomodOptionKind.couldBeUsable => 'Check requirements',
  FomodOptionKind.unknown => 'Requirement not checked',
};

class FomodOptionGroups extends StatelessWidget {
  const FomodOptionGroups({
    super.key,
    required this.groups,
    required this.available,
    required this.choose,
    required this.inspect,
  });
  final List<FomodGroup> groups;
  final bool available;
  final void Function(FomodOption, bool) choose;
  final ValueChanged<FomodOption> inspect;
  Widget row(BuildContext c, FomodOption option, {required bool radio}) {
    final label = fomodOptionLabel(option.kind),
        enabled = available && option.canChange;
    return Row(
      children: [
        Expanded(
          child: radio
              ? RadioListTile<int>(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  title: Text(option.name),
                  subtitle: label == null ? null : Text(label),
                  value: option.id,
                  enabled: enabled,
                  toggleable: true,
                )
              : CheckboxListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(option.name),
                  subtitle: label == null ? null : Text(label),
                  value: option.selected,
                  onChanged: enabled
                      ? (selected) => choose(option, selected!)
                      : null,
                ),
        ),
        McIconAction(
          label: 'Details for ${option.name}',
          icon: const Icon(Icons.info_outline),
          onPressed: () => inspect(option),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => ListView.builder(
    itemCount: groups.length,
    itemBuilder: (context, index) {
      final group = groups[index],
          radio =
              group.kind == FomodGroupKind.exactlyOne ||
              group.kind == FomodGroupKind.atMostOne;
      final options = Column(
        children: [
          for (var i = 0; i < group.options.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            row(context, group.options[i], radio: radio),
          ],
        ],
      );
      return Padding(
        padding: EdgeInsets.only(bottom: index == groups.length - 1 ? 0 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (groups.length > 1) ...[
              Text(group.name, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
            ],
            Material(
              color: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: radio
                  ? RadioGroup<int>(
                      groupValue: group.options
                          .where((option) => option.selected)
                          .firstOrNull
                          ?.id,
                      onChanged: (id) {
                        final option = group.options.firstWhere(
                          (option) =>
                              option.id ==
                              (id ??
                                  group.options
                                      .firstWhere((option) => option.selected)
                                      .id),
                        );
                        choose(option, id != null);
                      },
                      child: options,
                    )
                  : options,
            ),
          ],
        ),
      );
    },
  );
}
