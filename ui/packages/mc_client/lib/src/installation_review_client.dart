import 'installation_models.dart';
import 'generated/modconductor/v1/installation_review.pb.dart' as wire;

InstallationReviewedFile reviewedFile(
  wire.InstallationReviewedFile file, {
  bool included = true,
}) => InstallationReviewedFile(
  file.index,
  List.unmodifiable(file.destination),
  List.unmodifiable(file.source),
  file.choice,
  file.bytes.toInt(),
  [for (final source in file.replaces) List.unmodifiable(source.path)],
  included: included,
);
