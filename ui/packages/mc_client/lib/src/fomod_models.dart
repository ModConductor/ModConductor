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

class FomodReference {
  const FomodReference(this.workspaceId, this.id, this.revision);
  final String workspaceId, id;
  final int revision;
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

class FomodPlannedFile {
  const FomodPlannedFile(
    this.index,
    this.destination,
    this.source,
    this.choice,
    this.bytes,
    this.replaces,
  );
  final int index, bytes;
  final List<String> destination, source;
  final String choice;
  final List<List<String>> replaces;
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
  final FomodReference reference;
  final String profileId, name, stepName;
  final int stepNumber, visibleSteps;
  final bool hasStep, canBack, reviewReady;
  final List<FomodGroup> groups;
  final List<FomodPlannedFile> files;
  final InstallationDraft? reviewedDraft;
  final String? problem;
}
