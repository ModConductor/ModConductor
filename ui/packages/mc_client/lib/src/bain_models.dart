import 'installation_models.dart';

class BainPackage {
  const BainPackage(
    this.index,
    this.name,
    this.files,
    this.bytes,
    this.selected,
  );
  final int index, files, bytes;
  final String name;
  final bool selected;
}

class BainChoices {
  const BainChoices({
    required this.reference,
    required this.packages,
    required this.files,
    required this.reviewing,
    required this.hasNotes,
    this.problem,
    this.reviewedDraft,
  });
  final InstallationDraftReference reference;
  final List<BainPackage> packages;
  final List<InstallationReviewedFile> files;
  final bool reviewing, hasNotes;
  final String? problem;
  final InstallationDraft? reviewedDraft;
}
