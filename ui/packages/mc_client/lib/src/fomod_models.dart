import 'installation_models.dart';

enum FomodGroupKind { any, all, atLeastOne, atMostOne, exactlyOne }

enum FomodOptionKind {
  required,
  recommended,
  optional,
  notUsable,
  couldBeUsable,
  unknown,
}

class FomodOption {
  const FomodOption({
    required this.id,
    required this.name,
    required this.description,
    required this.kind,
    required this.selected,
    required this.canChange,
    required this.image,
    this.problem,
  });
  final int id;
  final String name, description;
  final FomodOptionKind kind;
  final bool selected, canChange;
  final List<String> image;
  final String? problem;
}

class FomodGroup {
  const FomodGroup(this.name, this.kind, this.options);
  final String name;
  final FomodGroupKind kind;
  final List<FomodOption> options;
}

class FomodChoices {
  const FomodChoices({
    required this.reference,
    required this.profileId,
    required this.name,
    required this.stepName,
    required this.stepNumber,
    required this.visibleSteps,
    required this.hasStep,
    required this.canBack,
    required this.groups,
    required this.files,
    required this.reviewReady,
    this.reviewedDraft,
    this.problem,
  });
  final InstallationDraftReference reference;
  final String profileId, name, stepName;
  final int stepNumber, visibleSteps;
  final bool hasStep, canBack, reviewReady;
  final List<FomodGroup> groups;
  final List<InstallationReviewedFile> files;
  final InstallationDraft? reviewedDraft;
  final String? problem;
}
